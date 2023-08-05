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
6. **Execute rewrite**: Use `git commit-tree` to rebuild commits with new timestamps (preserves all content, no diffs changed)
7. **Show results**: Display before/after timestamp comparison with commit hash changes noted

## Safety Guardrails

**Content Protection:**
- ✅ **Preserve ALL content**: No file diffs change, only `GIT_AUTHOR_DATE` and `GIT_COMMITTER_DATE` metadata
- ✅ **No commits deleted**: All commits are rebuilt with new timestamps (new hashes, same content)
- ✅ **Verify tree integrity**: Before rewrite, confirm `git fsck --full` passes
- ✅ **Post-rewrite verification**: After rewrite, run `git fsck --full` again and verify file counts match

**User Protection:**
- ✅ Refuse if commits are already pushed to remote (will show error with instructions)
- ✅ Require explicit confirmation before rewriting
- ✅ Show exact commits and timestamps before applying
- ✅ Display old→new commit hash mapping after rewrite
- ✅ Check for dirty working directory (uncommitted changes must be stashed first)

**Data Integrity:**
- ✅ Preserve commit messages (no truncation/modification)
- ✅ Preserve author name and email (only dates change)
- ✅ Preserve commit parents (ancestry chain intact)
- ✅ Preserve file permissions and modes

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
7. Rebuild commits using `git commit-tree`:
   - For each commit in order:
     - Set `GIT_AUTHOR_DATE` and `GIT_COMMITTER_DATE` environment variables
     - Execute `git commit-tree <tree> -p <parent> -m "<message>"`
     - Capture new commit hash
   - Update branch ref to point to final rebuilt commit
8. Show results: before/after timestamps with old→new commit hash mapping

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

**IMPLEMENTATION APPROACH**: Use `git commit-tree` instead of `git filter-repo`. Why?
- `git commit-tree` is the lowest-level git command that directly creates commit objects
- It guarantees timestamp control via `GIT_AUTHOR_DATE`/`GIT_COMMITTER_DATE` environment variables
- Higher-level tools (git filter-repo, git rebase) have limitations for timestamp-only rewrites
- **Critical**: This approach rebuilds commits (new hashes) but preserves ALL content—no file diffs change

**BEFORE PROCEEDING**: Verify git is available and working (`git --version`).

- Always confirm dates with user (parse flexible formats: "March 13", "3/13", "2026-03-13")
- Time preference should default to random 14:00-17:00 if user doesn't specify
- Emphasize that **only timestamps change**, file content is 100% identical (zero diff changes)
- Note to user: "New commit hashes will be generated, but all code/diffs remain unchanged"
- If commits are pushed, be clear: rewriting after push requires force-pushing and affects collaborators
- Show commit hashes and subjects so user can verify they're rewriting the right commits
- Check for dirty working directory before proceeding (uncommitted changes must be stashed/committed)
- After rewrite, show old→new commit hash mapping so user understands the history rewrite
