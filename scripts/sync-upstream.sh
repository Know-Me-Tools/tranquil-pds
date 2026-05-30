#!/usr/bin/env bash
# Mirror the original tangled.org repo (`upstream`) to the GitHub repo (`origin`).
#
#   upstream = https://tangled.org/tranquil.farm/tranquil-pds  (source of truth)
#   origin   = git@github.com:Know-Me-Tools/tranquil-pds.git    (GitHub mirror)
#
# Fetches every branch and tag from upstream and pushes them to origin. Also
# fast-forwards the local checkout's current branch when it tracks origin and
# can advance without a merge.
#
# Usage:
#   scripts/sync-upstream.sh            # mirror branches + tags
#   scripts/sync-upstream.sh --prune    # also delete origin branches gone upstream
#   scripts/sync-upstream.sh --dry-run  # show what would be pushed, change nothing
set -euo pipefail

UPSTREAM="${SYNC_UPSTREAM_REMOTE:-upstream}"
ORIGIN="${SYNC_ORIGIN_REMOTE:-origin}"

PRUNE=""
DRY_RUN=""
for arg in "$@"; do
    case "$arg" in
        --prune)   PRUNE="--prune" ;;
        --dry-run) DRY_RUN="--dry-run" ;;
        *) echo "Unknown argument: $arg" >&2; exit 2 ;;
    esac
done

require_remote() {
    git remote get-url "$1" >/dev/null 2>&1 || {
        echo "Remote '$1' not configured. Run 'git remote -v' to inspect." >&2
        exit 1
    }
}
require_remote "$UPSTREAM"
require_remote "$ORIGIN"

echo "Fetching from '$UPSTREAM'..."
git fetch --prune --tags "$UPSTREAM"

echo "Mirroring branches '$UPSTREAM' -> '$ORIGIN'..."
# Push each upstream branch to a same-named branch on origin.
while IFS= read -r branch; do
    [ -n "$branch" ] || continue
    # Skip the remote's symbolic HEAD pointer; it is not a real branch.
    [ "$branch" = "HEAD" ] && continue
    echo "  $branch"
    git push $DRY_RUN "$ORIGIN" \
        "refs/remotes/$UPSTREAM/$branch:refs/heads/$branch"
done < <(git for-each-ref --format='%(refname:strip=3)' "refs/remotes/$UPSTREAM/")

echo "Mirroring tags -> '$ORIGIN'..."
git push $DRY_RUN $PRUNE "$ORIGIN" --tags

# Fast-forward the local checkout if its branch tracks origin and can advance.
current="$(git symbolic-ref --quiet --short HEAD || true)"
if [ -n "$current" ] && [ -z "$DRY_RUN" ]; then
    if upstream_ref="$(git rev-parse --abbrev-ref "$current@{upstream}" 2>/dev/null)"; then
        git fetch "$ORIGIN" >/dev/null 2>&1 || true
        if git merge --ff-only "$upstream_ref" >/dev/null 2>&1; then
            echo "Fast-forwarded '$current' to '$upstream_ref'."
        fi
    fi
fi

echo "Sync complete."
