import Gtk from "types/@girs/gtk-3.0/gtk-3.0";
import Revealer from "types/widgets/revealer";
import { Timeout } from "utils/timeout";

const audio = await Service.import("audio");

const windowLifetime = 3000;

let revealer: Revealer<ReturnType<typeof VolumeIndicator>, unknown>;
let lastVolume: number;
let destroyTimeout: Timeout;

function onSpeakerChanged() {
  const currentVolume = audio.speaker.volume;

  if (lastVolume === currentVolume) {
    return;
  }

  lastVolume = currentVolume;

  revealer.set_reveal_child(true);

  clearTimeout(destroyTimeout);
  destroyTimeout = setTimeout(() => {
    revealer.set_reveal_child(false);
  }, windowLifetime);
}

function VolumeIndicator() {
  return Widget.Box({
    class_name: "volume-indicator-container",
    vertical: true,
    height_request: 150,
    children: [
      Widget.Icon({
        icon: "audio-volume-high",
        size: 100,
      }),
      Widget.Box({
        class_name: "volume-indicator-bar-container",
        child: Widget.LevelBar({
          name: "custom-level-bar",
          class_name: "volume-indicator-bar",
          width_request: 150,
          height_request: 5,

          bar_mode: "discrete",
          max_value: 18,
          value: audio.speaker.bind("volume").as((volume) => volume * 18),
        }),
      }),
    ],
  });
}

export function VolumeIndicatorWindow(monitor = 0) {
  revealer = Widget.Revealer({
    child: VolumeIndicator(),
    transitionDuration: 100,
    transition: "crossfade",
    css: "padding: 1px;",
    reveal_child: true,
  });

  const window = Widget.Window({
    monitor,
    name: `volume-indicator[${monitor}]`,
    class_name: "volume-indicator",
    exclusivity: "ignore",
    // anchor: ["bottom", "left", "right"],
    layer: "overlay",
    margin_bottom: 100,
    css: "padding: 1px;",
    child: revealer,
  });

  window.hook(audio, onSpeakerChanged, "speaker-changed");

  return window;
}
