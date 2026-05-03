{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    steam-tui
    steamcmd
  ];

  programs.gamescope = {
    enable = true;
    capSysNice = false;
  };

  programs.steam = {
    enable = true;

    gamescopeSession.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;

    package = pkgs.steam.override {
      extraPkgs =
        pkgs: with pkgs; [
          libkrb5
          keyutils
          libxcb
        ];
    };
  };
}
