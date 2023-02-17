# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-03-27

### Changed
- **Implementation**: Replaced git filter-repo with git commit-tree for reliable timestamp rewriting
- Updated SKILL.md with proven implementation approach and comprehensive safety guardrails

### Added
- Content protection guardrails: tree integrity verification (git fsck), commit preservation
- User protection guardrails: dirty directory checks, old→new commit hash mapping
- Data integrity checks: verify messages, authors, parents, permissions are preserved
- Verification steps in skill documentation (pre/post rewrite integrity checks)

### Fixed
- Documented why commits are rebuilt (new hashes, same content) not deleted
- Clarified that zero file diffs change, only timestamps modified

## [0.1.0] - 2026-03-27

### Added
- Initial release of lazy-commit plugin
- `/lazy-commit spread` skill for spreading git commit timestamps retroactively
- Interactive prompts for date range, distribution strategy, and time-of-day preference
- Safety guardrails (refuses on pushed commits, requires confirmation)
- Before/after timestamp comparison
- Support for weighted timestamp distribution based on file changes

### Planned
- `/lazy-commit audit` — Review which commits have been rewritten
- `/lazy-commit undo` — Restore original timestamps
- `/lazy-commit reset` — Clear all rewritten dates
- Custom time-of-day patterns and staggered work hour simulation
