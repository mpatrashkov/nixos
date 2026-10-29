{ lib, ... }:

{
  myNixOS.programs = {
    games.enable = lib.mkDefault true;
    steam.enable = lib.mkDefault true;
  };
}
