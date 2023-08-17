{ pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = import ./settings.nix;
  };
}
