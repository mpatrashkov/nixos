#! /usr/bin/env nix-shell
/*
#! nix-shell -i zx -p zx
*/

$.verbose = false;

import net from "net";

function parseHyprlandEventLine(line) {
  const [eventName, data] = line.trim().split(">>");

  if (eventName === "focusedmon" || eventName === "workspace") {
    printActiveWorkspaces();
    return;
  }
}

function parseHyprlandEvent(event) {
  const lines = event.split("\n");
  lines.forEach((line) => parseHyprlandEventLine(line));
}

async function printActiveWorkspaces() {
  const monitors = JSON.parse(await $`hyprctl monitors -j`);

  const activeWorkspaceMap = {};

  monitors.forEach((monitor) => {
    activeWorkspaceMap[monitor.activeWorkspace.id.toString()] = monitor.id;
  });

  const activeWorkspaces = monitors.map((monitor) => ({
    monitor: monitor.id,
    workspace: monitor.activeWorkspace.id.toString(),
  }));

  console.log(JSON.stringify(activeWorkspaceMap));
}
await printActiveWorkspaces();

const connection = net
  .createConnection(
    `/tmp/hypr/${process.env.HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock`
  )
  .on("data", (data) => {
    parseHyprlandEvent(data.toString());
  })
  .on("error", (error) => {
    console.log(error);
  });

let SHUTDOWN = false;
function cleanup() {
  if (!SHUTDOWN) {
    SHUTDOWN = true;
    connection.end();
    process.exit(0);
  }
}
process.on("SIGINT", cleanup);
