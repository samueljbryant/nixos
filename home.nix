{
  config,
  pkgs,
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
  };
in
{
  imports = [
    ./modules/neovim.nix
    ./modules/claude_code.nix
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
    };
    initExtra = ''
      source ${pkgs.blesh}/share/blesh/ble.sh
    '';
  };

  # More bash stuff
  # programs.starship = {
  #   enable = true;
  #   settings = {
  #     add_newline = false;
  #   };
  # };
  programs.fzf.enable = true;
  programs.zoxide.enable = true;
  programs.atuin.enable = true;

  # Auto-load per-project dev shells (flake devShells) when you cd into a
  # project directory containing a .envrc with `use flake`.
  # nix-direnv caches the evaluated shell so activation is near-instant.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    ripgrep
    gcc
    bat
    gh
    brightnessctl
    bluez
    posting
    redis
    zig
    proton-vpn

    # niri
    fuzzel
    xwayland-satellite
    wl-clipboard
    waybar
    swaybg
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

}
