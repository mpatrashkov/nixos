---
name: update-flake-inputs
description: Update Nix flake inputs, investigate breakages and GNOME extension compatibility, and request explicit approval before testing or switching the configuration.
---

# Update flake inputs

Follow AGENTS.md and load `.agents/skills/nixos-rebuild/SKILL.md`. Use the interaction tool if available, otherwise ask in plain chat. Do not activate a test or switch without approval.

1. Inspect repository status and preserve unrelated changes. Record `gnome-shell --version` before updating.
2. Run `nix flake update` when the user requested input updates. This edits the lockfile but does not activate anything.
3. Inspect the resulting diff. Read the updated pinned nixpkgs version of GNOME Shell, not a potentially unrelated global flake registry entry. For this repo:

   ```bash
   nix eval --impure --raw --expr '(builtins.getFlake (toString /home/miro/flake)).inputs.nixpkgs.legacyPackages.x86_64-linux.gnome-shell.version'
   ```

4. If the GNOME major version changed, inspect custom extensions in `nixos-modules/services/gnome/extensions/*.nix`. Check upstream `metadata.json` support and prefer an upstream compatible revision. If none exists, explain the compatibility risk before adding/changing any `shell-version` patch; metadata alone does not prove runtime compatibility.
5. Evaluate/build without activation where practical. Investigate failures without automatically widening scope or discarding changes.
6. Present **NixOS Action**: switch, test, or do nothing. Use ordinary `./scripts/nix-test` / `./scripts/nix-switch "<description>"` for this already-updated lockfile. Ask separately for the description after switch is selected. Stream raw output.
7. A successful test is not approval to switch. Report the outcome and ask again before permanent activation. Never automatically discard changes or invoke a rollback script as recovery.

The `nix-update-*` wrappers are an alternative when the user has explicitly approved updating and deploying together. They update the lockfile before snapshotting; do not repeat them merely to publish already-reviewed updates.
