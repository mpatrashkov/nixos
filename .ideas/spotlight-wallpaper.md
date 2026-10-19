---
title: "Spotlight wallpaper rotator for GNOME"
status: done
priority: medium
tags: [gnome, wayland, wallpaper, zig]
created: 2026-10-18
updated: 2026-10-19
---

Build a minimal Windows Spotlight wallpaper CLI in this repository's pnpm workspace, using native TypeScript execution on Node 22.18+. Keep dependencies minimal; Zod is used for feed validation. No test/mocking infrastructure initially.

## Approach

- `fetch`: download a batch of landscape images and metadata from the undocumented Windows 11 Spotlight feed.
- `next`: rotate cached images and update GNOME's light/dark wallpaper settings.
- `info`: show the current image's description and credit.
- Use XDG cache/state directories; retain up to 100 images.
- Start with manual commands. Defer systemd timers and NixOS integration until the basic tool has been used.

## Source

Endpoint investigation: https://github.com/ORelio/Spotlight-Downloader/blob/master/SpotlightAPI.md

The endpoint worked without credentials and returned 4K landscape photographs. It is undocumented and may change. Photographs retain their original copyright; do not commit or redistribute downloaded images.

## Implementation

Current source and documentation: `~/dev/wallpaper-daemon`, a standalone Zig 0.17 project using devenv. See [the migration plan and verification notes](rewrite-spotlight-wallpaper-in-zig.md).

On 2026-10-19, the user confirmed the Zig program works as expected and requested removal of the original TypeScript package. Deleted `packages/spotlight-wallpaper/` and its unused pnpm workspace/Zod entries. Existing wallpaper images/history and unrelated maintenance tooling were preserved.

### Historical TypeScript implementation

The approved refactor established a pnpm workspace and split the implementation into CLI orchestration, Spotlight feed parsing, local library management, and GNOME integration. The package runs directly on Node 22.18+ with no build step or zx globals. Existing maintenance scripts remain unchanged.

The existing cache and metadata format are preserved. Live smoke checks fetched four additional images into the eight-image library; ImageMagick confirmed all twelve files were 3840×2160 JPEGs. Help and info work through the package command. Node is supplied using `nix shell --inputs-from . nixpkgs#nodejs_22`, without editing NixOS configuration.

Wallpaper application remains for interactive use; no GNOME settings were changed. No timers, automated tests, or mocks were added.

## Zod validation

Per user request, replaced manual record/string guards and nested entry checks with Zod schemas. Schemas validate the batch envelope, nested items, numeric identifiers, and HTTPS Microsoft CDN URLs. Optional descriptive fields retain empty-string fallbacks, and metadata mapping is separate from validation. Malformed wallpaper entries now report schema errors rather than silently skipping missing required fields. A live fetch succeeded, adding three images to the existing library without changing the wallpaper.
