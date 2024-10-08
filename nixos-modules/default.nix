{ lib, config, tools, ... }:

let
  cfg = config.myNixOS;
  services = tools.extendModules
    (
      name: {
        extraOptions = {
          myNixOS.services.${name}.enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
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
            default = true;
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
            default = true;
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
}
