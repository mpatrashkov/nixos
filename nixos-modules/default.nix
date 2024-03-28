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
in
{
  imports = [ ] ++ services;
}
