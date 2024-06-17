export function Search(monitor: number) {
  const window = Widget.Window({
    monitor,
    name: `search[${monitor}]`,
    class_name: "search",
    exclusivity: "ignore",
    // anchor: ["top", "left", "right"],
    css: `background-color: white; padding: 10px;`,
  });

  return window;
}
