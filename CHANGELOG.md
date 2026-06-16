# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `molt new-user` command: scaffolds a new `molt-{user}` config repo from a tokenised skeleton (`templates/molt-user/`), substituting name, email, GitHub handle, and first hostname. Implemented in `lib/newuser.sh` with `test/newuser.bats` (10 tests)
- `docs/guides/new-user.md` guide explaining the scaffold, the identity surface, and the scaffold-time vs resleeve-time placeholder split
- `git_install` config-linking tests in `test/git.bats` (arbitrary identity name, multiple includes, empty-glob guard)
- `molt doctor` check (10th) for config files that bake in another user's absolute home path, including JSON-escaped `\/Users\/<x>` exports (`molt_foreign_home_paths`)
- `molt doctor` external-dependency check now also verifies `envsubst` (gettext), required for template rendering
- `web` liberator test (`test/liberators/web.bats`)

### Changed

- `git` liberator now links any `config/git/gitconfig_*` identity include instead of a hardcoded filename
- `bootstrap.sh` no longer assumes a fixed GitHub owner for the config repo: `MOLT_REPO` and the new `MOLT_USER_GH` are overridable (default `whoami`)
- Removed hardcoded personal identity strings throughout framework docs and project artifacts; the framework now reads as generic `{user}`/`{github}`
- `molt new-user` skeleton defaults `MOLT_FONT_FAMILY` to `Hack Nerd Font Mono` (a Nerd Font, matching the iTerm2 profile) so the prompt glyphs render out of the box

### Fixed

- `molt_render` now fails cleanly when `envsubst` is missing instead of writing an un-substituted file while reporting success (eg a literal `${MOLT_SSH_KEY}` left in `~/.ssh/config`)
- `web` liberator now detects the repo by `go.mod`/`.git` and links the platform binary (`web-<os>-<arch>`) or a locally built `./web`, instead of requiring a binary literally named `web` that a fresh clone never has

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
