---
title: "Install Pi subagents extension"
status: testing
priority: medium
tags: [pi, ai, extensions, dotfiles]
created: 2026-11-05
updated: 2026-11-05
---

Install a Pi subagents extension in a new JJ change, following explicit plan-first / Neovim review before implementation.

## Initial findings

- Pi 1.1.0 is installed through NixOS; shared extensions are Stow-managed under `dotfiles/common/pi/.pi/agent/extensions/`.
- Personal `~/.pi/agent/settings.json` currently exists as an unmanaged regular file containing machine-local preferences and a device ID; do not blindly adopt it into shared dotfiles.
- npm `pi-subagents` (nicobailon/pi-subagents) latest is 0.85.0 and declares `@earendil-works/pi-ai >=1.2.0`, newer than the installed Pi release. Choose an appropriate compatible release or separately approve a Pi upgrade.
- Existing JJ change contains unrelated GNOME preview work. Preserve it and create the requested child only after plan approval.
- User selected upgrading Pi as well. Approved plan targets Pi 1.5.0 and pi-subagents 0.85.0; see `.plans/install-pi-subagents.md`. Activation/publication require a separate NixOS Action decision.

## Implementation and validation

- New JJ child `kzuwrxll` contains the Pi upgrade, `scripts/pi-install-subagents`, and `docs/pi-subagents.md`.
- Pi 1.5.0 builds successfully with verified npm/model-data hashes. Updated runtime workspace copies for the unbundled SDK; retained the inherited offline build and clipboard wrapper.
- Verified version/help, SDK imports (`createAgentSession`, `DefaultResourceLoader`, `SessionManager`), and existing plan-review registration with no extension load errors.
- Full NixOS derivation evaluation, Nix formatting checks, Bash syntax, version rejection/acceptance and exact pinned install arguments passed. Only `pi-src` changed in `flake.lock`.
- User selected NixOS test. `./scripts/nix-test` succeeded for source `ede2331b7f200e667f7e2fe6183cc63f1cf17222`, label `test-Upgrade-Pi-and-install-subagents-ede2331b7f20`. Active Pi reports 1.5.0 and no systemd units are failed. Nothing published or made the boot default.
- Installed `npm:pi-subagents@0.85.0` using the helper. Verified exactly one pinned declaration and that every previous settings value was preserved.
- Offline loading in a fresh Node process using the packaged Pi SDK registered `review_plan`, `subagent`, `bg_wait`, and `subagents_enable`, plus `/subagents-doctor`, with no extension load errors. No model calls or background work started.
- Test closure comparison also removed `tmux-open-link` from the previously active configuration; this is inherited configuration drift, not a Pi input/package edit.
- Pending: interactive fresh-Pi `/subagents-doctor` and user-triggered foreground delegation. Background execution remains untested. Because this was a test activation, a reboot can restore the previous Pi runtime; the personal package declaration persists and requires Pi >=1.2.0.
