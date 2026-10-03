#!/usr/bin/env bash
# Deploy an rn-api branch to the one shared QA stack, under a ticket lock.
# Usage: qa-deploy.sh ENG-123 <branch> [--release] [--dry-run]
#   --release  drop the lock after deploying (use with master, after the PR merges)
#   --dry-run  run every check, change nothing
# The branch must already be pushed. Exit codes:
#   3 another ticket holds QA   4 server checkout has local edits
#   5 QA is running commits this branch does not have
#   6 container is not running the checkout, or web never came up
# ponytail: one global lock, so tickets with backend changes test one at a time.
# Move to a stack per ticket if they start queueing.
set -euo pipefail

KEY=$1
BRANCH=$2
shift 2
RELEASE=0 DRY=0
for a in "$@"; do
  case $a in
    --release) RELEASE=1 ;;
    --dry-run) DRY=1 ;;
    *) echo "unknown option $a" >&2; exit 2 ;;
  esac
done

ssh -o ConnectTimeout=10 "${RENIT_QA_SSH:-yash_ubuntu}" \
  "KEY='$KEY' BRANCH='$BRANCH' RELEASE=$RELEASE DRY=$DRY bash -s" <<'REMOTE'
set -euo pipefail
cd /home/yash/git/personal/rn-api
LOCK=$HOME/.renit-qa-deploy.lock

owner=$(cat "$LOCK" 2>/dev/null || true)
if [ -n "$owner" ] && [ "$owner" != "$KEY" ]; then
  echo "LOCKED: QA is held by $owner (running $(git branch --show-current))"; exit 3
fi
[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "DIRTY: the server checkout has local edits"; exit 4; }

git fetch -q origin "$BRANCH" master
prev=$(git rev-parse HEAD)
# If we did not already hold QA, whatever is running belongs to someone else.
# Refuse to roll it back: the QA database keeps their migrations either way.
# rn-api is squash-only, so a merged branch is never an ancestor of master.
# QA running the same code as master is also safe, but only for a branch that
# itself contains master - a branch cut from an older master would roll QA back.
safe=0
git merge-base --is-ancestor "$prev" "origin/$BRANCH" && safe=1
git diff --quiet "$prev" origin/master && git merge-base --is-ancestor origin/master "origin/$BRANCH" && safe=1
if [ "$owner" != "$KEY" ] && [ "$safe" = 0 ]; then
  echo "BEHIND: QA runs $(git branch --show-current) @ ${prev:0:7}, which is not in $BRANCH."
  echo "Merge or rebase onto it, or get an explicit OK to roll QA back."
  exit 5
fi

if [ "$DRY" = 1 ]; then
  echo "DRY RUN ok: would deploy $BRANCH @ $(git rev-parse --short "origin/$BRANCH") over ${prev:0:7}"; exit 0
fi

# noclobber makes taking the lock atomic against a second session.
( set -C; echo "$KEY" > "$LOCK" ) 2>/dev/null || [ "$(cat "$LOCK")" = "$KEY" ] || { echo "LOCKED: lost the race for QA"; exit 3; }

git checkout -q "$BRANCH" 2>/dev/null || git checkout -q -b "$BRANCH" "origin/$BRANCH"
git merge -q --ff-only "origin/$BRANCH"

export APP_ENV_FILE=config/environments/qa.env
docker compose --env-file "$APP_ENV_FILE" -f docker-compose.server.yml up -d --build web 2>&1 | tail -3

# A clean checkout is not proof of what the container runs: compare the code itself.
sums() { xargs sha1sum | sha1sum | cut -d' ' -f1; }
want=$(git ls-files 'src/*.py' | sort | sums)
web=$(docker compose --env-file "$APP_ENV_FILE" -f docker-compose.server.yml ps -q web)
got=$(git ls-files 'src/*.py' | sort | sed 's#^#/app/#' | docker exec -i "$web" sh -c 'xargs sha1sum' | sed 's#  /app/#  #' | sha1sum | cut -d' ' -f1)
[ "$want" = "$got" ] || { echo "MISMATCH: the container is not running the checked-out code"; exit 6; }

# migrate runs in the container's start command; wait for the server to answer.
for i in $(seq 1 30); do
  docker exec "$web" python -c "import socket; socket.create_connection(('localhost', 8000), 3)" 2>/dev/null && up=1 && break
  sleep 4
done
[ "${up:-0}" = 1 ] || { echo "DOWN: web did not answer in 2 minutes"; docker logs --tail 40 "$web"; exit 6; }

[ "$RELEASE" = 1 ] && rm -f "$LOCK"
echo "DEPLOYED $BRANCH @ $(git rev-parse --short HEAD); lock: $([ "$RELEASE" = 1 ] && echo released || echo "$KEY")"
REMOTE
