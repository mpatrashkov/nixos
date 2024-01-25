#! /usr/bin/env nix-shell
/*
#! nix-shell -i zx -p zx
*/

$.verbose = false;

import net from "net";

async function getWorkspaces() {
  const workspaces = JSON.parse(await $`hyprctl workspaces -j`);

  console.log(
    JSON.stringify(
      workspaces
        .map((workspace) => ({
          id: workspace.id.toString(),
          windows: workspace.windows,
        }))
        .sort((a, b) => a.id - b.id)
    )
  );
}

await getWorkspaces();

const connection = net
  .createConnection(
    `/tmp/hypr/${process.env.HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock`
  )
  .on("data", (data) => {
    getWorkspaces();
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
