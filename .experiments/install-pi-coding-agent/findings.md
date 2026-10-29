# Findings

## 2026-10-09 — build v1.1.0

- Added `pi-src` flake input (`github:earendil-works/pi/v1.1.0`). `nix flake lock`
  locked it to rev `abe508e1b89912adde45528136c3221eb69acdd7`, narHash
  `sha256-lwjspkMGrW+8Fl/yBEDEFsHZJA57OKOhmVQmi6zfej4=` (matches the prefetched hash).
- Overriding nixpkgs' `pi-coding-agent` (1.0.3 recipe) with the new src, npmDeps,
  modelData and preConfigure built cleanly on the first try. No hash mismatches,
  and the upstream `postInstall` didn't need changes.
- The derivation's versionCheckHook passed, and `pi --version` → `1.1.0`.
- Output: `/nix/store/yjc1hn690iwr9rl6ij4ragvlxry6431h-pi-coding-agent-1.1.0`.

## 2026-10-09 — `./scripts/nix-test`

- The build succeeded and `pi-coding-agent 1.1.0` was added. After activation,
  `/run/current-system/sw/bin/pi --version` → `1.1.0`.
- Activation exited with status 4 because of two failures that have nothing to do with pi:
  - `libvirtd.service`: "TPM key integrity check failed" (status 243/CREDENTIALS).
    It also fails on the current boot (libvirt 12.4.0), so the problem predates this change.
  - `systemd-machined.socket`: "Socket service systemd-machined.service already
    active, refusing". This is a transient activation race during the systemd 261.1 → 261.3 bump.
- The large closure diff (systemd, qt, vscode, …) happened because the running system
  was built from an older lock than HEAD. It isn't caused by this change.
