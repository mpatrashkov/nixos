#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash socat

CURRENT_DIR="$(dirname "$(readlink -f "$0")")"

$CURRENT_DIR/get-workspaces.mjs
socat -u UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
    $CURRENT_DIR/get-workspaces.mjs
done
