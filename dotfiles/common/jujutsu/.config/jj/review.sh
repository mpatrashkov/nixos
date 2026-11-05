#!/bin/sh
# Keep revision selection in JJ; Diffview receives only validated Git object IDs.
set -eu

fail() {
    printf '%s\n' "JJ review: $*" 'Use jj review-legacy -r <revision> for the snapshot viewer.' >&2
    exit 1
}

revision=@
case $# in
    0) ;;
    2)
        [ "$1" = -r ] || fail 'Usage: jj review [-r <revision>]'
        revision=$2
        ;;
    *) fail 'Usage: jj review [-r <revision>]' ;;
esac

JJ_REVIEW_ROOT=$(jj root)
cd "$JJ_REVIEW_ROOT"
JJ_REVIEW_CURRENT=$(jj log --no-graph -r @ -T commit_id)
JJ_REVIEW_SELECTED=$(jj --ignore-working-copy log --no-graph -r "$revision" -T commit_id)
case "$JJ_REVIEW_SELECTED" in
    ''|*[!0-9a-f]*) fail 'Select exactly one revision.' ;;
esac
[ "${#JJ_REVIEW_SELECTED}" -eq 40 ] || fail 'Select exactly one Git-backed revision.'

conflict=$(jj --ignore-working-copy log --no-graph -r "$JJ_REVIEW_SELECTED" -T conflict)
[ "$conflict" = false ] || fail 'Conflicted revisions require the legacy viewer.'
JJ_REVIEW_PARENT=$(jj --ignore-working-copy log --no-graph -r "$JJ_REVIEW_SELECTED" -T 'parents.map(|p| p.commit_id()).join(" ")')
case "$JJ_REVIEW_PARENT" in
    ''|*[!0-9a-f]*) fail 'Root and merge revisions require the legacy viewer.' ;;
esac
[ "${#JJ_REVIEW_PARENT}" -eq 40 ] || fail 'Expected a single Git-backed parent.'
parent_conflict=$(jj --ignore-working-copy log --no-graph -r "$JJ_REVIEW_PARENT" -T conflict)
[ "$parent_conflict" = false ] || fail 'A conflicted parent requires the legacy viewer.'

# Git is used for object reads only. Never consult HEAD or the index for identity.
export GIT_OPTIONAL_LOCKS=0
git_root=$(git rev-parse --show-toplevel 2>/dev/null) || fail 'A colocated Git repository is required.'
[ "$(realpath "$git_root")" = "$(realpath "$JJ_REVIEW_ROOT")" ] || fail 'Git and JJ workspace roots differ.'
git cat-file -e "$JJ_REVIEW_SELECTED^{commit}" 2>/dev/null || fail 'Selected Git object is unavailable.'
git cat-file -e "$JJ_REVIEW_PARENT^{commit}" 2>/dev/null || fail 'Parent Git object is unavailable.'

JJ_REVIEW_MODE=historical
if [ "$JJ_REVIEW_SELECTED" = "$JJ_REVIEW_CURRENT" ]; then
    JJ_REVIEW_MODE=live
fi
export JJ_REVIEW_ROOT JJ_REVIEW_SELECTED JJ_REVIEW_PARENT JJ_REVIEW_MODE
exec jj --ignore-working-copy diff -r "$JJ_REVIEW_SELECTED" --tool nvim-review --no-pager
