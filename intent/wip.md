---
verblock: "11 Mar 2026:v0.10: matts - molt maintain, brew liberator, starship hostname, doom migration"
---

# Work In Progress

## Current Focus

**011: Doom migration, upgrade scripts, hostname in prompt (DONE)**

- Added `molt maintain` command -- system maintenance separate from config sync
  - `molt maintain` runs all `_maintain()` hooks on enabled liberators
  - `molt maintain brew` -- targeted maintenance for specific liberators
  - `molt maintain --dry-run` -- preview what would happen
- New brew liberator (macOS) -- brew update/upgrade/cleanup/doctor + npm global update
- Added `editors_maintain()` -- runs `doom upgrade --force` (framework upgrade)
- Starship prompt now shows `matts@hostname` with per-host colors
  - Converted starship.toml to .tmpl template with `MOLT_PROMPT_HOST_COLOR`
  - rhadamanth: purple (#9A348E), gyges: teal (#2E86AB), kovacs: green (#44803F)
- Fixed `molt_render()` to only substitute `MOLT_*` variables via envsubst filter
- Fixed `zsh_check()` to detect missing/dangling starship config
- Doom migration on rhadamanth: removed legacy `~/.emacs.d` and stale `~/.doom.d`
- Removed `share_history` from zshrc (each terminal now has own history)
- 83 tests passing (19 liberators)

**010: molt git + centralised git operations (DONE)**

- Added `molt git <cmd>` -- runs git across framework, config, and liberator repos
- Per-liberator convention functions: `{name}_repo()`, `{name}_repo_git_commands()`
- Auto-detect remote for pull/fetch/push
- 77 tests passing (28 new in git.bats)

**009: gyges resleeve + symbolic directory vocabulary (DONE)**

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

- Deploy starship template to gyges (pull + molt resleeve)
- Deploy starship template to kovacs (pull + molt resleeve)
- Fix git remote/tracking config on gyges (remotes named "upstream", missing fetch refspecs)
- Persist GNOME Terminal Super bindings in gnome-terminal liberator
- GTK apps (Nautilus etc.) still use Ctrl+C/V -- low priority
- Export iTerm2 + Terminal.app profiles from rhadamanth
- Run `molt resleeve` on kovacs (needs MOLT_PRJ_DIR in .zshenv)
- Reproducible VM build (WP-07, future)

## Notes

19 liberators (brew added), 83 tests passing. Three sleeves operational (kovacs, rhadamanth, gyges). `molt upgrade` = fast config sync (daily). `molt maintain` = heavy system maintenance (weekly/monthly). envsubst now only substitutes MOLT\_\* variables, preventing clobbering of app-specific $VAR references in templates.
