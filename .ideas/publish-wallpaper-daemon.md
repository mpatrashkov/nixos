---
title: "Publish wallpaper-daemon and re-enable it"
status: done
priority: low
tags: [wallpaper, gnome, flake, multi-host]
created: 2026-10-23
updated: 2026-10-30
---

The `wallpaper-daemon` flake input was a local `path:/home/miro/dev/wallpaper-daemon`, which can't be fetched on other hosts (WSL). It was removed from `flake.nix` and its module/config commented out in `hosts/desktop/configuration.nix`.

## Approach

- Publish the repo (e.g. GitHub, private is fine with an access token) and add it back as a `github:` / `git+ssh:` input.
- Restore desktop scheduling through an opt-in service module selected by the desktop profile.

## Implementation (2026-10-30)

- User published `mpatrashkov/wallpaper-daemon`; verified that it is private and SSH access works.
- Added the remote input using `git+ssh://git@github.com/mpatrashkov/wallpaper-daemon.git?ref=main`, locked at `2e7b30f7e4ae6efca219135f6d3fb26ef5f51246`. Rebuilding hosts, including WSL, need SSH access to the private repository.
- Preserved the project's own nixpkgs/toolchain pin for Zig 0.17. Existing flake input pins were not updated.
- Added `nixos-modules/services/wallpaper-daemon.nix`, selected with `mkDefault true` by the desktop profile. Restored rotation every hour, fetching every six hours, country `US`, locale `en-US`.
- Removed the obsolete commented local-input configuration from the desktop host.
- Both host toplevel derivations evaluate. Desktop evaluation contains both user timers; WSL leaves the module disabled and has neither timer. Formatting and whitespace checks pass.
- No new test files, icon/theme changes, publishing, or activation. Deployment awaits the NixOS Action choice.
- Existing unrelated microphone-shortcut edits and the deferred theme-regression tracking file remain untouched; rebuild wrappers include them if deployment is approved.
