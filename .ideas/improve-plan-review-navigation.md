---
title: "Improve plan review navigation"
status: testing
priority: medium
tags: [neovim, pi, planning, markdown, shortcuts]
created: 2026-11-01
updated: 2026-11-01
---

Show line numbers in Neovim plan reviews, add quick heading navigation, and enable section folding compatible with Markview. The Pi launcher currently explicitly disables numbers. Markview documents native Treesitter section folding rather than a separate collapse command.

Plan: [.plans/improve-plan-review-navigation.md](../.plans/improve-plan-review-navigation.md).

Implemented in JJ child `kumxnrqr` after plan approval; existing work remains in its parent. No publishing or NixOS changes. The plan is saved locally under the repository's ignored `.plans/` directory.

## Implemented

- Review-only absolute source line numbers and a narrow fold column; heading sections start expanded.
- `]h` / `[h` navigate real ATX/Setext headings, support counts, stop at boundaries, and reveal folded destinations. Fenced fake headings are ignored.
- Native heading folds (`za`, `zc`/`zo`, `zM`/`zR`) compatible with Markview. Annotation jumps reveal source lines, including when recreating a plan split.
- Searchable shortcut reference and usage documentation updated. Shared Markdown query affects other windows only if they independently use Treesitter folding.

## Validation

Full-config headless Neovim checks passed using temporary fixtures/state: heading detection/counts/boundaries, nested and Setext fold levels, native open/close/toggle/all-fold commands, initially open folds, unchanged source, described shortcut entries, buffer-local mapping isolation, draft window number/fold-column isolation, annotation jumps and recreated splits, and active Markview rendering (13 extmarks). Review receipt, snapshot/report hashes, and lock release were verified. Whitespace checks and Stow dry-run passed; existing directory symlink exposes new files without re-stowing.

Manual terminal appearance and keyboard ergonomics remain pending. Open a fresh plan review; no Pi extension reload or NixOS activation is needed.
