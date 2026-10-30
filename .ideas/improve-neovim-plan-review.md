---
title: "Improve Neovim plan review with annotations"
status: testing
priority: medium
tags: [ai, pi, planning, neovim, markdown]
created: 2026-10-30
updated: 2026-10-30
---

Improve reading agent plans in Neovim and support annotations that return to the agent for iterative revision.

## Chosen first version

The user selected Markview and a Pi integration, without annotations initially.

- Added/pinned Markview in the shared Neovim Stow package and configured Markdown parsers, preview toggle, and split-preview mappings.
- Full rendering exposed an existing Neovim 0.12 incompatibility with Treesitter's legacy master branch (`set-lang-from-info-string!` receives capture arrays). Migrated to the current main API, retained parser languages and highlighting/indentation, and declared the required `tree-sitter` CLI in the NixOS Neovim module. NixOS activation is pending approval.
- Added a shared Pi `plan-review` skill for opt-in plan-first work. This is an instruction workflow, not a security sandbox; specialized repository workflows take precedence.
- Added `review_plan` and `/review-plan <path>` for explicit review of a read-only temporary snapshot. Pi's UI suspends while Neovim runs and resumes afterward.
- Opening is optional. Closing the editor is never approval. Implementation requires a separate explicit choice; changed plans withhold approval. Pending tool results stop automatic follow-up for feedback in chat.
- No annotations or automatic publishing/deployment. NixOS activation approval remains separate.
- Browser alternative: existing [Plannotator idea](install-plannotator-for-pi.md).

## Validation

- Actual read-only Markdown rendering (including fenced code blocks) passed in headless Neovim, with Markview attached and nonzero rendering extmarks.
- Refreshed all twelve configured parsers using the already-present Nix-store tree-sitter CLI with a temporary PATH. No system activation or persistent PATH modification. Evaluated the configured CLI version: 0.26.11.
- Fourteen automated review tests passed during implementation. The automated review suite and headless rendering check were subsequently removed at the user's request; no test files are retained.
- Strict TypeScript checking against the installed Pi 1.1.0 API and actual Pi extension loading pass.
- Stow links installed for Neovim and Pi. Interactive appearance and terminal round-trip await user verification after `/reload`.

Usage and implementation boundaries: [docs/pi-plan-review.md](../docs/pi-plan-review.md).

## Annotation follow-up (2026-10-30)

Implemented the approved [shared review-annotations plan](../.plans/neovim-review-annotations.md), tracked in [its own idea](neovim-review-annotations.md). The first-version notes above describe the pre-annotation baseline.

- Review-only line/range comments, multiline scratch editing, range markers, list/jump/edit/delete, and local Markdown reports.
- Private local persistence keyed to exact snapshots, with atomic writes and exclusive-session locks; no fuzzy reattachment to revised plans.
- Pi explicitly distinguishes pending, feedback-for-revision, and implementation approval. Saving/closing never submits; saved comments offer feedback rather than approval. Changed plans and unfinished drafts withhold both actions.
- The same UI supports JJ's read-only before/after review, with manual report handoff to Pi rather than cross-session routing.
- Temporary headless/full-config and actual Pi-loader checks passed, including feedback/approval continuation boundaries. Manual interactive appearance/key verification remains pending. No retained test suite, NixOS activation, publication, or history mutation.
