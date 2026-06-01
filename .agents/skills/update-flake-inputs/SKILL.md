---
name: update-flake-inputs
description: Safely updates Nix flake inputs, identifies broken configurations, autonomously attempts to fix them, and asks for confirmation before committing and applying.
---

# Skill: Update Flake Inputs

## Workflow

Whenever the user asks to update flake inputs (e.g., "update my flake", "bump flake inputs"), you MUST follow this sequence:

1. **Record the current GNOME Shell version:** Before updating, run `gnome-shell --version` and note the major version number (e.g., `50`).
2. **Update and Verify Build:** Run `./scripts/nix-update-test` to update the flake inputs and test the configuration simultaneously.
3. **Fix Broken Config (if needed):** If `./scripts/nix-update-test` fails, autonomously investigate the error, modify the configuration files to fix the breakages, and re-run `./scripts/nix-test` until it passes.
4. **Check for GNOME version bump:** After a successful build, determine the new GNOME Shell version from the updated nixpkgs by running:
   ```bash
   nix eval --raw 'nixpkgs#gnome-shell.version'
   ```
   Compare the major version to the one recorded in step 1. If the major version changed, proceed to step 5; otherwise skip to step 6.
5. **Update custom-packaged GNOME extensions:** All custom-packaged extensions live in `nixos-modules/services/gnome/extensions/*.nix`. For each extension file:
   a. Read the file and identify the upstream GitHub repo (`owner`/`repo` in `fetchFromGitHub`).
   b. Fetch the latest commit on the default branch and check its `metadata.json` for `shell-version` support.
   c. If the latest upstream commit adds support for the new GNOME major version, update `rev` and `hash` to point to that commit.
   d. If upstream still does **not** list the new GNOME version in `shell-version`, keep (or add) a `jq` patch in `installPhase` that appends the new version string to `metadata.json`'s `shell-version` array (see `multi-monitors.nix` for an example).
   e. After updating all extension files, re-run `./scripts/nix-test` to verify the build still passes.
6. **Ask for Approval:** Once the build passes, prompt the user to ask if they want to proceed with committing the changes. Use the user interaction tool to present multiple-choice options.
   **CRITICAL**: You must provide a short `header` for the question that is 12 characters or less (e.g., `header: "Flake Update"`).
   Present the following options:
   - **Apply (Switch)**: Prompt for a commit message (using a text prompt with `header: "Git Commit"`), then run `./scripts/nix-update-switch "<commit_message>"` to stage, commit, push, and apply the configuration.
   - **Revert**: Discard all changes by running the rollback script located at `scripts/rollback-test-changes.ts`.
