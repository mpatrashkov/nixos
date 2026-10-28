{ pkgs, lib, config, ... }:

{
  environment.systemPackages =
    with pkgs;
    [
      git
      jujutsu
      pre-commit
      github-cli
    ]
    ++ lib.optional config.myNixOS.desktop.enable github-desktop;
}
