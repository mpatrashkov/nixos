#!/usr/bin/env zx

import { $ } from "zx";

// `nix-env --list-generations` returns the generations in the format (note the extra spaces):
//  268   2024-06-10 12:00:00
//  269   2025-12-21 17:11:58   (current)
//
// We get the last line and extract the generation number from it.
const lastLine =
  await $`sudo nix-env --list-generations -p /nix/var/nix/profiles/system | tail -n 1`;
const lastGenerationNumber = lastLine.stdout.split(" ").filter(Boolean)[0];

await $`sudo nix-env --switch-generation ${lastGenerationNumber} -p /nix/var/nix/profiles/system`;
await $`sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch`;
