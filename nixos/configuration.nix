{
  pkgs,
  lib,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  myNixOS.services.smb.enable = false;

  # TODO: this speeds up build times, remove when https://github.com/NixOS/nixpkgs/pull/414076 is merged
  documentation.man.generateCaches = false;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "Europe/Sofia";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "bg_BG.UTF-8";
    LC_IDENTIFICATION = "bg_BG.UTF-8";
    LC_MEASUREMENT = "bg_BG.UTF-8";
    LC_MONETARY = "bg_BG.UTF-8";
    LC_NAME = "bg_BG.UTF-8";
    LC_NUMERIC = "bg_BG.UTF-8";
    LC_PAPER = "bg_BG.UTF-8";
    LC_TELEPHONE = "bg_BG.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  environment.pathsToLink = [ "/libexec" ];

  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1u"
    "openssl-1.1.1w"
    "electron-25.9.0"
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.miro = {
    isNormalUser = true;
    description = "Miroslav Patrashkov";
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "docker"
      "input"
      "kvm"
      "adbusers"
      "i2c"
      "dialout"
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    firefox
    eog
    gnome-tweaks
    vscode
    pavucontrol
    virt-manager
    pulseaudio
    steam-run
    (lutris.override {
      extraLibraries = pkgs: [
        # List library dependencies here
      ];
    })

    xdg-utils
    glib

    wayland
    grim
    slurp
    wl-clipboard
    imagemagick

    wineWowPackages.waylandFull
    protonup-qt
    eza
    bat
    grc
    wlsunset

    (import ./programs/wlsunset-toggle/wlsunset-toggle.nix { inherit pkgs; })

    obsidian
    pamixer

    mkcert

    pnpm
    alacritty
    tor-browser
    kdePackages.kleopatra
  ];

  services.gvfs.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.dconf.enable = true;

  boot.supportedFilesystems = [ "ntfs" ];

  virtualisation.libvirtd = {
    enable = true;

    qemu = {
      swtpm = {
        enable = true;
      };
    };
  };

  # Sway
  security.polkit.enable = true;

  # Hardware acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.amdgpu.initrd.enable = true;
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
    VA_DRIVER_NAME = "radeonsi";
  };

  # Latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";

  # Fix Electron Apps Fractional Scaling
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Flatpack
  services.flatpak.enable = true;

  # Networking config
  networking = {
    hostName = "nixos";
    nameservers = [
      "127.0.0.1"
      "::1"
    ];
  };

  # Fish
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  environment.shells = with pkgs; [ fish ];

  # KVM
  boot.kernelModules = [
    "kvm-intel"
    "i2c-dev"
  ];

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Windows time fix
  time.hardwareClockInLocalTime = true;
}
