---
title: "Explore JJ diffs in Neovim"
status: testing
priority: medium
tags: [jj, jujutsu, neovim, diffs, tooling]
created: 2026-10-28
updated: 2026-10-29
---

Make browsing JJ changes and diffs easy from Neovim. Consider jjui in an embedded terminal for graph/revision browsing and a JJ external diff tool for native Neovim comparisons. Existing Neovim configuration includes Diffview, which is Git-oriented; do not assume Git HEAD represents JJ's working-copy parent. User approved starting a new JJ change and installing jjui. Added `pkgs.jjui` to `nixos-modules/programs/git.nix`; jjui 0.10.11 is now available on the running system.

## Neovim diff viewer (2026-10-29)

- Added the `nvimdiff` JJ external viewer in the existing Stow-managed `jujutsu` package. Uses read-only Neovim diff mode and disables swap files.
- Created and Stow-linked the `jjui` package. `Ctrl-o` in `revisions.details` invokes the viewer for the selected commit and file, using shell-quoted arguments with jjui's `exec_shell` API. Built-in `d` and `p` bindings remain unchanged.
- Verified jjui loads its configuration and exits cleanly in a pseudo-terminal. A headless JJ external-tool smoke test opened two read-only Neovim diff panes successfully.
- Fixed the blank viewer: JJ external diff generators receive null stdin and piped stdout. The `nvimdiff` tool now launches `sh` and explicitly redirects all Neovim standard streams to `/dev/tty`, passing file paths as quoted positional arguments.
- Validated the actual configured tool in a disposable JJ repository under a pseudo-terminal, with the full user Neovim configuration. Confirmed all three standard streams are terminals and two named, read-only diff panes open. Neovim exited automatically via test-only commands; no automated jjui keystrokes were used.
- User confirmed the standalone `Ctrl-o` viewer works. Next requested step: plan deeper integration with jjui as a Neovim sidebar and native diff buffers in the same Neovim instance.

## Revised direction: whole-change review with hunk.nvim

User reports the embedded jjui integration is very buggy. Replace it rather than layering more fixes onto the RPC/terminal design.

Investigated `julienvincent/hunk.nvim` (master README): its read-only `HunkDiffView` provides a changed-file tree and side-by-side diff panes over two directories, with documented JJ directory-diff integration. This directly matches the simplified review workflow; prefer evaluating it over writing another custom UI. Requires `nui.nvim`; icons are optional. Use `HunkDiffView`, not the mutating diff editor.

Proposed replacement:

1. Remove the embedded jjui workspace, RPC bridge, environment routing, and associated commands/configuration.
2. Configure hunk.nvim's read-only directory viewer as a dedicated JJ diff tool, preserving `/dev/tty` redirection and using absolute comparison paths (`diff-do-chdir = false`). Validate quoting at both shell and Neovim command layers.
3. Add `:JJReview [revision]`, defaulting to `@`, with a current-change mapping. Initial review is a fixed snapshot; reopening refreshes it. Keep the JJ process alive while the external Neovim review session is open so all comparison files remain available.
4. Bind `Ctrl-o` in jjui's revision list to review the entire selected commit, with no file filter. A details-list binding may review the same whole change for convenience.
5. Separate launch contexts: from standalone jjui, launch a dedicated blocking Neovim review session; inside an existing Neovim, explicitly design a simple snapshot-owned review tab or, if hunk lacks a stable API for that, start with the dedicated session and document that boundary. Do not reintroduce terminal/RPC complexity implicitly.
6. Verify file selection, additions/deletions, filenames with spaces/quotes, close behavior, temporary-directory lifetime, and no changes to working files in disposable repositories before rollout.

User approved this replacement; implemented on 2026-10-29. Prior embedded design below is superseded and retained as history.

### Replacement implementation and validation

- Installed and pinned hunk.nvim plus nui.nvim through Lazy. The plugin spec enables only the read-only viewer entry point and uses a flat 40-column changed-file list.
- Removed `jj_workspace.lua`, the headless RPC bridge, embedded tool, and all embedded workspace commands/mappings. Stow pruned the obsolete bridge symlink.
- Added `jj review` (defaults to `@`) and `jj review -r <revision>`. JJ runs the viewer in directory mode with absolute paths and waits until the dedicated Neovim exits, preserving comparison-tree lifetime.
- Added a small `jj_review.lua` API launcher. Paths are shell positional arguments and environment values rather than interpolated Ex/Lua. All terminal streams reconnect to `/dev/tty`.
- Rebound jjui `Ctrl-o` in revision and file-detail scopes to review the entire selected commit without any file filter. Kept standalone per-file `nvimdiff` available explicitly.
- End-to-end disposable-repository tests through the actual `jj review` tool passed with full Neovim configuration and a pseudo-terminal: three changed files (modified/added/deleted), file switching via direct viewer callbacks, two read-only nonmodifiable panes, live temporary directories, paths with spaces/apostrophes, and successful `q` callback exit. Repeated explicit-revision invocation passed and working-file SHA-256 sums were unchanged.
- Direct action syntax/execution test confirmed the jjui shortcut passes only the selected revision. Tests stayed under `/tmp`, with no timed jjui keystrokes.
- Rewrote `docs/jj-neovim.md` with the new session-based workflow and keys. Manual user verification of actual jjui-to-review interaction remains pending. No NixOS rebuild, publication, or history mutation performed.

## Superseded plan: embedded jjui sidebar and native Neovim diff panes

### User experience

- `<leader>jj` opens/toggles a dedicated JJ workspace tab: jjui in a left terminal split, with two native Neovim diff windows to the right.
- Select a change, press `l`, select a file, then `Ctrl-o`. The existing Neovim instance displays before/after buffers; no nested editor opens.
- Reuse the two diff windows for subsequent selections. Focus moves to the right-hand diff pane; provide a mapping to return to the sidebar in terminal-input mode.
- Native `]c` / `[c` navigate hunks. A workspace close command returns to the previous tab without closing unrelated buffers or the whole editor.
- Preserve standalone jjui's working `/dev/tty` viewer when not launched from this integration. jjui remains a full, potentially mutating UI, not a read-only browser.

### Architecture

1. Add a small local Neovim Lua module, loaded through a Lazy plugin spec, to own the workspace tab, terminal job, diff windows, and scratch buffers. Do not repurpose Git-oriented Diffview or parse its internals.
2. Launch jjui with its repository root as cwd and a child-only environment variable pointing to this Neovim instance's RPC socket. Start a private server if needed; do not expose a network listener or set this variable globally.
3. Extend the jjui `Ctrl-o` action: choose a dedicated embedded diff tool when that variable exists; otherwise retain the standalone tool. Continue using JJ's own diff machinery and exact selected commit IDs, rather than reconstructing diffs against Git HEAD or assuming a single parent.
4. Configure the embedded tool as a short-lived Neovim headless RPC bridge using the installed executable and a Stow-managed Lua script. Receive JJ's `$left` and `$right` as positional arguments, connect to the parent socket, and use structured RPC arguments rather than generated Ex/Lua strings.
5. The parent callback must synchronously read/copy both temporary files into owned scratch buffers before returning success. JJ deletes its temporary comparison tree when the tool exits; never leave buffers dependent on those paths. Prototype this lifetime contract before building the workspace UI.
6. Enable native diff mode only in the two owned windows. Use descriptive buffer names, filetypes from the original filename, and read-only/nonmodifiable snapshots. Opening a diff must not alter the user's working files. Defer editable working-copy panes, staging-like actions, and automatic selection previews.

### Lifecycle and edge cases

- Handle file additions/deletions as an empty side, renamed files according to the paths supplied by JJ, and merges using JJ's generated comparison. Show clear messages for binary files or unsupported cases instead of decoding arbitrary bytes as text.
- Preserve missing-final-newline metadata and avoid claiming exact binary comparisons from line-oriented scratch buffers.
- Reuse resources on repeated selections; handle stale sockets, closed tabs/windows, bridge errors, and jjui exit without silently falling back to a nested editor inside the terminal.
- Determine terminal focus mappings without breaking jjui's own bindings. Explain that terminal-mode `q` exits jjui while the Neovim workspace close command closes the workspace.
- Scope each workspace to its repository and originating Neovim server. Closing the workspace must terminate/reap its own terminal job and remove only owned scratch buffers/windows.

### Proposed files

- `dotfiles/common/nvim/.config/nvim/lua/jj_workspace.lua`
- `dotfiles/common/nvim/.config/nvim/lua/plugins/jj.lua`
- `dotfiles/common/jujutsu/.config/jj/nvim-diff-bridge.lua`
- Existing JJ and jjui `config.toml` files for tool definition and context-sensitive action.

### Validation and rollout

1. Prototype RPC handoff in a disposable JJ repository: confirm both buffers remain readable after the bridge exits and JJ removes temporary files.
2. Validate the workspace with full Neovim config: repeat file selection, additions/deletions, paths containing spaces/quotes, historical revisions, merges, and multiple Neovim instances/repositories.
3. Check focus, resize, close/reopen, normal buffer preservation, and error reporting. Recheck standalone jjui fallback.
4. Never drive jjui with timed keystrokes against this real checkout. Use disposable repositories and direct callback/bridge tests; reserve interactive behavior for manual verification.
5. Apply through Stow only; no NixOS rebuild, publication, bookmark changes, or history rewrites. Implementation approved and completed on 2026-10-29; manual interactive verification pending.

## Embedded workspace implementation (2026-10-29)

- Implemented `jj_workspace.lua` with a dedicated workspace tab, 42-column jjui terminal sidebar, two reused read-only native diff buffers, focus/close/toggle mappings, and tab/job cleanup.
- Added local Lazy spec and `JJOpen`, `JJFocus`, `JJClose` commands. Documented usage and terminal-mode escape in `docs/jj-neovim.md`.
- Added and Stow-linked the headless RPC bridge and configured the `nvim-embedded` JJ tool. Embedded launches get child-only socket/workspace variables. Standalone jjui retains the working terminal viewer.
- The jjui action now quotes filenames both for the shell and JJ's fileset language, including filenames containing apostrophes. Uses exact root-relative file patterns.
- Disposable-repository tests passed with minimal and full Neovim configuration: structured RPC handoff through the actual JJ tool, two read-only diff panes, repeated selections reusing buffers, added/deleted files, quoted filenames, return focus to terminal, and workspace cleanup preserving the previous tab/buffer. The parent buffers remain available after the tool returns and JJ removes its temporary files.
- Direct Lua action tests passed for syntax, embedded/standalone selection, and shell/fileset quoting. Tests lived only under `/tmp`; no timed jjui input was sent to the real checkout.
- Still pending manual GUI verification of the sidebar and `Ctrl-o` interaction, resizing, and merge/multi-instance edge cases. No publishing, rebuild, bookmark changes, or history rewrites performed during this implementation.
