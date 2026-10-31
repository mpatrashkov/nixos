---
title: "Set up a chess engine for post-game analysis"
status: idea
priority: medium
tags: [chess, analysis, games, nixos]
created: 2026-11-01
updated: 2026-11-01
---

## Goal

Install a local chess engine and suitable review interface to analyze completed games and improve chess skills. No live online-match assistance or account integration is requested.

## Initial direction

Recommend Stockfish plus a graphical PGN analysis application. Confirm the user's preferred interface before finalizing the implementation plan. Investigate availability in the pinned Nixpkgs before committing to an application.

## Workflow

Prepare a plan for Neovim review. After explicit implementation approval, create a new JJ child change, preserving the current unrelated Neovim work. Keep planning/idea artifacts with the chess change where practical. NixOS testing, switching, and publication require separate approval.
