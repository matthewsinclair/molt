---
verblock: "10 Mar 2026:v0.9: matts - molt git, auto-detect remote, Intent symlink fix"
---

# Work In Progress

## Current Focus

**010: molt git + centralised git operations (DONE)**

- Added `molt git <cmd>` — runs git across framework, config, and liberator repos
- Per-liberator convention functions: `{name}_repo()`, `{name}_repo_git_commands()`
- Whitelist enforcement: liberator repos only allow declared commands (pull/status/log/diff/fetch)
- Auto-detect remote for pull/fetch/push: uses branch tracking remote, falls back to sole remote
- Fixed stdout contamination from liberator_load debug output in molt_all_repos
- Refactored editors_upgrade() to reuse editors_repo()
- Fixed Intent bin/intent symlink resolution (BASH_SOURCE doesn't resolve symlinks)
- 77 tests passing (28 new in git.bats)

**009: gyges resleeve + symbolic directory vocabulary (DONE)**

- Resleeved gyges (Mac Mini M2) as third Molt-managed sleeve
- Renamed `MOLT_PROJECTS_DIR` -> `MOLT_PRJ_DIR`, added `MOLT_OPT_DIR`

**008: Cmd key proper fix + per-app keybindings (DONE)**

**007: Phase 5 -- Upgrade, Emacs Keys, Tiling, VS Code (DONE)**

**006: Rhadamanth resleeve + chezmoi migration (DONE)**

**005: Make Molt Sleeveable (DONE)**

**004: Split terminal liberator into per-emulator liberators (DONE)**

**003: Bats test suite and CLI commands (DONE)**

**002: MOLT framework scaffolding (WP-05, DONE)**

## Active Steel Threads

- ST0001: Bootstrap -- Phase 1-6 COMPLETE

## Upcoming Work

- Fix git remote/tracking config on gyges (remotes named "upstream", missing fetch refspecs)
- Persist GNOME Terminal Super bindings in gnome-terminal liberator
- GTK apps (Nautilus etc.) still use Ctrl+C/V -- low priority
- Export iTerm2 + Terminal.app profiles from rhadamanth
- Update rhadamanth manifest with vscode liberator
- Run `molt resleeve` on rhadamanth (needs MOLT_PRJ_DIR in .zshenv)
- Run `molt resleeve` on kovacs (needs MOLT_PRJ_DIR in .zshenv)
- Reproducible VM build (WP-07, future)

## Notes

18 liberators, 77 tests passing. Three sleeves operational (kovacs, rhadamanth, gyges). Symbolic directory vocabulary: MOLT_PRJ_DIR (projects), MOLT_OPT_DIR (third-party). gyges has git remotes named "upstream" instead of "origin" with missing fetch refspecs -- fix with `git config remote.<name>.fetch '+refs/heads/*:refs/remotes/<name>/*'`.
