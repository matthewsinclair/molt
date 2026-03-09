# Tasks - ST0001: Bootstrap

## Phase 1: Resleeve (COMPLETE)

- [x] Install base packages (htop, jq, tree, bat, ripgrep, fd-find, fzf, mise, etc.)
- [x] Build and configure keyd from source
- [x] Create matts user with sudo, SSH key, Claude creds
- [x] Install and configure zsh + Starship
- [x] Write clean .zshrc (Highlander-compliant)
- [x] Configure git (user, email, aliases, git-lfs)
- [x] Configure tmux (Ctrl-a, vi keys, mouse, 256color)
- [x] Install and configure Doom Emacs
- [x] Install and configure LazyVim (nvim)
- [x] Install and configure Alacritty
- [x] Migrate all config into molt-matts/config/
- [x] Symlink all dotfiles from molt-matts
- [x] Strip GNOME Super keybindings
- [x] Install Intent skills
- [x] Push to GitHub

## Phase 2: Framework & Gaps

- [x] MOLT framework scaffolding -- CLI, core lib, liberator framework, manifest support
- [x] 15 liberators: system, local-bin, zsh, git, tmux, editors, alacritty, gnome-terminal, iterm2, terminal-app, keys, desktop, dev-tools, ssh, utilz
- [x] CLI commands: resleeve, status, list, doctor, test, version, help
- [x] Bats test suite -- all passing (HOME-sandboxed)
- [x] `molt doctor` -- 9-step diagnostics
- [x] Highlander & Thin Coordinator audit (WP-06)
- [x] Document Phase 1 bootstrap steps (docs/bootstrap-runbook.md)
- [x] Module registry (MODULES.md) with Highlander enforcement
- [x] Template rendering system (WP-08)
- [x] Split terminal.sh into per-emulator liberators (WP-09)
- [x] GNOME Terminal Molt profile applied on kovacs
- [x] Set up kovacs SSH key for direct GitHub access (WP-02)
- [x] Install Nerd Fonts on kovacs (WP-03)
- [x] Fix local-bin false negative -- PATH check softened to debug
- [x] Strip package manager calls from all liberators
- [x] Add `molt resleeve --dry-run`
- [x] Create rhadamanth/molt.toml manifest
- [x] Create bin/bootstrap.sh
- [x] Forensic review + fix of all destructive operations
- [x] Remove hardcoded MOLT_PROJECTS_DIR default, require env var
- [x] Update README
- [ ] Fix Cmd key passthrough from Parallels (PARKED -- needs investigation)
- [ ] Export iTerm2 + Terminal.app profiles from rhadamanth
- [ ] First resleeve on rhadamanth

## Dependencies

- Cmd key fix depends on Parallels configuration (may need macOS-side changes)
- rhadamanth resleeve requires commit + push from kovacs first
