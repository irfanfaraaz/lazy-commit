# lazy-commit Plugin Development Guide

## Project Overview

**lazy-commit** is a Claude Code plugin that spreads git commit timestamps retroactively to visualize work progress over time.

**Problem:** Work completed in one intensive burst (e.g., 1 day) appears compressed in git history, missing the narrative of gradual progress.

**Solution:** Use `/lazy-commit spread` to rewrite commit timestamps across a date range, showing steady progress without changing content.

## Plugin Structure

```
lazy-commit/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── skills/
│   └── lazy-commit/
│       ├── SKILL.md              # /lazy-commit spread skill
│       ├── examples/
│       │   └── spread-commits.sh # Bash implementation reference
│       └── references/
│           └── git-filter-repo.md # Technical documentation
├── LICENSE                        # MIT License
├── README.md                      # User documentation
├── CHANGELOG.md                   # Version history
├── DEVELOPMENT.md                 # Architecture & testing guide
└── CLAUDE.md                      # This file
```

## Installation for Development

### Local Testing
```bash
cd lazy-commit
claude --plugin-dir .
```

### Distribution
```bash
git clone https://github.com/irfanfaraaz/lazy-commit.git ~/.claude/plugins/lazy-commit
```

## Key Files

| File | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | Plugin metadata (name, version, author) |
| `skills/lazy-commit/SKILL.md` | Main user-facing skill definition |
| `README.md` | User documentation with examples |
| `DEVELOPMENT.md` | Architecture, testing, and maintenance |
| `CHANGELOG.md` | Release notes and version history |

## How to Test

1. Ensure `git-filter-repo` is installed:
   ```bash
   brew install git-filter-repo  # macOS
   pip install git-filter-repo   # Linux/Windows
   ```

2. Create a test repository:
   ```bash
   mkdir /tmp/test-lazy && cd /tmp/test-lazy
   git init && git checkout -b main
   ```

3. Add test commits:
   ```bash
   touch file1.txt && git add . && git commit -m "First"
   touch file2.txt && git add . && git commit -m "Second"
   ```

4. Invoke the skill:
   ```
   /lazy-commit spread from March 13 to March 15
   ```

5. Verify:
   ```bash
   git log --format="%h %ai %s"
   ```

## Skill: `/lazy-commit spread`

### Invocation
```
/lazy-commit spread my commits from March 13 to March 24
```

### Workflow
1. Parse start/end dates from user input
2. Detect current branch and commits since main (or custom base)
3. Prompt for distribution strategy (even or weighted)
4. Prompt for time-of-day preference
5. Show preview of commits to rewrite
6. Require confirmation
7. Execute `git filter-repo` with calculated timestamps
8. Display before/after comparison

### Safety
- Refuses on pushed commits (no force-push surprise)
- Requires explicit confirmation
- Shows all commits before rewriting
- Stores original dates for reference

## Future Enhancements (Phase 2+)

### Commands
- `/lazy-commit audit` — List modified commits
- `/lazy-commit undo` — Restore original timestamps
- `/lazy-commit reset` — Clear all modifications

### Features
- Custom time-of-day patterns (e.g., work hours simulation)
- Selective commit filtering (by message/file pattern)
- Export/import timestamp configurations
- Integration with `.claude/.lazy-commits.json` tracking

## Dependencies

- **Git** (any recent version)
- **git-filter-repo** (required separately)
- **Claude Code** (any recent version)

## License

MIT — See LICENSE file

## Contributing

Submit issues and PRs to: https://github.com/irfanfaraaz/lazy-commit
