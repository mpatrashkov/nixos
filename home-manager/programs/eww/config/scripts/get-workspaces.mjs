#! /usr/bin/env nix-shell
/*
#! nix-shell -i zx -p zx
*/

$.verbose = false;

const workspaces = JSON.parse(await $`hyprctl workspaces -j`);

console.log(
  JSON.stringify(
    workspaces.map((workspace) => ({
      id: workspace.id.toString(),
      windows: workspace.windows,
    }))
  )
);
