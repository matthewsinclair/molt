# Module Registry

> **The Highlander Rule**: There can be only one module per concern. ALWAYS check this file before creating a new script or helper function. If a module already owns that concern, use it. When you must create a new module, register it here FIRST, then create the file.

## Framework

| Module                | File                         | Concern                                                                                                                                                           |
| --------------------- | ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| molt (CLI)            | `bin/molt`                   | Main entry point, arg parsing, command dispatch                                                                                                                   |
| bootstrap             | `bin/bootstrap.sh`           | A fresh machine's dev checkout: clones the framework and the user repo, links `~/.local/bin/molt`, runs a dry-run resleeve, asks before the real one              |
| molt (constants)      | `lib/constants.sh`           | All configurable paths and defaults (single source of truth)                                                                                                      |
| molt (core)           | `lib/molt.sh`                | Core helpers (logging, platform, linking, rendering, the manifest, Homebrew, GNOME settings) and most verbs: list, doctor, test, resleeve, upgrade, maintain, git |
| molt (agent)          | `lib/agent.sh`               | Sleeve agents: the [[agent]] entries, each agent's home, `molt agent` (ST0006, ST0007)                                                                            |
| molt (env)            | `lib/env.sh`                 | Molt's one env writer: the variables a sleeve's shells and GUI apps get (ST0008 WP05)                                                                             |
| molt (install)        | `lib/install.sh`             | The trees Molt runs from (dev, opt, brew): `molt install`, which publishes one, `molt use`, which picks the one that serves molt, and the version line (ST0008)   |
| liberator (framework) | `lib/liberator.sh`           | Liberator loading and discovery, and running each one's check, install, upgrade and maintain                                                                      |
| newuser               | `lib/newuser.sh`             | Scaffold a new `Molt-{user}` config repo from the template skeleton                                                                                               |
| formula               | `tools/formula`              | Renders Molt's Homebrew formula for a release tag, and publishes it to the tap                                                                                    |
| formula template      | `packaging/homebrew/molt.rb` | Molt's Homebrew formula as a template, which `tools/formula` fills                                                                                                |
| devbin (vendored)     | `bin/devbin`, `bin/.devbin/` | devbin's dev launcher, vendored: devbin owns it                                                                                                                   |

## Liberators

| Module         | File                           | Concern                                                                                         |
| -------------- | ------------------------------ | ----------------------------------------------------------------------------------------------- |
| system         | `liberators/system.sh`         | Verifies sudo, the sudo group (linux) and Homebrew (macos)                                      |
| zsh            | `liberators/zsh.sh`            | zsh as the login shell, Starship prompt, config linking, iTerm2 ssh tab colours                 |
| git            | `liberators/git.sh`            | Git + git-lfs verification, gitconfig linking                                                   |
| tmux           | `liberators/tmux.sh`           | Tmux verification, config linking                                                               |
| editors        | `liberators/editors.sh`        | Doom Emacs + LazyVim installation, config linking                                               |
| alacritty      | `liberators/alacritty.sh`      | Alacritty config linking (linux, macos)                                                         |
| gnome-terminal | `liberators/gnome-terminal.sh` | GNOME Terminal dconf profile management (linux)                                                 |
| iterm2         | `liberators/iterm2.sh`         | iTerm2 dynamic profile linking (macos)                                                          |
| terminal-app   | `liberators/terminal-app.sh`   | Terminal.app profile import and default setting (macos)                                         |
| keys           | `liberators/keys.sh`           | keyd build from source, config from instance (Linux)                                            |
| desktop        | `liberators/desktop.sh`        | GNOME settings, GTK config (Linux)                                                              |
| tiling         | `liberators/tiling.sh`         | Tactile GNOME extension grid tiling (Linux)                                                     |
| vscode         | `liberators/vscode.sh`         | VS Code settings linking, CLI setup, dock pin                                                   |
| dev-tools      | `liberators/dev-tools.sh`      | CLI tools (jq, tree, rg, fzf, curl)                                                             |
| mise           | `liberators/mise.sh`           | mise runtime manager, off on every sleeve                                                       |
| npm            | `liberators/npm.sh`            | ~/.npmrc, npm's cache under XDG (issue 0031)                                                    |
| ssh            | `liberators/ssh.sh`            | SSH key detection or generation, config rendering + config.d fragments                          |
| local-bin      | `liberators/local-bin.sh`      | `~/.local/bin` (MOLT_LOCAL_BIN), and the molt link `molt use` sets                              |
| intent         | `liberators/intent.sh`         | Intent from Homebrew, what PATH and the pre-commit gate run                                     |
| gtools         | `liberators/gtools.sh`         | Gtools from Homebrew, private tap over ssh (issue 0057)                                         |
| pplr           | `liberators/pplr.sh`           | Pplr people/contacts manager, from a checkout, linked into `~/.local/bin`                       |
| utilz          | `liberators/utilz.sh`          | Utilz from a checkout (linked into `~/.local/bin`, with bats-core) or from Homebrew, per sleeve |
| web            | `liberators/web.sh`            | Web scraper for LLMs, from `$MOLT_OPT_DIR/web`, its binary linked into `~/.local/bin`           |
| brew           | `liberators/brew.sh`           | Homebrew lifecycle, package maintenance (linux, macos)                                          |
| claude         | `liberators/claude.sh`         | Claude Code config, its state out of $HOME (ST0006)                                             |
| env            | `liberators/env.sh`            | Sleeve variables for shells and GUI apps (ST0008 WP05)                                          |
| agents         | `liberators/agents.sh`         | A home for each sleeve agent, from its role (ST0006)                                            |
| backup         | `liberators/backup.sh`         | Checks the SuperDuper NAS backup; observes only (macos)                                         |
| herdr          | `liberators/herdr.sh`          | Herdr keys.json and hrdrcfg directory linking (macos)                                           |
| arngz          | `liberators/arngz.sh`          | arngz desks directory linking (macos)                                                           |
| menuz          | `liberators/menuz.sh`          | menuz menu and bin/ directory linking (macos)                                                   |
| hammerspoon    | `liberators/hammerspoon.sh`    | Hammerspoon init.lua linking, arngz's hs CLI (macos)                                            |
| cldr           | `liberators/cldr.sh`           | cldr from Homebrew, ~/.config/cldr directory linking                                            |
| karabiner      | `liberators/karabiner.sh`      | Karabiner-Elements config directory linking (macos)                                             |

## Testing

| Module           | File                          | Concern                                                                                                                                   |
| ---------------- | ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| test_helper      | `test/test_helper.bash`       | Shared bats harness: each test's temporary directory and HOME, stubs for sudo, launchctl and apparmor_parser, a fake Homebrew, assertions |
| framework suites | `test/<concern>.bats`         | One file per framework concern, named for it, eg `manifest.bats`, `install.bats`, `newuser.bats`                                          |
| liberator suites | `test/liberators/<name>.bats` | One file per liberator that has a suite of its own, named for the liberator                                                               |
| manual probes    | `test/manual/`                | Probes run by hand, which neither `molt test` nor bats runs                                                                               |

## Templates

| Module             | File                                            | Concern                                                                                                                                        |
| ------------------ | ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| molt.toml          | `templates/molt.toml.example`                   | Stack manifest example                                                                                                                         |
| molt-user skeleton | `templates/molt-user/`                          | Skeleton tree for new `Molt-{user}` config repos (tokenised), which `molt new-user` copies                                                     |
| agent CLAUDE.md    | `templates/agents/CLAUDE.md.tmpl`               | Each agent home's `CLAUDE.md`, which imports its `AGENTS.md` (ST0006)                                                                          |
| AppArmor profile   | `templates/apparmor/bwrap-userns-restrict.tmpl` | Molt's copy of Ubuntu's bwrap profile, for a Linux sleeve with an ops or docs agent (issue 0032)                                               |
| home guard         | `templates/claude/claude-home-guard.sh.tmpl`    | The hook that refuses a Claude Code session launched in `$HOME`, or under the agents root outside a home, rendered to `~/.config/molt/`        |
| home guard hook    | `templates/claude/home-guard-hook.json`         | The settings entry that runs the home guard, in the user settings and each agent home's                                                        |
| retired env files  | `templates/env/retired/`                        | The files the claude liberator published `CLAUDE_CONFIG_DIR` through before the env liberator, kept to tell molt's own copy from an edited one |
| npmrc              | `templates/npm/npmrc.tmpl`                      | `~/.npmrc`, npm's cache under XDG (npm liberator)                                                                                              |

## Documentation

| Module                | File                                                   | Concern                                                                                           |
| --------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| README                | `README.md`                                            | What Molt is: concepts, install, the CLI, the built-in liberators, both repos' layout             |
| changelog             | `CHANGELOG.md`                                         | What each release changed                                                                         |
| getting-started guide | `docs/guides/getting-started.md`                       | First-time setup, keeping a sleeve up to date, and the dev, opt and brew trees                    |
| new-user guide        | `docs/guides/new-user.md`                              | How `molt new-user` scaffolds a config repo                                                       |
| liberator guide       | `docs/guides/writing-a-liberator.md`                   | The liberator contract, and how to write one                                                      |
| templates guide       | `docs/guides/templates.md`                             | Rendering `.tmpl` files with an instance's `vars.sh`, and instance-scoped liberator config        |
| sleeve-agents guide   | `docs/guides/sleeve-agents.md`                         | Sleeve agents, their homes and roles, and Claude Code's state moved out of `$HOME`                |
| bootstrap-runbook     | `docs/guides/bootstrap-runbook.md`                     | Phase 1 manual resleeve of kovacs: the record the liberators were built from, not a specification |
| tn0001                | `docs/notes/tn0001-molt-and-conflab.md`                | Design note: a `conflab` liberator, proposed and not built                                        |
| bl0001                | `docs/blog/bl0001-so-you-want-to-run-a-local-agent.md` | Working notes for a blog piece on running a local agent                                           |
| design brief          | `design/molt-brief.md`                                 | The original design brief                                                                         |
| architecture          | `intent/llm/ARCHITECTURE.md`                           | How Molt is built, and how one run moves through it                                               |
| decision tree         | `intent/llm/DECISION_TREE.md`                          | Where new code goes                                                                               |
| rules                 | `intent/llm/RULES.md`                                  | Molt's own must and never rules                                                                   |
| usage rules           | `usage-rules.md`                                       | The DO / NEVER contract for working in Molt                                                       |
| CI workflows          | `.github/workflows/README.md`                          | What each CI workflow runs, and when                                                              |
