## Development environment

Prerequisites: Nix with flakes enabled and [devenv](https://devenv.sh/). System rebuilds also require the host's `sudo`/`nh` installation and sudo policy. GitHub helpers use your existing `gh` authentication.

From the repository root:

```sh
devenv shell
pnpm install --frozen-lockfile
devenv test
```

Dependency installation is explicit: entering the shell does not install npm packages, update lockfiles, or run operational scripts. In a noninteractive session, use `CI=true pnpm install --frozen-lockfile` if pnpm needs to replace an existing `node_modules` directory.

For automatic activation, install direnv with your shell integration (already configured for Fish on NixOS), review `.envrc`, then explicitly trust it with `direnv allow`. You still need the initial frozen pnpm install.

`devenv.nix` supplies Node.js/pnpm, script dependencies, and local nixd/nixfmt. zx comes from `package.json` and `pnpm-lock.yaml`; the local `node_modules/.bin` takes precedence over global packages. nixd and nixfmt remain globally installed for editing other projects too. Bootstrap/system tools and shared Git/JJ, gh, Stow, and editor tools remain global; zx, nix-prefetch-github, pre-commit, and pnpm are project-scoped.

`devenv.lock` pins the development environment independently of `flake.lock`. Its initial nixpkgs revision matches the system flake. Update it deliberately with `devenv update`; this does not update the NixOS inputs. Review and retain the lockfile in source control. Local overrides and generated state are ignored.

## Scripts

Inside the environment, these commands are available on PATH:

- `nix-test`, `nix-switch`, `nix-update-test`, `nix-update-switch`
- `stow-add`, `stow-adopt`, `stow-check`, `stow-remove`
- `update-github-packages-check`, `rollback-test-changes`

Run them from the repository root. Stow commands require the existing machine-local `.host` file; see the [dotfile skill](.agents/skills/manage-dotfiles/SKILL.md). Rollback and rebuild commands change system state; exposing them is not permission to run them.

Helper scripts remain in `scripts/`, and their existing `./scripts/...` interfaces still work. TypeScript helpers use the project-local zx (for example, `zx scripts/rollback-test-changes.ts`). Shell launchers retain their original locations so adjacent helpers resolve correctly.

NixOS rebuilds preserve `./scripts/nix-test` and `./scripts/nix-switch "<description>"`. Follow the approval policy in `AGENTS.md` and see [JJ setup, rebuilds, and generation descriptions](docs/jujutsu.md). The environment never rebuilds, publishes, rolls back, or changes Stow links automatically. `devenv test` only checks dependency resolution and script/configuration syntax; it is **not** a NixOS test activation.

VS Code tasks and agent commands must inherit this environment once global zx is removed. Start the editor/agent from `devenv shell` (for example, `code .`), or use a direnv-aware launcher. For one-off commands, use `devenv shell -- <command>`; the rebuild wrappers do not recursively bootstrap devenv.

## Useful commands

### Reset monitor config - https://unix.stackexchange.com/a/801854
```
gdctl set -LM DP-4 -ps 1
```

## Known issues

- There is an issue with Spotify on wayland, which causes the spotify client to have ugly windows border. See `nixos-modules/programs/spotify.nix`.


## Future improvements

- Decide if `npins` is a suitable flake replacement. Generation descriptions no longer require an impure environment variable or Git hook.