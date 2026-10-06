{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  dotfiles = "${config.home.homeDirectory}/nixos_dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

  # Rule of thumb for wiring a new tool:
  #   - Background DAEMON that must start with the session (mako, swayidle)?
  #       Use its home-manager module (services.*/programs.*). The real value is
  #       the systemd user service bound to graphical-session.target; its config
  #       is usually trivial. Don't also list the package below — the module adds it.
  #   - Config-heavy app you hand-tune (waybar, niri, nvim, alacritty)?
  #       Install the package below and symlink its NATIVE config file via `configs`
  #       (mkOutOfStoreSymlink). You keep the tool's own format + live hot-reload
  #       (edit the file, no rebuild). A module would translate it to Nix and force
  #       a `nrs` per tweak.
  #   - No module exists at all (swaybg, wl-clipboard, xwayland-satellite)?
  #       Package + manual wiring (niri spawn-at-startup, etc.) is the only option.
  # See `man home-configuration.nix` to check whether a tool has a module.

  configs = {
    nvim = "nvim";
    alacritty = "alacritty";
    posting = "posting";
    niri = "niri";
    waybar = "waybar";
    kanata = "kanata";
    # starship reads ~/.config/starship.toml (a bare FILE, not a dir), so key
    # this by the filename — the map then symlinks that exact path.
    "starship.toml" = "starship/starship.toml";
  };

  # Keys rendered into the fbg-cloud-server .env. Order mirrors the original
  # .env. Add/remove here in lockstep with `sops secrets/fbg.env`.
  awsKeys = [
    "AWS_ACCESS_KEY_ID"
    "AWS_SECRET_ACCESS_KEY"
    "AWS_DEFAULT_REGION"
  ];

  fbgAppKeys = [
    "FBG_API_KEY"
    "NTFY_API"
    "REDIS_HOST"
    "REDIS_PORT"
    "DATAFORCE_API_KEY"
    "RT_SPORTS_API_KEY"
    "SHGN_API_KEY"
    "SLEEPER_LOGIN"
    "MFL_LOGIN"
    "MFL_PASSWORD"
    "RTSPORTS_LOGIN"
    "RTSPORTS_PASSWORD"
    "NFC_CUST_ID"
    "FLEA_LOGIN"
    "FLEA_PASSWORD"
    "FFPC_LOGIN"
    "FFPC_PASSWORD"
    "FTX_SECRET"
    "DF_SECRET"
    "ESPN_COOKIES"
    "CBS_COOKIES"
    "BASECAMP_CLIENT_ID"
    "BASECAMP_CLIENT_SECRET"
  ];
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ./modules/neovim.nix
    ./modules/claude_code.nix
    # ./modules/wispr-flow.nix  # disabled: path input narHash mismatch, see flake.lock
  ];
  home.username = "sam";
  home.homeDirectory = "/home/sam";
  home.stateVersion = "26.05";

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "samueljbryant";
        email = "bryantsj@gmail.com";
      };
      core.editor = "nvim";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # Python now lives in per-project flake dev shells (templates/python), which
  # pin the interpreter and point uv at it (only-system). No global uv here.

  # Point foreign binaries (e.g. downloaded tool binaries) at NixOS's CA bundle;
  # their bundled OpenSSL looks for /etc/ssl/cert.pem, which doesn't exist here.
  home.sessionVariables.SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";

  # TODO: this can maybe be removed?
  xresources.properties = {
    "Xft.dpi" = 96;
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo i use nixos, btw";
      vi = "nvim";
      vim = "nvim";
      nrs = "sudo nixos-rebuild switch --flake ~/nixos_dotfiles#nixos-laptop";
      alre = "touch ~/.config/alacritty/alacritty.toml";
      fbg = "cd ~/Development/work/fbg-cloud-server";
      initrs = "cp -rT ~/nixos_dotfiles/templates/rust . && direnv allow";
      initpy = "cp -rT ~/nixos_dotfiles/templates/python . && direnv allow";
      initzig = "cp -rT ~/nixos_dotfiles/templates/zig . && direnv allow";
      initsc = "cp -rT ~/nixos_dotfiles/templates/supercollider . && direnv allow";
      initts = "cp -rT ~/nixos_dotfiles/templates/typescript/ . && direnv allow";
      initgo = "cp -rT ~/nixos_dotfiles/templates/go/ . && direnv allow";
      initc = "cp -rT ~/nixos_dotfiles/templates/c/ . && direnv allow && cp ~/nixos_dotfiles/templates/c/.clang-format .";
      initodin = "cp -rT ~/nixos_dotfiles/templates/odin/ . && direnv allow";
      aws_yah_errors = "aws logs tail '/fbg/prod/cs/requests/yahoo' --since 1h 2>&1 | grep -v ' OK ' | bat";
    };
    enableCompletion = true;
  };

  # More bash stuff.
  # enable = true wires `starship init bash` into bashrc AND sets
  # STARSHIP_CONFIG=~/.config/starship.toml. We deliberately DON'T set
  # `settings`: that would make the module generate ~/.config/starship.toml
  # itself, colliding with our symlink. With settings unset the module leaves
  # that path free, and the `configs` map symlinks our hand-tuned toml there.
  programs.starship.enable = true;
  # programs.fzf.enable = true;
  # programs.zoxide.enable = true;
  # programs.atuin.enable = true;

  # Auto-load per-project dev shells (flake devShells) when you cd into a
  # project directory containing a .envrc with `use flake`.
  # nix-direnv caches the evaluated shell so activation is near-instant.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    # AWS
    awscli2

    # secrets management (edit with: sops secrets/fbg.env)
    sops
    age
    ssh-to-age

    ntfy-sh
    cron
    ripgrep
    gcc
    bat
    gh
    brightnessctl
    bluez
    posting
    redis
    zig
    proton-vpn-cli

    # niri
    fuzzel
    xwayland-satellite
    wl-clipboard
    waybar
    swaybg
    grim
    slurp

    # audio
    # Wrap SuperCollider's entry-point binaries so they launch under pw-jack
    # (needed on NixOS so scsynth can find PipeWire's libjack). Wrapping at the
    # package level — rather than via shell aliases — means ANY process that runs
    # these from PATH gets the wrapper: app launchers AND subprocesses like the
    # sclang that ScNvim spawns (which then boots scsynth as a child that inherits
    # pw-jack's LD_LIBRARY_PATH). pw-jack is idempotent, so the double-wrap when a
    # wrapped sclang spawns a wrapped scsynth is harmless.
    (symlinkJoin {
      name = "supercollider-pw-jack";
      paths = [ supercollider-with-sc3-plugins ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        for bin in scide sclang scsynth; do
          rm $out/bin/$bin
          makeWrapper ${pipewire.jack}/bin/pw-jack $out/bin/$bin \
            --add-flags ${supercollider-with-sc3-plugins}/bin/$bin
        done
      '';
    })
    # PD
    puredata
    pd-else
    cardinal

    # Keyboard layers
    kanata

    # website
    flyctl

    # Games
    openmw

    steam

    # Math
    lean

  ];

  # Notifications
  services.mako = {
    enable = true;
    settings = {
      font = "0xProto Nerd Font 11";
      default-timeout = 5000;
      border-radius = 6;
      background-color = "#89b4fa";
      text-color = "#cdd6fa";
      border-color = "#89b4fa";
      # overrides for critical notifications
      "urgency=critical" = {
        border-color = "#f38ba8";
        default-timeout = 0;
      };
    };
  };

  # services.keyd.enable = true;

  # Lock screen apearance (invoked by swayidle)
  programs.swaylock = {
    enable = true;
    settings = {
      color = "1e1e2e";
      indicator-radius = 100;
      show-failed-attempts = true;
    };
  };

  # Idle management: lock after 5 min, screen off at 10 min, lock before sleep
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.swaylock}/bin/swaylock -f";
      }
      {
        timeout = 600;
        command = "niri msg action power-off-monitors";
        resumeCommand = "niri msg action power-on-monitors";
      }
    ];
    events = {
      before-sleep = "${pkgs.swaylock}/bin/swaylock -f";
      lock = "${pkgs.swaylock}/bin/swaylock -f";
    };
  };

  fonts.fontconfig.enable = true;

  xdg.configFile = builtins.mapAttrs (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
  }) configs;

  # Posting looks for custom themes in XDG_DATA_HOME (~/.local/share), NOT
  # ~/.config — so this uses xdg.dataFile, not the configs map above. Same
  # out-of-store symlink trick: drop new *.yaml theme files in the source dir
  # and posting hot-reloads them; no rebuild needed.
  xdg.dataFile."posting/themes".source = create_symlink "${dotfiles}/posting-themes";

  # ── Secrets (sops-nix) ──────────────────────────────────────────────────────
  # Everything lives encrypted in ./secrets/fbg.yaml, decrypted at activation with
  # the age key at ~/.config/sops/age/keys.txt (dedicated keypair; recipient in
  # .sops.yaml). No plaintext hits disk: rendered templates are symlinks into
  # tmpfs ($XDG_RUNTIME_DIR/secrets). Edit with `sops secrets/fbg.yaml`; when
  # adding/removing keys, update fbgAppKeys above and re-run `nrs`.
  # NB: YAML (not dotenv) — this sops-nix's installer only extracts per-key from
  # yaml/json; dotenv secrets each resolve to the whole file.
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets/fbg.yaml;
    defaultSopsFormat = "yaml";

    secrets = lib.genAttrs (fbgAppKeys ++ awsKeys) (_: { });

    # The fbg app (pydantic env_file=".env") and triage scripts read .env from
    # the repo cwd. Render it as a symlink in the working tree; the plaintext
    # stays in tmpfs. It's git-ignored, so git ops can't lose it and `nrs`
    # always restores the link.
    templates."fbg-app-env" = {
      path = "/home/sam/Development/work/fbg-cloud-server/.env";
      content = lib.concatMapStringsSep "\n" (k: "${k}=${config.sops.placeholder.${k}}") fbgAppKeys;
    };

    templates."aws-credentials" = {
      path = "${config.home.homeDirectory}/.aws/credentials";
      content = ''
        [default]
        aws_access_key_id = ${config.sops.placeholder.AWS_ACCESS_KEY_ID}
        aws_secret_access_key = ${config.sops.placeholder.AWS_SECRET_ACCESS_KEY}
        region = ${config.sops.placeholder.AWS_DEFAULT_REGION}
      '';
    };

  };
}
