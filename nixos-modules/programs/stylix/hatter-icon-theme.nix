{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  gtk3,
}:
stdenvNoCC.mkDerivation {
  pname = "hatter-icon-theme";
  version = "0-unstable-2026-05-06";

  src = fetchFromGitHub {
    owner = "Mibea";
    repo = "Hatter";
    rev = "a6ad2f74f07f66df9cb4e9e85653cd1bd90539d7";
    hash = "sha256-I8DLOP2EnlZjLVgS+srIKBhzmofds4iJbI+hj0lTuto=";
  };

  nativeBuildInputs = [ gtk3 ];

  dontDropIconThemeCache = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons
    # KDE variants (Hatter-kde, Hatter-kde-dark, Hatter-kde-light) are
    # excluded because upstream ships them with dangling symlinks (e.g.
    # weather-clear-night-*.svg targets that don't exist, and a reference
    # to a non-bundled WhiteSur theme), which trips noBrokenSymlinks.
    for theme in Hatter Hatter-Blue Hatter-Green Hatter-Orange Hatter-Pink \
                 Hatter-Purple Hatter-Red Hatter-Slate Hatter-Teal \
                 Hatter-Yellow Hatter-Yaru; do
      cp -r "$theme" "$out/share/icons/$theme"
    done

    for d in $out/share/icons/*/; do
      gtk-update-icon-cache -f -t "$d" || true
    done

    runHook postInstall
  '';

  meta = {
    description = "Hatter icon theme — rounded-square icons preserving each app's identity";
    homepage = "https://github.com/Mibea/Hatter";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
