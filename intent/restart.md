# Session Restart Context

## Last Session: 10 Mar 2026

### What Was Done

- Added `molt git <cmd>` for centralised git operations across all managed repos
  - Convention functions: `{name}_repo()`, `{name}_repo_git_commands()` on 5 liberators
  - Whitelist enforcement for liberator repos (default: pull/status/log/diff/fetch)
  - Auto-detect remote via `_git_detect_remote()` for pull/fetch/push
  - Fixed stdout contamination from liberator_load debug in molt_all_repos
  - Refactored editors_upgrade() to reuse editors_repo()
- Fixed Intent bin/intent symlink resolution (same pattern as bin/molt)
- 77 tests passing (28 new in test/git.bats)

### What's Next

- Fix git remote/tracking on gyges: remotes named "upstream", missing fetch refspecs
  - Fix: `git config remote.upstream.fetch '+refs/heads/*:refs/remotes/upstream/*'`
  - Then: `git fetch upstream && git branch --set-upstream-to=upstream/main main`
- Persist GNOME Terminal Super bindings in gnome-terminal liberator
- Export iTerm2 + Terminal.app profiles from rhadamanth
- Run `molt resleeve` on rhadamanth and kovacs (need MOLT_PRJ_DIR in .zshenv)

### Key Context

- Three sleeves: gyges (macOS M2), rhadamanth (macOS M4), kovacs (Ubuntu ARM64 VM)
- `molt git` auto-detects remotes: checks branch tracking first, falls back to sole remote
- gyges repos have remotes named "upstream" (not "origin") with missing fetch refspecs
- Intent symlink fix: bin/intent now resolves symlinks like bin/molt does
- 18 liberators, 77 tests
- `MOLT_PRJ_DIR` required (no default) -- set in `.zshenv`
