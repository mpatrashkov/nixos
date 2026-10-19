---
title: "Migrate Spotlight wallpaper to wallpaper-daemon in Zig 0.17"
status: done
priority: medium
tags: [gnome, wayland, wallpaper, zig, migration]
created: 2026-10-19
updated: 2026-10-19
---

## Goal

Move `packages/spotlight-wallpaper/` out of this flake into a standalone project at `~/dev/wallpaper-daemon`, rewriting it in Zig 0.17. Keep the TypeScript implementation working until the replacement passes acceptance checks. Related background: [original implementation](spotlight-wallpaper.md).

## Agreed direction

Start with CLI feature parity under the new executable name `wallpaper-daemon`. The project name does not by itself add a resident daemon. Defer background scheduling until the core port works; choose systemd user timers versus a long-running process separately.

Preserve existing XDG `spotlight-wallpaper` storage paths, JSON field names, absolute image paths, millisecond `lastShown` values, and `SPOTLIGHT_COUNTRY` / `SPOTLIGHT_LOCALE` overrides. Renaming the project must not discard downloaded images or history.

## Plan

### 1. Establish the standalone project and toolchain

- Inspect any applicable parent/project instructions before creating the destination.
- Create `~/dev/wallpaper-daemon` with `build.zig`, `build.zig.zon`, `src/`, tests, README, and ignore rules. Git initialization is explicit; do not create a remote or push implicitly.
- Use devenv, following `~/dev/custom-gui`: `devenv.nix`, `devenv.yaml`, committed `devenv.lock`, and `.envrc` using `eval "$(devenv direnvrc)"` followed by `use devenv`.
- Enable `languages.zig` with an explicitly selected Zig 0.17 compiler and compatible ZLS. The reference project's comment and test still target 0.16, so do not copy its toolchain assumptions unchanged. Pin exact available revisions through the lockfile; add explicit toolchain inputs/overrides if the pinned devenv nixpkgs does not supply the required versions.
- Follow the reference project's shell version banner and `enterTest` checks, updated to assert Zig 0.17 and verify ZLS compatibility. Include build/tests in `devenv test`.
- Ignore `.devenv*`, `.direnv`, local devenv overrides, `.zig-cache/`, and `zig-out/`; retain `devenv.lock`. Do not copy the reference project's unrelated GUI/debugging packages.
- First compile a small probe for the current 0.17 filesystem, process, HTTP/TLS, JSON, and I/O APIs. Verify certificate trust on NixOS and avoid copying obsolete Zig API examples.
- Prefer the standard library for HTTP, JSON, and process execution. If current HTTP/TLS APIs require a fallback, decide explicitly between libcurl and another dependency before implementing the transport.
- Establish `zig build`, `zig build test`, and `zig build run -- --help` inside `devenv shell`, with optional direnv activation. Supply required development/runtime tools such as `gsettings` through devenv as appropriate. No separate `flake.nix` shell or NixOS changes are required for the port.

### 2. Specify and test the compatibility contract

- Capture sanitized feed/state fixtures from the existing implementation; never commit downloaded photographs or private user paths.
- Preserve `fetch`, `next`, `info`, and help/error behavior.
- Feed behavior: same endpoint, placement, batch size, locale defaults, nested JSON item parsing, optional text defaults, title fallback, and removal of the `microsoft-edge:` source prefix.
- Security behavior: digit-only IDs; HTTPS image URLs restricted to the exact Microsoft CDN host; reject credentials, explicit ports, and redirects; 30-second request deadline; preserve copyright metadata.
- Cache behavior: skip existing IDs only when their files exist, save each completed download, atomic writes, retain at most 100 catalog entries, and preserve the selected image during pruning.
- Rotation behavior: offline selection among existing files, avoid the current image when alternatives exist, prefer the least recently shown images, randomize ties, and record selection only after GNOME application succeeds.
- Existing edge case: `next` fetches only when the catalog is empty, not when all recorded files are missing. Decide explicitly whether to preserve this or improve it with a documented test.

### 3. Port the core as small modules

Suggested modules (split further only when useful):

- `main.zig`: CLI, environment, orchestration, output, exit status.
- `spotlight.zig`: bounded requests, feed parsing, URL validation, metadata normalization.
- `library.zig`: XDG paths, catalog validation, atomic persistence, downloads, pruning, selection.
- `gnome.zig`: properly encoded file URIs and argument-based `gsettings` subprocess calls for both light and dark backgrounds; no shell interpolation.

Keep I/O boundaries testable and memory ownership explicit. Preserve unknown JSON fields tolerantly while validating fields the program relies on. Reject malformed state without overwriting it.

### 4. Add focused robustness during the port

- Enforce the 30 MiB JPEG limit during download rather than only after buffering; retain the current JPEG-signature check without claiming full image decoding.
- Bound feed response size as well as image size.
- Use a per-user advisory lock around mutating commands to prevent concurrent cache/state corruption; keep `info` read-only.
- Clean up temporary files on failure, preserve partial successful batches, and produce actionable errors for HTTP, parsing, filesystem, and GNOME failures.
- Restrict deletion to managed cache files even when catalog data is malformed or tampered with.
- Document that the two GNOME setting writes and catalog persistence are not one transactional operation; test failure handling rather than promising atomic desktop changes.

### 5. Validate without disturbing the live desktop

- Unit tests: nested feed parsing, IDs/URLs, optional metadata, malformed state, selection/ties/current exclusion, pruning, and URI encoding.
- Temporary-directory integration tests: original-format state loading, millisecond timestamp round-trips, missing files, interrupted downloads, write failures, lock contention, and safe cleanup.
- Use transport/process test seams for HTTP failures and `gsettings` failures; no live desktop mutation in automated tests.
- Smoke-test help/info and a live fetch against isolated XDG directories. Confirm HTTPS and certificate handling with the pinned toolchain.
- After explicit approval, run one real `next` in the user's GNOME session and verify both background keys and saved history.
- Back up the real catalog before using the replacement with existing storage. Avoid running old and new mutating commands concurrently: the old implementation does not honor the new lock.

### 6. Cut over and clean up

- Document build/run instructions, compatibility, network assumptions, copyright, and known limitations in the standalone project.
- Switch usage to the Zig executable only after acceptance checks pass.
- Remove the old TypeScript package and only the workspace/dependency entries made unnecessary by its removal. Preserve unrelated maintenance tooling and existing user changes; regenerate the pnpm lockfile with pnpm.
- Update `.ideas/spotlight-wallpaper.md` with the new project location and outcome.
- Handle Nix packaging, NixOS integration, scheduling, and remote publication as explicit follow-up decisions, not silent scope additions.

## Acceptance criteria

- `devenv shell` provides the pinned Zig 0.17 toolchain and compatible ZLS; `devenv test` verifies versions, build, and tests.
- No Node/pnpm runtime requirement in the new project; `gsettings` remains the GNOME integration dependency.
- Existing downloads and history work without destructive migration.
- Fetch/rotation/info preserve the documented behavior and safety constraints.
- Failed operations do not corrupt the catalog or delete unrelated files.
- The TypeScript source is removed only after the replacement is verified.

## Open decisions

1. CLI-first parity is the agreed starting point; scheduling or a resident daemon is deferred.
2. Resolved: Zig 0.17 standard-library HTTP/TLS works against the live feed on NixOS; no libcurl dependency.
3. Legacy storage paths are retained for compatibility; any rename is a separate migration.

## Implementation and verification (2026-10-19)

Standalone source now exists at `/home/miro/dev/wallpaper-daemon`, with devenv/direnv files and a generated `devenv.lock`. The shell provides Zig 0.17.0 from pinned nixpkgs and ZLS 0.17.0 from pinned upstream revision `542462c4ddf045493fa9ca028ee6bc3f38b2754a`. No Git remote, commits, publication, or NixOS changes were made.

Implemented the three CLI commands, legacy storage/state compatibility, standard-library network transport with bounded reads and a cancelable 30-second deadline, exact CDN/ID validation, atomic writes, mutation locking, rotation, safe pruning, and GNOME argument-based subprocess integration. Preserved the original empty-catalog-only auto-fetch behavior; missing recorded files require explicit `fetch`.

Verification so far:

- `zig build` and `zig build run -- --help` passed.
- `zig build test`: 16 tests passed, covering parsing, URL validation, URI encoding, state timestamps, selection, persistence, safe pruning, atomic failure cleanup, partial batches, bounded loopback HTTP, redirects/errors, and timeout cancellation.
- Isolated shell integration checks passed with fake `gsettings`: both light/dark setting failure paths leave history unchanged, successful offline rotation records selection, info is read-only, corrupt catalogs remain unchanged, and lock contention rejects mutation while allowing info.
- `devenv test` passed (versions, build, Zig tests, CLI tests).
- Two live fetches downloaded eight images into `/tmp/wallpaper-daemon-smoke.CMI4IK`, without using the real cache or changing the desktop.
- Read-only `info` successfully loaded the existing `/home/miro/.local/state/spotlight-wallpaper/state.json`; its SHA-256 checksum was unchanged afterward. The existing catalog has no current selection.
- A final `devenv test` rerun passed in 205 ms after fixing the shell test's lock-holder cleanup to avoid leaving an orphaned sleep process.

## Cutover completed (2026-10-19)

The user confirmed that the Zig program works as expected and requested deletion of the TypeScript implementation. Removed `packages/spotlight-wallpaper/`, its now-unused `pnpm-workspace.yaml`, the workspace-only `private` addition to the root manifest, and the package importer/Zod entries from `pnpm-lock.yaml`. Regenerated/verified the root lockfile with pnpm and ran an offline frozen-lockfile install; the existing `zx` maintenance dependency is unchanged.

The standalone Zig project at `~/dev/wallpaper-daemon` is now the maintained implementation. Cache images, catalog/history, maintenance scripts, and unrelated staged configuration changes were not modified. No additional desktop test was run during cleanup. See the standalone README for current paths, running instructions, safety guarantees, and limitations.
