---
date: 2026-10-09
status: approved
---

# Plan: Install pi coding agent 1.1.0 (revised: flake input source)

## Context

- "pi harness" = `pi` coding agent, repo `github:earendil-works/pi`, npm
  `@earendil-works/pi-coding-agent`. npm `latest` = **1.1.0**.
- The flake's locked nixpkgs has `pi-coding-agent` **1.0.3**.
- Not currently installed anywhere in this repo.
- v1.1.0 runtime workspace deps unchanged vs 1.0.3 → upstream `postInstall` works.
- Follow the `opencode-src` pattern: source pinned as a non-flake input, version
  read from `packages/coding-agent/package.json`.

## Hashes (v1.1.0)

| What | Hash |
|---|---|
| src | managed by flake.lock |
| npm deps | `sha256-GOh5WG+rRgzoy/yVHY5PoEKJZGQcEGhISrDDJxkP8W4=` |
| modelData (`pi-ai-1.1.0.tgz`) | `sha256-bKqzPOxXSA7QLFf+N0KKAwp3zCoGYoFLQ1pc+JMq2Ck=` |

## Step 1 — `flake.nix`: add `pi-src` input (`github:earendil-works/pi/v1.1.0`, `flake = false`) after `opencode-src`.

## Step 2 — `nixos-modules/programs/ai.nix`: add `pi-latest` override of
`pkgs.pi-coding-agent` with `src = inputs.pi-src`, explicit `npmDeps`
(`fetchNpmDeps`), `modelData` and `preConfigure`; add to `environment.systemPackages`.

## Step 3 — `nix flake lock`, then build only the pi package
(versionCheckHook asserts `pi --version` = 1.1.0). Fallbacks: hash mismatch → use
`got:` hash; postInstall workspace failure → override postInstall.

## Step 4 — NixOS Action prompt (switch / test / nothing).

## Step 5 — Record findings; on success mark idea/experiment/plan `done`.

To upgrade: bump tag in `flake.nix`, update npmDepsHash + modelData hash in `ai.nix`.
