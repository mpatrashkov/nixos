{
  lib,
  config,
  tools,
  ...
}:
let
  cfg = config.myNixOS;

  optInModules =
    kind: directory:
    tools.extendModules (name: {
      extraOptions.myNixOS.${kind}.${name}.enable = lib.mkEnableOption "the ${name} ${kind} module";
      configExtension = moduleConfig: lib.mkIf cfg.${kind}.${name}.enable moduleConfig;
    }) (tools.filesIn directory);
in
{
  imports =
    optInModules "services" ./services
    ++ optInModules "programs" ./programs
    ++ optInModules "features" ./features
    ++ optInModules "profiles" ./profiles;
}
