{ pkgs, ... }:

let
  vlc-pause-click-plugin = pkgs.stdenv.mkDerivation rec {
    pname = "vlc-pause-click-plugin";
    version = "2.2.0";

    src = pkgs.fetchFromGitHub {
      owner = "nurupo";
      repo = "vlc-pause-click-plugin";
      rev = version;
      sha256 = "13h4cszbl9vn8sig803hqsz2pp47in9lhp7ha3009dcb0jyxy454";
    };

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.vlc ];

    buildPhase = ''
      make
    '';

    installPhase = ''
      mkdir -p $out/lib/vlc/plugins/video_filter
      cp libpause_click_plugin.so $out/lib/vlc/plugins/video_filter/
    '';
  };

  vlcWithPlugin = pkgs.symlinkJoin {
    name = "vlc-with-plugins-${pkgs.vlc.version}";
    paths = [ pkgs.vlc vlc-pause-click-plugin ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/vlc \
        --prefix VLC_PLUGIN_PATH : $out/lib/vlc/plugins
    '';
  };
in
{
  environment.systemPackages = [ vlcWithPlugin ];
}
