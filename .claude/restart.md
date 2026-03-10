# Claude Restart Context

## Current WIP
- **ST0001**: Bootstrap -- all phases complete (1-6)
- Next: fix gyges git remotes, persist GNOME Terminal Super bindings, rhadamanth resleeve

## Key Changes This Session
- **`molt git <cmd>`**: centralised git across all managed repos
- Auto-detect remote for pull/fetch/push via `_git_detect_remote()`
- Per-liberator convention: `{name}_repo()`, `{name}_repo_git_commands()`
- Fixed Intent bin/intent symlink resolution (BASH_SOURCE vs readlink)
- 77 tests passing (28 new)

## Key Facts
- gyges repos have remotes named "upstream" with missing fetch refspecs
- Fix: `git config remote.upstream.fetch '+refs/heads/*:refs/remotes/upstream/*'`
- `MOLT_PRJ_DIR` required (no default) -- set in `.zshenv`
- 18 liberators, three sleeves (kovacs, rhadamanth, gyges)

## Quick Verification
```bash
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt test
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt doctor
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt git status
```
