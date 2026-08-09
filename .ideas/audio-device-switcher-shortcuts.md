---
title: "Audio Device Switcher Shortcuts"
status: idea
priority: medium
tags: [audio, keybindings, desktop, gnome, pipewire]
created: 2026-08-09
updated: 2026-08-09
---

Assign a dedicated global keyboard shortcut to each audio output device so that switching between them is instant, without opening any UI.

## Approach

1. Enumerate all audio output devices (e.g. headphones, speakers, HDMI) and assign each a shortcut key.
2. Write a small script (e.g. using `pactl` or `wpctl`) that sets the default sink by name/id when invoked.
3. Register the shortcuts system-wide — via GNOME custom keybindings (`org.gnome.settings-daemon.plugins.media-keys.custom-keybindings`) declared in NixOS config.
4. Optionally show a brief OSD notification on switch (e.g. via `notify-send`).
