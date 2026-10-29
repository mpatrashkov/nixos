{
  lib,
  pkgs,
  config,
  ...
}:
let
  # nixpkgs currently packages v72, before the unified blur backend.
  blurMyShell = pkgs.gnomeExtensions.blur-my-shell.overrideAttrs {
    version = "76";
    src = pkgs.fetchzip {
      name = "blur-my-shell-v76";
      url = "https://github.com/aunetx/blur-my-shell/releases/download/v76/blur-my-shell%40aunetx.shell-extension.zip";
      hash = "sha256-QU0+Y10jhYk0kYOrb94jRYi8TXZD/WvZkw6IqI7Qcrw=";
      stripRoot = false;
    };
  };

  # Effect properties use a{sv}; pipeline IDs map directly to those dictionaries.
  variantDict =
    attrs:
    lib.gvariant.mkArray (
      lib.mapAttrsToList (
        name: value: lib.gvariant.mkDictionaryEntry name (lib.gvariant.mkVariant value)
      ) attrs
    );

  glassPipeline = variantDict {
    name = "Subtle Liquid Glass";
    effects = lib.gvariant.mkArray [
      (lib.gvariant.mkVariant (variantDict {
        type = "refraction";
        id = "effect_liquid_glass";
        params = variantDict {
          strength = 0.15;
          blur_radius = 30.0;
          # Blend mostly charcoal over the backdrop for readable, frosted glass.
          tint = 0.85;
          tint_color = lib.gvariant.mkArray [
            0.08
            0.08
            0.10
            1.0
          ];
          gloss = 0.15;
          rgb_fringing = 0.02;
        };
      }))
    ];
  };
in
{
  # Imports are unconditional, so follow the parent module's opt-in switch.
  config = lib.mkIf config.myNixOS.services.gnome.enable {
    environment.systemPackages = [ blurMyShell ];

    # Separate from the locked GNOME settings: these are editable defaults.
    # User overrides take precedence; capture the final look in Nix after tuning.
    programs.dconf.profiles.user.databases = [
      {
        lockAll = false;
        settings = {
          "org/gnome/shell/extensions/blur-my-shell" = {
            pipelines = lib.gvariant.mkArray [
              (lib.gvariant.mkDictionaryEntry "pipeline_default" glassPipeline)
            ];
          };

          "org/gnome/shell/extensions/blur-my-shell/panel" = {
            blur = true;
            static-blur = false;
            pipeline = "pipeline_default";
            override-background = true;
            style-panel = lib.gvariant.mkInt32 2; # Dark tint, light text.
            force-light-text = true;
          };

          "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
            blur = true;
            static-blur = false;
            pipeline = "pipeline_default";
            override-background = true;
            style-dash-to-dock = lib.gvariant.mkInt32 2; # Dark tint.
          };

          "org/gnome/shell/extensions/blur-my-shell/popup" = {
            blur = true;
            static-blur = false;
            pipeline = "pipeline_default";
            override-background = true;
            preserve-shell-theme = true;
            style-popup = lib.gvariant.mkInt32 2; # Dark tint.
          };

          "org/gnome/shell/extensions/blur-my-shell/overview" = {
            blur = true;
            pipeline = "pipeline_default";
            style-components = lib.gvariant.mkInt32 2; # Dark overview components.
          };

          "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
            blur = true;
            pipeline = "pipeline_default";
            style-dialogs = lib.gvariant.mkInt32 3; # Dark folder dialogs.
          };

          "org/gnome/shell/extensions/blur-my-shell/lockscreen" = {
            blur = true;
            pipeline = "pipeline_default";
          };

          "org/gnome/shell/extensions/blur-my-shell/applications".blur = false;
          "org/gnome/shell/extensions/blur-my-shell/screenshot".blur = false;
          "org/gnome/shell/extensions/blur-my-shell/window-list".blur = false;
          "org/gnome/shell/extensions/blur-my-shell/coverflow-alt-tab".blur = false;
        };
      }
    ];
  };
}
