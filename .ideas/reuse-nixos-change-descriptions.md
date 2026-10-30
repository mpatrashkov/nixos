---
title: "Reuse or infer NixOS change descriptions without prompting"
status: done
priority: medium
tags: [nixos, skills, tooling, generations, jj]
created: 2026-10-30
updated: 2026-10-30
---

## Request

Do not ask for a switch description when the current change already has one. If it is undescribed, infer and set an accurate change name automatically.

## Implementation

- Updated AGENTS.md, the nixos-rebuild skill, the GNOME capture skill, and the active devenv rollout plan to remove the separate description prompt.
- Prefer an explicitly user-supplied description; otherwise reuse the intended current change's existing description. Infer a concise description from the reviewed diff only when it is missing.
- Pass the selected description to the approved switch wrapper, which sets it during finalization. Do not create an extra commit or describe operation just to name the change.
- Preserve explicit activation approval, current-change checks, unrelated-work review, and all publication safeguards. Do not borrow an unrelated parent/HEAD description.
- The current JJ change already has the description `setup devenv`. No publication or activation was performed as part of editing these instructions.
