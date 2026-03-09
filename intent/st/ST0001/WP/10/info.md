---
verblock: "09 Mar 2026:v0.3: rhadamanth - As-built, migration complete"
wp_id: WP-10
title: "Migrate from chezmoi to MOLT on rhadamanth"
scope: Medium
status: Done
---

# WP-10: Migrate from chezmoi to MOLT on rhadamanth

## Problem

rhadamanth used chezmoi (`~/.local/share/chezmoi`) to manage 9 dotfiles. MOLT's zsh and git liberators also wanted to manage several of the same files. Two config managers cannot own the same files.

chezmoi's config was stale (Aug-Nov 2024 vintage) with legacy cruft: RVM setup, a plaintext gem password, hardcoded paths, dead project references. MOLT's versions were already cleaner and more structured.

Decision: **ditch chezmoi, let MOLT own everything.**

## What Was Done

### 1. Rationalised zsh config (cross-platform)

- Updated `.zprofile` with Homebrew `brew shellenv` init (Apple Silicon + Intel detection)
- No-op on Linux (neither brew path exists)
- No `path_add` dependency — `brew shellenv` is self-contained
- `.zlogin` not needed (was empty). `.inputrc` not needed (zsh uses `IGNOREEOF`, not readline)
- All chezmoi zprofile cruft dropped (RVM, plaintext gem password, dead project refs, old bookmark aliases)

### 2. Merged git config

- Email: `hello@matthewsinclair.com` (canonical)
- Added `core.excludesfile = ~/.gitignore_global`, `core.autocrlf = false`, `http.sslVerify = true`
- Added `[include] path = ~/.gitconfig_matthewsinclair` identity include
- Created `molt-matts/config/git/gitignore_global` (OS/editor ignores)
- Created `molt-matts/config/git/gitconfig_matthewsinclair` (identity include)
- Updated git liberator to link both additional files
- Dropped: GPG signing config, project-level `.gitignore` (belongs in project repos)

### 3. Removed chezmoi from rhadamanth

- `chezmoi purge --force` — removed source state
- `brew uninstall chezmoi` — removed the tool
- Safety net: `github.com-matthewsinclair:matthewsinclair/cfg-dotfiles.git`

### 4. Fixed dry-run crash (zsh liberator) -- kovacs

Extracted shell detection into `_zsh_current_shell()` helper to avoid pipefail issues.

### 5. Fixed dry-run crash (arithmetic) -- rhadamanth

`((would_install++))` in `bin/molt` crashed under `set -e` because post-increment evaluates to 0 (falsy) on first invocation. Fixed to `would_install=$((would_install + 1))`.

### 6. Fixed symlink resolution in `bin/molt`

`BASH_SOURCE[0]` returned the symlink path (`~/bin/molt`) instead of the real path, causing `MOLT_ROOT` to resolve to `$HOME`. Fixed by resolving symlinks before computing `MOLT_ROOT`.

### 7. Resleeved rhadamanth

All 9 enabled liberators installed successfully:

- system, local-bin, zsh, git, editors, iterm2, dev-tools, ssh, utilz
- Old dotfiles backed up as `.molt-backup.*`
- SSH config rendered from template with LAN hosts fragment appended

## Acceptance Criteria

- [x] `.zshenv`, `.zprofile`, `.zshrc` work on both macOS (rhadamanth) and Ubuntu (kovacs)
- [x] Homebrew PATH is set correctly on macOS via `.zprofile`
- [x] No plaintext credentials in any config file
- [x] Git config includes identity file and global gitignore
- [x] `molt resleeve --dry-run` completes without crash on rhadamanth
- [x] chezmoi fully removed from rhadamanth
- [x] `molt resleeve` successfully manages all former chezmoi files
- [ ] No regressions on kovacs (pending verification)

## Dependencies

- WP-08 (Template system) -- Done
- WP-09 (Terminal liberator split) -- Done
