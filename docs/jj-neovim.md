# Review JJ changes in Neovim

Use **jjui to browse history** and **Diffview.nvim to review changes** in a full,
project-rooted Neovim session. The current change's working pane is a real,
editable project file: normal LSP, search, and navigation work without custom
`gd` or hover routing. Existing local review annotations are retained.

## Launch

In jjui, select a change and press **Ctrl-o** (also available from file details).
It opens the whole change, not just the highlighted file. Restart jjui after
changing its configuration.

From a normal terminal:

```sh
jj review                  # Current working-copy change (@)
jj review -r <revision>    # One selected change
```

This launches a separate blocking Neovim instance, with your normal configuration
and the JJ workspace root as cwd. There is no embedded jjui terminal or editor
RPC bridge. JJ waits until Neovim exits.

### Current change: live project context

When the selected commit is `@`, Diffview compares its **explicit parent commit**
against your live working files. The right pane is an ordinary editable buffer.
Use normal LSP commands such as `gd`, `K`, and `gr`, Telescope file search and
grep, and normal editing. New working files are included.

Launch jjui from the project's normal toolchain environment (for example, your
usual devenv shell). Zig requires compatible Zig/ZLS executables on inherited
PATH; the configuration does not install global ZLS or activate environments
for you. Zig syntax highlighting uses the managed Tree-sitter parser and queries.
On first installation, wait for it to finish and reopen Zig buffers if needed.

### Historical changes: exact snapshots

For another single-parent change, Diffview compares explicit `parent..selected`
commit IDs. Both panes show historical content, not today's working files.
Historical buffers do **not** have live-project LSP. Use **gf** to open the
corresponding working file in the previous tab, or **Ctrl-w, gf** in a new tab,
then use normal LSP there. That file and its answers reflect the **current
project**, not the historical revision. Missing/deleted working files cannot
provide live-project context.

The launcher does not assume Git HEAD or the Git index represents JJ's parent.
It reads Git objects without changing HEAD, the index, or bookmarks.

## Standard Diffview keys

| Key | Action |
| --- | --- |
| `j` / `k` in the file panel | Move through entries |
| `Enter` in the file panel | Open selected diff |
| `Tab` / `Shift-Tab` | Next/previous file |
| `<leader>e` (Space, e) | Focus the file panel |
| `<leader>b` | Toggle the file panel |
| `]c` / `[c` in a diff pane | Native Neovim next/previous diff hunk |
| `Ctrl-w, w` | Switch windows/panes |
| `gf` | Open working file in the previous tab |
| `Ctrl-w, gf` | Open working file in a new tab |
| `g?` | Diffview's context-sensitive key help |
| `<leader>gdc` / `:DiffviewClose` | Close the diff tab, keep editing |
| `:qa` | Exit Neovim and return to jjui; normal unsaved-change checks apply |

Unlike the old hunk session, **q is not a special exit key in the diff panes**.
Use DiffviewClose to keep editing, or `:qa` to return to jjui. Draft/report windows
still have their own local q behavior.

Managed JJ sessions disable Diffview's staging/unstaging and destructive restore
bindings (`-`, `s`, `S`, `U`, `X` in the file panel and restore in file history).
Do not invoke Git staging commands manually in this JJ workflow. Ordinary
Diffview sessions outside `jj review` retain their existing configuration.

## Local review annotations

| Key / command | Action |
| --- | --- |
| `<leader>ra` in a matching diff pane | Comment on current line or visual selection |
| `<leader>rl` | List comments and jump to a matching snapshot passage |
| `<leader>re` / `<leader>rd` | Edit/delete a comment at the cursor |
| `<leader>rr` | Open the local Markdown report |
| `:ReviewList` / `:ReviewReport` | List/report, including after closing Diffview |
| `:ReviewHelp` | Annotation help and report location |

Comments use the same UI as [Pi plan reviews](pi-plan-review.md): a multiline
draft, **`:w`** or **Ctrl-s** to save, **q** in normal mode to cancel with an
edited-draft prompt. Escape leaves Insert mode. Draft/report q closes that
window, not the entire editor. Save failures retain the draft for retry.

### Captured content versus editable working files

Annotations belong to the **captured before/after comparison at launch**, not to
a moving working tree. Before attaching an anchor, the adapter verifies that the
pane matches its captured text. Absent, empty, binary, invalid-UTF-8, symlink, and
oversized (>16 MiB) sources cannot receive passage comments.

**Editing a live source invalidates its anchors for that buffer/session.** Markers
are cleared, passage operations and stale jumps are rejected, and a later pane
mount does not reset that guard (even after undo). Existing comments and report
quotes remain attached to their original content; nothing is silently reanchored.
Exit and relaunch `jj review` to capture the new comparison. Diffview refreshing
its file list does not refresh annotation identity.

Annotation passage actions require the managed diff pane, even if the same real
file buffer is open elsewhere. List/report commands remain useful outside it.
Closing Diffview removes source annotation mappings/markers; saved comments and
reports survive. A closed/stale source jump reports the limitation instead of
opening or annotating a different file. An unfinished draft is not discarded by
closing the diff tab.

`<leader>rr` / `:ReviewReport` opens a read-only generated report. Give its absolute
**report.md** path to Pi in ordinary chat when you want the comments acted on.
There is no automatic code edit, approval, or direct JJ-to-Pi connection.

Storage, private permissions, writer locks, error recovery, and manual retention
are described in [the plan-review guide](pi-plan-review.md#local-persistence-and-reports).
Comparison identity still uses the canonical workspace and the deterministic
before/after manifest of logical paths, kinds, and raw-byte hashes. Temporary paths
are excluded. Identical comparisons intentionally reuse annotations, including
existing hunk-created stores; the fingerprint is not a JJ commit ID.

## Legacy viewer and unsupported comparisons

```sh
jj review-legacy
jj review-legacy -r <revision>
```

The legacy hunk.nvim viewer preserves JJ's original directory comparison semantics
and existing annotation UI. Its panes are read-only snapshots; q exits the
legacy session. It does not provide native project LSP in those snapshots.

Use it for merge changes: JJ's merged-parent comparison must not be replaced
silently with a Git first-parent comparison. The Diffview launcher rejects merges,
root revisions without usable Git parents, conflicts, missing Git objects, and
non-colocated repositories with an explanatory message. If Git's live-file
listing omits a captured JJ path, the managed view is rejected rather than
silently presenting a partial review; use the legacy viewer for that comparison.

The explicit older `jj diff --tool nvimdiff` remains available for per-file diffs.

## Implementation boundaries

- `~/.config/jj/review.sh` resolves JJ selections, validates Git object IDs, and
  invokes the JJ directory diff tool with launch metadata.
- `jj_review.lua` opens ordinary Diffview commands for managed sessions or hunk
  for explicit legacy sessions. Paths are passed as environment values or
  structured arguments; terminal streams reconnect to `/dev/tty`.
- `review_annotations/diffview.lua` is the only Diffview-specific annotation
  adapter. Documented lifecycle/buffer hooks plus a small pinned file-model
  accessor identify paths/sides and select files using the plugin's own API.
  It does not implement a custom diff UI, LSP routing, or file-opening framework.
- Shared store/draft/UI/report modules and Pi plan-review behavior remain in place.
- JJ retains comparison directories until Neovim exits; reports persist afterward.

These are Stow-managed dotfiles; no NixOS rebuild is needed. Focused disposable
end-to-end regression tests are available with:

```sh
python3 scripts/tests/jj-review.py
# Put compatible Zig/ZLS on PATH to include native language-server attachment checks.
```
