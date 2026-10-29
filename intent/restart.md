# Session Restart Context

Start here, then read the files below. This file is an index, not a record -- it carries no state of its own, so it cannot go stale.

## Where things stand

- [`wip.md`](wip.md) -- what is in flight and what is next. The only place current work is described. Finished work is in git, `CHANGELOG.md` and the closed issues.
- [`todo.md`](todo.md) -- generated view; the renderer owns it.
- [`issues/`](issues) -- issues tracked without a steel thread. Use `intent issues list --kind all`; the files are generated.

## The work itself

- [`st/`](st) -- steel threads. `info.md`, `acceptance.md` and `steel_threads.md` are renderer-owned; `design.md`, `impl.md` and `tasks.md` are authored.
- [`docs/`](docs) -- project documentation.
- [`eng/`](eng) -- engineering notes.
- [`ref/`](ref) -- reference material.
- [`llm/`](llm) -- LLM working context.

## Coordination

- [`whiteboard/README.md`](whiteboard/README.md) -- node roster, the project-Claude suffixes, and who is obliged to read whose inbox. The nodes: `hv` (human), `vc` (specifies, validates, merges), `cc` (builds code), `dc` (builds the developer experience), `ac` (authors briefs for hv). The boards are generated views of the store: change them only with `intent wb`.

## Project files outside intent/

- `VERSION` -- single source of truth for the version number.
- `CHANGELOG.md` -- Keep a Changelog format.
- `lib/`, `liberators/`, `bin/`, `test/` -- the framework itself.
- `~/Devel/cfg/Molt-matts/` (`MOLT_CFG_DIR`) -- the user config repo this framework renders from. Its GitHub name is lowercase: `matthewsinclair/molt-matts`.
