# Autonomous FBG triage pipeline — user systemd services + timers.
#
# A persistent dev server stays warm; staggered timers fire headless `claude` on
# the triage skills:
#   intake (:03,:33) -> fixer (:08,:23,:38,:53) -> reviewer (:15,:45)
#   publish (12am,5pm) — batches reviewed-and-passed fixes into one PR
# so each stage catches the previous stage's fresh output within a cycle. Every
# run is gated by has_work.sh: if there's nothing to do, claude is NOT invoked
# (no wasted tokens), and a gate/agent failure alerts via ntfy instead of looping.
#
# One-time host setup (the API key must NOT live in the world-readable nix store):
#   mkdir -p ~/.config/fbg-triage
#   printf 'ANTHROPIC_API_KEY=%s\n' 'sk-ant-...' > ~/.config/fbg-triage/env
#   chmod 600 ~/.config/fbg-triage/env
#   (better still: sops-nix / agenix)
#
# Apply:  nrs
# Watch:  journalctl --user -u triage-fixer -f
# Pause:  systemctl --user stop triage-fixer.timer   (or disable in this module)
{ pkgs, ... }:
let
  repo = "/home/sam/Development/work/fbg-cloud-server";
  keyFile = "%h/.config/fbg-triage/env"; # ANTHROPIC_API_KEY=... (mode 600)

  # Persistent server — kept warm so timer runs don't start/stop it (which would
  # race when fixer and reviewer overlap). Runs inside the repo's flake dev shell
  # for uv + the pinned interpreter + wheel LD_LIBRARY_PATH.
  fbgServer = pkgs.writeShellApplication {
    name = "fbg-server";
    runtimeInputs = [ pkgs.nix pkgs.git ];
    text = ''
      cd "${repo}"
      exec nix develop "path:${repo}" --command \
        uv run fastapi dev main.py --host 127.0.0.1 --port 8000
    '';
  };

  # One timer run: single-flight lock, a cheap no-LLM work check, then headless
  # claude on one skill only if there's actually work. TRIAGE_SERVER_MANAGED=1
  # makes the skill's server_up/down leave the persistent server alone. gh +
  # claude-code + curl are on PATH here (systemd user PATH is minimal, so we
  # can't rely on the global home.packages ones); SSL_CERT_FILE + curl let the
  # scripts publish ntfy alerts (the topic auth token lives in the repo .env as
  # NTFY_API). The gate (has_work.sh) fails CLOSED: on its own error it alerts
  # once and skips the run, so a broken environment can't loop failing agents.
  triageRun = pkgs.writeShellApplication {
    name = "fbg-triage-run";
    runtimeInputs = [ pkgs.nix pkgs.git pkgs.gh pkgs.claude-code pkgs.util-linux pkgs.coreutils pkgs.curl pkgs.cacert ];
    text = ''
      stage="''${1:?usage: fbg-triage-run <stage> <skill-prompt>}"
      cmd="''${2:?usage: fbg-triage-run <stage> <skill-prompt>}"
      lockdir="''${XDG_RUNTIME_DIR:-/tmp}/fbg-triage"; mkdir -p "$lockdir"
      lock="$lockdir/$stage.lock"
      exec 9>"$lock"
      flock -n 9 || { echo "skip: previous [$stage] run still going"; exit 0; }
      export TRIAGE_SERVER_MANAGED=1
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      cd "${repo}"
      # run_stage.sh gates, runs the agent, and alerts on crash — inside the dev
      # shell so its intake gate has uv/gh and curl+certs reach ntfy.
      exec nix develop "path:${repo}" --command \
        bash "${repo}/.claude/skills/triage/scripts/run_stage.sh" "$stage" "$cmd"
    '';
  };

  # oneshot service + timer pair. `at` is a systemd OnCalendar expression.
  job = name: prompt: at: {
    services."triage-${name}" = {
      Unit = {
        Description = "Triage ${name}";
        After = [ "fbg-server.service" "network-online.target" ];
        Wants = [ "fbg-server.service" ];
      };
      Service = {
        Type = "oneshot";
        WorkingDirectory = repo;
        EnvironmentFile = keyFile;
        ExecStart = "${triageRun}/bin/fbg-triage-run ${name} ${prompt}";
        TimeoutStartSec = "1800";
      };
    };
    timers."triage-${name}" = {
      Unit.Description = "Triage ${name} schedule";
      Timer = {
        OnCalendar = at;
        Persistent = false; # polling — no missed-run catch-up storm
        AccuracySec = "20s"; # honor the staggered minutes
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };

  intake = job "intake" "/triage-intake" "*:03,33";
  fixer = job "fixer" "/triage" "*:08,23,38,53";
  reviewer = job "reviewer" "/triage-review" "*:15,45";
  # publish (stage "publish" -> unit triage-publish) batches passed fixes at 12am/5pm.
  publisher = job "publish" "/triage-publish" "*-*-* 00,17:00:00";
in
{
  systemd.user.services =
    {
      fbg-server = {
        Unit = {
          Description = "FBG cloud dev server (triage pipeline)";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          ExecStart = "${fbgServer}/bin/fbg-server";
          WorkingDirectory = repo;
          Restart = "always";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    }
    // intake.services
    // fixer.services
    // reviewer.services
    // publisher.services;

  systemd.user.timers = intake.timers // fixer.timers // reviewer.timers // publisher.timers;
}
