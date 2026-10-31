---
title: "Improve Neovim word wrapping"
status: done
priority: medium
tags: [neovim, dotfiles, wrapping]
created: 2026-11-01
updated: 2026-11-01
---

Enabled `wrap` and `linebreak` in `dotfiles/common/nvim/.config/nvim/lua/options.lua`. Long lines wrap at word boundaries without changing file contents. Words longer than the window width may still split.

Validated both options with headless Neovim; `git diff --check` passed. The existing Stow symlink makes the source change available without re-stowing. Restart Neovim or run `:set wrap linebreak` in an existing window.
