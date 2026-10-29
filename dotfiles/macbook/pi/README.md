# Pi answer notifications (macOS)

Personal Pi extension for a Glass sound and readiness badges in the tmux session/window switcher after each completed response—even for the session you are viewing. Aborted responses do not notify. Requires Pi with `agent_settled` support (installed version: 1.3.0) and macOS’s built-in `afplay`. No desktop banners, terminal-notifier dependency, or npm dependencies.

## Activation

From the repository root, with `.host` set to `macbook`:

```sh
./scripts/stow-check pi
./scripts/stow-check tmux
./scripts/stow-add pi
./scripts/stow-add tmux
tmux source-file ~/.tmux.conf
```

Stop on Stow conflicts rather than overwriting existing files. Run `/reload` in **each existing Pi session**, or restart Pi. New sessions load the extension automatically. Non-macOS and non-TUI modes do nothing.

## Behavior

- Sound and tmux status operate independently; a broken backend does not disable the other. Each backend failure produces at most one warning per extension runtime.
- No Pi readiness indicator is shown in the status bar. The existing Saved status remains.
- The session switcher (`prefix s`) and window switcher (`prefix w`) show a yellow **PI READY** badge. Collapsed session rows aggregate readiness across all their windows/panes; expand the tree to locate the ready pane. Existing navigation, previews, and default row details are preserved. Close/reopen the switcher to refresh its readiness snapshot if a response finishes while it is open.
- Readiness clears when another run starts, on normal shutdown/session replacement/reload, or when you run `/notify-clear`. Merely viewing a pane does not clear it.
- Outside tmux, sound still works. There is no SSH forwarding.
- Force-killing Pi may leave a ready marker until Pi next starts in that pane. Destroying the pane removes its marker.

## macOS settings and troubleshooting

Sound depends on system volume, mute, and the selected output device; the extension does not override these settings. No macOS notification permission is required because no desktop notifications are sent.

No automated tests or smoke tests were added or run, as requested.

## Rollback

Run `/notify-clear` in active sessions, then `./scripts/stow-remove pi`. Remove the Pi tree-format/binding block from the in-repo tmux configuration. Restore the default switcher bindings with `tmux bind s choose-tree -Zs` and `tmux bind w choose-tree -Zw`, reload tmux, and restart Pi. Removing the symlink alone does not unload an extension already running. Keep unrelated tmux configuration and plugins intact.
