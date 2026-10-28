## Scripts

Helper scripts live in `scripts/`. TypeScript helpers use `zx` (e.g. `zx scripts/rollback-test-changes.ts`); the root `package.json`/`pnpm-lock.yaml` provide their dependencies.

NixOS rebuilds use TypeScript via `zx`, with tiny shell launchers preserving `./scripts/nix-test` and `./scripts/nix-switch "<description>"`. See [JJ setup, rebuilds, and generation descriptions](docs/jujutsu.md), and follow the approval policy in `AGENTS.md`.

## Useful commands

### Reset monitor config - https://unix.stackexchange.com/a/801854
```
gdctl set -LM DP-4 -ps 1
```

## Known issues

- There is an issue with Spotify on wayland, which causes the spotify client to have ugly windows border. See `nixos-modules/programs/spotify.nix`.


## Future improvements

- Decide if `npins` is a suitable flake replacement. Generation descriptions no longer require an impure environment variable or Git hook.