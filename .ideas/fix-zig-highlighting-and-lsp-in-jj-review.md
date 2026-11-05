---
title: "Fix Zig highlighting and LSP in JJ review"
status: testing
priority: medium
tags: [neovim, zig, lsp, treesitter, jj, jjui, dotfiles]
created: 2026-11-05
updated: 2026-11-05
---

## Implemented follow-up

User approved `.plans/project-aware-jj-neovim-review.md`. The default review now uses Diffview with real working files for the current change, preserving native LSP without custom routing, plus a bounded annotation adapter. Historical comparisons stay exact and use the plugin's working-file opening action for live LSP. Hunk remains an explicit legacy fallback for merges. Zig is now a managed Tree-sitter language; parser/query installation succeeded and native ZLS hover/definition passed in disposable full-config tests with the existing project toolchain. See [project-aware review](project-aware-jj-neovim-review.md) for full validation and remaining manual checks.

## Original investigation

Requested investigation in a new JJ change, `woqkmsxt`, based on the existing Pi change. No configuration fixes applied yet.

### Launch path

jjui Ctrl-o invokes `jj review -r <revision>`. JJ launches a dedicated Neovim with the inherited environment; `jj_review.lua` starts annotations and hunk.nvim's read-only directory viewer. Hunk creates `hunk://view/<session>/<side>/<logical-path>` buffers with `buftype=nofile`. Both Zig panes correctly detect `filetype=zig` and fire FileType events. This is not a jjui filetype-detection problem.

### Highlighting

- `lua/plugins/treesitter.lua` does not include `zig` in its managed parser installation list.
- A leftover Zig parser exists at `~/.local/share/nvim/lazy/nvim-treesitter/parser/zig.so`, so language loading succeeds and a Tree-sitter highlighter is active on both panes.
- However, `vim.treesitter.query.get("zig", "highlights")` returns nil and `nvim_get_runtime_file("queries/zig/highlights.scm", true)` is empty. An active highlighter without queries cannot color tokens.
- The installed plugin contains source queries under `runtime/queries/zig/`, but that directory is not itself on runtimepath. The main-branch installer normally installs managed queries under the data `site` directory. Having an old parser is insufficient.
- A process-local test appending the plugin's `runtime` directory makes the Zig highlight query discoverable. This confirms the query-discovery diagnosis without changing configuration or installing anything.
- Both panes have empty `syntax`, so there is no active legacy Zig syntax fallback in the tested configuration.

Recommended highlighting fix: add Zig to the managed Tree-sitter languages, let the main-branch installer install its parser and queries together, and verify query availability and captures in both panes and ordinary files. Avoid relying on an incidental stale parser or hard-coding Lazy's installation path.

### LSP

- `lua/plugins/lsp.lua` enables ZLS only when `executable("zls") == 1`. It is absent from the normal shell PATH used in this investigation. The wallpaper project's `.devenv/profile/bin` provides Zig and ZLS; jjui must inherit an appropriate environment for them to be available.
- Even with that project toolchain on PATH, ZLS is enabled but both review panes have zero attached clients.
- Neovim 0.12.5's native LSP auto-enable path (`runtime/lua/vim/lsp.lua`, around line 522) rejects buftypes other than empty or `help`. Hunk's `nofile` buffers are therefore excluded by design.
- Hunk's synthetic URI also lacks real project identity. Simply removing the buftype guard or forcing attachment would not establish correct roots, import resolution, or historical dependency context. JJ's temporary directories contain comparison data, not necessarily a complete buildable project.

Recommended LSP follow-up: choose explicitly between navigation into the live project (clearly distinct from the reviewed snapshot) and isolated, complete revision workspaces with compatible toolchains. Do not silently map both historical sides onto the current working file or enable write-oriented LSP actions on read-only snapshots.

## Validation

Headless tests with the full user configuration called the same `require("hunk").view(left, right)` API on disposable before/after directories containing changed `src/main.zig` files:

| Environment | Filetype | Tree-sitter active | Zig highlight query | ZLS enabled | Pane clients |
| --- | --- | --- | --- | --- | --- |
| Normal PATH | zig, both panes | yes | absent | no | 0 |
| Project Zig/ZLS PATH | zig, both panes | yes | absent | yes | 0 |
| Process-local plugin runtime path added | zig, both panes | yes | present | no | 0 |

These are API-level tests, not an interactive jjui visual verification. No project files, plugin versions, Stow links, NixOS configuration, publishing bookmarks, or activation were changed.
