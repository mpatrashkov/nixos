{ config, ... }:

{
  xdg.configFile."fastfetch/config.jsonc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/flake/home-manager-modules/features/fastfetch/config.jsonc";

  xdg.configFile."fastfetch/short-config.jsonc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/flake/home-manager-modules/features/fastfetch/short-config.jsonc";
}
