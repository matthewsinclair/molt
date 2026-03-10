# Session Restart Context

## Last Session: 10 Mar 2026

### What Was Done

- Cmd key fully resolved via custom Parallels keyboard profile
  - Reverse-engineered `Mac OS X.dat` binary format
  - Custom profile: 33 shortcuts, all Cmd passthrough as Super_L
  - Profile stored in `molt-matts/instances/rhadamanth/parallels/Mac OS X.dat`
- Per-app keybindings for Super (Cmd) support:
  - Emacs: `s-` (Super) Linux block in `010-keys.el`
  - Alacritty: Super+C/V/X in `alacritty.toml`
  - VS Code: `win+` Cmd shortcuts + Emacs Ctrl nav in `keybindings.json`
  - GNOME Terminal: Super bindings via gsettings
  - GNOME a11y shortcuts stripped in desktop liberator
- Phase 1 verification: all components confirmed working
- wip.md updated with rhadamanth instructions for Phase 5 commit/push

### What's Next

- Persist GNOME Terminal Super bindings in gnome-terminal liberator
- GTK apps (Nautilus etc.) still use Ctrl+C/V (low priority)
- Export iTerm2 + Terminal.app profiles from rhadamanth
- Update rhadamanth manifest with vscode liberator
- Run `molt resleeve` on rhadamanth
- Commit and push both repos

### Key Context

- Parallels must use "macOS" profile (not "Linux") with "Send macOS system shortcuts: Always"
- Parallels restart required after `Mac OS X.dat` file changes
- `MOLT_PROJECTS_DIR` is required — set in `.zshenv` symlinked from molt-matts
- 18 liberators, two sleeves (kovacs + rhadamanth)
- kovacs manifest: 14 enabled (keys disabled — not needed, keyd minimal)
- rhadamanth manifest: needs vscode liberator added
- VS Code on Linux needs `win+` prefix for Super keybindings (not `meta+`)
- Physical Ctrl and Opt both arrive as Alt_L in VM (Parallels merges them) — acceptable
