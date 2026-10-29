{
  inputs,
  lib,
  config,
  ...
}:

{
  imports = [
    inputs.nix-index-database.nixosModules.default

    # Imports are unconditional, and upstream defaults its module to enabled.
    # Keep its switch tied to ours even when our config is gated off.
    {
      programs.nix-index-database.enable = lib.mkDefault config.myNixOS.programs.nix-index-database.enable;
    }
  ];

  programs.nix-index-database.comma.enable = true;
}
