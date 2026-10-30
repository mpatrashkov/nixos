---
title: "Neovim review annotations for Pi plans and JJ diffs"
status: testing
priority: medium
tags: [pi, neovim, planning, jj, review, annotations]
created: 2026-10-30
updated: 2026-10-31
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

## TypeScript backend rewrite (2026-10-31)

The user successfully used annotations to request a revision of the rewrite plan and approved its revised version. Implemented that approved [TypeScript rewrite](rewrite-review-annotations-in-typescript.md) in dedicated JJ change `loqryumu`, separate from the shortcut-menu work.

During the TypeScript iteration, `review-annotations/*.ts` ran behind native Lua UI/stdio adapters, replacing `store.lua`. Node 24+ is required on PATH (provided by devenv); there are no runtime npm dependencies or compilation step. Version-1 identities, saved annotations and report bytes remain compatible. Asynchronous saves preserved drafts on failure or newer edits, and only clean, acknowledged finalization could publish Pi's receipt. Existing keys and explicit feedback/approval behavior are unchanged.

Parity, backend/transport failure handling, actual Pi/Neovim interaction, and actual JJ historical/merge reviews passed with disposable data. All temporary validation scripts/tests and fixtures were deleted; no retained test suite. At that stage, strict type-checking was available as `pnpm check:review-annotations` (removed by the Lua simplification below). Fresh-editor manual appearance/focus confirmation was still pending. No NixOS change or publication.

## Simplified plain Lua implementation (2026-10-31)

The user subsequently chose [plain Lua with readable, small functions](simplify-review-annotations-in-lua.md). This supersedes the TypeScript runtime above. The current code uses direct calls between focused filesystem, snapshot, storage/report, draft, UI, and review-lifecycle modules. The custom stdio/process bridge, TypeScript files, dev dependencies, and type-check command are removed. Pi's extension stays TypeScript, but the Neovim annotations have no Node/build requirement.

Version-1 identities, saved annotations/IDs, report bytes, mappings, read-only sources, and explicit feedback/approval behavior remain compatible. Synchronous saves keep drafts on failure; clean finalization closes the owned lock before emitting Pi's receipt. A coreutils hash command preserves binary-safe SHA-256. Temporary compatibility, UI, actual Pi, and actual JJ historical/merge checks passed and were deleted afterward. Interactive appearance/focus confirmation remains pending; no NixOS activation or publication.

## Annotation draft focus (2026-10-31)

At the user's request, newly opened annotation windows now enter Insert mode automatically, for both adding and editing comments in Pi and JJ reviews. Existing save/cancel behavior is unchanged. A disposable headless Neovim check verified Insert mode, immediate typing, Ctrl-s save, draft closure, and return to Normal mode. No test files or generated review state were retained.
