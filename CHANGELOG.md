# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
