---
name: lazy-commit
description: Spread git commit timestamps retroactively to visualize steady work progress over time instead of compressed bursts.
tags:
  - git
  - workflow
  - timeline
  - timestamps
  - collaboration
---

# lazy-commit

When a developer completes meaningful work in an intensive burst but wants to show it as steady progress to stakeholders, they need to rewrite commit timestamps retroactively.

The lazy-commit skill allows developers to spread commits across a date range without changing diffs or content—only timestamps change. Git history now shows gradual progress.

## Trigger Phrases

Users will invoke this skill with requests like:

- "Spread my commits from March 13 to March 24"
- "I want to rewrite my timestamps across 2 weeks"
- "Make my commits look like they were done over time"
- "Spread these commits over a date range"
- "/lazy-commit spread"

## What This Skill Does

1. **Detect branch and commits**: Asks user which commits to rewrite (all since main, or custom range)
2. **Ask about distribution**: How should commits be spaced? (evenly or weighted by file changes)
3. **Ask about time**: What time of day should commits be timestamped? (default: random afternoon 14:00-17:00)
4. **Show preview**: List commits that will be rewritten with calculated new timestamps
5. **Get confirmation**: Require explicit yes before proceeding
6. **Execute rewrite**: Use `git filter-repo` to rewrite `GIT_AUTHOR_DATE` and `GIT_COMMITTER_DATE`
7. **Show results**: Display before/after timestamp comparison

## Safety Guardrails

- ✅ Refuse if commits are already pushed to remote (will show error with instructions)
- ✅ Require explicit confirmation before rewriting
- ✅ Show exact commits and timestamps before applying
- ✅ Preserve all content (only dates change)

## Implementation Steps

1. Parse user's request for start and end dates
2. Detect current git branch and its merge-base with main
3. List commits between merge-base and HEAD
4. **Ask user** (interactive):
   - Confirm commit range: "Rewrite [N] commits? (Y/n)" or "Use different range?"
   - Choose distribution: "Spread evenly (1/day) or weighted by file changes?"
   - Choose time: "Time of day? (default: random 14:00-17:00)"
5. Check if commits are pushed: `git rev-list @{u}..HEAD` (if non-zero, refuse)
6. Calculate timestamps:
   - If **evenly**: date1 + (i × daySpan / commitCount) for each commit i
   - If **weighted**: proportion = (filesChanged_i / totalFilesChanged); date1 + (proportion × daySpan) for each commit i
7. Generate git filter-repo command with timestamp callback
8. Execute `git filter-repo --commit-callback` with calculated dates
9. Show results: before/after timestamps for first/last 3 commits

## Input/Output

**Input**: Natural language request with optional start/end dates
- "Spread from March 13 to 27"
- "Rewrite my commits across 2 weeks"
- "Timeline from 3/13 to 3/24"

**Output**:
- Interactive prompts for missing information
- Preview of commits to be rewritten
- Confirmation prompt
- Execution summary (success/error)
- Before/after timestamp comparison

## Error Handling

- **git filter-repo not installed** (CRITICAL):
  ```
  ❌ ERROR: git-filter-repo not found

  This tool is required to rewrite git commit timestamps.

  Install it for your platform:

  📦 macOS (recommended):
     brew install git-filter-repo

  📦 Linux (pip):
     pip install git-filter-repo
     # Or: sudo apt-get install git-filter-repo (Debian/Ubuntu)

  📦 Windows (pip):
     pip install git-filter-repo

  Then run the skill again.
  ```

- **Commits already pushed**: Show error: "Cannot rewrite pushed commits. Run `git push --force` only if you control this branch."
- **User declines**: "Aborted. No changes made."
- **Invalid date range**: "End date must be after start date. Please try again."
- **No commits found**: "No commits found in range. Check your branch/date selection."
- **Dirty working directory**: "Your working directory has uncommitted changes. Commit or stash them first."

## References & Examples

See references/git-filter-repo.md for:
- How git filter-repo works
- Understanding GIT_AUTHOR_DATE vs GIT_COMMITTER_DATE
- Reversing changes if needed

See examples/sample-spread.sh for:
- Actual git filter-repo command syntax
- Timestamp calculation logic
- Error handling patterns

## Notes for Claude

**BEFORE PROCEEDING**: Check if git-filter-repo is installed by running `which git-filter-repo` or `git filter-repo --version`. If not found, show the installation error (see Error Handling section) and stop.

- Always confirm dates with user (parse flexible formats: "March 13", "3/13", "2026-03-13")
- Time preference should default to random 14:00-17:00 if user doesn't specify
- Emphasize that **only timestamps change**, not code
- If commits are pushed, be clear: rewriting after push requires force-pushing and affects collaborators
- Show commit hashes and subjects so user can verify they're rewriting the right commits
- Check for dirty working directory before proceeding (uncommitted changes must be stashed/committed)
