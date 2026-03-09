---
verblock: "09 Mar 2026:v0.4: matts - Rhadamanth resleeved, chezmoi retired"
intent_version: 2.6.0
status: WIP
slug: bootstrap
created: 20260307
completed:
---

# ST0001: Bootstrap

## Objective

Stand up a fully opinionated, reproducible dev environment on a new sleeve (VM/machine) using the MOLT framework. The first target sleeve is **kovacs** (Ubuntu 24.04 ARM64, Parallels on rhadamanth).

## Context

MOLT (My Opinionated Local Terminal) is a system for maintaining consistent, portable dev environments across multiple machines ("sleeves"). The core principle is separation of concerns:

- **molt** (framework repo): templates, tooling, scripts — shared infrastructure
- **molt-matts** (personal repo): Matt's config ("the soul") + per-instance overrides

This steel thread covers the full bootstrap journey: from a bare VM to a working, opinionated environment with all dotfiles managed through molt-matts, editors configured, and the MOLT framework itself ready for development.

### Sleeves

- **kovacs**: Ubuntu 24.04 ARM64 VM (Parallels) — first target, fully bootstrapped
- **rhadamanth**: M4 MacBook Pro (macOS host) — fully resleeved, chezmoi retired

### What's Done (Phase 1 — Resleeve)

- keyd installed and configured (Cmd→Ctrl mapping, systemd enabled)
- matts user created with sudo, SSH key, Claude creds
- zsh + Starship prompt installed and configured
- Clean .zshrc (Highlander-compliant), minimal .zshenv, empty .zprofile
- Git configured (user.name, email, aliases, git-lfs)
- tmux configured (Ctrl-a prefix, vi keys, mouse, 256color)
- CLI tools: htop, jq, tree, wl-clipboard, bat, ripgrep, fd-find, fzf, mise
- Emacs + Doom Emacs installed and synced
- LazyVim (nvim) configured
- Alacritty installed and configured
- All config migrated into molt-matts/config/, symlinked from ~
- GNOME Super bindings stripped
- Intent skills installed (all 12 /in-\* skills)
- Commits pushed to GitHub

### What's Done (Phase 2 — Framework)

- MOLT framework scaffolded: CLI (`bin/molt`), core lib, 15 liberators, manifest support
- CLI commands: `resleeve [--dry-run]`, `status`, `list`, `doctor`, `test`, `version`, `help`
- Liberator framework: load, check, install, verify lifecycle
- Manifest-first (`molt.toml`) with enabled/disabled/OS filtering
- `constants.sh` for configurable paths (Highlander Rule)
- `MOLT_PROJECTS_DIR` required via env var (no hardcoded default)
- Bats test suite (52 tests, all passing)
  - `test/test_helper.bash` — shared infrastructure, HOME-sandboxed for safety
  - `test/molt.bats` — CLI tests
  - `test/constants.bats` — constants tests
  - `test/liberator.bats` — framework tests
  - `test/manifest.bats` — manifest parsing tests
  - `test/templates.bats` — template rendering tests (9 tests)
  - `test/liberators/zsh.bats` — exemplar liberator test
- `molt doctor` — 9-step diagnostic (structure, manifest, liberators, deps, SSH, GitHub auth)
- Highlander & Thin Coordinator audit (WP-06) completed and applied
- Module registry (`MODULES.md`) tracking all framework and liberator modules
- Template rendering system (WP-08): `molt_render` + `molt_install_config`, envsubst + vars.sh
  - SSH config rendered from `.tmpl` with `config.d/` fragment concatenation
  - `.molt-rendered` marker files with provenance
  - `molt_render` handles symlink removal, permission-sensitive dirs (e.g. `~/.ssh`)
- Split monolithic `terminal.sh` into four per-emulator liberators (WP-09):
  - `alacritty.sh` — GPU-accelerated terminal (linux, macos)
  - `gnome-terminal.sh` — dconf-based GNOME Terminal profile management (linux)
  - `iterm2.sh` — iTerm2 dynamic profiles (macos)
  - `terminal-app.sh` — Terminal.app profile import (macos)
- GNOME Terminal Molt profile created and applied on kovacs
- Liberators enforce "no package install" — fail with hints if binary missing
- `bin/molt` resolves symlinks for `MOLT_ROOT` (works via `~/bin/molt` symlink)
- `hostname -s` used everywhere for macOS compatibility
- `bin/bootstrap.sh` for fresh-machine setup

### What's Done (Phase 3 — Rhadamanth Resleeve)

- Migrated from chezmoi to MOLT on rhadamanth (WP-10)
  - chezmoi purged and uninstalled (safety net: cfg-dotfiles on GitHub)
  - `.zprofile` updated with Homebrew `brew shellenv` init
  - Git config merged: `gitignore_global`, `gitconfig_matthewsinclair` identity include
  - Git liberator updated to link additional files
  - All 9 enabled liberators installed: system, local-bin, zsh, git, editors, iterm2, dev-tools, ssh, utilz
  - Doctor: 9/9 checks, GitHub auth working

### What's Remaining

- Fix Cmd key passthrough (Parallels not sending leftmeta to VM) — PARKED
- Export iTerm2 + Terminal.app profiles from rhadamanth
- Verify WP-10 changes on kovacs (no regressions)
- Reproducible VM build (WP-07, future)

## Related Steel Threads

- None yet — this is the foundational steel thread

## Context for LLM

This is the bootstrap steel thread for the entire MOLT project. Phase 1 is complete (manual setup, config in molt-matts). Phase 2 is complete (framework, 15 liberators, 52 tests, template system). Phase 3 (rhadamanth resleeve, chezmoi migration) is complete. Both sleeves are operational.
