#!/usr/bin/env bash
# Example: spread local-only commits across a date range with guardrails
# Usage: ./spread-commits.sh 2026-03-13 2026-03-24

set -euo pipefail

START_DATE="${1:-2026-03-13}"
END_DATE="${2:-2026-03-24}"
TZ_OFFSET="${TZ_OFFSET:-+0000}"

to_epoch() {
  local input="$1"
  if date -j -f "%Y-%m-%d" "$input" "+%s" >/dev/null 2>&1; then
    date -j -f "%Y-%m-%d" "$input" "+%s"
  else
    date -d "$input" "+%s"
  fi
}

require_clean_tree() {
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "❌ Working tree is dirty. Commit or stash changes first."
    exit 1
  fi
}

if [[ -z "$(git symbolic-ref -q --short HEAD || true)" ]]; then
  echo "❌ Detached HEAD is not supported."
  exit 1
fi

START_EPOCH="$(to_epoch "$START_DATE")" || { echo "❌ Invalid start date: $START_DATE"; exit 1; }
END_EPOCH="$(to_epoch "$END_DATE")" || { echo "❌ Invalid end date: $END_DATE"; exit 1; }
if (( END_EPOCH <= START_EPOCH )); then
  echo "❌ End date must be after start date."
  exit 1
fi

require_clean_tree
git rev-parse --verify "@{u}" >/dev/null 2>&1 || { echo "❌ Upstream is required for strict local-only mode."; exit 1; }

LOCAL_ONLY_COUNT="$(git rev-list --count @{u}..HEAD)"
BEHIND_COUNT="$(git rev-list --count HEAD..@{u})"
if (( LOCAL_ONLY_COUNT == 0 )); then
  echo "❌ No unsynced commits in @{u}..HEAD."
  exit 1
fi
if (( BEHIND_COUNT > 0 )); then
  echo "❌ Branch is behind upstream. Pull/rebase first."
  exit 1
fi

echo "🔍 Rewriting $LOCAL_ONLY_COUNT commit(s) from @{u}..HEAD"
git log --reverse --pretty="format:%H %h %s" @{u}..HEAD

read -r -p "Proceed with timestamp rewrite? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "⚠️ Aborted. No changes made."
  exit 0
fi

SPAN_SECONDS=$((END_EPOCH - START_EPOCH))
export START_EPOCH SPAN_SECONDS LOCAL_ONLY_COUNT TZ_OFFSET

git filter-repo --force --refs "@{u}..HEAD" --commit-callback '
import os, sys
if not hasattr(sys, "_lazy_counter"):
    sys._lazy_counter = 0
count = int(os.environ["LOCAL_ONLY_COUNT"])
start = int(os.environ["START_EPOCH"])
span = int(os.environ["SPAN_SECONDS"])
tz = os.environ["TZ_OFFSET"]
idx = sys._lazy_counter
portion = (idx / (count - 1)) if count > 1 else 0
new_ts = int(start + (portion * span))
stamp = f"{new_ts} {tz}".encode("ascii")
commit.author_date = stamp
commit.committer_date = stamp
sys._lazy_counter += 1
'

echo "✅ Rewrite complete."
echo "🚀 Next: git push --force-with-lease"
