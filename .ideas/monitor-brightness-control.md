---
title: "Monitor brightness control"
status: testing
priority: medium
tags: [gnome, monitors, brightness, ddc, nixos]
created: 2026-11-05
updated: 2026-11-05
---

## Goal

Explore convenient brightness control for the external monitors, then implement the selected approach in a new JJ change after explicit plan review.

## Read-only findings

- GNOME Wayland; connected displays identify as Dell U2723QE and Dell S2722QC.
- No devices under `/sys/class/backlight`; laptop-style brightness tools alone are not the appropriate hardware interface.
- `i2c-dev` is configured in `hosts/desktop/configuration.nix`, and user `miro` belongs to `i2c`, but current `/dev/i2c-*` nodes are root-only. Non-root DDC access needs appropriate NixOS-managed device permissions.
- Neither `ddcutil` nor `brightnessctl` is currently on PATH. Monitor DDC/CI support and transport have not been tested.
- Options: GNOME DDC brightness extension (verify GNOME 50 compatibility), standalone DDC GUI such as ddcui, or ddcutil plus custom shortcuts/presets. Software dimming is a fallback, not hardware brightness control, and must support GNOME Wayland.
- Existing GNOME preview work in `@` and tmux work in its child must be preserved. Do not create the requested JJ change until an exact implementation plan is approved.

## Selected direction

User selected a custom TypeScript GNOME extension with independent monitor controls in a new repository at `/home/miro/dev/gnome-monitor-brightness-control`, initialized as colocated JJ + Git. Use devenv conventions from their other repositories. Existing extension research is retained as context only. The exact implementation plan was approved and local implementation is complete; live UI/hardware validation remains pending.

## Extension research (2026-11-05)

Checked live extensions.gnome.org metadata, upstream READMEs, and released extension ZIP source in memory. These are advertised compatibility and source findings, not runtime verification.

- **Brightness control using ddcutil**, daitj: live v59 supports GNOME 50; pinned nixpkgs already provides v59 for 50 as `gnomeExtensions.brightness-control-using-ddcutil`. Released source builds named per-monitor sliders, calls `setvcp` with a specific bus, and supports either a panel menu or Quick Settings. Optional All slider can remain disabled. Direct ddcutil dependency; no extra daemon. Best first candidate. Upstream documents detection stalls on some hardware and dock/daisy-chain caveats. https://extensions.gnome.org/extension/2645/brightness-control-using-ddcutil/ ; https://github.com/daitj/gnome-display-brightness-ddcutil
- **Display Adjustment**: live v12 supports GNOME 46–51; pinned nixpkgs has v11 with 50 support as `gnomeExtensions.displays-adjustments`. Released code creates separate brightness and contrast Quick Settings sliders per display. Requires a session D-Bus `ddcutil-service`; pinned nixpkgs packages service v1.0.15, but its activation/integration must be checked. More integration work; upstream claims improved responsiveness over CLI invocation. https://extensions.gnome.org/extension/7308/displays-adjustments/ ; https://gitlab.com/w8jcik/display-adjustment
- **DDC Brightness Controller**, lucasoskorep: live v2 supports GNOME 50/51; pinned nixpkgs has v1 for 50 as `gnomeExtensions.ddc-brightness-controller`. Released code creates separate sliders in its own panel menu; linking can be disabled. README documents active-screen shortcuts; Quick Settings integration is a future feature. Direct ddcutil, newer/smaller track record. https://extensions.gnome.org/extension/10312/ddc-brightness-controller/ ; https://github.com/lucasoskorep/ddc-brightness-control
- **MonitorControl – Brightness and Volume**: live v3 supports GNOME 50 and matches pinned nixpkgs, despite README still claiming 45–49. Released code creates one shared brightness slider and applies writes across monitor buses. Does not meet the independent-slider requirement; also adds unrelated volume behavior. https://extensions.gnome.org/extension/9665/monitorcontrol-brightness-and-volume/
- Older **Control monitor brightness and volume with ddcutil** is only listed through GNOME 49 in pinned nixpkgs; **Monitor DDC Brightness/Contrast** only through 48. Not preferred for this GNOME 50 setup.

## Pending decisions

Implementation plan: `.plans/custom-monitor-brightness-extension.md`, approved SHA-256 `95cf06e0f9d80e954d46e1067f429a60e4133104d4dadffb9b6792ca4170f27b`. Implementation completed in the new repository's JJ change `qltyyoou` (`Develop per-monitor GNOME brightness extension`). `devenv test` passes with 24 unit tests, GJS fake-child subprocess timeout/cancellation tests, strict type checking, lint/format checks, and ZIP packaging. Output: `/home/miro/dev/gnome-monitor-brightness-control/dist/monitor-brightness-control@miro.local.shell-extension.zip`. Project details are recorded in `README.md` and `IMPLEMENTATION.md`. No runtime install/enable, real DDC command, host permission change, NixOS activation, or publication occurred. Initial custom scope: independent named Quick Settings brightness sliders using asynchronous ddcutil; no volume, contrast, or linked controls. Hardware DDC/CI access remains unverified. Live extension installation, hardware brightness writes, NixOS integration/test/switch, and publication require separate explicit permission. Do not create a brightness change in the flake repository.
