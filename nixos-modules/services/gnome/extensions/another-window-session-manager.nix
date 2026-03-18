{ pkgs, ... }:
let
  anotherWindowSessionManager = pkgs.stdenv.mkDerivation {
    pname = "another-window-session-manager";
    version = "51"; # Supports GNOME 49
    src = pkgs.fetchFromGitHub {
      owner = "nlpsuge";
      repo = "gnome-shell-extension-another-window-session-manager";
      rev = "cf23fef152ce90692fc1df984f6fd945725334be";
      hash = "sha256-8vDZPLM/icjVt/Ts5pgl0a2rn01mB4jeRSUVpVKuFJg=";
    };
    installPhase = ''
      mkdir -p $out/share/gnome-shell/extensions/another-window-session-manager@gmail.com
      cp -r * $out/share/gnome-shell/extensions/another-window-session-manager@gmail.com/
    '';
  };
in
{
  environment.systemPackages = [
    anotherWindowSessionManager
  ];

  # https://github.com/nlpsuge/gnome-shell-extension-another-window-session-manager#how-to-make-close-by-rules-work
  programs.ydotool.enable = true;
}
