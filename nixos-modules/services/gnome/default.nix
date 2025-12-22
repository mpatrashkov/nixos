{ lib, pkgs, ... }:
{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    gnome-console
  ];

  # Extensions
  imports = [ ./extensions/multi-monitors.nix ];
  environment.systemPackages = with pkgs.gnomeExtensions; [
    dash-to-dock
  ];

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

        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = lib.gvariant.mkString "nothing";
        };

        "org/gnome/shell" = {
          enabled-extensions = lib.gvariant.mkArray [
            "dash-to-dock@micxgx.gmail.com"
            "multi-monitor-panel@coolssor"
            # TODO: not sure about this one
            "user-theme@gnome-shell-extensions.gcampax.github.com"
          ];

          favorite-apps = lib.gvariant.mkArray [
            "google-chrome.desktop"
            "code.desktop"
            "Alacritty.desktop"
            "org.gnome.Nautilus.desktop"
          ];
        };

        "org/gnome/shell/extensions/dash-to-dock" = {
          dock-position = lib.gvariant.mkString "LEFT";
          dock-fixed = lib.gvariant.mkBoolean true;
          extend-height = lib.gvariant.mkBoolean true;
          disable-overview-on-startup = lib.gvariant.mkBoolean true;
        };

        "org/gnome/desktop/input-sources" = {
          sources = [
            (lib.gvariant.mkTuple [
              "xkb"
              "us"
            ])
            (lib.gvariant.mkTuple [
              "xkb"
              "bg+phonetic"
            ])
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

  environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 =
    lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0"
      (
        with pkgs.gst_all_1;
        [
          gst-plugins-good
          gst-plugins-bad
          gst-plugins-ugly
          gst-libav
        ]
      );
}
