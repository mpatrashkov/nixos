{ pkgs, config, ... }:

{
  programs.eww = {
    enable = true;
    package = pkgs.eww-wayland;
    configDir = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/flake/home-manager/programs/eww/config";
  };

  # xdg.configFile."eww".source = config.lib.file.mkOutOfStoreSymlink ./config;
}
