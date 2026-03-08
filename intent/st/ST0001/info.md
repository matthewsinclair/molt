---
verblock: "08 Mar 2026:v0.2: matts - Fully elaborated"
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

- **kovacs**: Ubuntu 24.04 ARM64 VM (Parallels) — first target, currently being bootstrapped
- **rhadamanth**: M4 MacBook Pro (macOS host) — source of truth for config files

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

### What's Remaining (Phase 2)

- Fix Cmd key passthrough (Parallels not sending leftmeta to VM)
- Set up kovacs SSH for direct GitHub access
- Begin MOLT framework development (templates, scripts, automation)
- Nerd fonts installation

## Related Steel Threads

- None yet — this is the foundational steel thread

## Context for LLM

This is the bootstrap steel thread for the entire MOLT project. It covers getting from zero to a working environment. Phase 1 is complete (manual setup, config in molt-matts). Phase 2 focuses on the remaining gaps and transitioning into actual MOLT framework development.
