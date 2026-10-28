{
  config,
  inputs,
  lib,
  ...
}:
let
  # Rebuild wrappers stamp metadata into an exported, immutable source snapshot.
  # Ordinary flake evaluations need neither this file nor Git/JJ hooks.
  metadataPath = inputs.self + "/.nixos-generation.json";
  metadata =
    if builtins.pathExists metadataPath then
      builtins.fromJSON (builtins.readFile metadataPath)
    else
      { };
  fallbackLabel =
    if inputs.self ? shortRev then
      "revision-${inputs.self.shortRev}"
    else
      # Path and dirty source snapshots may not expose a clean revision.
      config.system.nixos.version;
  label = metadata.label or fallbackLabel;
  derivationName = "nixos-system-${config.system.name}-${label}.drv";
in
{
  system.nixos.label = label;
  system.configurationRevision = lib.mkDefault (metadata.revision or (inputs.self.rev or null));

  assertions = [
    {
      assertion = builtins.match "[A-Za-z0-9._-]+" label != null;
      message = "Generation labels must be nonempty and use only ASCII letters, digits, '.', '_' and '-'.";
    }
    {
      assertion = builtins.stringLength derivationName <= 211;
      message = "The NixOS generation label and system name exceed Nix's 211-byte store-name limit (including .drv).";
    }
  ];
}
