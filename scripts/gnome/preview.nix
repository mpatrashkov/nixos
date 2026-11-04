{ desktop }:
let
  inherit (desktop) pkgs config;
  inherit (pkgs) lib;

  themeUser = config.home-manager.users.miro or { };
  packages = config.environment.systemPackages ++ (themeUser.home.packages or [ ]);
  extensions = lib.unique (builtins.filter (package: package ? extensionUuid) packages);
  themes = lib.filter (package: package != null) [
    (config.stylix.icons.package or null)
    (config.stylix.cursor.package or null)
    (themeUser.gtk.theme.package or null)
  ];

  assets = pkgs.symlinkJoin {
    name = "gnome-preview-assets";
    paths = extensions ++ themes ++ [ pkgs.adwaita-icon-theme ];
  };

  schemas =
    pkgs.runCommand "gnome-preview-extension-schemas" { nativeBuildInputs = [ pkgs.glib ]; }
      ''
        mkdir -p "$out/share/glib-2.0/schemas"
        for extension in ${assets}/share/gnome-shell/extensions/*; do
          if [ -d "$extension/schemas" ]; then
            for schema in "$extension"/schemas/*.gschema.xml; do
              if [ -f "$schema" ]; then
                cp -n "$schema" "$out/share/glib-2.0/schemas/"
              fi
            done
          fi
        done
        glib-compile-schemas --strict "$out/share/glib-2.0/schemas"
      '';

  # Do not use the system profile: that would realize the entire desktop.
  profile = "${config.environment.etc.dconf.source}/profile/user";
  pipewireServer = pkgs.writeTextDir "server.conf" ''
    context.properties = {
      core.daemon = true
      core.name = pipewire-0
      support.dbus = false
    }
    context.spa-libs = {
      support.* = support/libspa-support
      audio.convert.* = audioconvert/libspa-audioconvert
      video.convert.* = videoconvert/libspa-videoconvert
    }
    context.modules = [
      { name = libpipewire-module-protocol-native }
      { name = libpipewire-module-metadata }
      { name = libpipewire-module-spa-node-factory }
      { name = libpipewire-module-client-node }
      { name = libpipewire-module-adapter }
      { name = libpipewire-module-link-factory }
      { name = libpipewire-module-session-manager }
    ]
  '';
  pipewireClient = pkgs.writeTextDir "client.conf" ''
    context.properties = { support.dbus = false }
    context.spa-libs = {
      support.* = support/libspa-support
      audio.convert.* = audioconvert/libspa-audioconvert
      video.convert.* = videoconvert/libspa-videoconvert
    }
    context.modules = [
      { name = libpipewire-module-protocol-native }
      { name = libpipewire-module-client-node }
      { name = libpipewire-module-adapter }
      { name = libpipewire-module-metadata }
      { name = libpipewire-module-session-manager }
    ]
  '';
  pipewireConfigDirectory = pkgs.symlinkJoin {
    name = "gnome-preview-pipewire-config";
    paths = [
      pipewireServer
      pipewireClient
    ];
  };
  manifest = pkgs.writeText "gnome-preview.json" (
    builtins.toJSON {
      shell = "${pkgs.gnome-shell}/bin/gnome-shell";
      shellVersion = pkgs.gnome-shell.version;
      inherit profile;
      extensionDirectory = "${assets}/share/gnome-shell/extensions";
      extensions = map (package: {
        uuid = package.extensionUuid;
        path = toString package;
        version = package.version or "unknown";
      }) extensions;
      dataDirectories =
        map (package: "${package}/share") [
          assets
          schemas
          pkgs.gnome-shell
          pkgs.gsettings-desktop-schemas
        ]
        ++ map (package: lib.removeSuffix "/glib-2.0/schemas" (pkgs.glib.getSchemaPath package)) [
          pkgs.gnome-shell
          pkgs.mutter
          pkgs.gsettings-desktop-schemas
        ];
      schemaDirectory = "${schemas}/share/glib-2.0/schemas";
      dbusRunSession = "${pkgs.dbus}/bin/dbus-run-session";
      systemBusProxy = "${pkgs.xdg-dbus-proxy}/bin/xdg-dbus-proxy";
      # Deny all host services. Do not grant --talk or wildcard method access.
      # Add individual read-only queries only if required by a future review.
      systemBusRules = [ ];
      gdbus = "${pkgs.glib.bin}/bin/gdbus";
      gsettings = "${pkgs.glib.bin}/bin/gsettings";
      pipewire = "${pkgs.pipewire}/bin/pipewire";
      inherit pipewireConfigDirectory;
      pipewireConfig = "${pipewireConfigDirectory}/server.conf";
      dconfServices = "${pkgs.dconf}/share/dbus-1/services";
      gioModules = "${pkgs.dconf.lib}/lib/gio/modules";
      path = lib.makeBinPath [
        pkgs.coreutils
        pkgs.dbus
        pkgs.glib.bin
        pkgs.gnome-shell
      ];
    }
  );
in
pkgs.writeShellApplication {
  name = "gnome-preview";
  text = ''
    exec ${pkgs.python3}/bin/python3 ${./preview.py} ${manifest} "$@"
  '';
  meta.description = "Preview candidate GNOME settings in an isolated nested Shell";
}
