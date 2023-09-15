{ pkgs, ... }:
let
  flake-compat = builtins.fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/master.tar.gz";
    sha256 = "sha256:1prd9b1xx8c0sfwnyzkspplh30m613j42l1k789s521f4kv4c2z2";
  };

  hyprland-flake = (import flake-compat {
    src = builtins.fetchTarball {
      url = "https://github.com/hyprwm/Hyprland/archive/master.tar.gz";
      sha256 = "sha256:1a9y3ynrwmdpzjwrdl39dnbg30pnd1x5q8c00927sdpdqzga6k4z";
    };
  }).defaultNix;
in
{
  programs.hyprland = {
    enable = true;
    package = hyprland-flake.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
  };
}
