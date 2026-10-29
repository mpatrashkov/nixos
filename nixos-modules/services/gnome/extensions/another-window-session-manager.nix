{ pkgs, inputs, ... }:
let
  anotherWindowSessionManager = pkgs.stdenv.mkDerivation {
    pname = "another-window-session-manager";
    version = "51"; # Supports GNOME 49
    src = inputs.another-window-session-manager-src;
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
