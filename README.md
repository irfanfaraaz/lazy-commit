# lazy-commit Plugin

**Spread git commit timestamps retroactively to visualize steady work progress.**

## Problem

Sometimes you finish 2 weeks of work in one intense day, but you do not want your Git history to make it obvious.
Maybe you want a little breathing room before sharing the final update. Maybe you want to show progress phase by phase instead of dumping everything at once. The issue is that even if you worked through the task in logical steps, Git still shows all the commits packed into a single day.
When managers or stakeholders check the history, it can look like the whole thing was already done long before you communicated it. This compressed timeline can mislead them into thinking the work was simpler or faster than it actually was, causing them to underestimate future similar tasks and set unrealistic expectations.

## Solution

After work is complete, use the `/lazy-commit spread` skill to rewrite commit timestamps across a date range. Git history will now show steady progress over the specified timeline.

**Example:**
- Work completed: March 13 (1 day)
- Commits: 11 total
- Run: `/lazy-commit spread --start 2026-03-13 --end 2026-03-24`
- Result: Commits timestamped March 13-24, showing 2 weeks of steady progress

## Features

- ✅ Retroactive timestamp rewriting (no content changes)
- ✅ Flexible commit selection (since branch point or custom hash)
- ✅ Multiple spacing strategies (even distribution or weighted by work)
- ✅ Safety guardrails (strict local-only scope + preflight checks)
- ✅ Interactive prompt (asks for time-of-day preference)

## Usage

Simply ask Claude:

```
/lazy-commit spread my commits from March 13 to March 24
```

Claude will:
1. Detect current branch and local-only commits (`@{u}..HEAD`)
2. Ask if you want to select commits differently
3. Ask how to distribute timestamps (evenly or weighted by file changes)
4. Ask for time-of-day preference (default: random afternoon)
5. Run preflight guardrails (clean tree, not behind upstream, unsynced commits exist)
6. Show commits that will be rewritten
7. Require confirmation before applying changes
8. Rewrite commits using `git filter-repo` (with `git commit-tree` fallback) with calculated timestamps
9. Display before/after comparison

## Prerequisites

- **Git** (any recent version)
- **Claude Code** (any recent version)
- **git-filter-repo** (recommended for optimal performance, optional with git-based fallback)

### Installing git-filter-repo (Optional)

For best performance, install git-filter-repo:

**macOS**:
```bash
brew install git-filter-repo
```

**Linux**:
```bash
pip install git-filter-repo
# Or (Debian/Ubuntu):
sudo apt-get install git-filter-repo
```

**Windows**:
```bash
pip install git-filter-repo
```

**Note**: If git-filter-repo is not installed, the plugin will automatically fall back to a git-based approach using `git commit-tree`.

## Installation

### Recommended: Via Claude Code Plugin Manager

```
/plugin marketplace add irfanfaraaz/lazy-commit
/plugin install lazy-commit
```

Then invoke the skill:
```
/lazy-commit spread my commits from March 13 to March 24
```

### Alternative: Manual Git Clone

```bash
git clone https://github.com/irfanfaraaz/lazy-commit.git ~/.claude/plugins/lazy-commit
```

## How It Works

The skill uses **`git filter-repo --commit-callback`** (industry standard, 10x faster) with an automatic fallback to **`git commit-tree`** (git-native, no dependencies):

**Primary approach (git filter-repo)**:
- Python callbacks for fine-grained timestamp control
- Single-pass processing for large repositories
- `GIT_AUTHOR_DATE` and `GIT_COMMITTER_DATE` precision

**Fallback approach (git commit-tree)**:
- Rebuilt commits with timestamp environment variables
- Works even if git-filter-repo is not installed
- Equally reliable, slightly slower

**Safety guarantees (both approaches)**:
- No content changes—only timestamps are modified
- Tree hashes stay identical (no diffs change)
- Commits are never deleted, only rebuilt with new identities
- All metadata (author, message, parents) is preserved exactly

## Safety

- **Strict local-only scope**: Rewrites only unsynced commits (`@{u}..HEAD`)
- **Refuses when behind upstream**: Won't rewrite if local branch is behind remote
- **Requires confirmation**: Shows preview before applying
- **Reversible**: Original commits can be restored if needed

## Future Enhancements

- `/lazy-commit audit` — Review which commits have been rewritten
- `/lazy-commit undo` — Restore original timestamps
- `/lazy-commit reset` — Clear all rewritten dates
- Support for custom time-of-day patterns

## License

MIT
