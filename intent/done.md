# Done

## 015: `dvb` shell function, whiteboard roster, snapshot re-cut (DONE)

- **`dvb` shell function** installed in molt-matts: new autoload file `config/zsh/functions/dvb`, registered on the `autoload -Uz` line at `config/zsh/zshrc:11`. Walks up from `$PWD` to the nearest `bin/devbin` and runs it, passing the child's exit code through.
  - Devbin's `9ce1c88` retired the per-project launcher symlinks and offered `dvb` as the replacement, but shipped it only as a README snippet. Measured: zero references in devbin's `bin/ lib/ tests/ docs/`, two in prose, and zero hits across all four of hv's zsh init files. The shortcut every devbin project assumed had never existed anywhere.
  - Lands in molt-matts rather than the framework: devbin's `usage-rules.md:66` says shell config and never a project, and the framework would otherwise hard-code one project's launcher into every sleeve.
  - **Two defects fixed before landing**, both verified under `zsh -f`: `${^tried}` collapsed the candidate list onto one line (needs `[@]`; byte-identical to the correct form at depth 1, which is why a `/tmp` negative control could not catch it); and `-x` with no `-f` arm let a mode-644 `bin/devbin` be stepped over so the walk ran a PARENT project's launcher and returned rc=0 -- now stops at rc=126 with the path named.
  - Verified through the real config in a fresh shell: rc=0 in a devbin project, rc=127 with a multi-line candidate list from `$HOME`, rc=126 non-executable, rc=2 passed through. hv confirmed live in their own shell.
- **Whiteboard escalation surface** stood up: provisioned the `hv` node, seeded inboxes both directions, and wrote `intent/whiteboard/README.md` naming `vc` as the node obliged to read `hv/inbox.*` and surface it to the human. Before this the board had one node, no roster, and no reader -- a write surface with no named reader is a queue, not a channel.
- **Snapshots re-cut off March**: `intent/wip.md` and `intent/restart.md` claimed 83 tests / 19 liberators / v0.1.0 and were five months stale. Measured 2026-08-27: 112 tests, ShellCheck clean over 27 scripts, 22 liberators, VERSION 0.1.1, `intent doctor` 0 findings. March's gyges/kovacs items carried forward marked unverifiable from this sleeve rather than silently re-asserted.
- Fixed the unsubstituted `{user}` author placeholder in wip.md's verblock that `fc20931` missed.
- ST0001 checked and found correct: WP-04 and WP-07 genuinely Not Started; the earlier "Phase 1-6 COMPLETE" was a different axis (phases map to focus items, not WP numbers).
- Commits: `131642d` (molt); `a4e6cb2` (molt-{user})

## 014: Intent v3 port (DONE)

- Migrated the project to the Intent v3 canonical store
- Substituted the author placeholder ahead of the migration
- Declared the open set and dehydrated the closed threads' flat views, by hand, ahead of `organize --default --force`
- Carried the v2 buckets' prose into the store per file, byte-verified, and pruned what was proven carried
- Fenced the renderer-owned views from prettier in `.prettierignore` -- generated views have one writer and it is the renderer. Established the owned set by perturbation rather than by family resemblance: `info.md`, `acceptance.md`, `steel_threads.md` and `todo.md` are restored by the renderer; `design.md`, `impl.md`, `tasks.md`, `claude/wip.md`, `intent/wip.md` and `intent/done.md` keep the perturbation and are authored.
- ST0002 dated and closed; `intent doctor` 0 findings
- Commits: `fc20931`, `84726b0`, `4212bf6`, `e94ed2b`, `fb053ab`, `555dd08`

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
- iTerm2 SSH background color wrapper in molt-{user}:
  - `config/zsh/iterm2-ssh-colors.sh`: tints background per host on SSH
  - gyges=navy, kovacs=forest, shrike=burgundy, yggdrasil=olive
  - zshrc sources it (only on iTerm2)
- Tagged v0.1.0
- 83 tests passing, 19 liberators
- Commits: `c38a284`, `37ff0bc` (molt); `57e00c5` (molt-{user})

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
- Starship prompt now shows `{user}@hostname` with per-host colors
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
