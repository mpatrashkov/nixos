---
title: "Fix Pi and tmux navigation keys after Shift+Enter changes"
status: testing
priority: high
tags: [pi, tmux, kitty, keyboard, nixos, dotfiles]
created: 2026-10-19
updated: 2026-10-19
---

## Problem

After commit `51c1831` enabled Kitty keyboard protocol via tmux's `Eneks`
capability, arrows, Home and End stopped working in Pi and tmux session navigation.

## Fix

- Remove the outer-terminal Kitty protocol override and the forced `extkeys`
  feature from `nixos-modules/programs/tmux.nix`.
- Keep application-requested extended-key forwarding with CSI-u output.
- Map only Shift+Enter to `CSI 13;2u` in the stow-managed Kitty configuration.

Tmux 3.7c's `tty_keys_extended_key` parser supports the basic CSI-u and xterm
extended-key encodings, not the full Kitty keyboard protocol.

## Verification

Pending interactive verification after applying: reload Kitty configuration,
then detach and reattach tmux (preferably from a fresh Kitty window to clear old
keyboard protocol state). Check arrows, Home/End, tmux's session picker, Enter,
and Shift+Enter in Pi. Reloading tmux configuration alone does not remove old
server options or refresh an attached client's terminal capabilities.
