# Development Guide: lazy-commit Plugin

## Architecture

The lazy-commit plugin is a single-skill workflow tool that uses git commit timestamp rewriting to spread work across dates retroactively.

### Implementation Approaches

Three tested methods for rewriting commit timestamps (in order of preference):

#### 1. PRIMARY: git filter-repo --commit-callback
- **Status**: ✅ Proven working
- **Speed**: Fast (single pass, 10x faster than filter-branch)
- **Format**: Python callback with bytes assignment
- **Key detail**: Use `sys._callback_counter` for persistent state across invocations
- **Code**:
  ```python
  import sys
  if not hasattr(sys, '_callback_counter'):
      sys._callback_counter = 0
  if sys._callback_counter < len(timestamps):
      commit.author_date = f"{timestamps[sys._callback_counter]}".encode()
      commit.committer_date = f"{timestamps[sys._callback_counter]}".encode()
      sys._callback_counter += 1
  ```
- **Dependencies**: Requires `git filter-repo` (optional, has fallback)

#### 2. SECONDARY: git commit-tree
- **Status**: ✅ Proven working
- **Speed**: Slower (manual per-commit rebuild)
- **Format**: Environment variables with timezone
- **Key detail**: Must include timezone in format: `"<timestamp> <+timezone>"`
- **Code**:
  ```bash
  GIT_AUTHOR_DATE="1772353800 +0000" GIT_COMMITTER_DATE="1772353800 +0000" \
    git commit-tree <tree> -p <parent> -m "<message>"
  ```
- **Dependencies**: None (pure git)
- **Use case**: When git-filter-repo not available

#### 3. TERTIARY: git fast-export/fast-import
- **Status**: ✅ Proven working
- **Speed**: Medium
- **Format**: Stream-based modification
- **Key detail**: Parse export stream, modify author_date/committer_date lines, re-import
- **Dependencies**: None (pure git)
- **Use case**: Most robust for edge cases

### Components

| Component | Location | Purpose |
|-----------|----------|---------|
| Skill | `skills/lazy-commit/SKILL.md` | Main user-facing skill for spreading commits |
| Reference | `skills/lazy-commit/references/git-filter-repo.md` | Technical documentation on git-filter-repo |
| Example | `skills/lazy-commit/examples/spread-commits.sh` | Working bash implementation |
| Manifest | `.claude-plugin/plugin.json` | Plugin metadata and version |

### Data Flow

```
User asks: "Spread my commits from March 13 to 24"
↓
Skill prompts for missing info (dates, distribution strategy, time preference)
↓
Skill calculates timestamps (evenly or weighted)
↓
Skill shows preview of commits to be rewritten
↓
Skill gets confirmation
↓
Skill executes git filter-repo with calculated dates
↓
Skill shows before/after comparison
```

## Future Enhancements

### Phase 2: Extended Commands
- `/lazy-commit audit` — List which commits have been modified
- `/lazy-commit undo` — Restore original timestamps
- `/lazy-commit reset` — Clear all timestamp modifications

### Phase 3: Advanced Features
- Time-of-day patterns (e.g., staggered work hours)
- Selective commit filtering (only commits matching a pattern)
- Export/import of timestamp configurations
- Integration with `.claude/.lazy-commits.json` for tracking

## Testing

### Manual Testing Checklist

1. **Installation**:
   ```bash
   git clone <repo> ~/.claude-plugins/lazy-commit
   cc --reload-plugins
   ```

2. **Invoke skill**:
   ```
   /lazy-commit spread my commits from March 13 to 24
   ```

3. **Verify prompts**:
   - [ ] User asked for start/end dates (if not specified)
   - [ ] User asked for distribution strategy
   - [ ] User asked for time-of-day preference
   - [ ] Preview shows commits to be rewritten
   - [ ] Confirmation required before proceeding

4. **Verify safety**:
   - [ ] Refuses if commits are pushed
   - [ ] Shows error messages clearly
   - [ ] Requires confirmation
   - [ ] No changes if user declines

5. **Verify execution**:
   - [ ] Primary method (git filter-repo) attempts to run
   - [ ] If git-filter-repo unavailable, falls back to git commit-tree
   - [ ] Tertiary method (git fast-export) available as last resort
   - [ ] Timestamps updated in git log (verify with `git log --format="%ai"`)
   - [ ] Commit content unchanged (git diff main shows nothing)
   - [ ] Commit hashes changed (expected, since timestamps are part of commit object)

## Local Testing

```bash
# Test in a temporary git repo
mkdir /tmp/test-lazy-commit
cd /tmp/test-lazy-commit
git init

# Create some test commits
touch file1.txt && git add . && git commit -m "First commit"
touch file2.txt && git add . && git commit -m "Second commit"
touch file3.txt && git add . && git commit -m "Third commit"

# Create main branch for reference
git checkout -b main

# Go back to test branch
git checkout -b feature

# Now test with Claude:
# /lazy-commit spread from March 13 to 15
```

## Maintenance

### Version Updates

Update `.claude-plugin/plugin.json` when releasing new versions:

```json
{
  "version": "0.2.0"
}
```

### Changelog

Document changes in `CHANGELOG.md` (to be created):

```markdown
## [0.2.0] - 2026-04-10
### Added
- /lazy-commit audit command
- Tracking support with .lazy-commits.json

### Fixed
- Better error messages for invalid dates
```

## Security Considerations

- ⚠️ **Force-pushing required**: Rewriting history requires `git push --force`, which affects collaborators
- ⚠️ **Irreversible after push**: Once pushed, timestamp changes are difficult to undo
- ✅ **Safety by default**: Plugin refuses to modify pushed commits
- ✅ **Explicit confirmation**: User must confirm before any changes
