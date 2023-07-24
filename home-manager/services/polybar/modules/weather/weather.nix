{ pkgs, ...}:

pkgs.writeShellScriptBin "weather" (builtins.readFile ./weather.mjs)