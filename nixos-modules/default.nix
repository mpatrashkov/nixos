{ lib, config, tools, ... }:

let
  cfg = config.myNixOS;

  # Modules that only make sense on a graphical, bare-metal host. Their enable
  # option defaults to `myNixOS.desktop.enable` instead of `true`.
  desktopOnly = {
    services = [
      "adguardhome"
      "audio"
      "boot"
      "default-applications"
      "dnscrypt-proxy2"
      "fonts"
      "geoclue"
      "gnome"
      "keychron"
      "networking"
      "smb"
    ];
    programs = [
      "chromium"
      "discord"
      "distrobox"
      "games"
      "krita"
      "pinta"
      "qbittorrent"
      "resources"
      "spotify"
      "steam"
      "stylix"
      "terminal"
      "tor"
      "vlc"
      "yeetmouse"
    ];
    features = [ ];
  };

  defaultEnable = kind: name: if builtins.elem name desktopOnly.${kind} then cfg.desktop.enable else true;

  services = tools.extendModules
    (
      name: {
        extraOptions = {
          myNixOS.services.${name}.enable = lib.mkOption {
            type = lib.types.bool;
            default = defaultEnable "services" name;
            description = "Whether to enable ${name} service";
          };
        };

        configExtension = config: (lib.mkIf cfg.services.${name}.enable config);
      }
    )
    (tools.filesIn ./services);
  programs = tools.extendModules
    (
      name: {
        extraOptions = {
          myNixOS.programs.${name}.enable = lib.mkOption {
            type = lib.types.bool;
            default = defaultEnable "programs" name;
            description = "Whether to enable ${name} service";
          };
        };

        configExtension = config: (lib.mkIf cfg.programs.${name}.enable config);
      }
    )
    (tools.filesIn ./programs);
  features = tools.extendModules
    (
      name: {
        extraOptions = {
          myNixOS.features.${name}.enable = lib.mkOption {
            type = lib.types.bool;
            default = defaultEnable "features" name;
            description = "Whether to enable ${name} service";
          };
        };

        configExtension = config: (lib.mkIf cfg.features.${name}.enable config);
      }
    )
    (tools.filesIn ./features);
in
{
  imports = [ ] ++ services ++ programs ++ features;

  options.myNixOS.desktop.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether this host is a graphical desktop. When false, desktop-only modules default to disabled.";
  };
}
