# Claude Restart Context

## Current WIP
- **ST0001**: Bootstrap -- all phases complete (1-6)
- Next: deploy starship template to gyges/kovacs, fix gyges git remotes

## Key Changes This Session
- **`molt maintain`**: system maintenance command (brew update, doom upgrade)
- **brew liberator**: new, macOS-only, with `_maintain()` hook
- **Starship template**: per-host color + hostname via MOLT_PROMPT_HOST_COLOR
- **envsubst fix**: molt_render() only substitutes MOLT_* variables now
- **zsh_check()**: detects missing/dangling starship config
- Removed share_history, cleaned up legacy doom files on rhadamanth

## Key Facts
- `molt upgrade` = config sync (fast). `molt maintain` = system maintenance (slow)
- doom upgrade needs --force (Emacs y-or-n-p can't read from shell stdin)
- Starship template has powerline Unicode chars -- don't use Write tool (strips them)
- ~/.emacs.d.bak on rhadamanth -- remove when confident
- 19 liberators, 83 tests, three sleeves

## Quick Verification
```bash
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt test
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt maintain --dry-run
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt doctor
```
