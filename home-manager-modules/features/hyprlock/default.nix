{ config, ... }: {
  programs.hyprlock.enable = true;

  xdg.configFile."hypr/hyprlock.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/flake/home-manager-modules/features/hyprlock/hyprlock.conf";
}
