{
  lib,
  config,
  tools,
  ...
}:

let
  cfg = config.myHomeManager;

  features = tools.extendModules (name: {
    extraOptions = {
      myHomeManager.${name}.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable ${name} feature";
      };
    };

    configExtension = config: (lib.mkIf cfg.${name}.enable config);
  }) (tools.filesIn ./features);
in
{
  imports = [ ] ++ features;
}
