{ pkgs, lib, ... }:
let
  multiMonitors = pkgs.stdenv.mkDerivation {
    pname = "multi-monitor-panel";
    version = "1.3-unstable-2025-05-13";
    src = pkgs.fetchFromGitHub {
      owner = "eveiscoull";
      repo = "multi-monitor-panel";
      rev = "fd1aa8f9c00b814f36ad84a885a753d3f26299a5";
      sha256 = "sha256-DYr+mzTN70IQXOWAKafQxTRQkBaRQIKy42kai9z72eE=";
    };
    nativeBuildInputs = [ pkgs.jq ];
    installPhase = ''
      # Patch metadata.json to add GNOME 50 support
      jq '.["shell-version"] += ["50"]' \
        multi-monitor-panel@coolssor/metadata.json > metadata.tmp
      mv metadata.tmp multi-monitor-panel@coolssor/metadata.json

      mkdir -p $out/share/gnome-shell/extensions
      cp -r multi-monitor-panel@coolssor \
        $out/share/gnome-shell/extensions/
    '';
  };
in
{
  imports = [ ];

  environment.systemPackages = [
    multiMonitors
  ];
}
