---
verblock: "3 Nov 2026:v0.1: Matthew Sinclair - vc: Molt's own rules, not the starter text (issue 0083)"
---

# RULES.md

Mandatory rules for working on Molt. Every statement is a must or a never.

## Where the rules live

- **The four cross-language principles** (Highlander, PFIC, Thin Coordinator, No Silent Errors): "Rules of the Road" in `AGENTS.md`.
- **Shell**: the installed Intent tool serves the shell rules, and none of them is copied into this repo. `intent claude rules list --lang shell` lists them, `intent claude rules show <id>` reads one, and `critic-shell` and the pre-commit gate apply them.
- **Liberators**: the Rules section of `docs/guides/writing-a-liberator.md`.
- **Which file owns a concern**: [MODULES.md](MODULES.md). Where new code goes: [DECISION_TREE.md](DECISION_TREE.md).

## Molt's own

- The framework **never** carries one person's or one machine's config. Dotfiles, settings, per-host values and anything only one user runs belong in that user's stack, `Molt-<user>`, which liberators link or render from.
- Framework code **must** run under macOS's `/bin/bash` 3.2 as well as a current bash. **Never** use what bash 4 added: associative arrays, `mapfile` or `readarray`, `${var,,}` and `${var^^}`, or namerefs. **Never** expand an array that may be empty while `set -u` is on, which 3.2 refuses as unbound.
- Framework code and its tests **must** pass the suite under both bashes before they are pushed: `MOLT_PRJ_DIR=$HOME/Devel/prj bin/molt test`, then the same with `PATH=/bin:$PATH` first. `bin/devbin test all` runs both, as every release's gates do. CI's only bash 3.2 run is its macOS job, which runs on a release candidate or on demand.
- A test **never** builds its expected value with the code under test: `test_hostname`, not `molt_hostname` (issue 0020).
- A test that must find no stack, or only its own, **must** set `MOLT_USER_REPO_SEARCH_PATHS` to its own repo or to one empty folder, **never** to an empty array, and only after it has loaded Molt's libs (`load_molt_libs`, which the first `load_liberator` calls), since `lib/constants.sh` rebuilds the list. With `MOLT_PRJ_DIR` set, the default search reaches the real `Molt-<user>`.
