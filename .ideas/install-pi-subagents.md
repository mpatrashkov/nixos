---
title: "Install Pi subagents extension"
status: planned
priority: medium
tags: [pi, ai, extensions, dotfiles]
created: 2026-11-05
updated: 2026-11-05
---

Install a Pi subagents extension in a new JJ change, following explicit plan-first / Neovim review before implementation.

## Initial findings

- Pi 1.1.0 is installed through NixOS; shared extensions are Stow-managed under `dotfiles/common/pi/.pi/agent/extensions/`.
- Personal `~/.pi/agent/settings.json` currently exists as an unmanaged regular file containing machine-local preferences and a device ID; do not blindly adopt it into shared dotfiles.
- npm `pi-subagents` (nicobailon/pi-subagents) latest is 0.85.0 and declares `@earendil-works/pi-ai >=1.2.0`, newer than the installed Pi release. Choose an appropriate compatible release or separately approve a Pi upgrade.
- Existing JJ change contains unrelated GNOME preview work. Preserve it and create the requested child only after plan approval.
- User selected upgrading Pi as well. Plan targets Pi 1.5.0 and pi-subagents 0.85.0; see `.plans/install-pi-subagents.md`. Activation/publication require a separate NixOS Action decision.
