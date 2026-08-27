# Claude Restart Context

## Current WIP

- Nothing in flight. Session of 27 Aug 2026 closed clean (globalfold).
- **ST0001**: Bootstrap -- WIP. WP-04 (document Phase 1 bootstrap steps) and WP-07 (reproducible VM build) open; other eleven done.
- **ST0002**: Completed 2026-03-23.

## Start Here

Run `/in-session`. It loads the skills, releases the prompt gate, and chains `/in-whiteboard pickup`. This project's declared language is `shell` -- no essentials skill; rules come from `intent claude rules list --lang shell` and the `critic-shell` subagent.

The whiteboard has two nodes: `hv` (human, `session_id: none`, heartbeat advisory) and `vc` (validation, currently `paused`). Molt has no control node, so `vc` both validates and, when hv says so, builds. `vc` is the node obliged to read `hv/inbox.*` and surface it to the human -- see `intent/whiteboard/README.md`.

## Key Changes Last Session

- **`dvb`**: shell function installed in molt-matts (`a4e6cb2`) -- walks up from `$PWD` to the nearest `bin/devbin` and runs it. Two defects fixed before landing; verified in a fresh shell and confirmed live by hv.
- **Whiteboard**: `hv` node provisioned and roster README written (`131642d`). Before this the escalation surface had no named reader.
- **Snapshots**: `wip.md`, `restart.md`, `done.md` re-cut. The first two were five months stale and claimed 83 tests / 19 liberators / v0.1.0.

## Key Facts

- Measured 27 Aug 2026: **112 tests**, ShellCheck clean over 27 scripts, **22 liberators**, VERSION **0.1.1**, `intent doctor` 0 findings
- **Autoload files contain the BODY ONLY** -- a `name() { ... }` wrapper makes the first call silently no-op, then work. `jump` and `git_current_branch` are the convention in `molt-matts/config/zsh/functions/`.
- `fpath` and `autoload` are read at shell startup -- changes need a fresh shell, not a `source`
- VERSION at project root is the single source of truth for version
- CI needs git user identity for git.bats tests (configured in workflow)
- iTerm2 SSH colors live in molt-{user} (user config), not framework
- `molt upgrade` = config sync (fast). `molt maintain` = system maintenance (slow)
- `doom upgrade` needs `--force` (Emacs y-or-n-p can't read from shell stdin)
- Starship template has powerline Unicode chars -- don't use the Write tool (strips them)
- `intent/wip.md`, `done.md`, ST `design/impl/tasks` are AUTHORED; `intent/st/**/info.md`, `acceptance.md`, `steel_threads.md`, `todo.md` are GENERATED and fenced in `.prettierignore`
- Never use `intent st edit` -- interactive editor. Edit ST files directly.

## Open Questions for hv

- WP-07's acceptance rows: `molt upgrade` already exists, so which rows tick? `intent ac` change against canon, hv's call.
- `molt-matts` is an Intent project with ZERO steel threads and the `dvb` work landed there untracked. Open its first thread?

## Quick Verification

```bash
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt test
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt doctor
intent doctor
intent claude ws list
```
