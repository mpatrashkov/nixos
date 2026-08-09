{ pkgs, ... }:

let
  opencode-latest = pkgs.opencode.overrideAttrs (old: rec {
    version = "1.18.15";
    src = pkgs.fetchFromGitHub {
      owner = "anomalyco";
      repo = "opencode";
      tag = "v${version}";
      hash = "sha256-yUPwXDv93O0Ub/giX78FJyFxZyaUzSguDoK2y/YIPBM=";
    };
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
