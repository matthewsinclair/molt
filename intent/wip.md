---
verblock: "10 Mar 2026:v0.7: matts - Cmd key resolved, per-app keybindings, Phase 5 complete"
---

# Work In Progress

## Current Focus

**008: Cmd key proper fix + per-app keybindings (DONE)**

- Diagnosed Parallels modifier mapping via xev (Cmd sent as Control_L)
- Reverse-engineered Parallels `Mac OS X.dat` binary keyboard profile format
- Built custom profile with 33 passthrough shortcuts — Cmd arrives as Super_L
- Per-app keybindings: Emacs (`s-`), Alacritty (Super+C/V/X), VS Code (`win+` + Emacs Ctrl nav), GNOME Terminal (gsettings)
- GNOME a11y shortcuts stripped (screen reader, magnifier) in desktop liberator
- VS Code `keybindings.json`: macOS Cmd shortcuts + Emacs-style Ctrl navigation (A/E/K/N/P/F/B/D/H/T)
- Custom profile stored in `molt-matts/instances/rhadamanth/parallels/`

**007: Phase 5 — Upgrade, Emacs Keys, Tiling, VS Code (DONE)**

- `molt upgrade` command (WP-11): pull repos, resleeve, --dry-run
- Emacs Linux keybindings (WP-12): `s-` (Super) bindings, same as macOS
- Tiling via Tactile (WP-13): 7x3 grid, Shift+Alt+Super+T trigger
- VS Code liberator + settings + keybindings
- Dock cleanup, font consistency, .gitignore, Dropbox symlink

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
- Run `molt resleeve` on rhadamanth
- Reproducible VM build (WP-07, future)

## Notes

18 liberators, all tests passing. Cmd key fully resolved via custom Parallels keyboard profile. Two sleeves operational (kovacs, rhadamanth). VS Code has both Cmd shortcuts and Emacs Ctrl navigation on Linux.
