# lazy-commit Plugin

**Spread git commit timestamps retroactively to visualize steady work progress.**

## Problem

You complete meaningful work in one intensive burst (e.g., 1 day), but git history shows everything compressed into a single day. When communicating progress to stakeholders, it looks like you did 2 weeks of work in 24 hours—missing the narrative of gradual progress.

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
- ✅ Safety guardrails (refuse if pushed, require confirmation)
- ✅ Interactive prompt (asks for time-of-day preference)

## Usage

Simply ask Claude:

```
/lazy-commit spread my commits from March 13 to March 24
```

Claude will:
1. Detect current branch and commits since main
2. Ask if you want to select commits differently
3. Ask how to distribute timestamps (evenly or weighted by file changes)
4. Ask for time-of-day preference (default: random afternoon)
5. Show commits that will be rewritten
6. Require confirmation before applying changes
7. Execute `git filter-repo` with calculated timestamps
8. Display before/after comparison

## Prerequisites

- **Git** (any recent version)
- **git-filter-repo** (required separately — see installation below)
- **Claude Code** (any recent version)

### Installing git-filter-repo

**macOS** (recommended):
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

**Verify installation**:
```bash
git filter-repo --version
```

## Installation

### Recommended: Via Claude Code Plugin Manager

```
/plugin marketplace add https://github.com/irfanfaraaz/lazy-commit
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

The skill uses `git filter-repo` to rewrite commit metadata:
- `GIT_AUTHOR_DATE`: When the commit was authored
- `GIT_COMMITTER_DATE`: When the commit was applied

No diffs or content is changed—only timestamps.

## Safety

- **Refuses on pushed branches**: Won't rewrite if commits exist on remote
- **Requires confirmation**: Shows preview before applying
- **Backs up metadata**: Stores original dates for reference
- **Reversible**: Original commits can be restored if needed

## Future Enhancements

- `/lazy-commit audit` — Review which commits have been rewritten
- `/lazy-commit undo` — Restore original timestamps
- `/lazy-commit reset` — Clear all rewritten dates
- Support for custom time-of-day patterns

## License

MIT
