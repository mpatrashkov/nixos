{ ... }:
{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      # !! Not Tested
      settings = {
        "org/gnome/desktop/wm/keybindings" = {
          switch-applications = "@as []";
          switch-applications-backward = "@as []";
          switch-windows = "['<Alt>Tab']";
          switch-windows-backward = "['<Shift><Alt>Tab']";
        };
      };
    }
  ];
}
