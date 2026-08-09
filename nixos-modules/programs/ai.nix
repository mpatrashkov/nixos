{ pkgs, inputs, ... }:

let
  opencode-latest = pkgs.opencode.overrideAttrs (old: rec {
    version = (builtins.fromJSON (builtins.readFile "${inputs.opencode-src}/packages/opencode/package.json")).version;
    src = inputs.opencode-src;
    env = old.env // {
      OPENCODE_VERSION = version;
    };
    node_modules = old.node_modules.overrideAttrs (_: {
      inherit version src;
      outputHash = "sha256-GBLs3nXtfSeXb4jXxSNM8ElMa/e/EB4sZn3c2inHnco=";
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
