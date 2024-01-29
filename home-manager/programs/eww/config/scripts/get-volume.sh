#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash pamixer

pamixer --get-volume
pactl subscribe | grep --line-buffered "sink" | while read -r UNUSED_LINE; do pamixer --get-volume; done
