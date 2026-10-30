---
title: "Investigate Kitty launch failure after theme and blur update"
status: done
priority: high
tags: [kitty, gnome, stylix, regression]
created: 2026-10-30
updated: 2026-10-30
---

User reports Kitty does not open after switching to generation `Reenable-home-manager-and-wallpaper-daemon-ea02aa7c4673`.

## Initial findings

- Kitty 0.49.2 is on PATH; `kitty --version` works.
- The user config remains a Stow symlink, with only two keyboard mappings; no Home Manager Kitty config has replaced it.
- An existing Kitty process (4550) launched by GNOME Shell has an active Fish child (4567).
- Diagnostic `kitty --debug-rendering -e /run/current-system/sw/bin/true` successfully creates a Wayland/OpenGL window and exits 0. Default `kitty` remains running until the diagnostic timeout (8s), without emitting a startup error.
- Kitty reports Mesa 26.2.4 and scale 166.7%; basic graphics initialization succeeds. This does not establish that the user sees the window or that the GNOME launcher works correctly.
- Important: diagnosis is running after the user booted the older generation `Replace-implicit-module-defaults-with-opt-in-profiles-6c71f53805c6`. Both `/run/booted-system` and `/run/current-system` confirm this. The affected `ea02aa7c4673` generation remains the persistent boot default. Successful launch observations above apply to the older session, not the reported failing session.
- Both generation profiles resolve Kitty to exactly `/nix/store/702dzpp63w7m1y7jiphqcz3dx64qqcyb-kitty-0.49.2/bin/kitty`; this was not a Kitty version change.
- Previous-boot Home Manager activation succeeded. Previous-boot journals contain no Kitty/GLFW/GLX startup error in the inspected entries; GNOME calendar errors are present, without an established connection.
- Initial checks did not establish the cause because they ran in the older session. Subsequent reproduction and resolution are below.

## Reproduction and resolution

- After the affected generation `ea02aa7c4673` became active, `kitty --debug-rendering` reproduced an immediate exit 1: `FreeTypeError: Failed to load face from path: /etc/profiles/per-user/miro/share/fonts/truetype/DejaVuSansMono.ttf` (`cannot open resource`).
- `fc-match monospace` returned that nonexistent path. The current per-user font directory contains Ubuntu Sans, not DejaVu, while the system still provides DejaVu. Stale fontconfig cache entries from a previous profile caused the failure.
- Refreshed fontconfig caches with `fc-cache --force`; this removed the bad match. Repeated as `env -u SOURCE_DATE_EPOCH fc-cache --force` to avoid warnings from the inherited build-environment variable. No cache directories or user configuration were deleted.
- `fc-match monospace` now resolves to `/nix/store/xadrivsjgk1bslbd64hq9zakin7vp6nr-dejavu-fonts-2.37/share/fonts/truetype/DejaVuSansMono.ttf`.
- Kitty's debug launch with a short-lived child created its Wayland/OpenGL window and exited 0. A normal Kitty launch stayed running until the five-second diagnostic timeout (124), with no error.
- No NixOS configuration changes, generation activation, rollback, or publication were needed. Cache repair resolves the observed failure; if profile switches reproduce it, investigate automated cache invalidation as a separate configuration change.
