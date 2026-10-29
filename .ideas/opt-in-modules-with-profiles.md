---
title: "Replace desktopOnly with opt-in modules and profiles"
status: done
priority: medium
tags: [nix, nixos, modules, profiles, multi-host]
created: 2026-10-29
updated: 2026-10-29
---

## Goal

Every `myNixOS` leaf module and profile defaults to disabled. Hosts explicitly enable a small set of profiles, which enable related modules with `lib.mkDefault true`. Remove the `desktopOnly` classification and `myNixOS.desktop.enable` entirely.

This applies to our custom module switches, not every upstream NixOS option.

## Proposed structure

Add `nixos-modules/profiles/` and expose `myNixOS.profiles.<name>.enable`, using the existing module-discovery/wrapping mechanism with false defaults.

Start with these profiles, refining membership after auditing each leaf module:

- `base`: shared user, locale, shell, essential CLI tools, Nix tooling, Stow, and generation metadata.
- `development`: editors, development tools, Git/JJ, AI tools, tmux, and related developer utilities.
- `desktop`: GNOME, audio, fonts, theme, terminal, desktop integration, and ordinary graphical applications.
- `gaming`: Steam and the existing games module.
- `dns`: the existing AdGuard Home and dnscrypt-proxy2 stack.

Keep machine-specific boot, networking, Keychron, and YeetMouse modules explicit in the desktop host rather than hiding hardware assumptions inside the desktop profile. Keep SMB disabled.

Profiles should be additive and mostly flat; hosts select their combination explicitly. Do not introduce automatic activation based on host name, platform, or another broad boolean. Use `mkDefault` for profile selections so a normal host-level `enable = false` overrides a profile without `mkForce`.

## Implementation plan

1. Record the currently enabled custom modules and relevant effective configuration for both `nixos` and `wsl`. Audit module dependencies and unconditional imports before changing defaults.
2. Change the generated service/program/feature switches to false defaults, preferably using `lib.mkEnableOption`. Remove `desktopOnly`, `defaultEnable`, and the old desktop option. Add profile discovery with the same false-default behavior; avoid a new custom framework.
3. Implement the profiles with explicit, readable membership. Cover all currently enabled modules intentionally; do not enable every discovered module automatically.
4. Extract `github-desktop` from `programs/git.nix` into its own opt-in program module and enable it through the desktop profile. Git/JJ should no longer inspect a desktop flag.
5. Update host selections:
   - Desktop: base, development, desktop, gaming, and DNS profiles, plus explicit machine-specific modules. Preserve the existing SMB opt-out.
   - WSL: base and development profiles, plus the existing explicit terminal and fonts opt-ins. Preserve WSLg and font settings.
6. Audit the legacy Home Manager feature. It still imports Home Manager despite the older removal idea being marked done. Do not include it in any profile or introduce new Home Manager usage. Report this deliberate deviation from the current implicit defaults; track complete legacy removal separately.
7. Validate both host evaluations, compare enabled-module inventories and important effective settings against the baseline, and explain any intentional differences. Check that no old desktop switch references remain, that no profile means no custom modules enabled, and that a host can disable a module selected by a profile using ordinary `false`. Account for `tools.extendModule` importing dependencies unconditionally: a disabled wrapper must not be mistaken for an import-free module.
8. Present the diff and request the repository's NixOS Action choice before any test activation, switch, commit, or push. Do not update flake inputs as part of this refactor.

## Scope

Implementation approved. Keep existing host-specific system configuration in place; reorganizing all direct host settings is a separate task. Preserve behavior except for explicitly excluding deprecated Home Manager functionality, leaving the empty specialisations placeholder disabled, and fixing configuration that leaked from disabled modules.

## Implementation and validation

- Added five independent profiles with explicit `mkDefault` selections. All leaf/profile switches now use `mkEnableOption` and default to false.
- Kept boot, networking, Keychron, and YeetMouse selections in the desktop host. WSL explicitly keeps terminal, fonts, and its previously enabled Slack module.
- Extracted GitHub Desktop into its own opt-in module.
- Connected the imported nix-index-database module's enabled-by-default switch to our custom switch.
- Gated the imported Blur My Shell fragment on GNOME's switch. It previously installed a GNOME extension and dconf settings even on WSL. WSL now drops the leaked `gnome-shell-extension-blur-my-shell` and `dconf` system packages; desktop packages are unchanged.
- Before/after inventories show all existing program/service selections and sampled effective settings unchanged on both hosts. The only changed feature selections are Home Manager and the empty specialisations placeholder, both intentionally off.
- Added `docs/nixos-modules.md`. All 13 evaluation-only regression checks passed during implementation; the test file was subsequently removed at the user's request.
- Both host toplevel derivations evaluate successfully. Existing evaluation warnings concern deprecated `xorg.xhost` and `gemini-cli`; no input updates were made.
- No test activation, switch, publication, or explicit source-control finalization performed. Await the NixOS Action choice.
