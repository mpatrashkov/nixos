# Pi plans in Neovim

The shared Stow `nvim` package provides **Markview**. The shared `pi` package
provides a **plan-review skill**, the **review_plan tool**, and a **/review-plan
command**. No third-party Pi package is required. The renderer setup targets
Neovim 0.12+ and the current Treesitter API; its `tree-sitter` CLI dependency is
declared in `nixos-modules/programs/neovim.nix` and needs separate activation
approval to become globally available.

## Start a plan-first task

After installation, run `/reload` in Pi (or restart it), then:

```text
/skill:plan-review Plan a refactor of the DNS configuration
```

You can also ask for a plan and Neovim review in ordinary chat. The explicit
skill command is more reliable because it loads the workflow directly.

The agent investigates, writes a self-contained Markdown plan, and calls
`review_plan` once the plan is ready. The default path is `.plans/<task>.md`,
unless the repository or active experiment has another convention.

The skill is **instructions, not a security-enforced read-only mode**. It tells
the agent not to implement while planning; it does not disable tools or try to
classify shell commands. Existing specialized workflows and repository approval
rules still take precedence.

## Review

1. Pi offers **Open in Neovim** or **Keep pending (discuss in chat)**.
2. Opening suspends Pi's terminal UI and launches your configured Neovim on a
   private, read-only `plan.md` snapshot. Markview renders Markdown as usual.
3. Navigate normally, search with `/`, and press **q** (or `:q`) to return to Pi.
4. Annotate passages using the keys below, or simply read the plan.
5. After returning, Pi offers **Keep pending** (the default) and **Reopen Neovim
   (continue annotating)**. Reopen as often as needed to read the same snapshot
   and edit saved annotations; the decision menu appears again after each exit.
   With saved comments, Pi also offers **Submit feedback for revision**; without
   comments, it offers **Approve implementation**. Remove comments in a reopened
   review before approving a plan that no longer needs revision.

Save annotation drafts before closing. Reopening restores saved comments, not
unsaved drafts, and does not make the plan itself editable or load a changed
version of the original file. Each editor run must produce a fresh valid result;
a receipt from an earlier run cannot authorize a later failed review.

Closing Neovim, Escape, an editor failure, or declining review does **not**
approve anything or submit feedback. Pending tool results stop the agent's
automatic follow-up—even when a local report exists. Explicitly submitting
feedback starts a revision turn: the agent reads the report, revises the plan,
and requests fresh review. It does not authorize implementation.

### Annotation keys

These mappings exist only on review source buffers (Space is the leader):

| Key | Action |
| --- | --- |
| `<leader>ra` | Comment on current line or visually selected lines |
| `<leader>rl` | List annotations and jump to a passage |
| `<leader>re` / `<leader>rd` | Edit/delete an annotation at the cursor |
| `<leader>rr` | Open the local Markdown report and display its path |
| `:ReviewHelp` | Show annotation keys and report location |

Comments open in Insert mode in a small multiline window. **`:w`** or **Ctrl-s** saves; **q** in
normal mode cancels, prompting before discarding edits. Escape leaves insert
mode; it does not submit. Saved comments appear as range highlights and a marker,
not edits to the source. All selections cover whole lines. When comments overlap,
choose the one to edit/delete from a list. Annotate the source snapshot, not a
Markview-generated preview buffer. **q** in a report closes just its split.

Saves are direct Lua calls. The draft closes only after persistence succeeds;
save errors retain the draft for retry. There is no background operation or
save-acknowledgment protocol.

### Local persistence and reports

Annotations live outside the checkout at Neovim's
`stdpath('state')/review-annotations/<identity-hash>/` (normally
`~/.local/state/nvim/review-annotations/`). Each target has versioned
`annotations.json`, a generated **`report.md`**, and an active-session `lock`.
Directories/files are private (0700/0600). JSON is authoritative: editing a report
will not change annotations. Reports contain quoted source and feedback, so share
or delete them deliberately. Nothing is published automatically.

The identity includes the canonical plan path, review working directory, and exact
SHA-256 of the original bytes. Reopening the same snapshot restores comments even
though the temporary snapshot path changes. Revised content starts a separate
review; old comments are not fuzzily reattached. Report quotations survive cleanup
of temporary files. There is no automatic expiry: close reviews before manually
removing unwanted identity directories.

Concurrent reviews of the same identity are refused rather than overwriting
comments. A stale lock error shows its path; inspect the recorded host/PID and
ensure the owning review is no longer running before manually removing it. Corrupt
or unsupported state is reported, never silently reset. Save failures retain the
comment draft for retry. Force-quitting with an unfinished draft withholds
feedback/approval; use the draft's q action to cancel cleanly.

An explicit approval returns the original path and a SHA-256 of the reviewed
bytes to the agent. If the original plan changes during review, the integration
withholds approval and feedback submission (the report remains available locally).
Missing/invalid annotation results also withhold both actions. The agent must
check the approved version before implementing.
Plan approval is not permission to publish, deploy, or activate NixOS changes.

## Reopen an existing plan

```text
/review-plan .plans/my-task.md
```

The argument is a literal path relative to Pi's working directory (absolute
paths also work). Spaces are allowed; do not add shell quotes. No persisted
"latest plan" pointer is needed, so switching sessions cannot accidentally
review another task's plan. An approved command review starts an agent turn;
an explicitly submitted feedback review also starts a revision turn. A pending
review records the decision without starting one.

Terminal handoff requires **interactive Pi**, a working terminal, and `nvim` on
`PATH`. RPC/JSON/print use returns a pending tool result without launching a
process. The tool accepts regular `.md` files up to 1 MiB. Temporary snapshots
are deleted on normal completion and error paths.

## Plain Lua implementation

Annotations run inside Neovim using direct Lua calls—no TypeScript backend,
custom IPC, Node requirement, native library, or build step. Pi's own extension
remains TypeScript; it still independently validates the review receipt and
report before offering feedback submission or approval.

The code under `lua/review_annotations/` uses focused modules:

- `files.lua`: private files, atomic writes, lock ownership, binary-safe hashes.
- `snapshot.lua`: comparison manifests, text verification, passage anchors.
- `store.lua` and `report.lua`: version-1 data, annotation operations, Markdown.
- `ui.lua` and `draft.lua`: mappings, markers, selections, comment windows.
- `init.lua` and `jj.lua`: review lifecycle and the hunk viewer adapter.

SHA-256 uses the existing coreutils `sha256sum` for raw-byte compatibility,
including embedded NULs. Scanning/hashing and saves are synchronous; large
comparisons can briefly pause the editor. No custom background process or protocol
is needed. Existing version-1 annotations, identity directories, and reports are
compatible with both preceding implementations; no data migration is needed.

On clean exit, Lua finalizes the report and releases its lock before publishing
Pi's receipt. Unfinished drafts, invalid state, and finalization/lock failures
withhold that receipt. Saved annotations remain on disk. A hard crash may leave
a stale lock: verify the recorded Neovim PID/host before removing it, never simply
delete a live lock. Unsupported/lossy text encodings cannot receive line comments.

## Markview keys

- `<leader>mt`: toggle rendered Markdown in the current buffer.
- `<leader>ms`: toggle a source/preview split.
- `:Markview`: toggle preview; `:checkhealth markview`: diagnose setup.

Markview and Treesitter are pinned in `lazy-lock.json`; Markdown and inline
Markdown parsers are included in Treesitter's configured parser list. The old
Treesitter `master` branch only supports Neovim through 0.11 and fails on Markdown
code-block injections with Neovim 0.12. This configuration uses `main`, preserves
the existing parser list, and explicitly enables highlighting/indentation with
the new API.

On a fresh machine, provide Neovim 0.12+, coreutils, a C compiler, curl/tar, and the
`tree-sitter` CLI (0.26.1+). After the dependency is available, use `:Lazy restore`
and `:TSUpdate` when moving from the old configuration. Let parser installation
finish before reviewing. The NixOS module declares the required compiler/CLI.

## Installation

```sh
./scripts/stow-check nvim
./scripts/stow-add nvim
./scripts/stow-check pi
./scripts/stow-add pi
```

To check the interaction manually, reload Pi and open an existing plan with
`/review-plan path/to/plan.md`. Choose **Keep pending** afterward unless you
intend to authorize implementation. To check annotations without requesting
revision, save a comment, return with q, and choose **Keep pending**. Reopen the
same plan to verify persistence. Choose **Submit feedback for revision** only when
you want the agent to revise it. Reload Pi and start a fresh Neovim review after
updating the integration.
