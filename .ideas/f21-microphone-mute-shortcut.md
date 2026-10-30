---
title: "F21 Microphone Mute Shortcut"
status: abandoned
priority: medium
tags: [audio, keybindings, desktop, gnome, pipewire]
created: 2026-10-30
updated: 2026-10-30
---

Bind F21 globally in GNOME to toggle the default microphone's mute state.

## Plan

1. Extend the existing standalone XKB patch to map FK21 to F21 instead of XF86TouchpadToggle. Update the related comments to include F21; preserve the F22–F24 audio output shortcuts and avoid a GNOME-wide rebuild.
2. Declare the native GNOME media-key setting `mic-mute = [ "F21" ];` in `nixos-modules/services/gnome/default.nix`, using the existing dconf configuration. Prefer native microphone mute handling and its OSD over a custom script. Check whether the existing dedicated microphone-mute key needs to be preserved explicitly.
3. Review the diff and validate the configuration without activating it.
4. Ask whether to switch, test, or do nothing before running any deployment wrapper.
5. After approved activation, refresh the GNOME session if needed for the XKB change. Verify repeated presses toggle the default input mute state, work with application focus, show GNOME feedback, and leave F22–F24 intact. This targets the default microphone, not every input device or application-specific mute state.

## Resolution

User remapped the key to F20, which already maps to `XF86AudioMicMute` and uses GNOME's existing native mute action. Reverted all F21 configuration changes before deployment; no activation was performed.
