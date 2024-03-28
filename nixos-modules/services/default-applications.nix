{ pkgs, ... }:

{
  config = {
    xdg.mime.enable = true;

    xdg.mime.defaultApplications = {
      "text/html" = "chromium-browser.desktop";
      "x-scheme-handler/http" = "chromium-browser.desktop";
      "x-scheme-handler/https" = "chromium-browser.desktop";
      "x-scheme-handler/about" = "chromium-browser.desktop";
      "x-scheme-handler/unknown" = "chromium-browser.desktop";
    };

    environment.sessionVariables.DEFAULT_BROWSER = "${pkgs.chromium}/bin/chromium";
  };
}
