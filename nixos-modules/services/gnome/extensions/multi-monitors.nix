{ pkgs, ... }:
let
  multiMonitors = pkgs.stdenv.mkDerivation {
    pname = "multi-monitor-panel";
    version = "git";
    src = pkgs.fetchFromGitHub {
      owner = "eveiscoull";
      repo = "multi-monitor-panel";
      rev = "611397219f51f5dbe3b6fa672cad33043a676b78";
      sha256 = "sha256-ruxO/6yY6/p7blHVjctTtjicADXZtwDZB1JNkuATRSw=";
    };
    installPhase = ''
      mkdir -p $out/share/gnome-shell/extensions
      cp -r multi-monitor-panel@coolssor \
        $out/share/gnome-shell/extensions/
    '';
  };
in
{
  imports = [ ];
  services.xserver.desktopManager.gnome.enable = true;

  environment.systemPackages = [
    multiMonitors
  ];
}
