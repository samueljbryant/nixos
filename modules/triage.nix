# Autonomous FBG triage pipeline — user systemd services + timers.
#
# A persistent dev server stays warm; three staggered timers fire headless
# `claude` on the triage skills:
#   intake  (:03,:33)  ->  fixer (:08,:23,:38,:53)  ->  reviewer (:15,:45)
# so each stage catches the previous stage's fresh output within a cycle.
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

  # One timer run: single-flight lock, then headless claude on one skill.
  # TRIAGE_SERVER_MANAGED=1 makes the skill's server_up/down leave the persistent
  # server alone. gh + claude-code are on PATH here (systemd user PATH is minimal,
  # so we can't rely on the global home.packages ones).
  triageRun = pkgs.writeShellApplication {
    name = "fbg-triage-run";
    runtimeInputs = [ pkgs.nix pkgs.git pkgs.gh pkgs.claude-code pkgs.util-linux pkgs.coreutils ];
    text = ''
      cmd="''${1:?usage: fbg-triage-run <skill-prompt>}"
      lockdir="''${XDG_RUNTIME_DIR:-/tmp}/fbg-triage"; mkdir -p "$lockdir"
      lock="$lockdir/$(printf '%s' "$cmd" | tr -c 'a-zA-Z0-9' _).lock"
      exec 9>"$lock"
      flock -n 9 || { echo "skip: previous [$cmd] run still going"; exit 0; }
      export TRIAGE_SERVER_MANAGED=1
      cd "${repo}"
      exec nix develop "path:${repo}" --command \
        claude -p "$cmd" \
          --dangerously-skip-permissions \
          --model opus \
          --max-turns 60 \
          --output-format json
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
        ExecStart = "${triageRun}/bin/fbg-triage-run ${prompt}";
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
    // reviewer.services;

  systemd.user.timers = intake.timers // fixer.timers // reviewer.timers;
}
