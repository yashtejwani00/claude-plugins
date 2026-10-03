#!/usr/bin/env bash
# Create (or find) the ticket branch and a sibling worktree in rn-app and rn-api.
# Usage: ticket-worktrees.sh ENG-123 "Jira summary" [base-branch]
#   base-branch: a story's parent branch. A repo that has no such branch uses main / master.
# Safe to re-run: existing worktrees and branches are reused, nothing is pushed.
set -euo pipefail

KEY=$1
SUMMARY=$2
BASE_OVERRIDE=${3:-}
ROOT=${RENIT_ROOT:-/Users/zineone/git/renit}

# Same shape Jira's "Create branch" gives: key + summary, punctuation and spaces become hyphens.
slug=$(printf '%s' "$SUMMARY" | LC_ALL=C sed -E 's/[^A-Za-z0-9]+/-/g; s/^-+|-+$//g')
suffix=$(printf '%s' "$KEY" | tr 'A-Z' 'a-z' | tr -d '-')

# Both repos get the same branch name. A branch for this key may already exist in
# either one under Jira's own spelling; reuse that rather than invent a second name.
branch=
for repo in rn-app rn-api; do
  git -C "$ROOT/$repo" fetch -q --prune origin
  [ -n "$branch" ] || branch=$(git -C "$ROOT/$repo" for-each-ref --format='%(refname:short)' \
    "refs/heads/$KEY-*" "refs/remotes/origin/$KEY-*" | sed 's#^origin/##' | head -1)
done
branch=${branch:-$KEY-$slug}

for pair in rn-app:main rn-api:master; do
  repo=${pair%%:*}
  base=${pair##*:}
  src=$ROOT/$repo
  wt=$ROOT/$repo-$suffix
  # A story's parent branch often exists in only one repo; the other starts from its default.
  if [ -n "$BASE_OVERRIDE" ] && git -C "$src" show-ref -q --verify "refs/remotes/origin/$BASE_OVERRIDE"; then
    base=$BASE_OVERRIDE
  fi

  if [ -d "$wt" ]; then
    state=existing
  elif git -C "$src" show-ref -q --verify "refs/heads/$branch"; then
    git -C "$src" worktree add -q "$wt" "$branch"; state=reused-local-branch
  elif git -C "$src" show-ref -q --verify "refs/remotes/origin/$branch"; then
    git -C "$src" worktree add -q -b "$branch" "$wt" "origin/$branch"; state=reused-remote-branch
  else
    git -C "$src" worktree add -q --no-track -b "$branch" "$wt" "origin/$base"; state="new-from-origin/$base"
  fi
  echo "$repo  $wt  $branch  ($state)"
done

# The app worktree needs its git-ignored pieces to run Metro. node_modules is an
# APFS clone (instant, no extra disk) and only valid while the lockfiles match.
app=$ROOT/rn-app
wt=$ROOT/rn-app-$suffix
for f in config/environments/qa.env config/environments/qa-test-accounts.local.json; do
  [ -f "$app/$f" ] && [ ! -f "$wt/$f" ] && cp "$app/$f" "$wt/$f"
done
if [ ! -d "$wt/node_modules" ]; then
  if cmp -s "$app/package-lock.json" "$wt/package-lock.json" && [ -d "$app/node_modules" ]; then
    cp -cR "$app/node_modules" "$wt/node_modules" && echo "rn-app  node_modules cloned"
  else
    echo "rn-app  lockfile differs from $app: run 'npm ci' in $wt"
  fi
fi
