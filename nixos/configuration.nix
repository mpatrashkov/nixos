# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, config, pkgs, lib, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Amd Driver
  boot.initrd.kernelModules = [ "amdgpu" ];

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
    LC_TIME = "bg_BG.UTF-8";
  };

  environment.pathsToLink = [ "/libexec" ];

  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1u"
    "electron-25.9.0"
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.miro = {
    isNormalUser = true;
    description = "Miroslav Patrashkov";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "docker" "input" "kvm" "adbusers" "i2c" "dialout" ];
    packages = with pkgs; [ ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    firefox
    gnome.eog
    gnome.gnome-tweaks
    vscode
    git
    pavucontrol
    neofetch
    virt-manager
    pulseaudio
    steam-run
    gamescope
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
    nil
    nixpkgs-fmt

    wineWowPackages.waylandFull
    protonup-qt
    eza
    grc
    wlsunset

    (import ./programs/wlsunset-toggle/wlsunset-toggle.nix { inherit pkgs; })

    obsidian
    pamixer
  ];

  services.gvfs.enable = true;

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  # Needed by Wayland
  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
    };
  };


  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  environment.etc."wireplumber/main.lua.d/51-disable-suspension.lua" = {
    text = ''
        table.insert (alsa_monitor.rules, {
        matches = {
          {
            -- Matches all sources.
            { "node.name", "matches", "alsa_input.*" },
          },
          {
            -- Matches all sinks.
            { "node.name", "matches", "alsa_output.*" },
          },
        },
        apply_properties = {
          ["session.suspend-timeout-seconds"] = 0,  -- 0 disables suspend
        },
      })
    '';
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  programs.dconf.enable = true;

  boot.supportedFilesystems = [ "ntfs" ];

  virtualisation.libvirtd = {
    enable = true;

    qemu = {
      swtpm = {
        enable = true;
      };
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      };
    };
  };

  # Sway
  security.polkit.enable = true;

  # Latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # # Fix dual monitors
  # boot.kernelParams = [
  #   "video=HDMI-A-5:3840x2160@60"
  #   "video=DP-4:3840x2160@60"
  # ];

  # Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "btrfs";

  # Fix Electron Apps Fractional Scaling
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Flatpack
  services.flatpak.enable = true;
  # xdg.portal = {
  #   enable = true;
  #   gtkUsePortal = true;
  #   extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
  # };

  # Networking config
  networking = {
    hostName = "nixos";
    nameservers = [ "127.0.0.1" "::1" ];
    networkmanager = {
      enable = true;
      dns = "none";
    };
  };

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;

      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };

      # You can choose a specific set of servers from https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
      # server_names = [ ... ];
    };
  };

  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };

  # Zsh
  # programs.zsh.enable = true;
  # users.defaultUserShell = pkgs.zsh;
  # environment.shells = with pkgs; [ zsh ];

  # Fish
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  environment.shells = with pkgs; [ fish ];

  # KVM
  boot.kernelModules = [ "kvm-intel" "i2c-dev" ];

  # KDE
  # services.xserver.enable = true;
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # GNOME
  # services.xserver.enable = true;
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
  # services.xserver.desktopManager.default = "gnome";
  # hardware.pulseaudio.enable = false;

  # Sway
  services.dbus.enable = true;
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # gtk portal needed to make gtk apps happy
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # gnome keyring
  services.gnome.gnome-keyring.enable = true;

  # Cachix
  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  # Hyprland
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
  };

  # Icon font
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "CascadiaCode" ]; })
  ];

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Windows time fix
  time.hardwareClockInLocalTime = true;
}

