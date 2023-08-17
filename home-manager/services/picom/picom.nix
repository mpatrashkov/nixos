{ config, pkgs, lib, ... }:

{
  services.picom = {
    enable = true;
    backend = "xrender";
    vSync = true;

  };
}
