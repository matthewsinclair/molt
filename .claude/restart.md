# Claude Restart Context

## Current WIP

- **ST0001**: Bootstrap -- all phases complete (1-6)
- Next: verify CI passes, deploy to gyges/kovacs, fix gyges git remotes

## Key Changes This Session

- **VERSION file**: single source of truth, constants.sh reads it
- **CHANGELOG.md**: Keep a Changelog format
- **CI/CD**: tests.yml (Linux + macOS + ShellCheck), pr-checks.yml (docs, commits, PR size)
- **CI fix**: git identity config for test runners (git.bats needs user.name/email)
- **Docs**: README (CLI, lifecycle, liberators, badge), getting-started (maintain, self-update)
- **iTerm2 SSH colors**: per-host background tinting in molt-matts
- **Tagged v0.1.0**

## Key Facts

- VERSION at project root is the single source of truth for version
- CI needs git user identity for git.bats tests (configured in workflow)
- iTerm2 SSH colors live in molt-matts (user config), not framework
- `molt upgrade` = config sync (fast). `molt maintain` = system maintenance (slow)
- doom upgrade needs --force (Emacs y-or-n-p can't read from shell stdin)
- Starship template has powerline Unicode chars -- don't use Write tool (strips them)
- 19 liberators, 83 tests, three sleeves

## Quick Verification

```bash
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt test
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt maintain --dry-run
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt doctor
```
