---
verblock: "09 Mar 2026:v0.5: matts - Rhadamanth resleeved, chezmoi retired"
---

# Work In Progress

## Current Focus

**006: Rhadamanth resleeve + chezmoi migration (DONE)**

- Migrated from chezmoi to MOLT on rhadamanth (WP-10)
- Updated `.zprofile` with Homebrew `brew shellenv` init (cross-platform)
- Merged git config: `gitignore_global`, `gitconfig_matthewsinclair` identity include
- Git liberator links additional files (`gitignore_global`, identity include)
- Fixed `bin/molt` symlink resolution (`BASH_SOURCE[0]` → resolve through symlinks)
- Fixed `((would_install++))` arithmetic crash under `set -e`
- chezmoi purged and uninstalled (safety net: cfg-dotfiles on GitHub)
- All 9 enabled liberators installed on rhadamanth
- 52 tests passing

**005: Make Molt Sleeveable (DONE)**

- Stripped package manager calls from all 7 liberators that had them
- Added `molt resleeve --dry-run`
- Created `rhadamanth/molt.toml` manifest and `bin/bootstrap.sh`
- Removed hardcoded `MOLT_PROJECTS_DIR` default -- must be set via env var
- All tests passing

**004: Split terminal liberator into per-emulator liberators (DONE)**

**003: Bats test suite and CLI commands (DONE)**

**002: MOLT framework scaffolding (WP-05, DONE)**

## Active Steel Threads

- ST0001: Bootstrap -- Phase 1 COMPLETE, Phase 2 COMPLETE, Phase 3 COMPLETE

## Upcoming Work

- Verify WP-10 changes on kovacs (no regressions)
- Fix Cmd key passthrough (WP-01, PARKED)
- Export iTerm2 and Terminal.app profiles from rhadamanth
- Reproducible VM build (WP-07, future)

## Notes

15 liberators, 52 tests passing. No liberator installs packages. `MOLT_PROJECTS_DIR` is required. Two sleeves operational (kovacs, rhadamanth). `hostname -s` used everywhere for macOS compatibility. chezmoi retired from rhadamanth.
