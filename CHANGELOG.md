# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `molt upgrade --self` for clean framework/config pull without hooks or resleeve
- `molt maintain` command for system maintenance (brew upgrade, doom upgrade, etc.)
- `molt maintain --dry-run` to preview maintenance actions
- Targeted upgrade/maintain: `molt upgrade zsh,git`, `molt maintain brew`
- `--resleeve`/`--no-resleeve` flags for `molt upgrade`
- `molt git` command for running git across managed repos
- Liberator lifecycle hooks: `_upgrade()` and `_maintain()`
- New liberators: `brew`, `intent`, `pplr`, `web`
- Third sleeve: gyges (macOS)
- VERSION file as single source of truth for version number
- CHANGELOG.md
- CI/CD via GitHub Actions (tests on Linux + macOS, ShellCheck, PR checks)

### Changed

- `constants.sh` reads version from VERSION file instead of hardcoding

## [0.1.0] - 2025-01-01

### Added

- Initial MOLT framework: two-repo model, liberator system, CLI
- Core commands: `resleeve`, `upgrade`, `status`, `list`, `doctor`, `test`, `version`
- 17 built-in liberators covering shell, git, editors, terminals, SSH, and more
- `molt.toml` manifest system with per-instance overrides
- Template rendering via `envsubst` with instance variables
- Bootstrap script for fresh machines
- Bats test suite with HOME-sandboxed test isolation
- Platform support: macOS (Apple Silicon + Intel), Linux (Debian/Ubuntu, Fedora/RHEL, Arch), WSL2
