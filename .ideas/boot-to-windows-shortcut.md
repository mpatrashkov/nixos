---
title: "Boot directly to Windows via shortcut"
status: idea
priority: low
tags: [desktop, bootloader, windows, shortcuts]
created: 2026-08-09
updated: 2026-08-09
---

A command, keyboard shortcut, or `.desktop` entry that reboots the machine and boots directly into Windows without having to interact with the bootloader menu.

## Approach

The mechanism depends on the bootloader in use:

- **systemd-boot**: `systemctl reboot --boot-loader-entry=<windows-entry>` sets a one-time boot entry via the EFI variable `LoaderEntryOneShot`. List available entries with `bootctl list`.
- **GRUB**: `grub-reboot <entry-index-or-title>` sets `GRUB_DEFAULT` for the next boot only, then reboot normally. Entry names can be found with `grub-editenv list` or by inspecting `/boot/grub/grub.cfg`.
- **rEFInd**: Supports EFI `OsIndicationsSupported`; one-shot boot can be set with `efibootmgr --bootnext <entry>` and then rebooting.

Implementation options once bootloader is confirmed:
1. A shell script/alias (e.g. `reboot-windows`) wrapping the appropriate command.
2. A `.desktop` file placed in applications so it appears in the launcher.
3. A keyboard shortcut bound to the script via GNOME custom shortcuts.
