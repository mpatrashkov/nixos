{ pkgs, lib, ... }:

{
  wayland.windowManager.sway = {
    enable = true;
    systemd.enable = true;
    config = rec {
      modifier = "Mod4";
      # Use kitty as default terminal
      terminal = "alacritty"; 
      bars = [];
      output = {
        HDMI-A-1 = {
          scale = "1.75";
          pos = "0 0";
        };
        DP-4 = {
          scale = "1.75";
          pos = "2194 0";
        };
	    };
      gaps = {
        inner = 10;
        bottom = 5;
        left = 5;
        right = 5;
      };
      keybindings = lib.mkOptionDefault {
        "${modifier}+d" = "exec --no-startup-id rofi -show drun -show-icons";
        # "${modifier}+Shift+d" = "exec --no-startup-id fuzzel";
        "XF86AudioRaiseVolume" = "exec 'pactl set-sink-volume @DEFAULT_SINK@ +1%'";
        "XF86AudioLowerVolume" = "exec 'pactl set-sink-volume @DEFAULT_SINK@ -1%'";
        "XF86AudioMute" = "exec 'pactl set-sink-mute @DEFAULT_SINK@ toggle'";
        "${modifier}+Control+Right" = "move workspace to output right";
        "${modifier}+Control+Left" = "move workspace to output left";
        "${modifier}+Control+Down" = "move workspace to output down";
        "${modifier}+Control+Up" = "move workspace to output up";
      };
    };
    extraConfig = ''
      default_border pixel 0

      exec_always swww init

      exec sleep 1; systemctl --user start waybar.service

      input "type:keyboard" {
        xkb_layout us,bg
        xkb_variant intl,phonetic
        xkb_options grp:win_space_toggle
      }
    '';
  };
}