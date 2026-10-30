{ pkgs, ... }:
{
  # Keep zx in package.json/pnpm-lock.yaml, not in a second Nix package declaration.
  # Install explicitly with pnpm install --frozen-lockfile; shell entry is read-only.
  packages = with pkgs; [
    nodejs
    pnpm_10 # Compatible with the existing v9 lockfile; avoid a pnpm major migration.
    bash
    coreutils
    (lib.getBin util-linux)
    gnutar
    stow
    git
    jujutsu
    github-cli
    nix-prefetch-github
    pre-commit
    nixd
    nixfmt
  ];

  # Preserve the original script locations: the launchers resolve adjacent helpers.
  enterShell = ''
    export PATH="$DEVENV_ROOT/node_modules/.bin:$DEVENV_ROOT/scripts:$PATH"
  '';

  scripts.update-github-packages-check.exec = ''
    exec "$DEVENV_ROOT/node_modules/.bin/zx" "$DEVENV_ROOT/scripts/update-github-packages-check.ts" "$@"
  '';

  scripts.rollback-test-changes.exec = ''
    exec "$DEVENV_ROOT/node_modules/.bin/zx" "$DEVENV_ROOT/scripts/rollback-test-changes.ts" "$@"
  '';

  # Only dependency/configuration checks; never invoke operational scripts here.
  enterTest = ''
    set -euo pipefail
    cd "$DEVENV_ROOT"
    test "$(command -v zx)" = "$DEVENV_ROOT/node_modules/.bin/zx"
    zx --version
    pre-commit validate-config
    for script in nix-test nix-switch nix-update-test nix-update-switch stow-add stow-adopt stow-check stow-remove; do
      test "$(command -v "$script")" = "$DEVENV_ROOT/scripts/$script"
      bash -n "$DEVENV_ROOT/scripts/$script"
    done
    bash -n scripts/rebuild/run scripts/_stow-lib.sh
  '';
}
