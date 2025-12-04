{
  pkgs,
  config,
  inputs,
  ...
}:
{
  imports = [ inputs.ags.homeManagerModules.default ];

  programs.ags = {
    enable = true;

    configDir = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/flake/home-manager-modules/features/ags/";

    extraPackages = with pkgs; [
      bun
    ];
  };

  home.packages = with pkgs; [
    bun
    sassc
  ];
}
