{ pkgs, ... }:

let
  opencode-latest = pkgs.opencode.overrideAttrs (old: rec {
    version = "1.15.4";
    src = pkgs.fetchFromGitHub {
      owner = "anomalyco";
      repo = "opencode";
      tag = "v${version}";
      hash = "sha256-aCoajfdfNsEq5YGFwX+YKkC6Bo19f34BbKt3wJ1FNmA=";
    };
    env = old.env // { OPENCODE_VERSION = version; };
    node_modules = old.node_modules.overrideAttrs (_: {
      inherit version src;
      outputHash = "sha256-cvExCHKkxerR4lyXavcbXqPXNVOQIJ173UOV1mp5dhk=";
    });
  });
in
{
  environment.systemPackages = [
    pkgs.claude-code
    pkgs.gemini-cli
    opencode-latest
  ];
}
