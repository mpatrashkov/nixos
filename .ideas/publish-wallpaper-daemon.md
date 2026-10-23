---
title: "Publish wallpaper-daemon and re-enable it"
status: idea
priority: low
tags: [wallpaper, gnome, flake, multi-host]
created: 2026-10-23
updated: 2026-10-23
---

The `wallpaper-daemon` flake input was a local `path:/home/miro/dev/wallpaper-daemon`, which can't be fetched on other hosts (WSL). It was removed from `flake.nix` and its module/config commented out in `hosts/desktop/configuration.nix`.

## Approach

- Publish the repo (e.g. GitHub, private is fine with an access token) and add it back as a `github:` / `git+ssh:` input.
- Uncomment the import and `services.wallpaper-daemon` block in `hosts/desktop/configuration.nix`.
