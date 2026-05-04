---
name: update-flake-inputs
description: Safely updates Nix flake inputs, identifies broken configurations, autonomously attempts to fix them, and asks for confirmation before committing and applying.
---

# Skill: Update Flake Inputs

## Workflow

Whenever the user asks to update flake inputs (e.g., "update my flake", "bump flake inputs"), you MUST follow this sequence:

1. **Update and Verify Build:** Run `./scripts/nix-update-test` to update the flake inputs and test the configuration simultaneously.
2. **Fix Broken Config (if needed):** If `./scripts/nix-update-test` fails, autonomously investigate the error, modify the configuration files to fix the breakages, and re-run `./scripts/nix-test` until it passes.
3. **Ask for Approval:** Once the build passes, prompt the user to ask if they want to proceed with committing the changes. Use the user interaction tool to present multiple-choice options.
   **CRITICAL**: You must provide a short `header` for the question that is 12 characters or less (e.g., `header: "Flake Update"`).
   Present the following options:
   - **Apply (Switch)**: Prompt for a commit message (using a text prompt with `header: "Git Commit"`), then run `./scripts/nix-update-switch "<commit_message>"` to stage, commit, push, and apply the configuration.
   - **Revert**: Discard all changes by running the rollback script located at `scripts/rollback-test-changes.ts`.
