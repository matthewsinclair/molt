# Session Restart Context

Start here, then read the files below. This file is an index, not a record -- it carries no state of its own, so it cannot go stale.

## Where things stand

- [`wip.md`](wip.md) -- what is in flight and what is next. The only place current work is described.
- [`done.md`](done.md) -- everything completed, newest first. Look here for why something is the way it is.
- [`todo.md`](todo.md) -- generated view; the renderer owns it.

## The work itself

- [`st/`](st) -- steel threads. `info.md`, `acceptance.md` and `steel_threads.md` are renderer-owned; `design.md`, `impl.md` and `tasks.md` are authored.
- [`docs/`](docs) -- project documentation.
- [`eng/`](eng) -- engineering notes.
- [`ref/`](ref) -- reference material.
- [`llm/`](llm) -- LLM working context.

## Coordination

- [`whiteboard/README.md`](whiteboard/README.md) -- node roster and who is obliged to read whose inbox. Two nodes: `hv` (human) and `vc`. Molt has no control node, so `vc` both validates and, when hv says so, builds.

## Project files outside intent/

- `VERSION` -- single source of truth for the version number.
- `CHANGELOG.md` -- Keep a Changelog format.
- `lib/`, `liberators/`, `bin/`, `test/` -- the framework itself.
- `../molt-matts/` -- the user config repo this framework renders from. Note the directory is `Molt-matts` on the Macs while every reference to it is lowercase; see `wip.md`.
