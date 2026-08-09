# Configuration Tooling: No Home Manager

**Home Manager is deprecated in this repo. Do not use it.** When you need to manage user-level files, dotfiles, or per-user configuration, choose between:

1. **NixOS configuration** (preferred for system-integrated config) — declare files, services, and packages via NixOS modules under `nixos-modules/`. Use `environment.etc`, system-level services, `users.users.<name>.packages`, or activation scripts as appropriate.
2. **Stow** (preferred for plain dotfiles in `$HOME`) — place dotfiles in the stow directory structure and let GNU Stow symlink them into place.

Do **not** introduce `home-manager`, `home.file`, `programs.<x>.enable` under a `home-manager` namespace, or any `home.nix` / `homeConfigurations` entries. If you find yourself reaching for Home Manager to solve a problem, stop and pick NixOS config or stow instead. If neither fits cleanly, ask before proceeding.

---

# NixOS Configuration Workflow

Whenever you implement a NixOS configuration change that I have requested, you MUST stop and use the user interaction tool to ask me how to proceed.
**CRITICAL**: You must provide a short `header` for the question that is 12 characters or less (e.g., `header: "NixOS Action"`).

Present the following options:

1. **Apply the change (switch)**: This will stage the changes, prompt for a commit message, commit, push, and apply the configuration.
2. **Verify the configuration (test)**: This will stage the changes and test the configuration without applying it permanently.
3. **Do nothing**

Both options run autonomously via the Bash tool. Passwordless sudo for `nh` is configured for user `miro` in `nixos-modules/services/users.nix`, and `--bypass-root-check` is required because `nh` otherwise refuses to run as root. Stream output back to me.

**Command reference (do not confuse these):**
- `./scripts/nix-test` — stages changes and tests the config without making it permanent (`nh os test`)
- `./scripts/nix-switch "<msg>"` — stages, commits, pushes, and applies the config permanently (`nh os switch`)

* If I select "Apply the change (switch)", immediately ask me for the commit message using a text input prompt. **CRITICAL**: Use a short `header` (max 12 chars), e.g., `header: "Git Commit"`. Once provided, run:
  `./scripts/nix-switch "<commit_message>"`
  Run the command exactly as shown — no output redirection.
* If I select "Verify the configuration (test)", run:
  `./scripts/nix-test`
  Run the command exactly as shown — no output redirection (no `2>&1 | tail -N` or similar). The raw output must be streamed directly to the Bash tool output so the user can see it in full.
