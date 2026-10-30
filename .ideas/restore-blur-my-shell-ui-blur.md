---
title: "Restore Blur my Shell UI blur after v77 upgrade"
status: done
priority: high
tags: [gnome, blur, regression, nixos]
created: 2026-10-30
updated: 2026-10-30
---

## Read-only findings

- Installed Blur my Shell is v77, enabled but in ERROR state.
- Current-boot user journal reports `TypeError: can't access property "name", pipeline is undefined` in `pack_pipelines`, called by `update_from_old_settings` during extension enable.
- Effective settings report `settings-version=7` and the declared custom Liquid Glass pipeline. Surface blur switches are enabled as intended; application-window blur remains deliberately disabled.
- This is an extension startup/settings-migration failure, not merely weak blur or the previously tracked panel flicker. Exact migration cause remains unverified.

## Plan

1. Inspect installed v77 settings updater, pipeline serialization, and schemas; compare migration assumptions with effective settings and repository defaults. Check upstream reports/fixes if necessary.
2. Back up the extension's user dconf subtree and distinguish user overrides from system defaults. Do not reset the entire subtree or change the settings-version marker blindly.
3. Identify the smallest repair: targeted migration/settings correction if valid, otherwise a narrowly scoped upstream patch or version rollback. Preserve the custom Liquid Glass preset and existing per-surface choices.
4. Present the repair before modifying the live session. If NixOS changes are required, validate the package/configuration and request the standard NixOS Action choice before any test or switch. Live settings changes or extension reloads also require approval.
5. After approved repair, reload the extension or use a fresh GNOME session as appropriate. Verify ACTIVE state and absence of migration errors, then visually check panel, dock, popups, overview, app folders, and lock screen. Recheck primary-monitor flicker separately with Alt+Tab and overview switching.

No live settings or NixOS configuration were changed while preparing this plan.

## Initial patch approach (superseded, 2026-10-30)

- Confirmed root cause: v77's version-8 migration calls `Gio.Settings.get_default_value('pipelines')`, which includes administrator dconf defaults. Our default contains only `pipeline_default`, so the migration inserts undefined values for four missing stock presets and crashes while serializing them.
- The schema itself contains all five shipped presets. Patched the migration to use `gsettings.settings_schema.get_key('pipelines').get_default_value()` for the stock preset source. Effective/custom settings remain unchanged.
- Added `nixos-modules/services/gnome/extensions/blur-my-shell-schema-defaults.patch` and applied it through the existing package override, preserving inherited patches.
- Backed up user overrides and effective pipelines under `/tmp/blur-my-shell-backup-HW0XX3`. The only user override is `settings-version=7`; the Liquid Glass preset is inherited from system dconf defaults. This temporary backup does not survive cleanup/reboot reliably.
- An isolated GJS test with a memory settings backend reproduced the exact original error. The patched migration passed starting at settings versions 4 and 7, preserved the custom preset, added all four stock presets, and was idempotent. Version 8 and stock-default checks also passed. No real-session writes were made.
- Patched extension package build, desktop toplevel derivation evaluation, and Nix formatting checks passed. Evaluation reports existing xorg deprecation and gemini-cli removal warnings.
- This patch approach was not activated and was subsequently replaced by the user-selected configuration-only approach below.
- Unrelated working-copy changes exist in `.ideas/investigate-freeze-during-devenv-switch.md` and `.ideas/setup-project-devenv.md`; deployment wrappers include them in the source snapshot.

## Selected repair: declare settings version 8 (2026-10-30)

- User approved preparing option 2: keep the compatible custom pipeline and declare `settings-version = lib.gvariant.mkInt32 8` in the same unlocked dconf defaults. Removed the proposed patch and restored the original unpatched v77 package declaration.
- This intentionally skips only migrations through version 8. The four additional stock presets remain absent; the custom appearance and per-surface settings are unchanged. Future migrations still run when their settings version exceeds 8.
- An isolated memory-backend test using unpatched v77 confirmed version 8 skips migration, leaves the custom preset byte-for-byte unchanged, parses it successfully, and remains idempotent on repeated calls.
- Nix formatting and desktop toplevel derivation evaluation passed; existing xorg/gemini-cli warnings remain.
- Not activated. The existing user `settings-version=7` overrides the new default. After approved activation, request approval for a targeted reset of only `/org/gnome/shell/extensions/blur-my-shell/settings-version`, verify the effective value is 8, then reload the extension or start a fresh GNOME session. Do not reset while the old system default is still active.
- Live verification is still required: extension ACTIVE state, clean startup journal, visual blur on the configured surfaces, and the separate primary-monitor flicker checks.

## Investigation after user-run nix-test and GNOME relogin (2026-10-30)

- User reports running nix-test and logging back into GNOME; blur is still absent.
- Read-only checks confirm the test system is active (`/run/current-system` points to `nixos-system-nixos-test-configuration-f233a50296b0`) and the backend default is now 8.
- The saved user override is still 7, so the effective settings version remains 7. Relogging does not remove persistent dconf user overrides. The extension remains in ERROR with the same migration stack trace.
- No new configuration change or rebuild is needed for this blocker. The pending targeted reset of `/org/gnome/shell/extensions/blur-my-shell/settings-version` is still required; request explicit approval before performing it and reloading the extension. No live settings were changed during this investigation.

## Approved targeted reset (2026-10-30)

- User approved the reset after the request to reset the single setting and reload the extension.
- Reset only the settings-version key. Verified the user override is absent and the effective value is 8.
- Disabled and re-enabled Blur my Shell, but it remained in ERROR state in the existing GNOME session. No new extension errors appeared in the inspected recent user journal. Requested a fresh GNOME login to retry startup cleanly. No appearance settings were reset.
- User subsequently confirmed blur works. Recovery is visually confirmed by the user; the separate panel-flicker issue remains independent. The configuration was tested, not permanently switched through this conversation.
