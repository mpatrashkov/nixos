---
title: "Restore GNOME themes through Stylix Home Manager integration"
status: done
priority: high
tags: [gnome, icons, stylix, nixos, regression]
created: 2026-10-30
updated: 2026-10-30
---

## Regression

After switching to opt-in profiles and disabling the deprecated Home Manager feature, the user noticed changed GNOME icons.

## Confirmed findings

- Live `org.gnome.desktop.interface icon-theme` remains `Hatter-Yaru`.
- The current system's `sw/share/icons` does not contain Hatter themes, and `/etc/profiles/per-user/miro/share/icons` no longer exists.
- The previous system (`test-Install-jjui-4910121126b7`) includes all Hatter variants in `etc/profiles/per-user/miro/share/icons`.
- The pinned Stylix NixOS GNOME module installs the cursor package and supplies the icon package through GDM's environment, but does not install the icon package in the system profile for user sessions. Its comment explicitly notes user icon settings are normally handled through Home Manager.
- Comparing `environment.systemPackages` during the refactor missed the removed per-user theme assets and Home Manager-generated settings.
- GTK remains configured to use `adw-gtk3`, which also appeared in the removed closure during activation. Audit GTK/Qt/shell assets and settings when migrating the theming, not only icons.

## Revised approach

The user requested an explicit Home Manager exception for Stylix theming. `AGENTS.md` now documents permission for the Home Manager NixOS integration, minimal user configuration, and Stylix-managed theme assets/settings. General dotfiles, packages, programs, and services remain managed through NixOS or Stow.

Restore the Stylix Home Manager integration under that narrow exception, checking for conflicting ownership of theme files and dconf settings. Audit icon, GTK/Qt, cursor, font, and shell theming rather than only installing Hatter. Preserve unrelated working-copy changes and request NixOS Action approval before activation.

## Implementation and validation

- The desktop profile selects the existing minimal Home Manager feature with `mkDefault true`; WSL leaves it disabled. The existing Home Manager input and user state version were retained, with no input updates.
- Stylix's Home Manager targets are explicitly limited to GNOME, GTK, Qt, and fontconfig. `stylix.autoEnable = false` prevents automatic configuration of Stow-managed applications.
- GNOME wallpaper-image management is disabled for Stylix; wallpaper-daemon remains responsible for wallpaper selection.
- Evaluation confirms `Hatter-Yaru` and its package, `adw-gtk3`, the User Themes extension, Bibata cursors, and Qt/Kvantum packages are included in the user's Home Manager configuration.
- Existing GTK/Qt settings files point to the old Home Manager generation; no matching Stow-owned theme files were found. No existing files were overwritten during implementation.
- Both desktop and WSL toplevel derivations evaluate, and formatting/whitespace checks pass. No test files were added.
- Updated `docs/nixos-modules.md` to describe the narrow exception. No activation or publication has occurred; request the NixOS Action choice before deployment.
