{ lib, pkgs, ... }:
{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    gnome-console
    gnome-system-monitor
  ];

  # Extensions
  imports = [
    ./extensions/multi-monitors.nix
    # Disabling AWSM fow now, as I can't make it work for apps with multiple windows (e.g. Chrome, VSCode, Alacritty)
    # ./extensions/another-window-session-manager.nix
    ./whitesur-wallpapers.nix
    ./xkb-overrides.nix
  ];
  environment.systemPackages = with pkgs.gnomeExtensions; [
    dash-to-dock
  ];

  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      settings = {
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

        # Neutralize GNOME/libinput acceleration so the YeetMouse kernel module
        # (Windows EPP curve) is the sole source of pointer acceleration.
        # "flat" = pure 1:1 in libinput, speed 0.0 = no extra scaling.
        "org/gnome/desktop/peripherals/mouse" = {
          accel-profile = lib.gvariant.mkString "flat";
          speed = lib.gvariant.mkDouble 0.0;
        };

        "org/gnome/desktop/session" = {
          idle-delay = lib.gvariant.mkUint32 900;
        };

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

        "org/gnome/settings-daemon/plugins/media-keys" = {
          custom-keybindings = [
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
          ];
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          name = "Audio Switch: HDMI Monitor";
          command = "switch-audio hdmi";
          binding = "F22";
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
          name = "Audio Switch: FiiO K11";
          command = "switch-audio fiio";
          binding = "F23";
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
          name = "Audio Switch: Logitech Headset";
          command = "switch-audio logitech";
          binding = "F24";
        };

        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = lib.gvariant.mkString "nothing";
        };

        "org/gnome/shell" = {
          enabled-extensions = lib.gvariant.mkArray [
            "dash-to-dock@micxgx.gmail.com"
            "multi-monitor-panel@coolssor"
            "another-window-session-manager@gmail.com"
            # TODO: not sure about this one
            "user-theme@gnome-shell-extensions.gcampax.github.com"
          ];

          favorite-apps = lib.gvariant.mkArray [
            "google-chrome.desktop"
            "code.desktop"
            "kitty.desktop"
            "org.gnome.Nautilus.desktop"
          ];

          last-selected-power-profile = lib.gvariant.mkString "performance";
        };

        "org/gnome/shell/extensions/dash-to-dock" = {
          custom-theme-shrink = lib.gvariant.mkBoolean true;
          dash-max-icon-size = lib.gvariant.mkInt32 42;
          disable-overview-on-startup = lib.gvariant.mkBoolean true;
          dock-fixed = lib.gvariant.mkBoolean true;
          dock-position = lib.gvariant.mkString "LEFT";
          extend-height = lib.gvariant.mkBoolean true;
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
