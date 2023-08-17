{ config, pkgs, lib, ... }:

let
  mypolybar = pkgs.polybar.override {
    # alsaSupport = true;
    # githubSupport = true;
    # mpdSupport = true;
    pulseSupport = true;
    i3Support = true;
  };

  #   weatherScript = pkgs.callPackage ./modules/weather/weather.nix {};

  #   weather = ''
  # [module/weather]
  # type = custom/script
  # exec = ${weatherScript}/bin/weather
  # tail = false
  # interval = 960
  # '';

in
{
  services.polybar = {
    enable = true;
    package = mypolybar;
    config = ./config.ini;
    # extraConfig = weather;
    script = builtins.readFile ./start.sh;
  };

  systemd.user.services.polybar.Service.Environment = lib.mkForce "";
  systemd.user.services.polybar.Service.PassEnvironment = "PATH";
}
