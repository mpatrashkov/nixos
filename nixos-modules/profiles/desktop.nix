{ lib, ... }:

{
  myNixOS = {
    # Home Manager is limited to Stylix's user-session theming integration.
    features.home-manager.enable = lib.mkDefault true;

    services = {
      audio.enable = lib.mkDefault true;
      default-applications.enable = lib.mkDefault true;
      fonts.enable = lib.mkDefault true;
      geoclue.enable = lib.mkDefault true;
      gnome.enable = lib.mkDefault true;
      wallpaper-daemon.enable = lib.mkDefault true;
    };

    programs = {
      chromium.enable = lib.mkDefault true;
      discord.enable = lib.mkDefault true;
      distrobox.enable = lib.mkDefault true;
      github-desktop.enable = lib.mkDefault true;
      krita.enable = lib.mkDefault true;
      pinta.enable = lib.mkDefault true;
      qbittorrent.enable = lib.mkDefault true;
      resources.enable = lib.mkDefault true;
      slack.enable = lib.mkDefault true;
      spotify.enable = lib.mkDefault true;
      stylix.enable = lib.mkDefault true;
      terminal.enable = lib.mkDefault true;
      tor.enable = lib.mkDefault true;
      vlc.enable = lib.mkDefault true;
    };
  };
}
