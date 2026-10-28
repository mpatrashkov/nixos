---
title: "Liquid Glass for the GNOME top bar and dock"
status: in_progress
priority: medium
tags: [gnome, nixos, desktop, blur]
created: 2026-10-26
updated: 2026-10-28
---

## Approved approach

- Pin Blur my Shell v76, which includes the unified pipeline backend and Liquid Glass.
- Install system-wide via the existing NixOS GNOME module; no Home Manager or manual extension installation.
- Share a subtle dynamic Liquid Glass pipeline between the top bar and the existing left-side Dash to Dock.
- Extend the same 85% charcoal pipeline to popups (preserving shell control styling), overview, app folders, and lock screen, with dark styling where supported.
- Keep application windows, screenshot UI, Window List, and Coverflow Alt-Tab blur disabled.
- Put visual defaults in an unlocked dconf database so preferences can be tuned interactively, then capture the preferred settings in Nix.
- Test secondary-monitor panels, overview/fullscreen transitions, readability and GPU load before marking complete.

## Validation

Blur my Shell v76 package and dconf databases built successfully. Full NixOS toplevel derivation evaluation passed (existing unrelated deprecation/package warnings remain). Nix formatting and git diff whitespace checks passed.

User confirmed the extension works, but the initial preset was far too transparent. Increased Liquid Glass tint from 12% to 65%, explicitly using charcoal instead of the effect's default white tint, and increased backdrop blur radius from 20 to 30. The revised defaults still need live visual validation.

User requested more consistent shell color with less influence from the backdrop. Increased charcoal tint again, from 65% to 85%, keeping blur radius, tint color, and refraction unchanged. This latest adjustment has not yet been tested live.

Implemented the approved surface expansion: dynamic popup blur with theme control styling preserved, dark overview components and app-folder dialogs, and lock-screen blur. All use the existing pipeline. Setting names and style values were checked against the installed v76 schemas. Live contrast, corner handling, transitions, multi-monitor behavior, and performance still need validation.

Pending user-selected NixOS test/switch workflow for the revised preset. A fresh GNOME session may be necessary after installation. Visual and performance validation must happen in the live desktop; secondary-panel compatibility is not yet verified.
