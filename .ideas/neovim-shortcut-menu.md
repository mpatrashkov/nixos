---
title: "Searchable Neovim shortcut menu"
status: testing
priority: medium
tags: [neovim, shortcuts, dotfiles]
created: 2026-10-31
updated: 2026-10-31
---

Add a searchable in-editor reference for important Vim basics and existing custom/plugin shortcuts. Use the existing Telescope dependency, with `<leader>?` and `:Shortcuts` entry points. Collect described global and current-buffer mappings on each open, respecting buffer-local overrides and lazy plugin key stubs. The menu is informational and never executes selected shortcuts.

Implemented in a new JJ child change, preserving the existing review annotation work in its parent. Stow only; no NixOS activation or publication.

## Usage

- Press **Space then ?** in Normal mode, or run `:Shortcuts`.
- Type to search descriptions, keys, modes, and categories. Move through results with Telescope's usual controls. Enter or Escape closes without executing a shortcut; `q` also closes in the picker's Normal mode.
- Basics are a curated reference; global and current-buffer mappings are collected fresh each time. Lazy key mappings appear before loading their plugins; context-specific mappings appear only once installed in that buffer (for example, after LSP attachment). A curated **Review only** section also documents annotation shortcuts outside review sessions; these entries are reference-only and do not install review mappings. In active reviews, the actual buffer mappings remain listed too.
- `n` = Normal, `x` = Visual, `s` = Select, `o` = Operator-pending, `i` = Insert, `c` = Command-line, `t` = Terminal. Space is the configured leader; map listings may show it as `<Space>`.
- Add `desc` when defining future custom mappings to include them automatically. LSP mappings now have descriptions. Completion controls are documented explicitly because nvim-cmp's generated mappings are not described.

## Validation

Full-config headless checks passed: picker startup, expected plugin shortcuts, global/local overrides (including undescribed local overrides), LSP descriptions, buffer isolation, Visual-mode entries, fuzzy filtering, safe Enter-to-close, window cleanup, and unchanged source text. `git diff --check` passed. Stow re-applied; `~/.config/nvim` resolves to the shared repository package. Test script lives only in `/tmp`; no dependencies added or lockfile changes.

Manual interactive appearance and keyboard verification remain pending. Restart Neovim to load the new entry points.
