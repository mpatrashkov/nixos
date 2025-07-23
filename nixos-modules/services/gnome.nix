{ lib, ... }:
{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      settings = {
        "org/gnome/desktop/wm/keybindings" = {
          switch-applications = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
          switch-applications-backward = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
          switch-windows = lib.gvariant.mkArray [ "<Alt>Tab" ];
          switch-windows-backward = lib.gvariant.mkArray [ "['<Shift><Alt>Tab']" ];
        };
        "org/gnome/mutter" = {
          experimental-features = lib.gvariant.mkArray [
            "scale-monitor-framebuffer"
            "xwayland-native-scaling"
          ];
        };
      };
    }
  ];

  programs.dconf.profiles.gdm.databases = [
    {
      lockAll = true;
      settings."org/gnome/desktop/interface".scaling-factor = lib.gvariant.mkUint32 2;
    }
  ];
}
