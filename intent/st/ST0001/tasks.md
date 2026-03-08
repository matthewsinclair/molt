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

- [x] MOLT framework scaffolding — CLI, core lib, liberator framework, manifest support
- [x] 12 liberators: system, local-bin, zsh, git, tmux, editors, terminal, keys, desktop, dev-tools, ssh, utilz
- [x] CLI commands: resleeve, status, list, doctor, test, version, help
- [x] Bats test suite — 42 tests, 6 files, all passing (HOME-sandboxed)
- [x] `molt doctor` — 7-step diagnostics
- [x] Highlander & Thin Coordinator audit (WP-06)
- [x] Document Phase 1 bootstrap steps (docs/bootstrap-runbook.md)
- [x] Module registry (MODULES.md) with Highlander enforcement
- [ ] Fix Cmd key passthrough from Parallels (PARKED — needs investigation)
- [ ] Set up kovacs SSH key for direct GitHub access
- [ ] Install Nerd Fonts on kovacs

## Dependencies

- Cmd key fix depends on Parallels configuration (may need macOS-side changes)
- SSH setup is independent and can be done anytime
- MOLT framework scaffolding can begin regardless of other tasks
- Nerd fonts is independent, just needs doing
