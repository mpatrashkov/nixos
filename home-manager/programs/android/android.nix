{ config, pkgs, ... }:

let
  androidSdkModule = import ((builtins.fetchGit {
    url = "https://github.com/tadfisher/android-nixpkgs.git";
    rev = "032e8a39894c3a8a50c77ab1d2e9daa9b27bcaaa";
    ref = "main"; # Or "stable", "beta", "preview", "canary"
  }) + "/hm-module.nix");

in
{
  imports = [ androidSdkModule ];

  android-sdk.enable = true;

  # Optional; default path is "~/.local/share/android".
  android-sdk.path = "${config.home.homeDirectory}/.android/sdk";

  android-sdk.packages = sdkPkgs: with sdkPkgs; [
    build-tools-31-0-0
    cmdline-tools-latest
    emulator
    platforms-android-31
    sources-android-31
  ];
}
