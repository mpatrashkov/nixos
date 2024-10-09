{ pkgs, ... }:

{
  programs.rofi = {
    package = pkgs.rofi-wayland;
    enable = true;
    # theme = ./spotlight-dark.rasi;
  };
}
