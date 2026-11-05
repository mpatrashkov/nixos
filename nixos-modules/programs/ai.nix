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
    npmDepsHash = "sha256-koVd02HEhEAOkcvIuUg4X1A6P6P0B+wJp4DJLwkH62w=";
    npmDeps = pkgs.fetchNpmDeps {
      name = "pi-coding-agent-${pi-version}-npm-deps";
      inherit src;
      hash = npmDepsHash;
    };
    modelData = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${pi-version}.tgz";
      hash = "sha256-4yD+e9K5J3grqaN9NW/lg38aqWpGQyYQ4bO5zLdI6lw=";
    };
    preConfigure = ''
      mkdir -p packages/ai/src/providers/data
      tar --extract --gzip --file=${modelData} \
        --directory=packages/ai/src/providers/data \
        --strip-components=4 \
        package/dist/providers/data
    '';
    # The inherited recipe references client/protocol workspaces removed in 1.5.
    # Keep the unbundled SDK's runtime workspaces alongside the bundled CLI.
    postInstall = ''
      local nm="$out/lib/node_modules/pi-monorepo/node_modules"

      for ws in @earendil-works/chord:packages/chord \
                @earendil-works/pi-ai:packages/ai \
                @earendil-works/pi-agent-core:packages/agent \
                @earendil-works/pi-codemode:packages/codemode \
                @earendil-works/pi-durable:packages/durable \
                @earendil-works/pi-env:packages/env \
                @earendil-works/pi-mcp:packages/mcp \
                @earendil-works/pi-schema:packages/schema \
                @earendil-works/pi-telemetry:packages/telemetry \
                @earendil-works/pi-tui:packages/tui; do
        IFS=: read -r pkg src <<< "$ws"
        rm "$nm/$pkg"
        cp -r "$src" "$nm/$pkg"
      done

      find "$nm" -type l -lname '*/packages/*' -delete
      find "$nm/.bin" -xtype l -delete
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
