---
title: "Install pi coding agent 1.1.0"
status: testing
priority: medium
tags: [ai, packages, nixos]
created: 2026-10-09
updated: 2026-10-09
---

Add the pi coding agent (`pi`) v1.1.0 to the system by overriding the nixpkgs
`pi-coding-agent` derivation (1.0.3 in the current lock) with v1.1.0 sources.

## Hypothesis

The nixpkgs 1.0.3 build recipe still works for 1.1.0 with only hash bumps:
the runtime workspace dependency set of `packages/coding-agent` is unchanged
(new workspaces `durable`, `env`, `server`, `evals` are dev-only / not runtime
deps of coding-agent).

## Results

(Populated by agents or manually as findings come in)
