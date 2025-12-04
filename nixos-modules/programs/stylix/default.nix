{
  pkgs,
  inputs,
  ...
}:
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
  };

  stylix.targets.gnome.enable = false;
}
