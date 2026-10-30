---
title: "Investigate Blur my Shell panel flashing during app switching"
status: in_progress
priority: medium
tags: [gnome, blur, rendering, regression]
created: 2026-10-30
updated: 2026-10-30
---

The user reports the bottom half of the top bar briefly flashing with the desktop background during application switching. Do not change live settings or activate NixOS configuration during diagnosis without approval.

## Findings (2026-10-30)

- Active extension is system-installed Blur my Shell v76 on GNOME Shell 50.4. Multi-monitor Panel v1.3 is also active.
- Both active monitors use fractional scaling of approximately 166.7%, confirmed through Mutter DisplayConfig's logical monitor state.
- Effective panel settings: dynamic blur (`static-blur=false`), Liquid Glass/refraction pipeline with radius 30 and tint 0.85, `override-background=true`, `override-background-dynamically=false`, `unblur-in-overview=true`, dark styling, no rounded corners or gradient.
- Installed `render/backdrop/capture.js` still uses the old floor/ceil damage-rectangle conversion. It lacks the fractional-scale inset in upstream PR #1170.
- Upstream v77 was released 2026-10-29 and includes PR #1170, which fixes backdrop-capture partial-redraw flicker at fractional scaling, as well as popup fade behavior. The shared capture fix is relevant to the dynamic panel backend, but its original report concerns popups: this is a strong lead, not proof of this specific panel symptom.
- The panel's overview handling explicitly hides its blur on overview entry when `unblur-in-overview=true`. If switching applications via overview causes the issue, test that toggle independently after the rendering fix.
- Multi-monitor Panel is a possible interaction, not a confirmed cause. Isolate it only if upgrading or a panel-only static-blur comparison does not explain the symptom.
- No recent journal entries naming Blur my Shell. Separate GNOME date-menu/calendar errors (`this._settings is null`, `layout is null`) were observed; no causal connection to panel flicker established.
- The older half-transparent-panel report #882 concerned startup geometry/wrong monitor width and is described upstream as fixed in v76. It is not an exact match for transient bottom-half flashing while switching applications.

## Recommended next steps

1. User confirmed both Alt+Tab and overview switching trigger the flicker, and only the primary monitor is affected. Overview-unblur alone therefore cannot explain all occurrences.
2. Prepare an update from v76 to v77, preserving current pipeline settings, and use the approved NixOS test workflow before permanent activation. A new GNOME session may be necessary to load new extension code.
3. If still reproducible, perform reversible single-variable live comparisons with explicit approval: panel static blur; overview-unblur toggle (for overview-only symptoms); popup blur off (for Alt+Tab-only symptoms); Multi-monitor Panel disabled. Save and restore prior settings. Static blur deliberately samples wallpaper rather than live windows.

Sources:
- https://github.com/aunetx/blur-my-shell/pull/1170
- https://github.com/aunetx/blur-my-shell/releases/tag/v77
- https://github.com/aunetx/blur-my-shell/issues/882
- https://github.com/aunetx/blur-my-shell/issues/1156 (styling/overview contrast, not a confirmed render fault)

## v77 update prepared (2026-10-30)

- User requested trying v77 after confirming the primary-monitor-only symptom with both switching methods.
- Updated only the extension version, release URL/name, and fixed-output source hash in `nixos-modules/services/gnome/extensions/blur-my-shell.nix`; pipeline and visual settings are unchanged. No flake inputs updated.
- The generic GitHub package scanner returned no updates because it does not identify this release-archive override; the explicitly requested v77 release was verified directly through GitHub.
- Prefetched v77, confirmed metadata version 77 and the fractional-scale inset in its shared capture code. The extension package builds successfully, desktop toplevel evaluation passes, and formatting/whitespace checks pass.
- No live settings or activation changed. Await the NixOS Action choice, then verify loaded version in a fresh GNOME session and reproduce both switching paths on the primary monitor.
