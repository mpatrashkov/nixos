---
title: "Disable Slack autostart on login"
status: testing
priority: medium
tags: [slack, desktop, autostart, dotfiles]
created: 2026-11-19
updated: 2026-11-19
---

Prevent Slack from opening automatically after logout/login while preserving manual launch.

## Findings

- Slack's stored `launchOnStartup` setting is already false.
- No Slack entry was found in the active XDG autostart directories or generated user services.
- Installed and verified a Stow-managed `~/.config/autostart/slack.desktop` with `Hidden=true` to explicitly suppress standard desktop autostart. This does not block launches triggered by browser links or another session-restoration mechanism.
- Stow dry-run and installation passed; the live symlink resolves to the repository file. Awaiting logout/login verification.
