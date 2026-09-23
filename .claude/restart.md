# Claude Restart Context

This file is the entry point and holds no state. It says where to start; what is in flight lives in the files it points at, which are kept current and this one is not.

## Start Here

1. Run `/in-session`. It loads the skills, releases the prompt gate, and chains `/in-whiteboard pickup`. The declared language is `shell`: there is no essentials skill, so the rules come from `intent claude rules list --lang shell` and the `critic-shell` subagent.
2. Read [`intent/restart.md`](../intent/restart.md), the index of where things are, then [`intent/wip.md`](../intent/wip.md), the only place current work is described.
3. As `vc`, read every `hv/inbox.*` before reporting anything else and put what is in it in front of hv. [`intent/whiteboard/README.md`](../intent/whiteboard/README.md) says why.

## Nodes

Two: `hv`, the human (`session_id: none`, heartbeat advisory), and `vc`, validation. Molt has no control node, so `vc` both validates and, when hv says so, builds.

## Durable Facts

- **Autoload files contain the BODY ONLY** -- a `name() { ... }` wrapper makes the first call silently no-op, then work. `jump` and `git_current_branch` are the convention in `Molt-matts/config/zsh/functions/`.
- `fpath` and `autoload` are read at shell startup -- changes need a fresh shell, not a `source`.
- `VERSION` at the project root is the single source of truth for the version.
- CI needs a git user identity for the `git.bats` tests (configured in the workflow).
- iTerm2 SSH colours live in Molt-matts (user config), not the framework.
- `molt upgrade` = config sync (fast). `molt maintain` = system maintenance (slow).
- `doom upgrade` needs `--force` (Emacs `y-or-n-p` cannot read from shell stdin).
- The Starship template has powerline Unicode characters -- do not rewrite it with the Write tool, which strips them.
- `intent/wip.md`, `done.md` and a thread's attached `design`/`impl`/`tasks` are AUTHORED; `intent/st/**/info.md`, `acceptance.md`, `steel_threads.md` and `todo.md` are GENERATED and fenced in `.prettierignore`.
- Never use `intent st edit` -- it opens an interactive editor. Write a thread's prose with `intent set <ID> objective|context --from <file>`.

## Quick Verification

Measure these; never quote a count from a file.

```bash
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt test                   # Homebrew bash
PATH=/bin:$PATH MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt test   # bash 3.2, as on CI's macOS runner
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt doctor
intent doctor
intent wb status
```
