{
  inputs,
  ...
}:

{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    ./wslg.nix
  ];

  wsl.enable = true;
  wsl.defaultUser = "miro";

  networking.hostName = "wsl";
  nixpkgs.hostPlatform = "x86_64-linux";

  myNixOS = {
    profiles = {
      base.enable = true;
      development.enable = true;
    };

    # Keep the existing WSLg applications without enabling a full desktop.
    programs = {
      terminal.enable = true;
      slack.enable = true;
    };
    services.fonts.enable = true;
  };
  fonts.fontconfig.defaultFonts.monospace = [ "CaskaydiaCove Nerd Font Mono" ];

  # Expose .desktop files (kitty) in the Windows Start menu.
  wsl.startMenuLaunchers = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "26.05"; # Did you read the comment?
}
