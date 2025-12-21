#!/usr/bin/env bash

# `commit-msg` hooks receive the path to a temporary file, containing the commit
# message, as their second argument ($1).
COMMIT_MSG_FILE=$1

# Commit message is in the following format:
# `[<branch> <short_hash>] <commit_message>`
# Example: `[main 7a8a3a1] edit README.md`
UNFORMATTED_COMMIT_MSG=`head -n1 $COMMIT_MSG_FILE`

# Replace spaces with underscores, because NixOS doesn't support spaces in labels.
# See https://search.nixos.org/options?channel=unstable&show=system.nixos.label
COMMIT_MSG="${UNFORMATTED_COMMIT_MSG// /__}"

# The `last-commit-message` file is stored in the flake root directory.
LAST_COMMIT_MESSAGE_FILE=$NH_FLAKE/last-commit-message

echo $COMMIT_MSG > $LAST_COMMIT_MESSAGE_FILE