---
name: manage-dotfiles
description: Manages stow-based dotfiles in ./dotfiles/. Handles adding files to existing packages, creating new packages, removing packages, adopting files from $HOME, and editing tracked files. Bypasses Planning Mode — this skill is the workflow.
---

# Skill: Manage Dotfiles (Stow)

This skill is the workflow for any task that touches `./dotfiles/`. Do NOT invoke Planning Mode — follow this skill instead.

The repo uses GNU Stow to symlink files into `$HOME`. Dotfiles are organized into **tiers**: a shared `common` tier plus one tier per machine. The active machine tier is named by the untracked `.host` file at the repo root. Within a tier, each subdirectory is a **package** whose internal tree mirrors `$HOME`.

```
dotfiles/common/opencode/.config/opencode/opencode.jsonc
                        └────────┬──────────────────────┘
                                 expands to ~/.config/opencode/opencode.jsonc
```

## Constants

- **Dotfiles dir:** `./dotfiles` (relative to repo root)
- **Tiers:** `dotfiles/common/` (shared across all machines) and `dotfiles/<host>/` (host-specific, e.g. `dotfiles/macbook/`, `dotfiles/nixos/`).
- **Active host:** read from the untracked file `./.host` at repo root (contains a single profile name, e.g. `macbook` or `nixos`). The scripts **error with setup instructions if `.host` is missing** — they never guess or auto-create it.
- **Stow target:** `$HOME`
- **Helper scripts (run from repo root):** each reads `.host`, then applies the package from every tier that contains it (`common` first, then the active host tier).
  - `./scripts/stow-add <pkg>` — stow or re-stow a package (idempotent, uses `--restow`)
  - `./scripts/stow-remove <pkg>` — unstow a package's symlinks from `$HOME`
  - `./scripts/stow-adopt <pkg>` — pull existing `$HOME` files into the repo, replacing them with symlinks
  - `./scripts/stow-check <pkg>` — dry-run (`--no --verbose=2 --restow`) to preview symlinks and surface conflicts
  - `./scripts/_stow-lib.sh` — shared helper sourced by the four scripts (resolves repo root, reads/validates `.host`, computes which tiers contain the package). Not run directly.

All scripts take only `<pkg>` — the host comes from `.host`, not an argument. They resolve the repo root from their own location and reject missing/invalid package names. Prefer these wrappers over raw `stow` — if behavior needs to change, edit the script, not the skill.

## Tier model

- A package may live in `common`, in a host tier, or both. The scripts operate on whichever tiers contain it.
- **Single-tier-per-file rule:** any given `$HOME` path must be owned by exactly one tier. If the same relative file exists in both `common/<pkg>` and `<host>/<pkg>`, stow reports a conflict. To make a file host-specific, remove it from `common/<pkg>` and place the per-host variants in each host tier's copy of the package.
- Default new files/packages to `common` unless they are genuinely host-specific.

## Git policy

This skill **never** runs `git add`, `git commit`, or `git push`. Read-only git commands (`git status`, `git diff`) are fine for reporting. The user handles commits manually.

## NixOS policy

This skill **never** invokes `./scripts/nix-switch` or `./scripts/nix-test`. Dotfiles live outside the NixOS rebuild path.

## Workflow dispatcher

Identify which of the five operations the user wants. If unclear, ask via the user interaction tool (`header: "Dotfile Op"`) with these options:

- Edit existing tracked file
- Add new file to existing package
- Create new package
- Remove file or package
- Adopt existing $HOME file

Then jump to the matching section.

---

## Op A — Edit existing tracked file

The file in `$HOME` is already a symlink into the repo, so editing through either path is equivalent. Always edit the **in-repo** source so the change is tracked by git.

1. Resolve the in-repo path. If the user gave the `$HOME` path, run `readlink -f <path>` to find the repo target (it will be under `dotfiles/<tier>/<pkg>/...`), or infer from the convention.
2. Edit the in-repo file with the Edit tool.
3. No stow command is needed — the symlink already exists.

---

## Op B — Add new file to existing package

1. Identify the package and the tier it lives in. If the file should be host-specific rather than shared, decide the tier (ask the user with `header: "Which tier"` when ambiguous; default to `common`).
2. Create the file under `dotfiles/<tier>/<pkg>/<relative-path-from-$HOME>/...` using the Write tool.
3. Run `./scripts/stow-add <pkg>` via Bash (workdir = repo root).
4. Verify: `ls -la <expected-$HOME-path>` and confirm the arrow target starts with `<repo_root>/dotfiles/common/` or `<repo_root>/dotfiles/<host>/`. Show the output to the user.

---

## Op C — Create new package

1. If the package name isn't obvious, ask the user (`header: "Pkg Name"`, text input).
2. Choose the tier: `common` by default, or a host tier if host-specific (ask with `header: "Which tier"` when ambiguous).
3. Create the mirrored subtree: `mkdir -p dotfiles/<tier>/<pkg>/<dir>` and Write initial file(s).
4. Run `./scripts/stow-check <pkg>` first (dry-run). If it reports conflicts (existing real files in `$HOME` blocking the symlink), STOP and ask the user (`header: "Conflict"`):
   - **Adopt** — switch to Op E (adopt) to absorb the `$HOME` files into the repo
   - **Abort** — leave everything as-is
   - **Manual** — user will resolve conflicts by hand; re-invoke skill after
5. On a clean dry-run, run `./scripts/stow-add <pkg>`.
6. Verify each created symlink with `ls -la`.

---

## Op D — Remove file or package

### Whole package

1. Run `./scripts/stow-remove <pkg>` to delete the symlinks from `$HOME` (across all tiers that contain it).
2. Ask the user (`header: "Delete Src"`):
   - **Keep source** (default) — leave `dotfiles/<tier>/<pkg>/` in place
   - **Delete source** — `rm -rf dotfiles/<tier>/<pkg>` (for each tier that has it)
3. Verify the `$HOME` paths no longer exist (or are no longer symlinks into the repo) with `ls -la`.

### Single file from a package

1. Delete the in-repo file: `rm dotfiles/<tier>/<pkg>/<path>`.
2. Run `./scripts/stow-add <pkg>` — `--restow` first unstows then re-stows, which prunes the now-orphaned `$HOME` symlink.
3. Verify with `ls -la $HOME/<path>` that the symlink is gone.

---

## Op E — Adopt existing $HOME file

`stow --adopt` replaces a real file in `$HOME` with a symlink into the package, **overwriting** the in-repo copy with the `$HOME` contents. The safe sequence:

1. Ensure the destination package exists in the intended tier. If not, create it: `mkdir -p dotfiles/<tier>/<pkg>/<dir>`.
2. Pre-seed the in-repo path with a copy of the live file so adopt has a placeholder:
   ```
   cp -a "$HOME/<dir>/<file>" "dotfiles/<tier>/<pkg>/<dir>/<file>"
   ```
3. Run `./scripts/stow-adopt <pkg>`. This converts `$HOME/<dir>/<file>` into a symlink into the repo.
4. Verify with `ls -la $HOME/<dir>/<file>` — must be a symlink pointing under `<repo_root>/dotfiles/common/` or `<repo_root>/dotfiles/<host>/`.
5. Run `git status dotfiles/` and `git diff dotfiles/` and show the output so the user can review what got pulled in.

---

## Verification rule (applies to all stow ops)

After every script that mutates symlinks (`stow-add`, `stow-remove`, `stow-adopt`), run `ls -la` on the affected `$HOME` paths and show the output. The symlink target MUST start with `<repo_root>/dotfiles/common/` or `<repo_root>/dotfiles/<host>/` (where `<repo_root>` is the actual resolved repo root — it differs per machine, e.g. `/home/miro/flake` on the NixOS host). If it doesn't, stop and report — something went wrong.

## What this skill never does

- Never edits files under `~` directly — always edits the in-repo source.
- Never runs git mutations (`add`, `commit`, `push`, `reset`, `restore`).
- Never invokes NixOS rebuild scripts.
- Never calls raw `stow` — always goes through `./scripts/stow-*`.
- Never creates or overwrites `.host` — if it's missing, the scripts instruct the user to create it.
