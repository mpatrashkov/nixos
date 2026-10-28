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

The file list uses flat paths. Both file panes are read-only snapshots; this
workflow does not select, stage, split, or write changes. JJui itself remains a
full, potentially mutating history UI.

## Implementation

- `julienvincent/hunk.nvim` provides `hunk.view`, its read-only directory viewer.
  `nui.nvim` is its only added required dependency. Both are pinned in Lazy's lockfile.
- JJ's `nvim-review` tool receives the whole before/after directory comparison,
  with absolute paths and JJ's own parent/merge semantics.
- The tool reconnects stdin/stdout/stderr to `/dev/tty`, since JJ normally gives
  external diff generators null stdin and piped stdout.
- Directory paths are passed as quoted shell arguments and environment values,
  never interpolated into Lua or Ex commands.
- The small `jj_review.lua` launcher calls the viewer API. It does not manage
  windows, file switching, terminal focus, or communication between editors.
- JJ waits for the review editor to exit, so its temporary directories remain
  available throughout the review. Closing/reopening captures a fresh snapshot;
  the viewer does not watch subsequent working-copy edits.

The older per-file `nvimdiff` tool remains available explicitly via
`jj diff --tool nvimdiff`; it is no longer the jjui Ctrl-o action.

These are Stow-managed dotfiles. No NixOS rebuild is needed for this integration.
