---
title: "Rewrite review annotation logic in TypeScript"
status: abandoned
priority: medium
tags: [pi, neovim, typescript, review, annotations]
created: 2026-10-31
updated: 2026-10-31
---

Move the review annotation backend from Lua to TypeScript, retaining a thin Lua adapter for native Neovim interaction. Preserve local annotations, Markdown reports, Pi approval/feedback boundaries, and JJ review behavior. Use the implementation plan itself to exercise the existing annotation feedback workflow.

Related: [review annotations](neovim-review-annotations.md).

Plan: [rewrite-review-annotations-in-typescript](../.plans/rewrite-review-annotations-in-typescript.md). Approved plan version `6bfa540c3bdb00099403608897226439025f0fb3fa9f0a78c24e792947ce80e7`. Implementation requested in dedicated JJ change `loqryumu`, leaving the shortcut-menu change separate. No deployment/publication authorized.

## Superseded by plain Lua

After trying the TypeScript rewrite, the user chose [readable plain Lua](simplify-review-annotations-in-lua.md) to remove the process/protocol overhead. The TypeScript implementation, Lua transport, development dependencies, and type-check command below have been removed from the current change. The historical implementation/validation record is retained here; it no longer describes the active runtime. No publication or NixOS activation occurred.

## Historical implementation

- Moved snapshot identity/scanning, raw-byte hashing, validated annotation operations, locking/private atomic storage, and deterministic Markdown reports to `dotfiles/common/nvim/.config/nvim/review-annotations/*.ts`.
- Node 24+ runs the TypeScript directly using built-in modules. The backend has no runtime npm dependencies, build step, Neovim Node provider, or network service. A standalone copied backend runs outside the repository without its `node_modules`.
- Native Lua retains editor UI, hunk navigation, bounded/versioned chunked stdio transport, and clean-exit receipt publication. The Lua store was removed; TypeScript is the sole annotation writer.
- Saves are serialized and acknowledged after persistence. Failed saves retain drafts; newer edits made during an in-flight save remain unsaved. Pane generations/changed ticks guard delayed replies. Unsupported panes are identified before attempting to serialize their contents.
- Finalization drains requests, rejects unfinished drafts, finalizes the report, releases the owned lock, and reaps the child before publishing Pi's unchanged version-1 receipt. Failures withhold approval/feedback; the backend never writes a late receipt independently.
- Preserved all mappings, local JJ report handoff, version-1 stores, snapshot identities, report paths/output, and Pi's independent feedback/approval checks. No Pi extension API changes were necessary.
- Added strict/no-emit `pnpm check:review-annotations` with development-only TypeScript/Node declarations in the existing root manifest/lockfile. Frozen installation passes; no test command, runner, test dependencies, or retained tests were added.
- Re-stowed nvim and updated both review guides. No NixOS changes, deployment, push, bookmark move, or shortcut-menu source edits.

## Validation and cleanup

- Compared the original Lua implementation with TypeScript using disposable fixtures: exact JSON array serialization, UTF-8 bytewise filename ordering (including supplementary-plane characters), manifests/fingerprints, identity directories, raw binary hashes, and report bytes matched. Copied version-1 stores reopened and edited without losing IDs or creating new directories.
- Checked standalone runtime, fragmented/coalesced/multiframe messages, protocol/size limits, invalid operations/ranges/comments, corrupt/symlink state refusal, invalid UTF-8, lock contention, permissions, JSON-authoritative report-write failure, and EOF lock cleanup.
- Full-config Neovim checks passed for normal/visual selection, multiline Unicode drafts, edit/delete/cancel, markers, reports, read-only source hashes, reopen persistence, BOM/CRLF plans, 200-KiB multiframe passages, simulated disk failure/retry, and edits made before save acknowledgment.
- Actual Pi extension loading and command/tool checks passed: pending terminates, explicit feedback permits revision only, comments block approval, changed plans withhold approval/feedback, and missing receipts, unfinished drafts, and backend crashes cannot authorize implementation.
- Actual configured `jj review` passed in a disposable repository and pseudo-terminal: before/after navigation, added/deleted/modified files, absent-pane rejection, quote/Unicode filenames, persistence across fresh comparison paths, historical revisions, merges, unchanged working files, q callback, and report survival after snapshot cleanup.
- Missing Node, malformed replies, shortened-deadline timeout, and owned-child reaping checks passed. Ordinary Neovim has neither review mappings nor a running backend.
- Strict type-checking, frozen pnpm installation, and whitespace checks pass. Temporary validation scripts/tests, legacy fixtures, copied backend, disposable repositories/state, and earlier annotation-test artifacts were deleted. Actual user plan annotations/reports were preserved.

Manual confirmation of the rewritten backend remains pending: start fresh review editors, `/reload` Pi if needed, try the feedback/revision loop and jjui Ctrl-o, and verify appearance/focus. The user successfully exercised feedback and fresh approval using the pre-rewrite implementation while reviewing this plan.
