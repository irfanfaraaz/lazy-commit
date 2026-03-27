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
6. **Execute rewrite**: Use `git filter-repo --commit-callback` with Python to rewrite timestamps (preserves all content, no diffs changed)
7. **Show results**: Display before/after timestamp comparison with commit hash changes noted

## Safety Guardrails

**Content Protection:**
- ✅ **Preserve ALL content**: No file diffs change, only `GIT_AUTHOR_DATE` and `GIT_COMMITTER_DATE` metadata
- ✅ **No commits deleted**: All commits are rebuilt with new timestamps (new hashes, same content)
- ✅ **Verify tree integrity**: Before rewrite, confirm `git fsck --full` passes
- ✅ **Post-rewrite verification**: After rewrite, run `git fsck --full` again and verify file counts match

**User Protection:**
- ✅ Strict local-only scope: only rewrite commits in `@{u}..HEAD`
- ✅ Refuse if branch is behind upstream (`HEAD..@{u}` non-zero)
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
2. Detect current branch and upstream (`@{u}`)
3. Build rewrite scope from local-only commits: `@{u}..HEAD`
4. **Ask user** (interactive):
   - Confirm commit range: "Rewrite [N] commits? (Y/n)" or "Use different range?"
   - Choose distribution: "Spread evenly (1/day) or weighted by file changes?"
   - Choose time: "Time of day? (default: random 14:00-17:00)"
5. **Preflight guardrails**:
   - Verify not detached: `git symbolic-ref -q --short HEAD`
   - Verify clean working tree: `git status --porcelain` is empty
   - Verify local-only commits exist: `git rev-list @{u}..HEAD --count` > 0
   - Verify not behind upstream: `git rev-list HEAD..@{u} --count` = 0
6. Calculate timestamps:
   - If **evenly**: date1 + (i × daySpan / commitCount) for each commit i
   - If **weighted**: proportion = (filesChanged_i / totalFilesChanged); date1 + (proportion × daySpan) for each commit i
7. Rebuild commits using `git filter-repo --refs "@{u}..HEAD" --commit-callback --force` with Python:
   - Build a timestamp list indexed by commit order: `[b'<ts1> <tz>', b'<ts2> <tz>', ...]`
   - Execute `git filter-repo --commit-callback --force` with Python code that:
     - Uses `sys._callback_counter` for persistent state across callback invocations
     - Assigns bytes to `commit.author_date` and `commit.committer_date` (format: `b'<timestamp> <timezone>'`)
     - Preserves all other commit metadata (message, author name/email, parents, encoding)
   - **Fallback**: If git-filter-repo fails, use `git commit-tree` with environment variables:
     - For each commit in topological order, set `GIT_AUTHOR_DATE="<ts> <tz>"` and `GIT_COMMITTER_DATE="<ts> <tz>"` before invoking `git commit-tree`
     - Rebuild parent chain manually (slightly more complex but no external dependencies)
8. **Integrity checks**:
   - Run `git fsck --full`
   - Ensure rewritten scope commit count is unchanged
9. Show results: before/after timestamps + old→new commit hash mapping

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

- **git filter-repo not installed**:
  ```
  ❌ ERROR: git-filter-repo not found

  `git-filter-repo` is recommended for speed, but not required.
  Use fallback mode (`git commit-tree`) to continue without installing it.

  Install it for your platform:

  📦 macOS (recommended):
     brew install git-filter-repo

  📦 Linux (pip):
     pip install git-filter-repo
     # Or: sudo apt-get install git-filter-repo (Debian/Ubuntu)

  📦 Windows (pip):
     pip install git-filter-repo

  Or continue now with fallback mode.
  ```

- **No local-only commits**: "No unsynced commits found in `@{u}..HEAD`."
- **Branch behind upstream**: "Branch is behind upstream. Pull/rebase first; rewrite is blocked."
- **User declines**: "Aborted. No changes made."
- **Invalid date range**: "End date must be after start date. Please try again."
- **No commits found**: "No commits found in range. Check your branch/date selection."
- **Dirty working directory**: "Your working directory has uncommitted changes. Commit or stash them first."

## References & Examples

See references/git-filter-repo.md for:
- How git filter-repo works
- Understanding GIT_AUTHOR_DATE vs GIT_COMMITTER_DATE
- Reversing changes if needed

See examples/spread-commits.sh for:
- Actual git filter-repo command syntax
- Timestamp calculation logic
- Error handling patterns

## Notes for Claude

**IMPLEMENTATION APPROACH**: Use `git filter-repo --commit-callback` as primary, fallback to `git commit-tree`.

**Primary (git filter-repo)**:
- Industry-standard for history rewriting (10x faster than filter-branch)
- Python callbacks provide fine-grained control over timestamps
- Single-pass processing is efficient for large repositories
- **Key implementation detail**: Use `sys` module for persistent state across callback invocations (local variables don't persist)
- **Format**: Assign bytes directly: `commit.author_date = b'<timestamp> <+timezone>'` (e.g., `b'1772353800 +0000'`)
- Callback body only (no `def callback(commit):` wrapper—git-filter-repo adds that automatically)
- Use partial-scope rewrite (`--refs "@{u}..HEAD"`) for strict local-only behavior
- **Important**: Include `--force` flag; both `--refs` and `--partial` automatically preserve the origin remote (confirmed by maintainer: github.com/newren/git-filter-repo/issues/46)

**Fallback (git commit-tree)**:
- Lower-level but reliable approach
- No external dependencies beyond git
- Works if git-filter-repo fails or isn't installed
- Rebuilds commits manually with timestamp environment variables
- **Format**: Environment variables must include timezone: `GIT_AUTHOR_DATE="<timestamp> <+timezone>"` (e.g., `"1772353800 +0000"`)
- Requires manual parent chain management but proven stable

**Critical**: Both approaches rebuild commits (new hashes) but preserve ALL content—no file diffs change.

**BEFORE PROCEEDING**: Verify dependencies:
- `git --version` (required for both)
- `git filter-repo --version` (required for primary; missing triggers fallback)

- Always confirm dates with user (parse flexible formats: "March 13", "3/13", "2026-03-13")
- Time preference should default to random 14:00-17:00 if user doesn't specify
- Emphasize that **only timestamps change**, file content is 100% identical (zero diff changes)
- Note to user: "New commit hashes will be generated, but all code/diffs remain unchanged"
- If commits are pushed, be clear: rewriting after push requires force-pushing and affects collaborators
- Show commit hashes and subjects so user can verify they're rewriting the right commits
- Check for dirty working directory before proceeding (uncommitted changes must be stashed/committed)
- After rewrite, show old→new commit hash mapping so user understands the history rewrite
