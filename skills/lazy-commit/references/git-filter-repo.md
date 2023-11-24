# git filter-repo: Timestamp Rewriting

## How It Works

`git filter-repo` is a powerful git tool for rewriting repository history. For lazy-commit, we use the `--commit-callback` feature to modify commit metadata (author/committer dates) without changing content.

## Key Concepts

### GIT_AUTHOR_DATE vs GIT_COMMITTER_DATE

- **GIT_AUTHOR_DATE**: When the developer originally wrote the code (shows in `git log`)
- **GIT_COMMITTER_DATE**: When the commit was applied to the repository

For lazy-commit, we rewrite both to the same value for consistency.

### Format

Both dates use Unix timestamp format (seconds since 1970-01-01 00:00:00 UTC):

```bash
export GIT_AUTHOR_DATE="1710345600"  # Unix timestamp
export GIT_COMMITTER_DATE="1710345600"
```

Or with timezone offset:

```bash
export GIT_AUTHOR_DATE="2026-03-13 14:30:00 +0000"
```

## git filter-repo Command

Basic syntax for rewriting timestamps:

```bash
git filter-repo --commit-callback '
  # Modify GIT_AUTHOR_DATE and GIT_COMMITTER_DATE here
  # Commit object available as environment variables
'
```

## Calculating Timestamps

### Even Distribution

Spread N commits evenly across (endDate - startDate):

```bash
daysSpan=$(($(date -d "$endDate" +%s) - $(date -d "$startDate" +%s)))
daysSpan=$((daysSpan / 86400))
daysPerCommit=$(echo "scale=2; $daysSpan / $commitCount" | bc)

for i in $(seq 0 $((commitCount - 1))); do
  timestamp=$(date -d "$startDate + $i days" +%s)
  echo "Commit $i: $(date -d @$timestamp)"
done
```

### Weighted by File Changes

Proportion-based distribution:

```bash
totalFiles=$(git log --name-only --pretty="" --all | wc -l)

for commit in commits; do
  filesInCommit=$(git show $commit --name-only --pretty="" | wc -l)
  proportion=$(echo "scale=4; $filesInCommit / $totalFiles" | bc)
  timestampOffset=$(echo "$proportion * $daysSpan * 86400" | bc)
  newTimestamp=$(date -d @$(($(date -d "$startDate" +%s) + timestampOffset)) +%s)
done
```

## Example Command

```bash
#!/bin/bash

START_DATE="2026-03-13"
END_DATE="2026-03-24"
START_EPOCH=$(date -d "$START_DATE" +%s)
END_EPOCH=$(date -d "$END_DATE" +%s)
SPAN=$((END_EPOCH - START_EPOCH))

# Get total commits
COMMIT_COUNT=$(git rev-list --count HEAD)

git filter-repo --commit-callback "
  import os, sys, datetime

  # Parse commit epoch (passed by filter-repo)
  commit_time = int(os.environ.get('COMMIT_TIME', 0))

  # Calculate proportional timestamp
  days_per_commit = $SPAN / $COMMIT_COUNT
  new_time = $START_EPOCH + (os.environ['COMMIT_INDEX'] * days_per_commit)

  # Set environment variables for new dates
  os.environ['GIT_AUTHOR_DATE'] = str(int(new_time))
  os.environ['GIT_COMMITTER_DATE'] = str(int(new_time))
"
```

## Safety: Reversing Changes

If you need to undo timestamp changes:

```bash
# Back up current state first
git reflog

# Check previous state
git log --all --oneline

# Reset to previous reflog entry if needed
git reset --hard @{1}
```

## Installation

```bash
pip install git-filter-repo
```

Or on macOS:

```bash
brew install git-filter-repo
```

## Limitations

- Cannot rewrite pushed commits without force-pushing (affects collaborators)
- Changes entire repository history (all commits, not just selection)
- Requires clean working directory (no staged/unstaged changes)
