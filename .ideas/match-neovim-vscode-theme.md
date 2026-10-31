---
title: "Match Neovim to VS Code theme and fix Nix highlighting"
status: testing
priority: medium
tags: [neovim, vscode, theme, treesitter, nix, dotfiles]
created: 2026-10-31
updated: 2026-10-31
---

Use the current VS Code Gruvbox DrakenLords Dark Draken palette in Neovim, including its distinctive #031417 background. Replace Kanagawa with Gruvbox and explicit palette/highlight overrides. Add the missing Nix Treesitter parser so Nix files receive structural syntax highlighting.

Implemented in JJ change `rrkoxpku`, a child of the existing review annotation change, preserving that work. Followed the Stow skill (which bypasses plan review); no NixOS activation or publication.

## Findings and validation

- VS Code's active user theme is Gruvbox DrakenLords Dark Draken. Read its installed palette and token settings; configured ellisonleao/gruvbox.nvim with the matching dark background, UI colors, and approximate token mappings. TextMate scopes and Treesitter/LSP captures cannot map perfectly one-to-one.
- Nix was absent from both the configured parser list and installed parsers. Added `nix` and installed it successfully through the existing Treesitter tooling.
- Re-stowed the existing nvim package; `~/.config/nvim` still points into the shared repository package.
- Headless full-config test on `flake.nix` passed: Gruvbox selected, Normal background #031417, Nix filetype detected, active Treesitter highlighter, error-free parse, and 351 syntax captures. Whitespace check passed.
- Lazy pinned the new theme. Preserved unrelated lockfile entries rather than including incidental reconciliation of existing plugins.
- Restart Neovim to load the changes. Interactive appearance verification remains pending.
