{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # TODO: re-enable once wallpaper-daemon is published (see .ideas/publish-wallpaper-daemon.md).
    # The local `path:` input can't be fetched on other hosts (e.g. WSL).
    # inputs.wallpaper-daemon.nixosModules.default
  ];

  # services.wallpaper-daemon = {
  #   enable = true;
  #   rotateInterval = "1h";
  #   fetchInterval = "6h";
  #   country = "US";
  #   locale = "en-US";
  # };

  networking.hostName = "nixos";

  # Windows stores the hardware clock in local time, while Linux
  # expects it to be in UTC. This fixes the time showing incorrectly
  # when dual-booting.
  time.hardwareClockInLocalTime = true;

  myNixOS.services.smb.enable = false;

  environment.pathsToLink = [ "/libexec" ];

  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1u"
    "openssl-1.1.1w"
    "electron-25.9.0"
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.packageOverrides = pkgs: {
    # Skip flaky tests in the openldap build.
    openldap = pkgs.openldap.overrideAttrs (oldAttrs: {
      doCheck = false;
    });
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    firefox
    gnome-tweaks
    vscode

    pulseaudio
    steam-run

    xdg-utils
    glib

    wineWow64Packages.waylandFull

    obsidian

    mkcert

    pnpm
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

  virtualisation.libvirtd = {
    enable = true;

    qemu = {
      swtpm = {
        enable = true;
      };
    };
  };

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

  # Fix Electron Apps Fractional Scaling
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Flatpack
  services.flatpak.enable = true;

  # KVM
  boot.kernelModules = [
    "kvm-intel"
    "i2c-dev"
  ];

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}
