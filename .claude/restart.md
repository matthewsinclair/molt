# Claude Restart Context

## Current WIP
- **ST0001**: Bootstrap -- Phase 3 (rhadamanth resleeve) complete, Phase 4 done
- Next: export terminal profiles, verify WP-10 on kovacs, commit/push

## Key Changes This Session
- **Cmd key RESOLVED** (WP-01 DONE): Parallels keyboard shortcuts map Cmd+C/V/X → Ctrl+Shift+C/V/X
- keyd config minimal (`/etc/keyd/default.conf`) — not used for key remapping
- Alacritty liberator adds itself to GNOME dock favorites (Linux only)
- Alacritty config comment updated (references Parallels, not keyd)

## Previous Session Changes (still relevant)
- `MOLT_PROJECTS_DIR` required (no default) -- set in `.zshenv`
- Liberators never install packages -- verify + hint only
- `molt resleeve --dry-run` available
- `hostname -s` used everywhere (macOS compat)

## Quick Verification
```bash
MOLT_PROJECTS_DIR=$HOME/Devel/prj bin/molt test
MOLT_PROJECTS_DIR=$HOME/Devel/prj bin/molt doctor
MOLT_PROJECTS_DIR=$HOME/Devel/prj bin/molt resleeve --dry-run
```
