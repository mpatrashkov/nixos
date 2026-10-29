---
title: "Global Pi code style skill"
status: done
priority: medium
tags: [pi, ai, dotfiles, code-style]
created: 2026-10-20
updated: 2026-10-20
---

Add a global, Stow-managed Pi skill that favors readable code: multiline control
flow, whitespace between logical blocks, and simple expressions rather than
compressed one-liners.

## Implementation

- Source: `dotfiles/common/pi/.pi/agent/skills/code-style/SKILL.md`.
- Global location: `~/.pi/agent/skills/code-style/SKILL.md`.
- Available on demand for coding tasks or explicitly with `/skill:code-style`.
- Stow dry-run passed; installed and verified the global symlink.
