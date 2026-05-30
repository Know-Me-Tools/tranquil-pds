# GitHub Mirror Setup

This GitHub repo (`Know-Me-Tools/tranquil-pds`) is a **mirror** of the upstream
project hosted on tangled.org. Upstream is the source of truth; this repo tracks it.

## Remotes

| Remote     | URL                                                  | Role            |
|------------|------------------------------------------------------|-----------------|
| `origin`   | `git@github.com:Know-Me-Tools/tranquil-pds.git`      | GitHub mirror   |
| `upstream` | `https://tangled.org/tranquil.farm/tranquil-pds`     | Source of truth |

If a fresh clone is missing `upstream`, add it:

```bash
git remote add upstream https://tangled.org/tranquil.farm/tranquil-pds
```

## Branch layout

- **`main`** — a *pure mirror* of upstream's `main`. It carries **no local commits**,
  so syncing it is always a clean `git merge --ff-only` (no rebases, no force-pushes).
  Do **not** commit project tooling or any local-only work to `main`.
- **`tooling`** — a permanent branch that holds the mirror tooling itself
  (`scripts/sync-upstream.sh`, the `just sync-upstream` recipe, and this file).
  Kept off `main` so it can never pollute the mirror. Make tooling changes here.
- All other upstream branches and tags are mirrored as-is.

## Syncing from upstream

A self-contained git alias does the whole job and works from any branch
(it lives in local `.git/config`, so it does not depend on checked-out files):

```bash
git sync-upstream            # fetch upstream, mirror all branches + tags to origin,
                             # then ff-update the current branch if it tracks origin
git sync-upstream --dry-run  # preview only, push nothing
git sync-upstream --prune    # also delete tags on origin that were removed upstream
```

Equivalent file-based entry points (only available when the `tooling` branch is
checked out):

```bash
just sync-upstream [--dry-run|--prune]
./scripts/sync-upstream.sh [--dry-run|--prune]
```

### Re-creating the `git sync-upstream` alias

The alias is machine-local (stored in `.git/config`, not version-controlled).
On a fresh clone, recreate it by running the script form once, or re-add the
alias. The simplest portable alias just calls the committed script from the
`tooling` branch:

```bash
git config alias.sync-upstream \
  '!sh -c "$(git rev-parse --show-toplevel)/scripts/sync-upstream.sh \"$@\"" --'
```

(That form requires the `tooling` branch — or a worktree of it — to be checked
out so the script is on disk. The fully self-contained inline alias used on the
maintainer's machine does not require the script file; see the project notes if
you need it.)

## Why this design

Keeping `main` free of local commits means GitHub's `main` is always a strict
ancestor of upstream's `main`. That preserves `--ff-only` syncing forever and
avoids ever force-pushing `main`. The cost is that the tooling lives on a
separate branch instead of `main` — a deliberate trade.
