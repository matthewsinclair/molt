# Claude Restart Context

## Current WIP
- **ST0001**: Bootstrap -- Phase 2 framework mature, sleeveable
- Next: commit/push, first rhadamanth resleeve, export terminal profiles

## Key Changes This Session
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
