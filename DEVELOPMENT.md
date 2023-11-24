# Development Guide: lazy-commit Plugin

## Architecture

The lazy-commit plugin is a single-skill workflow tool that uses `git filter-repo` to rewrite commit timestamps retroactively.

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
   - [ ] `git filter-repo` runs successfully
   - [ ] Timestamps updated in git log
   - [ ] Commit content unchanged (git diff main shows nothing)

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
