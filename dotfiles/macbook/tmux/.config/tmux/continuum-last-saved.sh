#!/usr/bin/env bash
# Print how long ago tmux-continuum last saved the environment, e.g. "12m ago".
# Reads continuum's @continuum-save-last-timestamp (unix epoch). macOS/BSD date.

ts="$(tmux show-option -gqv @continuum-save-last-timestamp)"
if [ -z "$ts" ] || { [ "$ts" -eq 0 ] 2>/dev/null; }; then
	printf 'never'
	exit 0
fi

now="$(date +%s)"
d=$(( now - ts ))

if [ "$d" -lt 60 ]; then
	printf 'just now'
elif [ "$d" -lt 3600 ]; then
	printf '%dm ago' $(( d / 60 ))
elif [ "$d" -lt 86400 ]; then
	printf '%dh%dm ago' $(( d / 3600 )) $(( (d % 3600) / 60 ))
else
	printf '%dd ago' $(( d / 86400 ))
fi
