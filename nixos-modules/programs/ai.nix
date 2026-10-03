{ pkgs, inputs, ... }:

let
  opencode-version = (builtins.fromJSON (builtins.readFile "${inputs.opencode-src}/packages/opencode/package.json")).version;
  opencode-latest = pkgs.opencode.overrideAttrs (old: {
    version = opencode-version;
    src = inputs.opencode-src;
    env = old.env // {
      OPENCODE_VERSION = opencode-version;
    };
    node_modules = pkgs.opencode.node_modules.overrideAttrs (_: {
      version = opencode-version;
      src = inputs.opencode-src;
      outputHash = "sha256-3QJzASZSJfWqbFpbxzIQ/ZRRaFX8KAF4Jd2BI6v9e+s=";
    });
  });
in
{
  environment.systemPackages = [
    pkgs.claude-code
    pkgs.gemini-cli
    pkgs.antigravity-cli
    opencode-latest
  ];
}
