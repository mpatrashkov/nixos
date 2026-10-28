---
name: jujutsu
description: Use Jujutsu (jj) to inspect changes, describe and organize commits, work with bookmarks and Git remotes, resolve conflicts, and recover operations. Load for JJ tasks and before version-control mutations in a JJ checkout.
---

# Jujutsu workflow

## Inspect before acting

1. Read the repository's AGENTS.md and check `jj --version`. These examples are verified against JJ 0.45.1; consult `jj <command> --help` when behavior differs.
2. Check `jj status`, `jj log`, `jj diff`, and `jj bookmark list`. Inspection normally snapshots the working copy: use `jj --ignore-working-copy ...` when a truly non-snapshotting view is required, acknowledging that it can be stale.
3. Preserve unrelated work. Do not initialize/migrate a repository, move publishing bookmarks, push, abandon changes, restore files, rebase published work, or undo operations without user authorization.

## Mental model

- `@` is a real, mutable working-copy commit. There is no Git-style staging step.
- `jj describe -m "description"` names the current change; it does not create an empty child.
- `jj new` starts an empty child. `jj commit -m "description"` describes the current change and starts a child.
- A change ID persists across rewrites; a commit ID identifies an exact snapshot. Use full commit IDs for build provenance. After `jj new`, the intended build source is often `@-`, not `@`; select it explicitly, never guess.
- Bookmarks do not generally advance just because files changed. Move only the intended bookmark, and inspect before publishing.
- Colocated repositories retain Git for interoperability. Avoid Git `add`, `commit`, `reset`, `checkout`, and Git-writing GUIs while JJ owns the working copy unless following a deliberate interoperability procedure.

## Common operations

Read-only/snapshotting inspection:

```bash
jj status
jj log
jj diff
jj show <revision>
jj bookmark list
jj op log
```

With authorization for the requested mutation:

```bash
jj describe -m "Explain the change"
jj new
jj split
jj squash --from <source> --into <destination>
jj rebase -r <revision> -d <destination>
```

Review diffs and graph after each operation. For split/squash/rebase, verify the installed command's options and avoid unintentionally including unrelated paths or descendants. Do not use `--ignore-immutable` as an automatic fix.

## Remotes and publishing

1. Inspect `jj git remote list` and `jj bookmark list`; do not assume a branch name or remote.
2. With authorization, fetch using `jj git fetch --remote <remote>`, then inspect divergence and conflicts. Do not automatically rebase or force a push.
3. For an approved fast-forward publication, move the chosen bookmark with `jj bookmark set <name> -r <exact-commit-id>`, inspect `jj git push --remote <remote> --bookmark exact:<name> --dry-run`, then perform the approved push without `--dry-run`.
4. Never use `--all`, `--allow-backwards`, `--allow-conflicts`, or broad generated bookmarks as a shortcut. JJ push uses lease-like safety checks; this is not permission to rewrite published history.

For this NixOS flake, use its rebuild skill and wrappers rather than manually reproducing the publish/build sequence.

## Conflicts and recovery

- Use `jj status` and `jj resolve --list`; inspect conflicted files before editing or using `jj resolve` with a configured merge tool.
- Recheck the diff and conflict status after resolving. Do not push conflicted commits.
- Before destructive recovery, capture the relevant operation IDs with `jj op log` and explain the impact. `jj undo` reverses the latest operation; `jj op restore <operation-id>` restores broader repository state. Neither is an automatic response to an error, and neither reverses an already published remote change.
- `jj restore --from <revision> <paths>` overwrites content: use only for explicitly approved paths after reviewing the current diff.

## Installation and configuration

Use NixOS for the executable and Stow for personal configuration. Never track credentials or machine-local trust/session data. Use `jj config path --user` to locate configuration and `jj config get user.name` / `user.email` to check identity. Do not copy another repository's identity or publishing defaults without verification.
