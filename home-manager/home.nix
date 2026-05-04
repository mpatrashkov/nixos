{ ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "miro";
  home.homeDirectory = "/home/miro";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.05";

  # Adopt HM 26.05's new default: GTK4 apps fall back to system Adwaita
  # rather than reusing the GTK3 theme (adw-gtk3 has no GTK4 build).
  gtk.gtk4.theme = null;

  fonts.fontconfig.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  services.xembed-sni-proxy = {
    enable = true;
  };
}
