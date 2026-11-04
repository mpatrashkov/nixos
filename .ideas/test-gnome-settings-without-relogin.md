---
title: "Test GNOME configuration changes without relogging"
status: testing
priority: medium
tags: [gnome, nixos, dconf, testing, jj]
created: 2026-11-04
updated: 2026-11-04
---

## Goal

Provide a repeatable way to preview GNOME configuration changes without signing out of the current Wayland session. User requests implementation in a new JJ change inserted as the parent of the current `fix tmux links` change (`zxullxkx`). Explicit plan-review approval is required before implementation or graph mutations.

## Read-only findings

- GNOME Shell 50.4 runs on Wayland. Restarting the main compositor is not a safe general-purpose reload mechanism.
- The user dconf profile references immutable Nix store databases via `file-db:`. Replacing the profile at NixOS activation does not guarantee that already-running clients reopen it.
- Most settings in `nixos-modules/services/gnome/default.nix` are locked with `lockAll = true`; `gsettings writable org.gnome.desktop.session idle-delay` returns false. Ordinary user overrides cannot bypass these locks.
- Blur my Shell settings are in a separate unlocked defaults database. Existing user overrides can mask changed system defaults; relogging does not clear them.
- Extension schemas are not necessarily on the ordinary command-line schema search path: the default `gsettings` invocation could not find the Blur my Shell panel schema.
- GNOME 50 advertises `--devkit`, `--wayland`, and `--virtual-monitor`; any nested-shell launcher must use supported options and isolate both D-Bus and dconf from the real desktop.

## Selected scope

User selected both workflows, starting only with option 2: an isolated nested GNOME session. The first implementation will not include live overrides in the real desktop. Live previews remain a separately approved follow-up. Keep Stylix/Home Manager ownership unchanged.

Plan: `.plans/test-gnome-settings-without-relogin.md`. Initial plan was approved (SHA-256 `b320852e25b717881ec8bd61e70bdd265ac718451f849efa8c7b1b6ff82a7d79`); implementation started in new parent change `rmxxqrwp`. The original tmux diff in child `zxullxkx` is byte-for-byte preserved.

## Partial implementation and safety stop

- Added candidate preview package and scripts with private HOME/XDG paths, dconf profile, restricted session-bus activation, and a private PipeWire helper. Added only passthru UUID metadata to the custom Multi-monitor Panel derivation; its package output is unchanged.
- Bundle builds, dry-run diagnostics work, and desktop/WSL toplevel derivations evaluate. Existing xorg/gemini-cli warnings remain. No test files or test harness were added.
- A disposable launch started GNOME Shell 50.4/Devkit and discovered the configured candidate extensions. Another Window Session Manager is declared enabled but not packaged; this is reported as a warning.
- The launch logged GDM session/display registration attempts and logind session monitoring. Source inspection confirms these use the system bus, which the initial implementation did not isolate. Per the approved stop condition, further implementation/launches are paused for a revised plan with explicit system-bus restrictions.
- Devkit escaped the launcher's process group and survived shutdown. The exact preview-owned viewer was identified by its executable and private environment, then terminated through a pidfd. Robust descendant cleanup also needs revision.
- Outer GNOME Shell PID stayed 3594, user dconf SHA-256 stayed `d7020c3ed8604053ce32ec323f384459f6b22b1b7d73de2b78ef31a46bd875b5`, idle-delay stayed 900, and Blur my Shell remained ACTIVE. These checks do not prove GDM/logind received no calls; do not claim full isolation.
- No input updates, NixOS activation, publishing, or bookmark moves occurred. At this checkpoint tooling was incomplete; the subsequent approved work below resolves the isolation/cleanup blockers.

## Phase 1 implemented after revised approval

User approved revised plan SHA-256 `0fb9d01c77fc4abaec98be298d05907e7aef0ac581c0553aae82b923f212535c`.

- `scripts/gnome-preview` builds the candidate flake package and launches GNOME 50 Devkit with disposable HOME/XDG state, ordered compiled user dconf databases, candidate extension/schema/theme assets, a private session bus with dconf-only activation, and private minimal PipeWire server/client configs.
- Added an explicit `xdg-dbus-proxy` system-bus boundary. The allowlist is empty: GNOME starts without any host-service access. Proxy logs show GDM RegisterSession/RegisterDisplay, polkit registration, and other host-service calls being hidden/blocked rather than forwarded.
- Replaced process-group cleanup with child-subreaper supervision, pidfd-scoped termination, escalation, and reaping before temporary-state removal. The detached Devkit viewer no longer survives termination.
- The isolated launch returned all four candidate extensions as ACTIVE with empty extension errors: Blur my Shell 77, Dash to Dock 109, Multi-monitor Panel, and User Themes 79. The candidate idle-delay remains locked, and private dconf reads Blur my Shell settings-version 8.
- Bundle build, Python/Bash syntax, Nix formatting, dry-run from outside the repository, invalid-size handling, and early unsupported-session rejection pass. Desktop/WSL toplevel derivations still evaluate to the same paths as before the isolation changes. Existing xorg/gemini-cli warnings remain; concurrent evaluation emitted an ignored busy eval-cache warning without failing builds/evaluations.
- The verified termination left no preview-owned processes or workspace. Main Shell PID and user dconf checksum remain unchanged. No test files or test harness were added.
- Usage, limits, stripped-session warnings, read-only private-bus inspection, and cleanup behavior are documented in `docs/gnome-preview.md`, linked from `docs/nixos-modules.md`.
- Phase 1 implementation is complete; visual acceptance is pending. Run `./scripts/gnome-preview` and judge the nested window. Full theme/home-file parity and real hardware/session integration are intentionally outside this preview.
- Phase 2 (reversible live previews in the real desktop) is deferred and requires fresh approval. No activation or publication is required for this tooling.
