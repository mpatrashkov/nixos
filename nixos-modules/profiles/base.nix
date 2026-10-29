{ lib, ... }:

{
  myNixOS = {
    services = {
      i18n.enable = lib.mkDefault true;
      users.enable = lib.mkDefault true;
    };

    programs = {
      fastfetch.enable = lib.mkDefault true;
      fish.enable = lib.mkDefault true;
      nh.enable = lib.mkDefault true;
      nix-index-database.enable = lib.mkDefault true;
      nix-ld.enable = lib.mkDefault true;
      nix-search-tv.enable = lib.mkDefault true;
      stow.enable = lib.mkDefault true;
    };

    features.generations.enable = lib.mkDefault true;
  };
}
