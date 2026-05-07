{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  hatter-icon-theme = pkgs.callPackage ./hatter-icon-theme.nix { };
in
{
  imports = [
    inputs.stylix.nixosModules.stylix
  ];
  stylix = {
    enable = true;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/google-dark.yaml";

    cursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };

    polarity = "dark";

    # Stylix auto-detects GNOME and picks `platform = "gnome"`, but its
    # GNOME platform is a no-op (only "qtct" is actually implemented),
    # which triggers stylix's own "unsupported platform" warning and a
    # downstream HM deprecation warning for `qt.platformTheme.name = "gnome"`.
    # Pinning to "qtct" enables real Qt theming via qt5ct/qt6ct + Kvantum.
    targets.qt.platform = lib.mkForce "qtct";
  };

  stylix.fonts = {
    serif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Serif";
    };

    sansSerif = {
      package = pkgs.ubuntu-sans;
      name = "Ubuntu Sans";
    };
  };

  stylix.icons = {
    enable = true;

    package = hatter-icon-theme;
    dark = "Hatter-Yaru";
    light = "Hatter-Yaru";
  };
}
