---
title: "Remove Home Manager"
status: idea
priority: medium
tags: [nix, home-manager, dotfiles, cleanup]
created: 2026-08-09
updated: 2026-08-09
---

Remove all remaining Home Manager usage from the flake and migrate managed config to NixOS modules or Stow-based dotfiles.

## Approach

1. Audit the flake for any `homeConfigurations`, `home-manager` inputs, or `home.nix` references.
2. For each managed item, decide: NixOS module (system-integrated config) or Stow package (plain dotfiles).
3. Migrate each item and remove Home Manager from `flake.nix` inputs and `flake.lock`.
4. Verify the system builds and applies cleanly without Home Manager.
