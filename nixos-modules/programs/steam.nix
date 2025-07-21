{ pkgs, ... }:
{
  programs.steam = {
    enable = true;

    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;

    package = pkgs.steam.override {
      extraPkgs =
        pkgs: with pkgs; [
          libkrb5
          keyutils
        ];
    };
  };
}
