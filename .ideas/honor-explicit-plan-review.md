---
title: "Honor explicit plan-review requests across specialized skills"
status: testing
priority: high
tags: [pi, planning, skills, neovim, dotfiles]
created: 2026-11-01
updated: 2026-11-01
---

Explicit `/skill:plan-review` requests can be bypassed because the planning skill yields to specialized workflows and the dotfiles/GNOME skills unconditionally bypass planning. Make explicit planning requests authoritative for task sequencing, while retaining specialized implementation rules and separate deployment approvals.

Investigation and approved plan: [.plans/honor-explicit-plan-review.md](../.plans/honor-explicit-plan-review.md). Neovim review explicitly approved SHA-256 `ac93e6a0d5c6c80ed5662cb829a1cad7148690e07dfc0dc1e618e5cd8ca44e17`; reread and verified before implementation.

## Implementation and validation

- Updated the shared planning skill, dotfiles skill, and GNOME capture skill, including their advertised descriptions. Explicit planning now controls when implementation starts; specialized skills still control implementation after approval. Ordinary tasks without an explicit planning request retain their direct workflows.
- Added the precedence rule to `AGENTS.md`, updated `docs/pi-plan-review.md`, and appended a superseding note to the original planning idea. Approval/feedback/pending handling and separate deployment approvals are unchanged; no runtime extension or Neovim changes were made for this fix.
- Scoped diff review and `git diff --check` passed. Audited active skills/documentation for unconditional planning bypasses; the historical precedence statement remains with a dated superseding note.
- Simple frontmatter structure/name checks passed for all three changed skills; descriptions are 196, 271, and 246 characters (below Pi's 1024-character limit). This was a structural check, not a full YAML-parser or Pi-loader test.
- Confirmed the active global planning skill resolves to the edited shared Stow source. No re-stow needed.
- Fresh-session interactive behavioral cases remain **pending manual validation**: explicit skill invocation for a tiny dotfile task, plain-language planning, GNOME capture planning, ordinary direct dotfile work, pending/cancel/error, submitted feedback, exact-plan approval, and “continue” while pending. Run the scenarios from the plan in an isolated scratch project with copied instructions, not against real user configuration. This tool-driven session cannot provide a separate human-operated interactive Pi session; no model subprocess or sample implementation was run, and static checks are not behavioral proof.
- Reload Pi and use a fresh session to avoid stale skill bodies/descriptions already present in the current transcript. Instruction compliance is not tool-level enforcement.
- Existing theme/Treesitter/lockfile/word-wrap and other idea changes were preserved. No commits, pushes, history mutations, rebuilds, or activation.
