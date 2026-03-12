# Done

## 013: Docs, CI/CD, versioning, and iTerm2 SSH colors (DONE)

- VERSION file as single source of truth; `constants.sh` reads it with fallback
- CHANGELOG.md in Keep a Changelog format (Unreleased + 0.1.0 sections)
- GitHub Actions CI/CD:
  - `tests.yml`: bats on Linux + macOS, ShellCheck (non-blocking), test summary
  - `pr-checks.yml`: documentation checks, commit message length, PR size warnings
  - `.github/workflows/README.md`: workflow documentation
  - Fixed CI: added git identity config for test runners (git.bats needs it)
- README.md: CI badge, `upgrade --self`, `maintain`, targeted variants, lifecycle hooks, 4 new liberators (brew, intent, pplr, web), three sleeves
- getting-started.md: self-update, maintain, recommended workflow section
- iTerm2 SSH background color wrapper in molt-matts:
  - `config/zsh/iterm2-ssh-colors.sh`: tints background per host on SSH
  - gyges=navy, kovacs=forest, shrike=burgundy, yggdrasil=olive
  - zshrc sources it (only on iTerm2)
- Tagged v0.1.0
- 83 tests passing, 19 liberators
- Commits: `c38a284`, `37ff0bc` (molt); `57e00c5` (molt-matts)

## 012: molt upgrade --self — self-update before upgrade (DONE)

- Extracted `_upgrade_pull_repos()` from inline pull logic in `cmd_upgrade()`
  - Checks framework + config repos for uncommitted changes
  - Pulls both repos via `git pull --ff-only`
  - Re-sources constants, reports version changes
- Added `--self` flag to `cmd_upgrade()` argument parser
  - When set: calls `_upgrade_pull_repos()` and exits (no hooks, no resleeve)
  - Enables composable workflow: `molt upgrade --self && molt upgrade && molt maintain`
- Full upgrade path now calls `_upgrade_pull_repos()` instead of inline code (DRY)
- Updated help text in `bin/molt`
- 83 tests passing, 19 liberators
- Commit: `dca5bb8` — pushed to upstream + local

## 011: Doom migration, upgrade scripts, hostname in prompt (DONE)

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

## 010: molt git + centralised git operations (DONE)

- Added `molt git <cmd>` -- runs git across framework, config, and liberator repos
- Per-liberator convention functions: `{name}_repo()`, `{name}_repo_git_commands()`
- Auto-detect remote for pull/fetch/push
- 77 tests passing (28 new in git.bats)

## 009: gyges resleeve + symbolic directory vocabulary (DONE)

## 008: Cmd key proper fix + per-app keybindings (DONE)

## 007: Phase 5 -- Upgrade, Emacs Keys, Tiling, VS Code (DONE)

## 006: Rhadamanth resleeve + chezmoi migration (DONE)

## 005: Make Molt Sleeveable (DONE)

## 004: Split terminal liberator into per-emulator liberators (DONE)

## 003: Bats test suite and CLI commands (DONE)

## 002: MOLT framework scaffolding (WP-05, DONE)
