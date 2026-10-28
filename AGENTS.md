# Configuration Tooling: No Home Manager

**Home Manager is deprecated in this repo. Do not use it.** When you need to manage user-level files, dotfiles, or per-user configuration, choose between:

1. **NixOS configuration** (preferred for system-integrated config) — declare files, services, and packages via NixOS modules under `nixos-modules/`. Use `environment.etc`, system-level services, `users.users.<name>.packages`, or activation scripts as appropriate.
2. **Stow** (preferred for plain dotfiles in `$HOME`) — place dotfiles in the stow directory structure and let GNU Stow symlink them into place.

Do **not** introduce `home-manager`, `home.file`, `programs.<x>.enable` under a `home-manager` namespace, or any `home.nix` / `homeConfigurations` entries. If you find yourself reaching for Home Manager to solve a problem, stop and pick NixOS config or stow instead. If neither fits cleanly, ask before proceeding.

---

# NixOS Configuration Workflow

Whenever you implement a requested NixOS configuration change, stop before activation and ask how to proceed. Use the user interaction tool if available, otherwise ask in plain chat and wait for an explicit answer. Implementation approval is not activation approval.

Use a short question header (12 characters or less), e.g. **NixOS Action**, and present:

1. **Apply the change (switch)**: collect a change description, finalize the source snapshot, push, and apply permanently.
2. **Verify the configuration (test)**: snapshot and test without publishing or making it the boot default.
3. **Do nothing**

After switch is selected, ask separately for the description with a short header such as **Commit Msg**, then run exactly:

`./scripts/nix-switch "<description>"`

After test is selected, run exactly:

`./scripts/nix-test`

Use Bash with no output redirection or truncation. Passwordless sudo for `nh` is configured in `nixos-modules/services/users.nix`; wrappers retain `--bypass-root-check`. Report failures and never automatically switch after a test.

## Source control and generation labels

- Load `.agents/skills/nixos-rebuild/SKILL.md` for rebuild work and the global `jujutsu` skill for JJ operations.
- Installing JJ does not migrate this repository. Until `.jj` is explicitly initialized, wrappers use Git. Once colocated JJ is initialized, wrappers use JJ; do not mix Git index-based mutations into that workflow.
- Git switch stages/commits and pushes. Git test uses a temporary index and unpublished commit, preserving the real index and branch. Both include all nonignored work; inspect and report unrelated changes before deployment.
- JJ switch finalizes the intended nonempty `@`, advances only the configured publishing bookmark without backwards moves, pushes it, then creates an empty child. JJ test snapshots `@` without publishing. Never guess `@-` when the current change is empty.
- Configure `nixos.publish-bookmark` and `nixos.publish-remote` with `jj config set --repo` only during an approved migration after checking branch/upstream/remotes. The current Git branch is `main` and remote is `origin`, but verify before use.
- Rebuilds export the exact captured commit into a temporary source tree. Generated `.nixos-generation.json` metadata belongs only there, never in a commit. Labels use sanitized descriptions and immutable commit IDs, with `test-` on tests; Limine's `Generation N` titles and hover descriptions remain unchanged.
- Ordinary wrappers do not update inputs. Use `nix-update-test` or `nix-update-switch` only when input updates were requested. They update the lockfile **before** snapshotting, so the label identifies the updated source. To test/switch an already-reviewed update, use ordinary wrappers rather than updating again.
- Do not initialize JJ, rewrite published history, move publishing bookmarks, push, or activate as an unapproved side effect of editing skills/dotfiles.

---

# Idea & Experiment Tracking

Two directories at the repo root track improvement ideas and active experiments:

- **`.ideas/`** — one markdown file per idea (`<slug>.md`)
- **`.experiments/`** — one subdirectory per experiment (`<slug>/idea.md` + supporting files)

Both use the same frontmatter schema:

```yaml
---
title: ""
status: idea        # idea | planned | in_progress | testing | done | abandoned
priority: medium    # high | medium | low
tags: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

**Status pipeline:** `idea → planned → in_progress → testing → done / abandoned`

Slug naming: kebab-case derived from the title (e.g. `Add ZRAM Swap` → `add-zram-swap`).

Templates: `.ideas/_template.md` and `.experiments/_template/idea.md`.

## Agent Responsibilities

1. **Read for context** — Before starting any task, glob `.ideas/*.md` and `.experiments/*/idea.md`, filter by matching tags or keywords in the title, and read relevant files to inform your approach.

2. **File new ideas** — When the user mentions something worth tracking (a new improvement, a future task, an experiment idea) and no file exists for it yet, immediately create `.ideas/<slug>.md` with appropriate frontmatter. Use today's date for `created` and `updated`. Set `status: idea` unless the user specifies otherwise.

3. **Update status** — When an idea moves through the pipeline (e.g. you start implementing it, finish it, or it is abandoned), update the `status` and `updated` fields in its frontmatter in-place.

4. **Add findings to experiments** — When working inside an experiment, append notes, results, and observations to `.experiments/<slug>/findings.md` (create it if absent). Place code artifacts (patches, config snippets) as separate files in the same folder.
