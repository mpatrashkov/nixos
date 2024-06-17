import GLib from "gi://GLib";
import Gtk from "types/@girs/gtk-3.0/gtk-3.0";

const hyprland = await Service.import("hyprland");

function Workspaces() {
  // const all = [1, 2, 3, 4, 5, 6, 7, 8, 9];
  const all = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9],
  ];

  return Widget.Box({
    children: all.map((group) =>
      Widget.Box({
        className: "workspace-group",
        children: group.map((i) =>
          Widget.Label({
            label: i.toString(),
            className: "workspace-label",
            setup(self) {
              self.hook(hyprland, () => {
                self.toggleClassName(
                  "monitor-0",
                  (hyprland.getWorkspace(i)?.monitorID ?? 0) === 0
                );
                self.toggleClassName(
                  "monitor-1",
                  (hyprland.getWorkspace(i)?.monitorID ?? 0) === 1
                );

                self.toggleClassName(
                  "active",
                  hyprland.active.workspace.id === i
                );
                self.toggleClassName(
                  "occupied",
                  (hyprland.getWorkspace(i)?.windows ?? 0) > 0
                );
              });
            },
          })
        ),
      })
    ),
  });
}

const clock = Variable(GLib.DateTime.new_now_local(), {
  poll: [1000, () => GLib.DateTime.new_now_local()],
});
const time = Utils.derive([clock], (c) => c.format("%a %b %d  %H:%M") || "");

function Date() {
  return Widget.Box({
    child: Widget.Label({
      label: time.bind(),
    }),
  });
}

function ControlCenter() {
  return Widget.Box({
    halign: Gtk.Align.END,
    children: [
      Widget.Box({
        children: [
          Widget.Icon({
            icon: "system-search",
            size: 16,
          }),
        ],
      }),
      Widget.Box({
        children: [
          Widget.Icon({
            icon: "network-wireless",
            size: 16,
          }),
          Widget.Icon({
            icon: "audio-volume-high",
            size: 16,
          }),
          Widget.Icon({
            icon: "weather-few-clouds",
            size: 16,
          }),
        ],
      }),
    ],
  });
}

export function BarWindow(monitor = 0) {
  const window = Widget.Window({
    monitor,
    name: `bar-window[${monitor}]`,
    class_name: "bar",
    exclusivity: "exclusive",
    anchor: ["top", "left", "right"],
    child: Widget.CenterBox({
      class_name: "bar-container",
      startWidget: Workspaces(),
      centerWidget: Date(),
      endWidget: ControlCenter(),
    }),
  });

  // window.hook(
  //   hyprland,
  //   (self, kname: string, lname: string) => {
  //     console.log(lname);
  //   },
  //   "keyboard-layout"
  // );

  return window;
}
