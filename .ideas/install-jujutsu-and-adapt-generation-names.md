---
title: "Install Jujutsu, add usage skills, and adapt generation naming"
status: testing
priority: medium
tags: [jujutsu, jj, git, pi, skills, nixos, generations, tooling]
created: 2026-10-27
updated: 2026-10-28
---

# Scope

Implementation approved on 2026-10-27. Installation/configuration and skills are being implemented; deployment still requires the NixOS Action approval. Defer initializing JJ in this checkout until the installed tooling and wrappers are validated. Do not publish or activate without approval.

Related: [Pi workflows and generation naming](pi-workflow-and-generation-names.md). This plan supplies the JJ-specific migration and naming design; coordinate the shared naming work rather than implementing it twice.

## Verified baseline

- `jj` is not currently on PATH.
- `nixos-modules/programs/git.nix` installs Git, pre-commit, GitHub Desktop, and GitHub CLI.
- `scripts/nix-switch` and `scripts/nix-update-switch` stage everything, commit, push, then invoke `nh`; the update variant adds `-u`.
- `scripts/nix-test` stages everything; `scripts/nix-update-test` does not. Both invoke `nh` without refreshing generation labels.
- A Git commit-msg hook generates ignored `last-commit-message`, replacing spaces with double underscores. A path flake input and overrides in all four scripts feed it into `system.nixos.label`.
- JJ should not be assumed to run Git hooks. The existing label mechanism therefore cannot remain the source of truth after migration.
- Repo skills live in `.agents/skills/`; portable personal skills are Stow-managed under `dotfiles/common/pi/.pi/agent/skills/`.
- Existing AGENTS.md mandates Git-based switch/test wrappers. Any JJ migration must update that policy and the wrappers together, not have a skill silently override it.

## 1. Install JJ without migrating the repository yet

1. Inspect the locked nixpkgs `jujutsu` version and its packaged documentation/help before choosing version-specific commands.
2. Add `pkgs.jujutsu` alongside Git in the NixOS package module. Retain Git and existing tooling for interoperability.
3. Use Stow for any personal JJ configuration. Check the actual version's config path; configure identity, editor, and only a small set of documented defaults. Do not copy credentials or introduce Home Manager.
4. Follow the NixOS Action approval workflow for installation. Test or switch only after explicit approval; use plain chat if the interaction tool is unavailable.
5. Verify `jj --version` and practice in a disposable repository before touching this checkout.

## 2. Add two narrowly scoped skills

### Portable `jujutsu` skill

Recommended location: `dotfiles/common/pi/.pi/agent/skills/jujutsu/SKILL.md`.

Cover inspecting status/log/diffs; working-copy commits; descriptions; `new`, split, squash, restore, and rebase; bookmarks and remotes; fetch/push; conflicts; and operation-log recovery. Verify exact commands against installed JJ help.

Safety rules:

- Inspect state before changing it. Explain that `@` is a mutable working-copy commit, not Git's staging area.
- Distinguish stable change IDs from content-addressed commit IDs; descriptions and edits can change the latter.
- Do not rewrite published history, abandon changes, undo operations, move publishing bookmarks, or push without approval.
- Treat snapshotting as a possible side effect even of inspection commands; use documented no-snapshot/ignore-working-copy modes where appropriate.
- Do not mix Git index-based mutations with JJ operations by default in a colocated repository.
- Inspect fetch results before rebasing or pushing. Handle conflicts explicitly rather than auto-resolving them.

### Repo `nixos-rebuild` skill

Recommended location: `.agents/skills/nixos-rebuild/SKILL.md`.

Reference the authoritative AGENTS.md policy and approved wrappers. Cover test/switch/do-nothing, message collection, source selection, publishing, labels, raw output, and failure reporting. Audit the existing four skills for assumptions about Git staging/commits and update only affected instructions.

Read Pi skills docs and relevant linked configuration/package docs before implementation. Confirm discovery and `/skill:jujutsu` / `/skill:nixos-rebuild` after `/reload`; no rebuild as a skill smoke test.

## 3. Migrate this repo deliberately

Recommended backend: colocated Git + JJ, preserving the Git remote, GitHub, and Nix flake interoperability.

1. Inventory branch, upstream, remotes, dirty/untracked/ignored files, hooks, signing, and pre-commit checks. Record recovery state and preserve unrelated work.
2. Try the intended workflow in a disposable clone with the installed JJ version, including Git-backed flake source inclusion and new files.
3. Initialize colocation only with approval. Verify default branch/bookmark tracking rather than assuming `main` or automatic bookmark advancement.
4. Make lint/format checks explicit: JJ publishing does not replace Git pre-commit hooks. Keep unrelated checks intact when removing the obsolete naming hook.
5. Confirm GitHub Desktop and any other Git-writing tools are either used under documented interoperability rules or avoided while JJ owns changes.
6. Explicitly decide whether to keep Git fallback support in wrappers. Never silently pick a publishing workflow solely because `jj` happens to be installed.

## 4. Generation-label contract

### Recommended labels

- Permanent switch: `<sanitized-description>-<short-commit-id>`.
- Test: `test-<sanitized-description>-<short-commit-id>`; use `test-<short-commit-id>` when undescribed.
- Direct flake build: a deterministic revision-based/default fallback that does not require hooks, JJ, or ignored files to exist.

Use the immutable Git commit ID for build provenance, not a JJ change ID alone. A change ID can identify successive versions of a change but does not identify exact source content. The human description remains the primary readable part.

### Source and publishing semantics

- Select an exact non-conflicted source snapshot before deriving the label. Verify tracked/new-file inclusion and clean versus dirty status.
- For switching, explicitly finalize the intended JJ change, move the agreed publishing bookmark, and push that bookmark. Account for the empty `@` often created after finalizing a change: do not label/build that empty child by accident.
- For testing, snapshot without publishing or forcing a permanent description. Label the exact tested snapshot, not the parent or last published commit.
- Capture the immutable source commit once and use it consistently for labels and builds; later commands must not silently change the source being built.
- Preserve the current push-before-switch contract unless explicitly changed. Failure to validate, finalize, or push must stop activation. Build-before-push can be considered separately.
- For update variants, resolve how `nh -u` mutates `flake.lock`: the final updated lockfile must belong to the snapshot identified by the label. Do not stamp a pre-update revision onto different source contents.

### Transport and formatting

1. Implement one shared label formatter. Verify actual locked NixOS constraints, then define allowed characters, whitespace/punctuation/Unicode handling, truncation budget, empty-description fallback, and newline handling.
2. Remove label generation from commit-msg hooks.
3. Prefer deterministic pure evaluation, with an explicit script-generated label transport for test/switch if required. Prototype whether the existing path-input transport or another Nix-supported override is simplest.
4. Ensure a clean clone evaluates without the ignored `last-commit-message` file. Do not adopt an environment-variable solution that requires impure evaluation or a tracked file containing its own commit hash.
5. Confirm Nix can build the exact selected commit from the colocated repository; do not assume Git HEAD, JJ `@`, and the desired source are identical.

Affected files: all four rebuild scripts; a shared helper and tests; `nixos-modules/features/generations/`; `.pre-commit-config.yaml`; `flake.nix`/`flake.lock`/`.gitignore` as required; AGENTS.md and affected skills.

## Verified naming constraints (2026-10-27)

Inspected pinned nixpkgs revision `151fa4e8ddfdd8dd25d945ad94ed54a13de9f6e4`, available locally at `/nix/store/0r7xswpqa49y26bl05lydybpw86sywmq-source`, and the installed Nix 2.34.8 validator. These are constraints from source, not generic assumptions about boot labels.

### Two validators with different allowed characters

- NixOS `nixos/modules/misc/label.nix:11` defines `system.nixos.label` as `lib.types.strMatching "[a-zA-Z0-9:_\\.-]*"`. It permits ASCII letters/digits, colon, underscore, dot, and hyphen, including an empty string. Spaces, Unicode, slashes, plus signs, and newlines fail this option type.
- Nix 2.34.8 [`src/libstore/path.cc`](https://github.com/NixOS/nix/blob/2.34.8/src/libstore/path.cc), `checkName`, permits ASCII letters/digits and `+ - . _ ? =`, but **not colon**. It additionally rejects empty names and certain leading dot components. The fixed `nixos-system-` prefix avoids those leading-component issues for the system derivation.
- Therefore the safe intersection for labels is **`[A-Za-z0-9._-]`**. Do not use colon merely because the NixOS option accepts it. Our formatter should also require a nonempty result even though the option itself does not.

### Length is a full derivation-name budget

- `nixos/modules/system/activation/top-level.nix:60` creates `nixos-system-${config.system.name}-${config.system.nixos.label}`.
- `system.name` defaults to the hostname (or `unnamed` for an empty hostname); this repo sets `networking.hostName = "nixos"`.
- Nix [`src/libstore/include/nix/store/path.hh`](https://github.com/NixOS/nix/blob/2.34.8/src/libstore/include/nix/store/path.hh) sets `StorePath::MaxPathLen = 211`. This is the name part after the hash, not the entire `/nix/store/...` path. Reserve another 4 bytes for `.drv`.
- For the ordinary top-level derivation, the label budget is therefore `211 - 4 - byteLength("nixos-system-${system.name}-")`. With system name `nixos`, the prefix is 19 bytes, leaving **188 ASCII bytes** for the complete label, including `test-`, separators, and revision suffix.
- Confirmed with evaluation-only dummy derivations (no builds or activation): a 188-character label succeeds; 189 fails because the `.drv` name exceeds 211. A colon-containing name also fails Nix validation.
- Other generated outputs may add their own suffixes or prefixes. This top-level bound is not a promise that every image/specialisation/tool permits the same length; test the actual targeted outputs.

Recommended formatter policy: use a smaller readability cap (provisionally 80 ASCII characters for the entire label), bounded by the calculated top-level limit. Reserve mode and revision suffix space first, truncate only the description, and fail clearly if the system name leaves insufficient space. Do not hard-code 188 as a universal limit. Add exact-boundary tests and recheck on Nix/nixpkgs upgrades.

### Actual bootloader behavior: Limine

- `nixos-modules/services/boot/default.nix` enables Limine, not GRUB or systemd-boot.
- `nixos/modules/system/activation/bootspec.nix:29` constructs a longer display string: `${distroName} ${codeName} ${system.nixos.label} (Linux ${kernelVersion})`.
- `nixos/modules/system/boot/loader/limine/limine-install.py:315` places that bootspec label in `comment: <bootspec label>, built on <time>`.
- `generate_config_entry` in that file uses **`Generation N`** as the menu title, or `Default` within a generation containing specialisations. Changing `system.nixos.label` alone does **not** rename the Limine menu title.
- User confirmed the current behavior: entries are titled `Generation N`, and the commit-message-derived description is shown when an entry is hovered/selected. Preserve this presentation; no Limine title customization or installer patch is needed.
- No explicit label-length check was found in this installer path; this does not prove the Limine renderer has unlimited width/length. Verify visibility and truncation of the selected-entry description on the actual boot menu.

The migration should replace how the description is obtained and sanitized, not how Limine presents it: use the intended JJ snapshot's description instead of the Git commit-msg hook, while retaining the `Generation N` title and selected-entry description.

## 5. Validation and rollout

- Unit-test formatting: blank/multiline/long descriptions, punctuation, Unicode, and consistent revision suffixes. Explicitly reject/sanitize colons despite the option type allowing them; cover total-length accounting, long system names, and 188/189-byte top-level boundaries for system name `nixos`.
- Integration-test scripts in temporary Git/JJ repos with mocked `sudo`/`nh` and remote pushes. Cover fresh clone, missing hooks, new files, empty `@`, undescribed changes, conflicts, detached/no bookmark state, rejected push, and failed build.
- Verify ordinary wrappers do not update inputs. Verify update wrappers label source containing the actual resulting lockfile.
- Confirm direct flake evaluation works without machine-local files; evaluate the resulting NixOS label before activation.
- Show diffs, then request the mandated NixOS Action approval. Do not run deployment during planning or migration tests.
- Verify active-system labeling after approved activation and boot-menu presentation on a later reboot.

## Implementation results (2026-10-27)

- Added pinned nixpkgs `jujutsu` 0.45.1 to system packages. Fetched and ran that executable for validation, but have not activated the NixOS configuration.
- Added and Stow-linked personal JJ identity/editor configuration and the global `jujutsu` skill. Added repo `nixos-rebuild` skill, updated AGENTS.md and affected skills, and documented setup in `docs/jujutsu.md`.
- Replaced hook/path-input label transport with `.nixos-generation.json` generated only inside an archive of the captured commit. Removed the obsolete hook/input and its lock node without updating any package inputs. Clean-checkout evaluations use revision/version fallbacks.
- Implemented one formatter with an 80-byte readability cap, dynamic system-name budget, safe alphabet, first-line descriptions, and 12-character immutable commit suffixes. The full revision is recorded in `system.configurationRevision`. Limine presentation remains unchanged.
- All four wrappers share orchestration. After the user requested TypeScript rather than split Bash, replaced all rebuild/label logic with `scripts/nixos-rebuild.ts` and focused modules in `scripts/rebuild/{git,jj,snapshot,label}.ts`. The existing zx runtime runs them; tiny shell launchers retain command names and hold the rebuild lock. Typed snapshots and a backend interface replace shell state/stdout protocols, and exceptions stop failures before publication/activation. No new npm dependencies or test files were added. Updates happen before snapshots. Git tests preserve the actual index/branch using a temporary index and unpublished commit. JJ tests snapshot without publishing; JJ switches require explicit publishing settings, reject conflicts/empty changes/non-fast-forward sources, publish one bookmark, and build the captured source rather than the new empty child.
- Selected compatibility behavior: use Git until this checkout is explicitly initialized with JJ, then use JJ. Merely installing the binary never selects a different workflow. This checkout has not been initialized or pushed; migration commands are documented for a separately approved follow-up.

### Validation completed

The validation below was performed during implementation. At the user's request, the test files were subsequently removed; do not retain test suites in this repository.

- Shell syntax, ShellCheck, nixfmt checks, pre-commit configuration validation, and `git diff --check` passed.
- Real temporary Git/JJ integration tests passed with Nix/sudo/nh mocked. Covered sanitization, new files, dynamic lengths, later checkout edits, input-update ordering, index/branch preservation, switch provenance, empty JJ children, missing config, failed checks/commits/pushes/builds, detached HEAD, conflicts, and non-fast-forward history.
- Pure Nix module tests passed: clean-clone fallback, 188-byte acceptance, 189-byte rejection, and colon rejection.
- Evaluated the complete NixOS top-level derivation both without metadata and with test metadata, using a temporary source copy containing the implementation. Confirmed the stamped full revision and installed package version 0.45.1. No full system build or activation performed yet.
- Existing evaluation warnings remain: xorg.xhost deprecation, gemini-cli replacement, and a legacy Home Manager rofi option rename. They are unrelated and were not changed.

### TypeScript rewrite validation (2026-10-28)

- Replaced the split Bash helpers and standalone Bash formatter with typed zx modules; only tiny command/lock launchers remain in Bash.
- Strict TypeScript checking, Prettier, ShellCheck for launchers, and `git diff --check` passed.
- Confirmed the installed zx runtime loads the TypeScript modules, rejects invalid CLI arguments before rebuilding, and formats a sample label. A disposable Git repository smoke check confirmed new-file inclusion and real branch/index preservation.
- No test files, npm dependency changes, real-repository commits/pushes, or NixOS activation were introduced by the rewrite.

### Test deployment (2026-10-28)

- User approved `./scripts/nix-test`. This checkout was already initialized with JJ when deployment was inspected; JJ was not yet on PATH, so the pinned 0.45.1 binary was temporarily added to the command environment for bootstrapping.
- The first attempt stopped before building because zx retains an extra launcher entry in `process.argv`. Corrected CLI parsing to use `slice(3)` and reran the approved test.
- Full build and temporary activation succeeded for revision `928d75b71adb732b246459c2c7735480b10f9c8b`, label `test-configuration-928d75b71adb`.
- Verified `/run/current-system` points to the tested system, `jj --version` reports 0.45.1, and system/user failed-service lists are empty. The persistent system profile and booted system remain `install__slack`, confirming no permanent switch.
- No publishing occurred. JJ reports a pre-existing `main` bookmark conflict; left it untouched. Review/resolve it with explicit approval before any switch/publication.

### Remaining rollout

1. Keep the test activation for user verification; do not automatically switch or publish. A reboot returns to the persistent configuration unless a switch is separately approved.
2. Before a requested switch, inspect the existing JJ bookmark conflict and publishing settings. Resolve/configure only with explicit approval; then collect the description and use the approved wrapper.
3. In Pi, `/reload` and confirm `/skill:jujutsu` / `/skill:nixos-rebuild` discovery. Confirm selected-entry description visibility after a later approved permanent switch/reboot.
4. Mark tracking done only after the chosen rollout checks are complete.
