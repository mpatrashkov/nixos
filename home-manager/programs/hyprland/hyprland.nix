{ config, ... }:

{
  xdg.configFile."hypr/hyprland.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/flake/home-manager/programs/hyprland/config/hyprland.conf";

  xdg.configFile."hypr/start.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/flake/home-manager/programs/hyprland/config/hyprland-start.sh";
}
