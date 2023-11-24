#!/bin/bash
# Example: Spread commits across a date range
# Usage: ./spread-commits.sh 2026-03-13 2026-03-24

set -e

START_DATE="${1:-2026-03-13}"
END_DATE="${2:-2026-03-24}"

echo "🔄 lazy-commit: Spreading commits from $START_DATE to $END_DATE"

# Validate dates
START_EPOCH=$(date -d "$START_DATE" +%s 2>/dev/null) || {
  echo "❌ Invalid start date: $START_DATE"
  exit 1
}

END_EPOCH=$(date -d "$END_DATE" +%s 2>/dev/null) || {
  echo "❌ Invalid end date: $END_DATE"
  exit 1
}

if [ $END_EPOCH -le $START_EPOCH ]; then
  echo "❌ End date must be after start date"
  exit 1
fi

# Check if commits are pushed
PUSH_CHECK=$(git rev-list @{u}..HEAD 2>/dev/null | wc -l || echo "0")
if [ "$PUSH_CHECK" -gt 0 ]; then
  echo "❌ Cannot rewrite pushed commits. They exist on remote."
  echo "   If you control this branch, run: git push --force"
  exit 1
fi

# Count commits since main
COMMIT_COUNT=$(git rev-list main..HEAD --count 2>/dev/null || git rev-list HEAD --count)
if [ "$COMMIT_COUNT" -eq 0 ]; then
  echo "❌ No commits found"
  exit 1
fi

SPAN=$((END_EPOCH - START_EPOCH))
SPAN_DAYS=$((SPAN / 86400))

echo "📊 Found $COMMIT_COUNT commits over $SPAN_DAYS days"
echo ""

# Show preview
echo "🔍 Preview (first 3 commits):"
git log --pretty="format:%h %ai %s" -n 3 | while read line; do
  echo "  $line"
done
echo "  ..."
echo ""

# Create temporary Python script for filter-repo callback
CALLBACK_SCRIPT=$(mktemp)
cat > "$CALLBACK_SCRIPT" << 'PYTHON_SCRIPT'
#!/usr/bin/env python3
import os
import sys
from datetime import datetime, timedelta

# Parameters passed by shell
start_epoch = int(os.environ.get('START_EPOCH', 0))
span_seconds = int(os.environ.get('SPAN_SECONDS', 0))
commit_count = int(os.environ.get('COMMIT_COUNT', 0))
commit_index = int(os.environ.get('COMMIT_INDEX', 0))

# Calculate proportional timestamp
if commit_count > 0:
  proportion = commit_index / (commit_count - 1) if commit_count > 1 else 0
  new_timestamp = int(start_epoch + (proportion * span_seconds))
else:
  new_timestamp = start_epoch

# Set environment variables for git filter-repo
os.environ['GIT_AUTHOR_DATE'] = str(new_timestamp)
os.environ['GIT_COMMITTER_DATE'] = str(new_timestamp)

print(f"Commit {commit_index+1}/{commit_count}: {new_timestamp}", file=sys.stderr)
PYTHON_SCRIPT

chmod +x "$CALLBACK_SCRIPT"

# Ask for confirmation
read -p "Proceed with rewriting? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "⚠️  Aborted. No changes made."
  rm -f "$CALLBACK_SCRIPT"
  exit 0
fi

# Run git filter-repo
echo "⏳ Rewriting commits..."
export START_EPOCH
export SPAN_SECONDS=$SPAN
export COMMIT_COUNT

git filter-repo --commit-callback "
import os, sys
start_epoch = int(os.environ.get('START_EPOCH', 0))
span_seconds = int(os.environ.get('SPAN_SECONDS', 0))
commit_count = int(os.environ.get('COMMIT_COUNT', 0))

# This is a simplified callback - in practice, track commit index via environment
proportion = $(git rev-list main..HEAD --count 2>/dev/null || git rev-list HEAD --count) / commit_count if commit_count > 0 else 0
new_timestamp = int(start_epoch + (proportion * span_seconds))

os.environ['GIT_AUTHOR_DATE'] = str(new_timestamp)
os.environ['GIT_COMMITTER_DATE'] = str(new_timestamp)
" 2>&1 | grep -v "^Processed" | grep -v "^WARNING"

echo ""
echo "✅ Complete! Commits rewritten."
echo ""
echo "📝 New timestamps:"
git log --pretty="format:%h %ai %s" -n 3 | while read line; do
  echo "  $line"
done
echo "  ..."
echo ""
echo "💡 Tip: Run \`git push --force\` if you want to update remote (affects collaborators!)"

rm -f "$CALLBACK_SCRIPT"
