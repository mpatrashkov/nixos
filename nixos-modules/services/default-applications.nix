{ ... }:

{
  config = {
    xdg.mime.enable = true;

    xdg.mime.defaultApplications = {
      "text/html" = "google-chrome.desktop";
      "x-scheme-handler/http" = "google-chrome.desktop";
      "x-scheme-handler/https" = "google-chrome.desktop";
      "x-scheme-handler/about" = "google-chrome.desktop";
      "x-scheme-handler/unknown" = "google-chrome.desktop";

      "video/mp4" = "vlc.desktop";
      "video/x-matroska" = "vlc.desktop"; # .mkv
      "video/webm" = "vlc.desktop";
    };
  };
}
