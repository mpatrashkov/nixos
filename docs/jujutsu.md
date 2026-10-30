# JJ and NixOS rebuilds

JJ is installed alongside Git through `nixos-modules/programs/git.nix`. Personal identity/editor configuration is Stow-managed by the `jujutsu` package. The global Pi skill lives in the existing `pi` Stow package; run `/reload` in Pi after updates, then use `/skill:jujutsu` or `/skill:nixos-rebuild`.

## Initial setup

The package/configuration change does not automatically initialize this checkout. After an approved NixOS test/switch makes `jj` available:

1. Inspect `git status`, `git branch -vv`, `git remote -v`, identity/signing settings, and any unrelated work. Preserve it before proceeding. Do not use initialization as a substitute for reviewing dirty files.
2. With explicit migration approval, initialize and inspect:

   ```bash
   jj git init --colocate
   jj status
   jj log
   jj bookmark list
   ```

3. If `main` and `origin` are still the intended publishing branch/remote, explicitly track and configure them:

   ```bash
   jj bookmark track main@origin
   jj config set --repo nixos.publish-bookmark main
   jj config set --repo nixos.publish-remote origin
   ```

   Otherwise use the verified names, not these examples. The publishing bookmark and its remote counterpart must already exist. Review any divergence before proceeding.

4. Verify `jj config get user.name`, `jj config get user.email`, and the working-copy author. Identity changes do not retroactively change existing commits; investigate a wrong author rather than rewriting it automatically.
5. From now on use JJ for local version-control mutations. Keep Git for interoperability, but avoid Git-writing GUIs and Git index-based mutations unless deliberately coordinating them with JJ.

An existing installed `commit-msg` pre-commit launcher is harmless: the updated configuration contains no naming hook. It can be uninstalled separately if desired. `last-commit-message` is no longer read and can be deleted manually.

## Rebuild commands

Enter `devenv shell` and install the project dependencies with `pnpm install --frozen-lockfile` before running rebuilds. zx and pre-commit are project-scoped; editors and agent command sessions must inherit the environment. See the [development environment setup](../README.md#development-environment).

Follow AGENTS.md's deployment approval policy. Do not invoke these merely to smoke-test a skill.

```bash
./scripts/nix-test
./scripts/nix-switch "Describe the change"
```

Until this checkout has `.jj`, wrappers retain Git support. Git test creates an unpublished snapshot using a temporary index: it includes nonignored new files but does not move the current branch or alter the real index. Git switch stages, commits, and pushes normally.

With JJ initialized:

- Test snapshots `@` without pushing or requiring a permanent description.
- Switch requires a nonempty, non-conflicted `@`, runs configured pre-commit checks, describes the change, moves only the configured bookmark forwards, and pushes only that bookmark. Both the local and known remote bookmark must be ancestors of the source. A changed remote can still reject the push safely.
- After publishing, a new empty working-copy change is created. The build still uses the finalized source, not that empty child.
- An empty `@` is rejected for switch. Select the intended change explicitly; wrappers do not assume `@-` is what you meant.

`nix-update-test` and `nix-update-switch` explicitly run `nix flake update` before taking the snapshot. Do not use them again just to deploy an already-reviewed lockfile update. Ordinary wrappers never update inputs.

The four entry points launch `scripts/nixos-rebuild.ts` through the existing `zx` runtime. The only shared Bash launcher, `scripts/rebuild/run`, holds a `flock` while TypeScript runs. Git and JJ operations live in `scripts/rebuild/git.ts` and `scripts/rebuild/jj.ts`; `snapshot.ts` exports source and writes metadata, and `label.ts` formats generation descriptions. All rebuild logic is TypeScript; no new npm dependencies are needed.

All wrappers capture an immutable Git commit ID, export that commit into a temporary directory, and stamp generation metadata only into that export. Nix evaluates/builds the export with lock updates disabled. The live checkout is not the build source. All nonignored work is included: review unrelated edits first.

## Generation descriptions

Example labels:

```text
Install-JJ-and-skills-0123456789ab
test-Adjust-audio-routing-0123456789ab
```

Undescribed tests use `test-configuration-<revision>`. Git tests always use this neutral description rather than borrowing the last commit subject. The complete commit ID is recorded in `system.configurationRevision`, even though the display suffix uses 12 characters.

The formatter:

- Takes only the description's first line.
- Replaces unsupported characters with hyphens; retains only ASCII letters/digits, `.`, `_`, and `-`. In particular, colons are unsafe even though the NixOS option type permits them.
- Uses a nonempty fallback and caps the complete label at 80 ASCII bytes.
- Also enforces the dynamic budget `211 - 4 - length("nixos-system-${system.name}-")`. The `.drv` suffix counts; for system name `nixos`, the top-level label maximum is 188 bytes.
- Reserves the mode prefix and revision suffix before truncating the description.

The NixOS module independently asserts the safe alphabet and complete derivation filename length. Direct flake evaluations work without generated metadata: a clean source revision is used when available, otherwise the pinned NixOS version is the fallback.

Limine is unchanged: menu entries remain `Generation N`, and the description appears on hover/selection through the bootspec comment. Other image/output types can impose additional naming limits; the top-level derivation budget is not a universal image-name guarantee.

## Failure behavior

Checks, source export, evaluation, and push failures stop activation. A successful push followed by a failed build/activation leaves the remote published; no automatic rollback, bookmark reset, or history rewrite is attempted. A rejected push can leave the local change described and bookmark moved. Inspect status and remotes before deciding how to retry.
