---
name: nixos-rebuild
description: Test or switch this NixOS flake with its approved rebuild wrappers, Git or colocated JJ snapshots, safe generation descriptions, and explicit deployment confirmation. Load after NixOS changes or for rebuild/deployment requests.
---

# NixOS rebuild

Read and follow the repository's AGENTS.md: it is the authoritative approval policy. If no user-interaction tool is available, ask the same question in chat and wait. Never treat implementation approval as activation approval.

## Before deployment

- Inspect the diff, repository status, and validation results. Report unrelated changes: wrappers include all nonignored work in the selected snapshot.
- In a colocated JJ checkout, load the `jujutsu` skill. Verify the intended change is `@`, nonempty for switch, and non-conflicted. Do not automatically select `@-` when `@` is empty.
- JJ switch requires repository settings `nixos.publish-bookmark` and `nixos.publish-remote`; inspect them and bookmark tracking. Configure them only as part of an approved migration, not by guessing.
- The repo uses Git until `.jj` is explicitly initialized. Installing JJ alone does not change publishing behavior.

## Approval and commands

Present **NixOS Action**: apply/switch, verify/test, or do nothing. For switch, ask for the change description separately (**Commit Msg**), then invoke exactly:

```bash
./scripts/nix-switch "<description>"
```

For test, invoke exactly:

```bash
./scripts/nix-test
```

Do not redirect or truncate output. Do not automatically switch after a test. Failures require a report, not automatic rollback or history manipulation.

Only use `nix-update-test` / `nix-update-switch` when input updates were requested. These update `flake.lock` before the source snapshot is captured; ordinary wrappers never update inputs. Repeating an update wrapper updates inputs again, so use ordinary wrappers when verifying or publishing already-reviewed updates.

## What the wrappers guarantee

- Git switch stages/commits and pushes. Git test uses a temporary index and an unpublished snapshot without moving the branch or changing the real index.
- JJ test snapshots without publishing. JJ switch describes `@`, runs configured pre-commit checks, advances only the configured bookmark without backwards moves, pushes it, then starts a new working-copy change.
- Builds use an archive of the exact captured commit, not the subsequently changing checkout. Metadata is stamped only into that temporary archive.
- Labels use a sanitized description and a 12-character commit ID, prefixed `test-` for tests. The full commit ID is recorded as `system.configurationRevision`.
- Labels are capped at 80 ASCII characters and additionally bounded by the system-name-dependent Nix store-name limit. No Git hook, environment-variable impurity, or ignored local file is required for direct flake evaluation.
- Limine retains `Generation N` titles and displays the description on hover/selection. Do not patch its title rendering.

After deployment, report the outcome and printed source/label. A failed push stops activation; a failed build after a successful push does not undo the remote publication.
