# Claude Restart Context

This file is the entry point and holds no state. It says where to start; what is in flight lives in the files it points at, which are kept current and this one is not.

## Start Here

1. Run `/in-session`. It loads the skills, releases the prompt gate, and chains `/in-whiteboard pickup`. The declared language is `shell`: there is no essentials skill, so the rules come from `intent claude rules list --lang shell` and the `critic-shell` subagent.
2. Read [`intent/restart.md`](../intent/restart.md), the index of where things are, then [`intent/wip.md`](../intent/wip.md), the only place current work is described.
3. As `vc`, read every `hv/inbox.*` before reporting anything else and put what is in it in front of hv. [`intent/whiteboard/README.md`](../intent/whiteboard/README.md) says why.

## Nodes

The roster is the one in [`intent/whiteboard/README.md`](../intent/whiteboard/README.md): who each node is, what it builds or checks, and who reads `hv/inbox.*`.

## Durable Facts

- **Autoload files contain the BODY ONLY**: a `name() { ... }` wrapper makes the first call silently no-op, then work. `jump` and `git_current_branch` are the convention in `Molt-matts/config/zsh/functions/`.
- `fpath` and `autoload` are read at shell startup: changes need a fresh shell, not a `source`.
- `VERSION` at the project root is the single source of truth for the version.
- A test that commits names its own git identity, as `git.bats` does: `test/test_helper.bash` gives git an empty global config, so no machine's or runner's identity is read (issue 0062), and CI sets none.
- iTerm2 SSH colours live in Molt-matts (user config), not the framework.
- `molt upgrade` = config sync (fast). `molt maintain` = system maintenance (slow).
- `doom upgrade` needs `--force` (Emacs `y-or-n-p` cannot read from shell stdin).
- The Starship template has powerline Unicode characters: do not rewrite it with the Write tool, which strips them.
- `intent/wip.md` and a thread's attached `design`/`impl`/`tasks` are AUTHORED; `intent/st/**/info.md`, `acceptance.md`, `steel_threads.md` and `todo.md` are GENERATED and fenced in `.prettierignore`.
- Never use `intent st edit`: it opens an editor only on a terminal, and elsewhere prints a path, first writing the thread's files to disk when they are not there. Write a thread's prose with `intent set <ID> objective|context --from <file>`.

## Quick Verification

Measure these; never quote a count from a file.

```bash
MOLT_PRJ_DIR=$HOME/Devel/prj bin/devbin test all   # the suite under Homebrew bash, then /bin/bash 3.2 (tools/test-bash32), as a cut's gates run it
MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt doctor
intent doctor
intent wb status
```
