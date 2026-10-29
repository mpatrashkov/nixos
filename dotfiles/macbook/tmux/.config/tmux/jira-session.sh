#!/usr/bin/env bash
# Link tmux sessions to Jira tickets via the session name prefix (KEY-slug).
#   jira-session.sh new            - pick a ticket, create/switch to its session
#   jira-session.sh open <session> - open the session's ticket in the browser
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

MONOREPO="$HOME/dev/monorepo/master"
KEY_RE='^[A-Z][A-Z0-9]+-[0-9]+'

die() {
  tmux display-message "jira-session: $1"
  exit 1
}

for bin in acli jq fzf; do
  command -v "$bin" >/dev/null || die "'$bin' not found"
done

pause_fail() {
  echo
  echo "$1"
  read -r -p "Press enter to close" _
  exit 1
}

slugify() {
  tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' | cut -c1-30 | sed -E 's/-+$//'
}

cmd_new() {
  echo "Loading tickets..."
  local json
  json=$(acli jira workitem search \
    --jql 'assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC' \
    --fields key,status,summary --limit 100 --json) || pause_fail "Failed to fetch tickets from Jira."

  local pick
  pick=$(jq -r '.[] | [.key, .fields.status.name, .fields.summary] | @tsv' <<<"$json" |
    fzf --delimiter=$'\t' --prompt='Ticket> ' --header='Select Jira ticket') || exit 0

  local key summary slug name
  key=$(cut -f1 <<<"$pick")
  summary=$(cut -f3- <<<"$pick")
  slug=$(slugify <<<"$summary")
  name="$key${slug:+-$slug}"

  # Already have a session for this ticket? Just switch to it.
  local existing
  existing=$(tmux list-sessions -F '#S' | grep -E "^${key}(-|$)" | head -n1 || true)
  if [[ -n "$existing" ]]; then
    tmux switch-client -t "=$existing"
    exit 0
  fi

  local type dir
  type=$(printf 'Other\nFE\n' | fzf --prompt='Task type> ' --header="$key $summary") || exit 0

  if [[ "$type" == FE ]]; then
    dir="$(dirname "$MONOREPO")/$(basename "$MONOREPO")-$key"
    if [[ ! -d "$dir" ]]; then
      echo "Creating worktree for $key..."
      (cd "$MONOREPO" && pnpm nx g cli:create-branch --issue="$key" --sourceBranch=master \
        --worktree --skipConfirmation --no-interactive) || pause_fail "Worktree generator failed."
      [[ -d "$dir" ]] || pause_fail "Expected worktree at $dir but it does not exist."
    fi
  else
    dir=$({
      echo "$HOME"
      find "$HOME/dev" -mindepth 1 -maxdepth 2 -type d \
        -not -name '.*' -not -name node_modules 2>/dev/null | sort
    } | fzf --prompt='Directory> ' --header="$key $summary") || exit 0
  fi

  tmux new-session -d -s "$name" -c "$dir"
  tmux switch-client -t "=$name"
}

cmd_open() {
  local session="${1:-}" key
  key=$(grep -oE "$KEY_RE" <<<"$session" || true)
  [[ -n "$key" ]] || { tmux display-message "No Jira ticket linked to this session"; exit 0; }
  acli jira workitem view "$key" --web >/dev/null 2>&1 || die "failed to open $key"
}

case "${1:-}" in
  new) cmd_new ;;
  open) shift; cmd_open "$@" ;;
  *) echo "usage: $0 {new|open <session>}" >&2; exit 2 ;;
esac
