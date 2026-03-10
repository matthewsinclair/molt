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
- [x] Fix Cmd key passthrough from Parallels (resolved via Parallels keyboard shortcuts)
- [x] Add Alacritty to GNOME dock favorites (alacritty liberator updated)
- [ ] Export iTerm2 + Terminal.app profiles from rhadamanth

## Phase 5: Upgrade, Emacs Keys, Tiling, VS Code (COMPLETE)

- [x] WP-11: Add `molt upgrade` command (pull repos + resleeve)
- [x] WP-11: Verified — dirty repo detection, pull, resleeve all working
- [x] WP-12: Add Linux `C-S-` keybindings to Emacs `010-keys.el`
- [x] WP-12: Verified Cmd+C/V/X/S/Z/A work in Emacs on kovacs + `doom sync`
- [x] WP-13: Evaluated Ubuntu Tiling Assistant — insufficient (no grid picker mode)
- [x] WP-13: Installed Tactile extension (Divvy-like two-key grid picker)
- [x] WP-13: Configured 7x3 grid, Shift+Alt+Super+T trigger
- [x] WP-13: Created `tiling.sh` liberator, added to kovacs manifest
- [x] Install VS Code from Microsoft apt repo
- [x] Create `vscode.sh` liberator (settings.json symlink, dock pinning)
- [x] Create `molt-matts/config/vscode/settings.json` (JetBrainsMono, telemetry off)
- [x] Update `editors.sh` to pin Emacs to GNOME dock
- [x] Clean up GNOME dock (Firefox, Nautilus, Alacritty, Emacs, VS Code)
- [x] Font consistency: JetBrainsMono Nerd Font (Alacritty 11pt, Emacs 14pt, VS Code 14pt)
- [x] Symlink ~/Dropbox to macOS CloudStorage via Parallels mount

## Phase 5b: Cmd Key Proper Fix + Per-App Keybindings (COMPLETE)

- [x] Diagnose Parallels modifier mapping via xev (Cmd→Control_L, Ctrl/Opt→Alt_L)
- [x] Reverse-engineer Parallels `Mac OS X.dat` binary profile format
- [x] Build custom profile with 33 ⌘→⌘ passthrough shortcuts (Cmd arrives as Super_L)
- [x] Verify Cmd+S arrives as Super_L in xev after profile install + Parallels restart
- [x] Update Emacs Linux keybindings to `s-` (Super) — same prefix as macOS
- [x] Add Super+C/V/X bindings to Alacritty config
- [x] Set Super bindings for GNOME Terminal via gsettings
- [x] Create VS Code `keybindings.json` — `win+` Cmd shortcuts + Emacs Ctrl navigation
- [x] Disable GNOME a11y shortcuts (screen reader, magnifier) that conflict with Super combos
- [x] Store custom `Mac OS X.dat` in `molt-matts/instances/rhadamanth/parallels/`
- [ ] Persist GNOME Terminal Super bindings in gnome-terminal liberator
- [ ] GTK apps (Nautilus etc.) still use Ctrl+C/V — not yet addressed

## Dependencies

- rhadamanth resleeve requires commit + push from kovacs first
