---
verblock: "10 Mar 2026:v0.8: matts - gyges resleeve, MOLT_PRJ_DIR rename, MOLT_OPT_DIR"
---

# Work In Progress

## Current Focus

**009: gyges resleeve + symbolic directory vocabulary (DONE)**

- Resleeved gyges (Mac Mini M2) as third Molt-managed sleeve
- Cleaned legacy: chezmoi, RVM, old zsh plugins, archived ~/bin scripts
- Relocated Doom Emacs to modern paths (~/.config/emacs, ~/.config/doom)
- Installed prereqs: fzf, gh, neovim, bats-core, VS Code (updated to 1.111.0)
- Generated ed25519 SSH key, added to GitHub
- Created gyges instance config (instance.toml, vars.sh, molt.toml)
- `molt resleeve` — all 10 enabled liberators installed
- `molt doctor` — all 9 checks pass
- Renamed `MOLT_PROJECTS_DIR` -> `MOLT_PRJ_DIR` across both repos
- Added `MOLT_OPT_DIR` — symbolic directory for third-party tools/libs
  - Derives from `MOLT_PRJ_DIR`'s parent: `$(dirname "$MOLT_PRJ_DIR")/opt`
  - Overridable independently via env var
- 55 tests passing (3 new tests for MOLT_OPT_DIR)

**008: Cmd key proper fix + per-app keybindings (DONE)**

- Diagnosed Parallels modifier mapping via xev (Cmd sent as Control_L)
- Reverse-engineered Parallels `Mac OS X.dat` binary keyboard profile format
- Built custom profile with 33 passthrough shortcuts — Cmd arrives as Super_L
- Per-app keybindings: Emacs (`s-`), Alacritty (Super+C/V/X), VS Code (`win+` + Emacs Ctrl nav), GNOME Terminal (gsettings)
- GNOME a11y shortcuts stripped (screen reader, magnifier) in desktop liberator
- VS Code `keybindings.json`: macOS Cmd shortcuts + Emacs-style Ctrl navigation (A/E/K/N/P/F/B/D/H/T)
- Custom profile stored in `molt-matts/instances/rhadamanth/parallels/`

**007: Phase 5 — Upgrade, Emacs Keys, Tiling, VS Code (DONE)**

**006: Rhadamanth resleeve + chezmoi migration (DONE)**

**005: Make Molt Sleeveable (DONE)**

**004: Split terminal liberator into per-emulator liberators (DONE)**

**003: Bats test suite and CLI commands (DONE)**

**002: MOLT framework scaffolding (WP-05, DONE)**

## Active Steel Threads

- ST0001: Bootstrap — Phase 1-5 COMPLETE

## Upcoming Work

- Persist GNOME Terminal Super bindings in gnome-terminal liberator
- GTK apps (Nautilus etc.) still use Ctrl+C/V — low priority
- Export iTerm2 + Terminal.app profiles from rhadamanth
- Update rhadamanth manifest with vscode liberator
- Run `molt resleeve` on rhadamanth (needs MOLT_PRJ_DIR in .zshenv)
- Run `molt resleeve` on kovacs (needs MOLT_PRJ_DIR in .zshenv)
- Reproducible VM build (WP-07, future)

## Notes

18 liberators, 55 tests passing. Three sleeves operational (kovacs, rhadamanth, gyges). Symbolic directory vocabulary: MOLT_PRJ_DIR (projects), MOLT_OPT_DIR (third-party).
