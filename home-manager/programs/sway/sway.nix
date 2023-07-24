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
        "${modifier}+d" = "exec --no-startup-id fuzzel";
        # "${modifier}+Shift+d" = "exec --no-startup-id fuzzel";
        "XF86AudioRaiseVolume" = "exec 'pactl set-sink-volume @DEFAULT_SINK@ +1%'";
        "XF86AudioLowerVolume" = "exec 'pactl set-sink-volume @DEFAULT_SINK@ -1%'";
        "XF86AudioMute" = "exec 'pactl set-sink-mute @DEFAULT_SINK@ toggle'";
      };
    };
    extraConfig = ''
      default_border pixel 0

      exec_always swww init

      exec sleep 1; systemctl --user start waybar.service
    '';
  };
}