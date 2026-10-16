---
title: "Install pi coding agent 1.1.0"
status: testing
priority: medium
tags: [ai, packages, nixos]
created: 2026-10-09
updated: 2026-10-09
---

Install the pi coding agent harness (`pi`, github.com/earendil-works/pi, npm
`@earendil-works/pi-coding-agent`) at v1.1.0. The flake's nixpkgs ships 1.0.3.

## Approach

Override `pkgs.pi-coding-agent` in `nixos-modules/programs/ai.nix` with v1.1.0
src / npmDeps / modelData hashes. See `.experiments/install-pi-coding-agent/plan.md`.
