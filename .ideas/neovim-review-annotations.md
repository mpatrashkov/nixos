---
title: "Neovim review annotations for Pi plans and JJ diffs"
status: testing
priority: medium
tags: [pi, neovim, planning, jj, review, annotations]
created: 2026-10-30
updated: 2026-10-30
---

Add annotations available only in dedicated review contexts: plans opened from Pi and code diffs opened through `jj review` / jjui. Reuse a shared Neovim interaction while preserving read-only source snapshots and explicit plan approval.

Related: [existing plan review](improve-neovim-plan-review.md), [JJ diff viewer](explore-jj-diffs-in-neovim.md).

User chose Markdown report handoff for JJ reviews and persistent local annotations. Plan proposes shared selection-based comments, exact-snapshot anchors, private local storage, and explicit Pi plan-feedback submission without granting implementation approval.

Implementation plan: [neovim-review-annotations](../.plans/neovim-review-annotations.md), explicitly approved and implemented. Manual interactive verification remains pending; no activation/publication authorized or performed.

## Implementation

- Shared `review_annotations/{store,ui,init,jj}.lua` modules provide review-only line/range comments, multiline drafting, visible markers, list/jump/edit/delete, and Markdown reports.
- Private local state under Neovim's state directory persists per canonical target/workspace and exact snapshot/comparison fingerprint. Raw-byte hashes, versioned/validated anchors, atomic writes, exclusive writer locks, and deliberate stale-lock recovery prevent silent reattachment/overwrite.
- Pi passes bounded session metadata via the environment and validates the clean editor result/report. Explicit feedback triggers plan revision only; pending stops; approval is available only without comments and remains hash-bound. Unfinished drafts, missing/bad results, and changed plans withhold feedback/approval.
- JJ uses documented hunk mount hooks and a small pinned-viewer adapter for before/after anchors and cross-file navigation. Reports are handed to Pi manually; no changes to jjui routing or JJ config were necessary.
- Updated both review guides and the plan-review skill. Existing Stow nvim package re-stowed; no dependencies or NixOS changes.

## Validation

Temporary checks only (no retained test suite):

- Headless store/UI: raw binary-safe hashes, exact-snapshot isolation, multiline/Unicode comments, normal/visual line selection, edit/delete/cancel, marker creation, read-only sources, save/reload, restrictive permissions, concurrent lock refusal, corrupt data refusal, and simulated disk failure with draft retained for retry.
- Full-config Pi-to-Neovim round trips: explicit feedback versus pending/approval, approval blocked while comments remain, unchanged-content persistence, changed-plan guard, no-comment feedback refusal, unfinished draft rejection, missing/malformed result rejection, BOM/CRLF plans, and actual command/tool continuation behavior.
- Strict TypeScript checking against installed Pi 1.1.0 types and actual extension-loader registration passed.
- Actual `jj review` in a disposable repository and pseudo-terminal: both sides, added/deleted/modified files, absent-pane rejection, quoted/Unicode filenames, file switching/list jumps, persistence despite new temporary directories, historical revisions and merges, source hash preservation, viewer q callback, and report survival after comparison cleanup.
- Ordinary full-config Neovim has no annotation mappings or ReviewHelp command. Stow link resolves to the repository. `git diff --check` passed.

Still verify manually: rendered Markdown/source selection, scratch-window feel, Pi TUI handoff and feedback loop, jjui Ctrl-o return/focus, and report sharing. Restart review editors and `/reload` Pi first.
