{ pkgs, ... }:

{
  config = {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;
    };

    services.pipewire.wireplumber.configPackages = [
      (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/51-disable-suspension.conf" ''
        monitor.alsa.rules = [
          {
            matches = [
              {
                # Matches all sources
                node.name = "~alsa_input.*"
              },
              {
                # Matches all sinks
                node.name = "~alsa_output.*"
              }
            ]
            actions = {
              update-props = {
                session.suspend-timeout-seconds = 0
              }
            }
          }
        ]
      '')
    ];

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "switch-audio" ''
        DEVICE_KEY="$1"

        case "$DEVICE_KEY" in
          fiio|speakers)
            SINK_NAME=$(${pkgs.pulseaudio}/bin/pactl list short sinks | ${pkgs.gnugrep}/bin/grep -i 'FIIO' | ${pkgs.gawk}/bin/awk '{print $2}')
            NAME="FiiO K11 (Speakers)"
            ICON="audio-speakers-symbolic"
            ;;
          logitech|headset)
            SINK_NAME=$(${pkgs.pulseaudio}/bin/pactl list short sinks | ${pkgs.gnugrep}/bin/grep -i 'Logitech' | ${pkgs.gawk}/bin/awk '{print $2}')
            NAME="Logitech Headset"
            ICON="audio-headphones-symbolic"
            ;;
          hdmi|monitor)
            SINK_NAME=$(${pkgs.pulseaudio}/bin/pactl list short sinks | ${pkgs.gnugrep}/bin/grep -i 'hdmi-stereo' | ${pkgs.gawk}/bin/awk '{print $2}')
            NAME="HDMI Monitor"
            ICON="video-display-symbolic"
            ;;
          *)
            echo "Usage: $0 {fiio|logitech|hdmi}"
            exit 1
            ;;
        esac

        if [ -n "$SINK_NAME" ]; then
          ${pkgs.pulseaudio}/bin/pactl set-default-sink "$SINK_NAME"
          ${pkgs.libnotify}/bin/notify-send "Audio Output" "$NAME" -i "$ICON" -h string:x-canonical-private-synchronous:audio-switch -t 2000
        else
          ${pkgs.libnotify}/bin/notify-send "Audio Switch Failed" "Could not find device: $NAME" -i dialog-error -h string:x-canonical-private-synchronous:audio-switch -t 2000
        fi
      '')
    ];
  };
}
