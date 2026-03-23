# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-03-23

### Added

- Cross-instance aggregation: `molt_instances_field()` reads TOML fields from all instances
- iTerm2 SSH background colors now generated at resleeve time from `instance.toml` data
- `[terminal]` section in `instance.toml` for host identity metadata (e.g., `ssh_bg_color`)
- Stub instance support: minimal `instance.toml` for non-Molt hosts (shrike, yggdrasil)
- ShellCheck integrated into `molt test` (runs before bats, fails on any warning)
- 6 new bats tests for cross-instance aggregation (`test/instances.bats`)
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

- ShellCheck is now blocking in CI (was non-blocking)
- Generated SSH colors output to `~/.config/molt/iterm2-ssh-colors.sh` (was hardcoded in zsh config)
- zshrc sources SSH colors from `~/.config/molt/` instead of relative to zshrc symlink
- `constants.sh` reads version from VERSION file instead of hardcoding

### Fixed

- All ShellCheck warnings across 25 scripts (SC2155, SC2046, SC2001, SC2164, SC2088, SC2129, SC2043)

### Removed

- Hardcoded hostname-to-color mapping from `config/zsh/iterm2-ssh-colors.sh` (replaced by generation)

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
