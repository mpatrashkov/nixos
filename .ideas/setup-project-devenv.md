---
title: "Set up a project devenv and localize repository tooling"
status: testing
priority: medium
tags: [devenv, tooling, nix, scripts, development]
created: 2026-10-30
updated: 2026-10-30
---

## Goal

Provide a reproducible development environment for this configuration repository, expose its public scripts as commands, and stop installing repository-specific tooling globally. Implementation completed on 2026-10-30. Development-shell validation passed; NixOS package removals await separately approved test/switch. No publication or activation has occurred.

## Findings

- `nixos-modules/programs/devtools.nix` already installs devenv. `programs/direnv.nix` enables direnv with Fish integration.
- The repository has no devenv configuration or dev shell. Its only npm dependency is zx, declared in `package.json` and pinned through `pnpm-lock.yaml`.
- `programs/zx.nix` and `programs/nix-prefetch-github.nix` install repo-script dependencies globally; both are enabled by the development profile.
- `programs/git.nix` installs pre-commit alongside general-purpose Git, JJ, jjui, and GitHub CLI. The pre-commit configuration currently has no checks, but the JJ switch backend explicitly runs it.
- `hosts/desktop/configuration.nix` installs pnpm globally.
- `programs/nixd.nix` installs nixd/nixfmt and configures nixPath; removing the entire module would also remove that independent system setting.
- `programs/neovim.nix` supplies editor/runtime dependencies and cross-project language tooling. These are not automatically repository-only dependencies.
- Rebuild scripts require Bash, zx, Git/JJ, pre-commit, flock, tar, Nix, sudo, and nh. The GitHub checker also requires gh and nix-prefetch-github. Stow scripts require stow and coreutils.
- Shell launchers resolve adjacent files using their own paths. Stow scripts infer the repo root from their original script location. Symlinking/copying them into a generated bin directory would break these assumptions.
- `.jj` exists. Implementation must preserve the existing JJ workflow and must not mutate the Git index, initialize JJ, move bookmarks, or push as a side effect.

## Plan

### 1. Establish devenv

- Add standalone `devenv.nix`, `devenv.yaml`, and committed `devenv.lock`, following the existing standalone-project convention recorded in `rewrite-spotlight-wallpaper-in-zig.md`. Do not add a second flake devShell implementation.
- Select a pinned nixpkgs input deliberately, preferably aligned with the system flake's current revision initially. Document that `devenv.lock` and `flake.lock` have separate update lifecycles. Do not refresh unrelated system inputs.
- Add `.envrc` with `eval "$(devenv direnvrc)"` and `use devenv`; leave `direnv allow` as an explicit user trust step.
- Ignore `.devenv/`, `.direnv/`, and documented local devenv overrides/generated state, without ignoring `devenv.lock` or the tracked configuration files.
- Provide Node.js and pnpm through devenv. Keep zx in the existing npm manifest/lockfile as the single project dependency source; install with `pnpm install --frozen-lockfile` and expose `node_modules/.bin` in the environment. Use the supported devenv pnpm integration only after checking its lockfile/install behavior. Never silently rewrite the lockfile on shell entry.
- Provide `nix-prefetch-github`, `pre-commit`, `nixd`, and `nixfmt`. Also declare direct script dependencies such as Bash, coreutils, util-linux/flock, GNU tar, stow, Git, JJ, and GitHub CLI so a successful shell does not depend accidentally on this workstation's package list. Keep Nix, sudo, and the privileged nh installation as host prerequisites.

### 2. Expose public scripts safely

- Add `$DEVENV_ROOT/scripts` to PATH using devenv's supported environment mechanism. This preserves original script locations, existing shebangs, argument forwarding, exit status, and existing `./scripts/...` interfaces.
- Public shell commands: `nix-test`, `nix-switch`, `nix-update-test`, `nix-update-switch`, `stow-add`, `stow-adopt`, `stow-check`, and `stow-remove`.
- Add convenient extensionless devenv wrappers for `update-github-packages-check` and `rollback-test-changes`, delegating to the original TypeScript files with the project-local zx runtime. Do not give internal `nixos-rebuild.ts`, `_stow-lib.sh`, or `rebuild/` helpers additional public aliases.
- Do not copy, symlink, or source the public shell scripts into generated wrappers. Preserve the current zx CLI argument shape (`process.argv.slice(3)`) used by rebuild orchestration.
- Preserve the current execution-directory contract of rebuild/checker scripts unless an explicit root-normalization change is needed; document invocation from the repository root.
- Shell entry must never rebuild, activate, roll back, change Stow links, publish, or run the GitHub checker automatically.

### 3. Remove only clearly project-scoped global packages

After the shell works:

- Disable/remove the global zx and nix-prefetch-github modules and their development-profile enables, checking for other references first.
- Remove pre-commit from `programs/git.nix`; retain its explicit invocation in the switch workflow, now satisfied by devenv.
- Remove desktop-global pnpm after checking whether it is intentionally a cross-project convenience; otherwise retain globally and still pin it locally.
- Keep nixd and nixfmt globally installed: the user edits Nix files in other projects too. Preserve `programs/nixd.nix`, including its nixPath setting. Also provide pinned local versions in devenv for reproducible project tooling; do not remove their global packages.
- Keep devenv, direnv/Fish integration, Nix, nh, sudo policy, Git, JJ/jjui, gh, stow, and general shell tools globally. These provide bootstrap, system-administration, or cross-project functionality; local declarations can overlap intentionally for reproducibility.
- Keep Neovim, gcc/gnumake, ripgrep/fd, imagemagick, and general editor language tooling in this pass. The repository has no Svelte source, so moving its Svelte server here would merely hide another project's dependency. Treat broader per-project editor-toolchain migration as separate work.
- Keep mkcert and other desktop utilities unless concrete repository-only usage is found; no such usage was identified in this audit.

### 4. Documentation and checks

- Update README with bootstrap prerequisites, `devenv shell`, optional direnv trust, frozen dependency installation, public command names, and host-versus-project package ownership.
- Document that existing VS Code tasks and agent workflows must run inside/inherit the devenv environment after global zx removal. Preserve the approved exact `./scripts/nix-test` and `./scripts/nix-switch "<description>"` entry points; no self-bootstrapping recursion inside those wrappers.
- Verify clean-shell dependency availability, local zx resolution, and script argument forwarding. Use temporary directories or mocked commands for side-effecting scripts; do not execute real activation/rollback/Stow-adopt operations as smoke tests.
- Validate shell syntax, Nix formatting, frozen pnpm installation, and pre-commit configuration. The npm `test` script is a placeholder that exits 1, not an existing test suite. Use ephemeral smoke checks rather than introducing a persistent test suite contrary to the earlier user preference recorded in the JJ idea.
- Check that opening devenv does not update `flake.lock`, change `.host`, or alter JJ publishing settings. Do not run `devenv test` until any configured test hooks have been reviewed for side effects.

### 5. Approval and rollout

- Review all diffs and unrelated work. Load the rebuild skill and global JJ skill before relevant deployment/version-control operations.
- Because package removals are NixOS configuration changes, stop and present **NixOS Action**: switch, test, or do nothing. Implementation approval is not activation approval.
- Test only after approval with exactly `./scripts/nix-test`, inside the prepared environment. Never automatically switch after a test.
- If switch is selected, reuse the intended current change's existing description or infer one from the reviewed changes, without prompting (unless the user already supplied a description, which takes precedence). Run exactly `./scripts/nix-switch "<description>"` in the prepared environment. Do not publish during shell setup.

## Implementation and verification (2026-10-30)

- Added standalone devenv configuration, generated `devenv.lock`, optional `.envrc`, ignored local state, and documented setup/command ownership. Updated rebuild documentation and skill with the environment prerequisite.
- Resolved the system flake's root nixpkgs input (`nixpkgs_2`), pinning devenv to the same `151fa4e8ddfdd8dd25d945ad94ed54a13de9f6e4` revision. The similarly named `nixpkgs` lock node belongs to a transitive input and is not the system pin.
- Selected `pnpm_10` (10.34.5), compatible with the existing v9 lockfile. At this nixpkgs revision the default pnpm is a newer Rust-based major and no longer accepts a Node.js override; using pnpm 10 avoids an unrelated major/lockfile migration. Node.js is 24.21.0, JJ is 0.45.1, and project-local zx remains 8.8.5.
- Kept dependency installation explicit rather than using automatic pnpm install on entry. Initial noninteractive install needed `CI=true` to replace the pre-existing node_modules layout. Frozen installation succeeded without manifest/lockfile changes.
- Exposed original shell script paths and two extensionless TypeScript aliases. No operational script runs on entry or in `devenv test`.
- Removed the zx and nix-prefetch-github NixOS modules/profile enables, pre-commit from global Git packages, and desktop-global pnpm. Kept global nixd/nixfmt and the full nixd module unchanged, as requested.
- `devenv test` passed, including local zx resolution, all public shell launcher syntax/path checks, helper syntax, and pre-commit configuration validation.
- Clean-shell checks confirmed direct dependencies resolve from Nix store packages, not system-global PATH; absolute script/zx paths remain usable after changing directory.
- Ephemeral mocked smoke checks passed for all four rebuild entry points (mode/update/description forwarding and exit status), all four Stow scripts (common/host tier resolution without touching HOME links), and both TypeScript aliases (argument boundaries and exit status). Temporary fixtures were removed; no persistent test suite was added.
- Nix formatting and whitespace checks passed. Full NixOS top-level derivation evaluation succeeded without building or activating; existing xorg.xhost and gemini-cli warnings remain unrelated. The evaluated global package list retains nixd/nixfmt and excludes the four localized tools.
- `flake.lock`, `pnpm-lock.yaml`, and `nixos-modules/programs/nixd.nix` are unchanged. No JJ config/bookmark/index mutations or publication were performed. Unrelated `.ideas/investigate-kitty-launch-regression.md` was present before implementation and remains untouched; deployment wrappers would include it.
- User approved permanent application. Direnv trust (`direnv allow`) remains the user's explicit choice.

## Switch attempt (2026-10-30)

- Ran the approved `./scripts/nix-switch "setup devenv"` inside devenv, reusing the existing JJ description.
- Published exact revision `e2b2d6b2f7c1831c67f34bb47c030ee7ec4bf663` to `main@origin`. Generation label: `setup-devenv-e2b2d6b2f7c1`. The wrapper created an empty child; do not rerun switch against that child or automatically select its parent.
- The command runner timed out after 120 seconds while `sudo nh os switch` was running. Subsequent checks found the root nh process (51620) and Nix child (51621) still present; Nix was in uninterruptible sleep (D state). Activation success is not established.
- At inspection, `/run/current-system` remained `test-setup-devenv-e2cd96927dac`, and the persistent system profile remained `Reenable-home-manager-and-wallpaper-daemon-ea02aa7c4673`. These are not the published target label.
- System journal inspection found a large stream of USB audio kernel warnings (`snd_usb_audio`, `usb_submit_urb`, `BOGUS urb flags`) on the running kernel. No causal link to the stalled Nix process is established. Did not change drivers, reboot, kill processes, retry deployment, or roll back publication.
- Source export remained at `/tmp/nixos-rebuild-5xZSYE/source` while the surviving process could still need it. This rollout note was a new, unpublished working-copy edit after the published source snapshot.

## Approved retry (2026-10-30)

- After the forced reboot, the user explicitly requested another apply attempt. No old nh/Nix processes remain, and a bounded current-boot kernel query found no matching RCU stalls, hung-task messages, or USB warning flood.
- Current `@` contains only the rollout and freeze-investigation notes, on top of the published devenv implementation. Retry will finalize this nonempty current change as `Retry devenv deployment`, including these notes; no system configuration or inputs were changed since the first attempt.
