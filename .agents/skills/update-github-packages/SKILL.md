---
name: update-github-packages
description: Safely updates GitHub-sourced packages in the NixOS configuration, identifies broken configurations, autonomously attempts to fix them, and asks for confirmation before committing and applying.
---

# Skill: update-github-packages

Updates custom GitHub-sourced packages in the NixOS configuration.

## Workflow

1. Run `./scripts/update-github-packages-check.ts` and parse the JSON from stdout.
   Progress messages go to stderr; the JSON array goes to stdout.
   Each entry contains: `owner`, `repo`, `file`, `currentRev`, `latestRev`, `currentHash`, `hashType`, `newHash`.

2. If the JSON array is empty, tell the user all packages are up to date and stop.

3. Use the interaction tool if available, otherwise plain chat, to ask which packages to update. Wait for the answer.
   Label each option as `"owner/repo  (currentRev → latestRev)"`.

4. For each selected package, read the specified `file` and update the package to `latestRev`
   with the new hash `newHash`. Use your judgement to make the correct edits.

5. Inspect the diff (`jj diff` in an initialized JJ checkout, otherwise `git diff`).

6. Load `.agents/skills/nixos-rebuild/SKILL.md` and follow AGENTS.md's NixOS Action approval workflow. Test does not imply permission to switch.
