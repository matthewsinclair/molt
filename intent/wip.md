---
verblock: "09 Mar 2026:v0.4: matts - Sleeveable: no pkg install, dry-run, bootstrap, rhadamanth"
---

# Work In Progress

## Current Focus

**005: Make Molt Sleeveable (DONE)**

- Stripped package manager calls from all 7 liberators that had them
  - system, zsh, git, tmux, editors, dev-tools, utilz
  - Liberators now verify prerequisites and fail with install hints
- Added `molt resleeve --dry-run` for previewing changes
- Created `rhadamanth/molt.toml` manifest (macOS, iTerm2 enabled, tmux disabled)
- Created `bin/bootstrap.sh` for fresh-machine setup
- Forensic review and fix of all destructive operations:
  - SSH: detects any existing key (not just id_ed25519/id_rsa), config.d appends are idempotent
  - editors: no doom sync/install (molt clones + links only), nvim guarded by directory existence
  - resleeve: one liberator failure no longer aborts the entire run
  - molt_render: backs up rendered files if content changed since last render
  - zsh: macOS-safe shell detection (dscl), chsh only when needed
- Removed hardcoded `~/Devel/prj` default from constants.sh
  - `MOLT_PROJECTS_DIR` must be set via env var (zshenv exports it)
  - Clear error with hint if unset
  - zshrc uses `$MOLT_PROJECTS_DIR` for Intent/Utilz paths
- Added `projects_dir` to both sleeve manifests and instance vars.sh
- bootstrap.sh requires `MOLT_PROJECTS_DIR`, detects existing repos, SSH probe has timeout
- Updated README with MOLT_PROJECTS_DIR docs, dry-run, bootstrap, all 15 liberators
- All tests passing

**004: Split terminal liberator into per-emulator liberators (DONE)**

**003: Bats test suite and CLI commands (DONE)**

**002: MOLT framework scaffolding (WP-05, DONE)**

## Active Steel Threads

- ST0001: Bootstrap -- Phase 1 COMPLETE, Phase 2 framework mature

## Upcoming Work

- Fix Cmd key passthrough (WP-01, PARKED)
- Export iTerm2 and Terminal.app profiles from rhadamanth
- First resleeve on rhadamanth (after committing + pushing from kovacs)
- Reproducible VM build (WP-07, future)

## Notes

15 liberators, all tests passing. No liberator installs packages. `MOLT_PROJECTS_DIR` is required. Two sleeves configured (kovacs, rhadamanth). `hostname -s` used everywhere for macOS compatibility.
