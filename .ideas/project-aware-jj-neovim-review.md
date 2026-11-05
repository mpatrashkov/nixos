---
title: "Project-aware JJ Neovim review"
status: testing
priority: medium
tags: [neovim, jj, jjui, lsp, review, dotfiles]
created: 2026-11-05
updated: 2026-11-05
---

Rethink the current dedicated hunk.nvim snapshot review so it offers a full Neovim project context and easy navigation to related files. User explicitly requested plan-first Neovim review; no implementation until an exact plan is approved.

Related investigation: [Zig highlighting and LSP in JJ review](fix-zig-highlighting-and-lsp-in-jj-review.md). Existing integration and prior rejected embedded-jjui design: [Explore JJ diffs in Neovim](explore-jj-diffs-in-neovim.md).

User selected live-project navigation with normal editing available, then requested out-of-the-box plugin behavior rather than custom gd/hover routing. Revised direction: use the existing Diffview plugin with live working buffers for current changes, exact snapshot comparisons for historical changes, and retain annotations through a bounded adapter. Keep hunk as an explicit merge/legacy fallback. Plan: `.plans/project-aware-jj-neovim-review.md`. Historical/live differences and stale annotation safety must remain explicit. User approved the revised saved plan in chat. Implemented in JJ change `woqkmsxt`; automated validation passes, with manual jjui interaction pending.

## Implementation and validation

- Default `jj review` now uses existing Diffview: live real-file buffers for `@`, explicit parent/selected Git object comparisons for historical single-parent changes. No custom LSP routing or diff UI.
- Preserved `jj review-legacy` for hunk and JJ merged-parent semantics. Unsupported/ambiguous selections are explicitly rejected rather than silently changing the comparison.
- New annotation adapter reuses manifest identities and persistence, validates pane content, invalidates changed live-buffer anchors, and cleans mappings on view close. Reports/list commands survive closing the view.
- Added Zig to managed Tree-sitter languages and installed parser/queries successfully. Native ZLS hover/definition passed using the existing project toolchain on PATH.
- Retained regression suite: `python3 scripts/tests/jj-review.py`, also run with wallpaper project's compatible Zig/ZLS PATH. Tests cover configured-tool terminal launch, live/historical/legacy modes, exact paths/sides, added/deleted/renamed and quoted/Unicode files, BOM/CRLF, unsupported binary panes, native LSP, stale-anchor refusal, unsaved changes, report persistence, view-close cleanup, merge/root/ambiguous rejection, and unchanged disk source/Git index.
- Stow linked the new launcher; Neovim's existing directory symlink exposes the adapter. No plugin updates, Git index mutations, publication, or NixOS activation.
- Remaining manual check: restart jjui, Ctrl-o on the current change, navigate with native LSP and Diffview keys, add a comment, close the diff, and exit back to jjui.
