#!/usr/bin/env bash
# Shared helpers for the tier-aware stow-* scripts.
# Dotfiles are organized as dotfiles/<tier>/<pkg>/... where <tier> is either
# "common" (shared across all machines) or the active host tier named by the
# untracked .host file at the repo root (e.g. "macbook" or "nixos").
#
# Source this from a stow-* script AFTER setting `pkg`. It exports:
#   repo_root   - absolute repo root (also cd's into it)
#   host        - contents of .host (the active host tier name)
#   TIERS       - array of tier dirs (relative to repo_root) that contain <pkg>,
#                 ordered common-first then host.

# Resolve repo root from the sourcing script's location and cd into it.
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[1]}")/.." && pwd)
cd "$repo_root"

# Read and validate the active host from .host.
if [ ! -f "./.host" ]; then
  cat >&2 <<EOF
error: no .host file found at $repo_root/.host
Create it with the profile name for this machine, e.g.:
  echo macbook > .host   # or: echo nixos > .host
EOF
  exit 1
fi

host=$(tr -d '[:space:]' < ./.host)
if [ -z "$host" ]; then
  echo "error: .host is empty; write a profile name into it (e.g. 'macbook' or 'nixos')" >&2
  exit 1
fi

if [ ! -d "./dotfiles/$host" ]; then
  echo "error: host tier './dotfiles/$host' (from .host) does not exist" >&2
  exit 1
fi

# Determine which tiers contain the package (common first, then host).
TIERS=()
for tier in common "$host"; do
  if [ -d "./dotfiles/$tier/$pkg" ]; then
    TIERS+=("dotfiles/$tier")
  fi
done

if [ ${#TIERS[@]} -eq 0 ]; then
  echo "error: package '$pkg' not found in 'common' or '$host' tier" >&2
  exit 1
fi
