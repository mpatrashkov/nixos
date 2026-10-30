# Review JJ changes in Neovim

Use **jjui to browse history** and **hunk.nvim to review one complete change**.
The review runs in a dedicated Neovim session with a changed-file sidebar and
side-by-side, read-only diff buffers. There is no embedded jjui terminal or RPC
bridge.

## From jjui

Restart jjui after changing its configuration. Select a change and press
**Ctrl-o**. The entire selected change opens in Neovim. The shortcut also works
from the changed-file list, but still reviews the whole change.

Press **q** inside the review to close that dedicated Neovim session and return
to jjui. Press **Esc**, then **q** in jjui to exit jjui itself.

## From a shell

```sh
jj review                  # Current working-copy change (@)
jj review -r <revision>    # Another change
```

Run these in a normal terminal, not inside a Neovim terminal buffer. This initial
integration intentionally uses a separate blocking review session, not a review
tab inside an already-running editor. The old `JJOpen`, `JJFocus`, `JJClose`, and
workspace `<leader>jj`/`jf`/`jq` mappings have been removed; restart old Neovim
sessions to unload them.

## Review keys

| Key | Action |
| --- | --- |
| `j` / `k` in the sidebar | Select a changed file |
| `Enter` | Open the selected file and focus its diff |
| `<leader>e` (Space, e) | Focus the file sidebar |
| `Tab` in a diff | Switch between before/after panes |
| `[h` / `]h` | Previous/next diff hunk |
| `g?` | Show viewer key help |
| `q` | Close the review and return to its caller |
| `<leader>ra` in a diff | Comment on current line or visually selected lines |
| `<leader>rl` | List annotations and jump to a file/side/passage |
| `<leader>re` / `<leader>rd` in a diff | Edit/delete an annotation at the cursor |
| `<leader>rr` | Open the local Markdown report and show its path |
| `:ReviewHelp` | Show annotation help and report location |

The file list uses flat paths. Both file panes are read-only snapshots; this
workflow does not select, stage, split, or write changes. JJui itself remains a
full, potentially mutating history UI.

## Annotations and report handoff

Comments use the same interface as [Pi plan reviews](pi-plan-review.md): a small
multiline window, **`:w`** or **Ctrl-s** to save, **q** in normal mode to cancel
(with a prompt for edits). Escape leaves insert mode. Selections cover whole
lines. Saves are direct Lua calls: the draft closes only after persistence
succeeds, and a failed save leaves it editable for retry. Saved comments have
visible range markers. Before/after panes have distinct anchors; absent,
empty, binary, invalid-UTF-8, symlink, and oversized (>16 MiB) panes cannot receive
line comments. Sidebar mappings provide only list/report actions, not annotation
of the file list itself.

`<leader>rl` navigates through the viewer's own file-opening callback, updating
both panes before focusing the annotated side. It never opens a writable working
file. `<leader>rr` opens a read-only generated report; q closes only that split.
The notification and `:ReviewHelp` give its absolute path. Give that **`report.md`**
path to Pi in ordinary chat when you want it acted on. There is no direct JJ-to-Pi
connection, automatic turn, approval, or code change.

Local JSON/report storage, permissions, concurrent-review locks, manual retention,
and save-error behavior are described in [the plan-review guide](pi-plan-review.md#local-persistence-and-reports).
For JJ, identity uses the canonical workspace root and a deterministic comparison
manifest (logical path, before/after side, entry kind, raw-byte SHA-256). Temporary
directory names are excluded. The fingerprint is **not a JJ commit ID**: identical
comparisons in the same workspace intentionally share annotations. Changes to either
side start a new identity; comments are never silently reanchored. Reports retain
quoted passages after JJ removes its temporary comparison directories.

The adapter uses hunk.nvim's documented mount hooks and the pinned viewer's buffer
names/tree context. Unexpected viewer content fails explicitly rather than
attaching misleading annotations. Restart Neovim/jjui after updating; ordinary
Neovim buffers and the older explicit `nvimdiff` tool have no annotation mappings.

## Implementation

- `julienvincent/hunk.nvim` provides `hunk.view`, its read-only directory viewer.
  `nui.nvim` is its only added required dependency. Both are pinned in Lazy's lockfile.
- JJ's `nvim-review` tool receives the whole before/after directory comparison,
  with absolute paths and JJ's own parent/merge semantics.
- The tool reconnects stdin/stdout/stderr to `/dev/tty`, since JJ normally gives
  external diff generators null stdin and piped stdout.
- Directory paths are passed as quoted shell arguments and environment values,
  never interpolated into Lua or Ex commands.
- The small `jj_review.lua` launcher initializes local annotations and calls the
  viewer API. `review_annotations/jj.lua` adapts the pinned viewer's mount hooks
  and navigation callbacks; shared storage/UI modules also serve Pi plans.
- `lua/review_annotations/` handles snapshots, annotation operations, persistence,
  reports, and UI with direct Lua calls. There is no Node backend, custom IPC,
  native library, or build step. Binary-safe hashes use coreutils `sha256sum`.
- Existing version-1 stores retain their identities and reports. See the
  [implementation guide](pi-plan-review.md#plain-lua-implementation) for module
  responsibilities, synchronous-save behavior, and stale-lock recovery.
- JJ waits for the review editor to exit, so its temporary directories remain
  available throughout the review. Closing/reopening captures a fresh snapshot;
  the viewer does not watch subsequent working-copy edits.

The older per-file `nvimdiff` tool remains available explicitly via
`jj diff --tool nvimdiff`; it is no longer the jjui Ctrl-o action.

These are Stow-managed dotfiles. No NixOS rebuild is needed for this integration.
