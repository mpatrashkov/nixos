{
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  myNixOS.services.smb.enable = false;

  environment.pathsToLink = [ "/libexec" ];

  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1u"
    "openssl-1.1.1w"
    "electron-25.9.0"
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Override openldap to skip flaky tests
  nixpkgs.config.packageOverrides = pkgs: {
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
    protonup-qt

    obsidian

    mkcert

    pnpm
    alacritty
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
