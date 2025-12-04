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
  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "openssl-1.1.1u"
        "openssl-1.1.1v"
        "openssl-1.1.1w"
      ];
      # experimental-features = "nix-command flakes";
    };
  };

  imports = [ ] ++ features;
}
