---
title: "Simplify review annotations in readable plain Lua"
status: testing
priority: medium
tags: [neovim, lua, pi, jj, review, annotations]
created: 2026-10-31
updated: 2026-10-31
---

User chose plain Lua instead of the TypeScript process or a Zig/native library. Replace the TypeScript rewrite in current annotation change `loqryumu`, preserving the separate shortcut-menu work. Remove the custom process/protocol bridge and its development dependencies. Prefer small focused functions, explicit control flow, and whitespace between logical sections.

Keep existing keys, exact-snapshot/version-1 persistence and reports, read-only sources, and Pi feedback/approval safeguards. Preserve actual user annotations. Use disposable checks only and delete all validation artifacts afterward.

Related: [annotations](neovim-review-annotations.md), [superseded TypeScript rewrite](rewrite-review-annotations-in-typescript.md).

## Implementation

- Direct, synchronous Lua calls replace the TypeScript backend and custom stdio transport. Removed all backend TypeScript files, transport code, Node-specific dev dependencies, and the targeted type-check command. Root package/lock files match the parent change again.
- Focused modules separate private file/hash/lock operations, snapshots and UTF-8 validation, persistence, deterministic reports, scratch drafts, UI actions, and review/JJ lifecycle. Small named functions, guard clauses, and whitespace separate logical operations; UI callbacks no longer contain backend state machines.
- Existing keys, saved IDs, version-1 manifests/identity directories/report bytes, read-only panes, and Pi's explicit feedback/approval boundary remain compatible. Failed saves retain editable drafts. Locks retain their descriptor until release and are removed only when ownership matches. Finalization failure or unfinished drafts withhold Pi's receipt.
- Hashing uses the existing binary-safe coreutils command; the annotation component needs no Node, Zig, build, custom worker, or IPC. Snapshot scans and disk operations can briefly block Neovim on large comparisons.
- Updated both review guides. Work stays in `loqryumu`, renamed **Simplify review annotations in Lua**. Shortcut-menu source, publishing bookmarks, NixOS configuration, and actual user review state were untouched.

## Validation

- Captured disposable version-1 fixtures from the TypeScript implementation before removing it; plain Lua matched manifest order, hashes, identity directories, IDs, and exact report bytes, including supplementary-plane Unicode filenames, binary data, symlinks, and missing final newline.
- Headless store/UI checks passed for normal/visual selection, multiline Unicode comments, markers, edit/delete/cancel, save/reload, corrupt-state refusal, invalid UTF-8 rejection, lock contention and ownership changes, disk failure with draft retry, and JSON-authoritative report-write failure. The checks also passed with Node absent from PATH.
- Full-config Pi/Neovim and actual extension command/tool checks passed for pending/feedback/approval continuation, comments blocking approval, changed-plan guard, missing receipts, unfinished drafts, and BOM/CRLF plans.
- Actual configured `jj review` passed through a pseudo-terminal in a disposable repository: both sides, additions/deletions/modifications, absent-pane rejection, quote/Unicode filenames, navigation, reopen persistence, historical revisions, merges, unchanged working hashes, normal q return, and report survival after comparison cleanup.
- Ordinary editing has no review mappings/commands. Stow links resolve to the shared package. Frozen pnpm installation and whitespace checks passed.
- Deleted all temporary validation scripts, copied reference implementation, fixtures, repositories, and generated state afterward. No test suite or test tooling was retained; actual user plan annotations/reports were preserved.

Manual appearance/focus confirmation remains pending in fresh review editors.
