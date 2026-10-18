{ pkgs, inputs, ... }:

let
  opencode-version =
    (builtins.fromJSON (builtins.readFile "${inputs.opencode-src}/packages/opencode/package.json"))
    .version;
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

  # Bump the tag in flake.nix's pi-src, then update npmDepsHash + modelData hash.
  pi-version =
    (builtins.fromJSON (builtins.readFile "${inputs.pi-src}/packages/coding-agent/package.json"))
    .version;
  pi-latest = pkgs.pi-coding-agent.overrideAttrs (old: rec {
    version = pi-version;
    src = inputs.pi-src;
    npmDepsHash = "sha256-GOh5WG+rRgzoy/yVHY5PoEKJZGQcEGhISrDDJxkP8W4=";
    npmDeps = pkgs.fetchNpmDeps {
      name = "pi-coding-agent-${pi-version}-npm-deps";
      inherit src;
      hash = npmDepsHash;
    };
    modelData = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${pi-version}.tgz";
      hash = "sha256-bKqzPOxXSA7QLFf+N0KKAwp3zCoGYoFLQ1pc+JMq2Ck=";
    };
    preConfigure = ''
      mkdir -p packages/ai/src/providers/data
      tar --extract --gzip --file=${modelData} \
        --directory=packages/ai/src/providers/data \
        --strip-components=4 \
        package/dist/providers/data
    '';
    # Pi requires wl-clipboard for copy functionality.
    postFixup = (old.postFixup or "") + ''
      wrapProgram "$out/bin/pi" \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.wl-clipboard ]}
    '';
  });
in
{
  environment.systemPackages = [
    pkgs.claude-code
    pkgs.gemini-cli
    pkgs.antigravity-cli
    opencode-latest

    pi-latest
  ];
}
