{ config, ... }:

{
  xdg.configFile."hypr".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/flake/home-manager/programs/hyprland/config";
}
