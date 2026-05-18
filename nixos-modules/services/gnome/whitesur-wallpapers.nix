{ pkgs, ... }:
let
  whitesur-wallpapers = pkgs.stdenvNoCC.mkDerivation {
    pname = "whitesur-wallpapers";
    version = "unstable-2026-05-17";

    src = pkgs.fetchFromGitHub {
      owner = "vinceliuice";
      repo = "WhiteSur-wallpapers";
      rev = "5c1d7ca20b8de0a7efe443792c19e49277262e02";
      hash = "sha256-JnSItAAqbIlnreV5uLAtR3LRCgQm3K0eplM6K58WHHc=";
    };

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall

      bgdir=$out/share/backgrounds
      propdir=$out/share/gnome-background-properties
      mkdir -p "$propdir" "$bgdir/Wallpaper-nord"

      cp $src/Wallpaper-nord/*.png "$bgdir/Wallpaper-nord/"

      install_theme() {
        local Theme=$1
        shift
        mkdir -p "$bgdir/$Theme"
        for f in "$@"; do
          cp "$src/4k/$f" "$bgdir/$Theme/"
        done
        cp "$src/xml-files/timed-xml-files/$Theme-timed.xml" "$bgdir/$Theme/"
        cp "$src/xml-files/gnome-background-properties/$Theme.xml" "$propdir/"
        sed -i "s|@BACKGROUNDDIR@|$bgdir|g" \
          "$bgdir/$Theme/$Theme-timed.xml" \
          "$propdir/$Theme.xml"
      }

      install_theme WhiteSur WhiteSur-dark.jpg WhiteSur-light.jpg WhiteSur-morning.jpg WhiteSur.jpg
      install_theme Monterey Monterey-dark.jpg Monterey-light.jpg Monterey-morning.jpg Monterey.jpg
      install_theme Ventura  Ventura-dark.jpg  Ventura-light.jpg
      install_theme Sonoma   Sonoma-dark.jpg   Sonoma-light.jpg

      cp "$src/xml-files/gnome-background-properties/Mojave-nord.xml" "$propdir/"
      sed -i "s|@BACKGROUNDDIR@|$bgdir|g" "$propdir/Mojave-nord.xml"

      runHook postInstall
    '';

    meta = {
      description = "WhiteSur macOS-style time-of-day wallpapers for GNOME";
      homepage = "https://github.com/vinceliuice/WhiteSur-wallpapers";
      license = pkgs.lib.licenses.gpl3Only;
      platforms = pkgs.lib.platforms.linux;
    };
  };
in
{
  environment.systemPackages = [ whitesur-wallpapers ];
}
