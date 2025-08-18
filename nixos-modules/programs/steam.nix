{ pkgs, ... }:
{
  # programs.gamescope = {
  #   enable = true;
  #   capSysNice = true;
  #   package = pkgs.gamescope-wsi;
  # };

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
          xorg.libxcb
        ];
    };
  };
}
