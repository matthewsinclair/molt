# Claude Restart Context

## Current WIP
- **ST0001**: Bootstrap — all phases complete (1-5)
- Next: persist GNOME Terminal Super bindings in liberator, rhadamanth resleeve, commit/push

## Key Changes This Session
- **Cmd key FULLY RESOLVED**: custom Parallels `Mac OS X.dat` profile (33 shortcuts, Cmd as Super)
- Per-app Super keybindings: Emacs (`s-`), Alacritty, VS Code (`win+`), GNOME Terminal
- VS Code `keybindings.json`: Cmd shortcuts + Emacs Ctrl navigation (A/E/K/N/P/F/B/D/H/T)
- GNOME a11y shortcuts stripped in desktop liberator
- Parallels profile stored in `molt-matts/instances/rhadamanth/parallels/Mac OS X.dat`

## Key Facts
- Parallels must use "macOS" profile, "Send macOS system shortcuts: Always"
- VS Code uses `win+` for Super (not `meta+` which collides with Ctrl)
- Physical Ctrl and Opt both arrive as Alt_L (Parallels merges them) — acceptable
- `MOLT_PRJ_DIR` required (no default) — set in `.zshenv`
- 18 liberators, two sleeves (kovacs + rhadamanth)

## Quick Verification
```bash
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt test
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt doctor
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt resleeve --dry-run
```
