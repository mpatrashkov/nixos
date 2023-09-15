{ pkgs, ... }:

{
  programs.rofi = {
    package = pkgs.rofi-wayland;
    enable = true;
    theme = ./windows11-grid-dark.rasi;
  };
}
