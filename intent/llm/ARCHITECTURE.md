---
verblock: "3 Nov 2026:v0.1: Matthew Sinclair - vc: Molt's architecture, not the starter text (issue 0083)"
---

# ARCHITECTURE.md

How Molt is built, and how one run moves through it. `README.md` has the concepts (stack, sleeve, liberator, `molt.toml`), the layout of both repos and the CLI. [MODULES.md](MODULES.md) says which file owns each concern, [DECISION_TREE.md](DECISION_TREE.md) says where new code goes, and [RULES.md](RULES.md) holds the rules.

## Framework and stack

Molt is the framework and holds nobody's config. A user's stack, `Molt-<user>`, holds `config/`, the files liberators link or render into place, and `instances/<hostname>/`, one directory per sleeve with its `molt.toml`, `vars.sh` and overlays. `molt_find_user_repo` takes the first directory holding a `config/` among `MOLT_USER_REPO_SEARCH_PATHS`, which `lib/constants.sh` builds: `Molt-<user>`, then its lowercase form, under `MOLT_CFG_DIR`, then under `MOLT_PRJ_DIR`, then in `~`, and last `~/.molt-<user>`.

## The layers

`bin/molt` finds `MOLT_ROOT` from its own resolved path, sources `lib/`, and hands each verb to a `cmd_*` function. It is a thin coordinator: it parses, calls and prints, and the logic is in `lib/`. `lib/` is the framework. `molt.sh` holds the core helpers (logging, platform, linking, rendering, the manifest, Homebrew) and most verbs; `liberator.sh` loads and runs liberators; `env.sh`, `install.sh`, `agent.sh` and `newuser.sh` each own one concern; and `constants.sh` holds every configurable path and default. `liberators/` holds one script per liberator, sourced on demand, each defining `<name>_check` and `<name>_install`, with optional `_upgrade`, `_maintain` and `_verify`.

## One run

`molt resleeve` finds the stack, then the liberators the sleeve's `molt.toml` enables for this platform, in manifest order. With no manifest it runs every liberator Molt ships, and a manifest that enables none for this platform is refused. For each liberator it runs `<name>_check`, and `<name>_install` only when the check fails. An unknown name is skipped with a warning, a failed install is reported and the run goes on, and the run fails at the end naming each failure. Order is how one liberator waits for another: `env` comes after `claude`, which hands over `CLAUDE_CONFIG_DIR` only once Claude Code's state has moved.

`molt upgrade` updates the framework as its tree allows: it pulls a dev tree, fast-forward only, upgrades the formula for a brew tree, and leaves an opt tree to `molt install --force`. It pulls the stack too, restarts on the new code when the framework changed, runs each liberator's `_upgrade` hook, and then resleeves, unless it was told not to or named only some liberators. `molt maintain` runs the slow `_maintain` hooks. `molt doctor` installs nothing: it runs each enabled liberator's `_check` and Molt's own checks, and names what did not pass.

## What a run leaves on a sleeve

- Links into the stack from `$HOME` and the XDG config dir, made by `molt_link`, which first moves a real file it would replace to `<target>.molt-backup.<timestamp>`.
- Files rendered with `envsubst` and the instance's `vars.sh`, from the stack's `.tmpl` files and Molt's own `templates/` (`docs/guides/templates.md`).
- The published environment, rebuilt whole on each run by `lib/env.sh`, Molt's one env writer: `~/.config/molt/env.sh`, which the stack's `zshenv` sources, and the GUI file, a LaunchAgent on macOS and an `environment.d` file on Linux. The `env` liberator gathers its values: `CLAUDE_CONFIG_DIR` from the `claude` liberator and, where ccusage is installed, `CLAUDE_SECURESTORAGE_CONFIG_DIR`, a command pair that `env.sh` and the LaunchAgent read from `ccusage dir` each time they run; each `<TOOL>_INSTALL_PREFIX` the instance's `vars.sh` exports; and, for GUI apps only, a login shell's `PATH`.
- `~/.local/bin/molt`, the switch link `molt use` sets for a dev or opt tree. With no link, Homebrew's molt answers.

## Trees and releases

A tree is a directory holding the runtime set: `bin/molt`, `lib/`, `liberators/`, `templates/` and `VERSION`. dev is the git checkout. opt is what `molt install` publishes from a clean dev tree to the prefix the instance's `vars.sh` declares, and brew is the same publish, run by the Homebrew formula in its keg. Each published tree carries a `.molt-install` manifest of its files' hashes. `molt use dev` or `molt use opt` points the switch link at that tree's `bin/molt`, and `molt use brew` removes the link (`lib/install.sh`).

A release is one command, `bin/devbin release vX.Y.Z`, devbin's release core, which `bin/.devbin/config.yaml` declares (issue 0087). It stamps `VERSION`, dates the version's `CHANGELOG.md` section, written `## [X.Y.Z] - unreleased` until then, and commits. It then runs the gates, `check all`, `test all` and `doctor`, where `test all` is the suite under the bash PATH finds and again with `/bin` first, under `/bin/bash` 3.2. Meanwhile CI runs on the release commit pushed to `candidate/<tag>`, the macOS job included. Once every leg is green it tags, pushes to both remotes, makes the GitHub release with the section as its notes, and runs `bin/devbin formula publish`, which renders `packaging/homebrew/molt.rb` for the tag into the `matthewsinclair/homebrew-molt` tap. `tools/`, outside the runtime set because nothing on a sleeve runs it, holds `test-bash32`, the `/bin/bash` 3.2 gate.

## Tests and CI

`molt test` runs ShellCheck, then bats over `test/` and `test/liberators/`, which holds the liberators' suites, with `test/test_helper.bash` as the shared harness. It runs in the dev tree only. CI runs the suite on Linux at every push to main or to a release candidate, and on macOS, whose bash is 3.2, only on a release candidate or tag, or on demand. ShellCheck runs on every push.

## Why it is built this way

The steel threads' design records and the closed issues hold the reasons: `intent st list --status all` and `intent issues list --kind all`.
