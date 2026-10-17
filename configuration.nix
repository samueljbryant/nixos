{ pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # limit the number of nix generations we track, cosmetic only
  boot.loader.systemd-boot.configurationLimit = 10;

  # Clean up generations older than 14d, runs daily
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # dedup identical files in the store
  nix.settings.auto-optimise-store = true;

  # Enable rest mode on this laptop
  boot.resumeDevice = "/dev/vg/swap";

  networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";
  hardware.bluetooth.enable = true;

  # Lets a non-root process (kanata, spawned by niri) create a virtual keyboard.
  # Loads the uinput module, creates the `uinput` group, and adds a udev rule
  # making /dev/uinput group-writable. The `sam` user is added to `uinput`
  # (write the virtual device) and `input` (read the physical keyboards) below.
  hardware.uinput.enable = true;

  # Gamer stuff
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  services.displayManager.ly.enable = true;

  services.redis.servers."" = {
    enable = true;
    bind = "127.0.0.1";
    port = 6379;
  };

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ]; # Brother printers
  };

  # Let VIA (WebHID) open the WOBKEY Rainy 75 keyboard
  services.udev.extraRules = ''
    KERNEL=="hidraw*", ATTRS{idVendor}=="320f", ATTRS{idProduct}=="5055", MODE="0660", GROUP="users"
  '';

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Realtime scheduling for audio (avoids xruns/crackle). Recommended with PipeWire.
  security.rtkit.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;
  # virtualisation.docker.enable = true;
  virtualisation.podman.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sam = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "networkmanager"
      "input" # read /dev/input/event* (physical keyboards) for kanata
      "uinput" # write /dev/uinput (kanata's virtual keyboard)
      "podman"
    ];
    packages = with pkgs; [
      tree
    ];
  };

  users.groups.keyd = { };

  programs.firefox.enable = true;
  programs.niri.enable = true;
  programs.sway.enable = true;
  programs.mango.enable = true;
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib # provides libstdc++.so.6 + libgcc — fixes greenlet
      zlib # extremely common wheel dependency
      openssl
      # chromium runtime deps:
      glib
      nss
      nspr
      nssTools
      atk
      at-spi2-atk
      at-spi2-core
      cups
      dbus
      expat
      libdrm
      libxkbcommon
      mesa
      alsa-lib
      pango
      cairo
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxcb
      libgbm
    ];
  };

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    alacritty
    git
    less
    pipewire.jack # provides `pw-jack`, the wrapper that lets JACK apps (e.g. SuperCollider) find PipeWire's libjack
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;

  fonts.packages = with pkgs; [
    nerd-fonts._0xproto
    nerd-fonts.symbols-only
    nerd-fonts.victor-mono
    nerd-fonts.inconsolata
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.ubuntu-mono
    nerd-fonts.zed-mono
  ];

  fonts.fontconfig.defaultFonts.monospace = [
    "Inconsolata Nerd Font Mono"
    "0xProto Nerd Font Mono"
    "Symbols Nerd Font Mono"
    "FiraCode Nerd Font"
    "FiraMono Nerd Font"
    "JetBrainsMono Nerd Font"
    "UbuntuMono Nerd Font"
    "ZedMono Nerd Font"
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
