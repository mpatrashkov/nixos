---
title: "Add Zig LSP to Neovim"
status: done
priority: medium
tags: [neovim, zig, lsp, dotfiles, jj]
created: 2026-11-04
updated: 2026-11-04
---

Configure ZLS using Neovim's existing native LSP setup and shared completion capabilities, enabled when `zls` is on PATH. Use project-provided compatible Zig/ZLS toolchains rather than adding global packages.

Implemented in JJ change `wuxmvnmz`, inserted immediately before the GNOME preview change (`rmxxqrwp`). Plan approved: `.plans/add-zig-lsp-to-neovim.md`.

## Validation

- Headless configuration checks passed with ZLS both present and absent; shared completion capabilities and existing server enablement were preserved.
- Real ZLS attached to `~/dev/wallpaper-daemon/src/main.zig` using the project's existing `.devenv/profile/bin` toolchain on PATH, with completion and definition capabilities advertised. No dependencies installed or project configuration changed.
- No global packages, plugin updates, Stow operations, publication, or NixOS activation required. Launch Neovim from the project environment so it inherits compatible Zig/ZLS executables.
