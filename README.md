[![Molt Tests](https://github.com/matthewsinclair/molt/actions/workflows/tests.yml/badge.svg)](https://github.com/matthewsinclair/molt/actions/workflows/tests.yml)

# MOLT: My Opinionated Local Terminal

<p align="center">
  <img src="design/molt-logo.svg" alt="MOLT logo" width="150">
</p>

Your shell config is your identity. Every new machine is just a new body.

MOLT is a cross-platform, multi-machine personal shell environment tool. It takes your zsh config, dotfiles, and dev environment setup and makes them portable, reproducible, and bootstrappable from a single command on a fresh machine.

Think of it as what [Omarchy](https://github.com/basecamp/omarchy) does for Linux desktop config, but for shell and dev environments across macOS and Linux.

## The name

"Molt" is the biological process of shedding an exoskeleton to grow a new one. The backronym is **My Opinionated Local Terminal**. Both readings work: you shed the default shell and replace it with yours.

## Framework and config repo

MOLT separates the framework from your personal config:

| Repo                              | What it contains                                              | Shared?         |
| --------------------------------- | ------------------------------------------------------------- | --------------- |
| **Molt** (this repo)              | Framework: CLI, core libs, liberator runner, tests            | Yes: the engine |
| **Molt-{user}** (eg `Molt-flynn`) | Your config files, dotfiles, manifest, per-instance overrides | No: your soul   |

Directory names are exact-case: the framework's checkout is `Molt` and your config repo's is `Molt-{user}`, while the GitHub repos are lowercase (`molt`, `molt-{user}`). On a case-sensitive Linux disk a lowercase directory is a different directory.

The framework finds your personal repo by searching for `Molt-$(whoami)` (or `molt-$(whoami)`) in `$MOLT_CFG_DIR`, then `$MOLT_PRJ_DIR`, then `~`, and last for `~/.molt-$(whoami)`. The first of these that holds a `config/` directory is the one it uses. Your personal repo contains a `config/` directory with dotfiles and a `molt.toml` manifest declaring which liberators to run.

This separation means you can fork the framework independently from your config, and your config never contains framework code.

To create a personal repo, run `molt new-user <you>`. [Creating a New User Config Repo](docs/guides/new-user.md) describes what it makes.

## Quick start

With [Homebrew](https://brew.sh), on macOS or Linux:

```bash
brew install matthewsinclair/molt/molt
```

[Getting Started](docs/guides/getting-started.md) describes the steps after the install. To work on Molt itself, use a dev checkout, as its [maintainer section](docs/guides/getting-started.md#for-the-maintainer-of-a-dev-checkout) describes.

## Concepts

In Molt, your config is your cortical stack, your consciousness. Every machine is just a sleeve it gets loaded into.

| Term           | What it means                                                                      |
| -------------- | ---------------------------------------------------------------------------------- |
| **stack**      | Your dotfiles and config bundle. The portable identity.                            |
| **sleeve**     | A target machine that receives your stack.                                         |
| **needlecast** | Push your stack to a remote machine. Not built yet: there is no such command.      |
| **resleeve**   | Bootstrap a fresh machine from your stack.                                         |
| **zen**        | Molt's voice on each machine: the `Zen:` that opens its messages.                  |
| **liberators** | Config modules. Each one frees you from a default.                                 |
| **molt.toml**  | The manifest file. The authoritative source of truth for what your stack contains. |

## CLI

```bash
molt resleeve              # Bootstrap the current machine from your stack
molt resleeve --dry-run    # Preview what resleeve would do, without changing anything
molt upgrade               # Update the framework and config, run upgrade hooks, resleeve
molt upgrade --self        # Update framework + config repos only (no hooks, no resleeve)
molt upgrade --dry-run     # Preview what upgrade would do
molt upgrade zsh,git       # Run upgrade hooks for specific liberators only
molt upgrade --no-resleeve # Upgrade without resleeve
molt upgrade --resleeve    # Resleeve after a targeted upgrade too
molt upgrade --no-pull     # Upgrade without pulling first
molt maintain              # Run system maintenance (brew upgrade, doom upgrade, etc.)
molt maintain --dry-run    # Preview maintenance actions
molt maintain brew         # Maintain specific liberators only
molt new-user <user>       # Scaffold a new Molt-{user} config repo (prompts for details)
molt status                # Show sleeve state and liberator status
molt list                  # List liberators with enabled/installed status
molt agent list            # List this sleeve's agents: name, role, enabled, state, home
molt agent roles           # List the roles this sleeve declares, a disabled one marked
molt agent start <role>    # Start the agent in its home, as claude start --name <hostname>-<role>
molt agent home <role>     # Print the agent's home
molt agent config <role>   # An agent's home, its files' state, and its permission rules by layer
molt git <cmd>             # Run a git command across all managed repos
molt doctor                # System diagnostics and health checks
molt test [liberator]      # Run bats test suite (all or one liberator), in the dev tree only
molt version               # Show the version, the tree (dev, opt or brew) and its commit
molt help                  # Show help
```

`molt help` is the full list, with every flag.

[Keeping up to date](docs/guides/getting-started.md#keeping-up-to-date) says how `molt upgrade` updates Molt from brew. The [maintainer section](docs/guides/getting-started.md#for-the-maintainer-of-a-dev-checkout) covers the dev and opt trees.

## Configuration

### MOLT_PRJ_DIR

The only required setting. Tells molt where to find repos. Set it in your shell config (eg `.zshenv`):

```bash
export MOLT_PRJ_DIR="$HOME/Devel/prj"
```

### MOLT_CFG_DIR

Where your config repo lives, kept apart from development projects. Defaults to the `cfg/` sibling of `MOLT_PRJ_DIR`, so `~/Devel/prj` gives `~/Devel/cfg`. If you move your config repo, run `molt resleeve` from a shell that is already open. Until then, the dotfile symlinks point at the old location.

### Other environment variables

| Variable         | Purpose                       | Default                          |
| ---------------- | ----------------------------- | -------------------------------- |
| `MOLT_PRJ_DIR`   | Where repos live              | _(none: must be set)_            |
| `MOLT_CFG_DIR`   | Where your config repo lives  | `$(dirname "$MOLT_PRJ_DIR")/cfg` |
| `MOLT_OPT_DIR`   | Where opt-style installs live | `$(dirname "$MOLT_PRJ_DIR")/opt` |
| `MOLT_AGT_DIR`   | Where sleeve agents live      | `$(dirname "$MOLT_PRJ_DIR")/agt` |
| `MOLT_LOCAL_BIN` | Where to symlink executables  | `~/.local/bin`                   |
| `UTILZ_HOME`     | Override Utilz repo location  | `$MOLT_PRJ_DIR/Utilz`            |

### MOLT_CLAUDE_CONFIG_DIR

Declare it in a sleeve's `instances/<host>/vars.sh` to move Claude Code's state out of `$HOME`. [Sleeve Agents](docs/guides/sleeve-agents.md#moving-claude-codes-state-out-of-home) describes the move and what it publishes. A sleeve that declares nothing keeps `~/.claude`.

## Liberators

A liberator is a config module that frees you from one default. Each liberator implements a lifecycle of functions, which [Writing a Liberator](docs/guides/writing-a-liberator.md) sets out.

Liberators **never install packages**, with these exceptions. A liberator installs its own subject from a Homebrew tap: Intent, Gtools, cldr, pplr, and Utilz on a `source = "brew"` sleeve. The `brew` liberator installs what a sleeve's own `Brewfile` lists. The `keys` liberator builds keyd from source. The `editors` liberator clones Doom Emacs and the LazyVim starter when they are missing. The `claude` liberator uses npm to install the ccstatusline version that `config/ccstatusline/package.json` pins. Otherwise, liberators check for prerequisites and fail with a hint if something is missing. You install packages yourself, or list them in the sleeve's `Brewfile`; liberators handle configuration.

A sleeve's `Brewfile` is `instances/<host>/Brewfile` in your config repo, in Homebrew's own format, eg `brew "pigz"`. With one, the `brew` liberator's check fails while Homebrew lacks anything it lists, naming each, and `molt resleeve` installs what is missing with `brew bundle install`. The file is a minimum: nothing it leaves out is removed, and nothing it lists is upgraded except by `molt maintain`. A sleeve without one is unchanged.

The framework discovers liberator scripts in `liberators/`, loads them on demand, and runs them through the lifecycle automatically.

### Built-in liberators

| Liberator      | Concern                                                       | OS           |
| -------------- | ------------------------------------------------------------- | ------------ |
| system         | Verify sudo, the sudo or wheel group (linux) and brew (macos) | linux, macos |
| local-bin      | `~/.local/bin` directory, a check of molt's link              | linux, macos |
| zsh            | Shell, Starship, config links, ssh tab colours                | linux, macos |
| git            | Git + git-lfs verification, gitconfig linking                 | linux, macos |
| tmux           | Tmux verification, config linking                             | linux, macos |
| editors        | Doom Emacs + LazyVim, config linking, dock pin                | linux, macos |
| alacritty      | Alacritty config linking, dock pin                            | linux, macos |
| gnome-terminal | GNOME Terminal profile via dconf                              | linux        |
| iterm2         | iTerm2 dynamic profile linking                                | macos        |
| terminal-app   | Terminal.app profile import                                   | macos        |
| keys           | keyd build from source, key remapping                         | linux        |
| desktop        | GNOME keys, GTK stylesheet, dock favourites                   | linux        |
| tiling         | Tactile GNOME extension grid tiling                           | linux        |
| vscode         | VS Code settings linking, CLI setup, dock pin                 | linux, macos |
| dev-tools      | CLI tools (jq, tree, rg, fzf, curl)                           | linux, macos |
| mise           | mise runtime manager, off in the templates                    | linux, macos |
| ssh            | SSH key detection, config rendering + fragments               | linux, macos |
| utilz          | Utilz, from a checkout or Homebrew, per sleeve                | linux, macos |
| brew           | Homebrew maintenance, and what a sleeve's `Brewfile` lists    | linux, macos |
| intent         | Intent from Homebrew, what PATH and gate run                  | linux, macos |
| gtools         | Gtools from Homebrew, from its private tap                    | linux, macos |
| pplr           | pplr from Homebrew, or the dev or opt tree `pplr use` chose   | macos        |
| web            | Web scraper for LLMs, linked into ~/.local/bin                | linux, macos |
| claude         | Claude Code config, and its state out of $HOME                | linux, macos |
| env            | Publishes the sleeve's variables, shell and GUI               | linux, macos |
| npm            | ~/.npmrc, with npm's cache under XDG                          | linux, macos |
| agents         | A home for each sleeve agent, from its role                   | linux, macos |
| backup         | Checks the SuperDuper NAS backup; observes only               | macos        |
| herdr          | Herdr's key bindings and hrdrcfg config linking               | macos        |
| arngz          | arngz window desks, config directory linking                  | macos        |
| menuz          | menuz menu bar config, directory linking                      | macos        |
| hammerspoon    | Hammerspoon init.lua linking                                  | macos        |
| cldr           | cldr from Homebrew, config directory linking                  | linux, macos |
| karabiner      | Karabiner-Elements config directory linking                   | macos        |

### molt.toml

The manifest lives in your personal config repo. It declares which liberators to run and on which platforms:

```toml
[stack]
name = "my-stack"
version = "0.1.0"
user_repo = "Molt-{user}"           # read by molt doctor only

[[liberator]]
name = "zsh"
enabled = true
os = ["linux", "macos"]

[[liberator]]
name = "keys"
enabled = false              # disabled: toggle when ready
os = ["linux"]
```

Instance-specific manifests can override the repo-level one. MOLT checks `instances/{hostname}/molt.toml` first, then falls back to the repo root.

A liberator may also read keys of its own from its entry. `utilz` takes `source = "checkout"`, the default, or `source = "brew"`. `gtools` takes `source = "brew"`, the default, or `source = "switch"`, which holds its dev, opt and brew trees for `gtools use` to choose between.

A sleeve declares its agents, the local agents that do machine work on it as you, in `[[agent]]` entries, as [Sleeve Agents](docs/guides/sleeve-agents.md#declaring-an-agent) describes.

## Your config repo layout

```
Molt-{user}/
  config/
    zsh/zshrc                        # -> ~/.zshrc
    zsh/zshenv                       # -> ~/.zshenv
    zsh/zprofile                     # -> ~/.zprofile
    git/gitconfig                    # -> ~/.gitconfig
    tmux/tmux.conf                   # -> ~/.tmux.conf
    doom/                            # -> ~/.config/doom
    alacritty/alacritty.toml         # -> ~/.config/alacritty/alacritty.toml
    starship/starship.toml           # -> ~/.config/starship.toml
    ssh/config.tmpl                  # -> ~/.ssh/config (rendered via envsubst)
  instances/
    kovacs/                          # Per-machine overrides
      molt.toml                      # Instance manifest
      vars.sh                        # Template variables (MOLT_PRJ_DIR, etc)
      instance.toml                  # [terminal] colours for the iTerm2 ssh wrapper
      ssh/config.d/                  # Instance-specific SSH config fragments
      keyd/default.conf              # Machine-specific keyd config
    rhadamanth/
      molt.toml
      vars.sh
      Brewfile                       # Packages this sleeve needs, which the brew liberator installs
```

Liberators use `molt_link` to symlink config files from your repo into their expected locations. Existing files are backed up automatically. Template files (`.tmpl`) are rendered via `envsubst` using instance-specific variables.

## Personality

MOLT has opinions and says so. The tone is dry, terse, and functional. Output during a resleeve feels like waking up, not like installing software.

## Platform support

Run every day on:

- macOS on Apple silicon: rhadamanth and gyges
- Ubuntu 26.04 on ARM64: kovacs, a Parallels VM
- Raspberry Pi OS (Debian 13, trixie) on ARM64: farcaster and pihole

CI runs the suite on Ubuntu at every push to main, and on macOS for each release candidate.

Written for, but not yet run on any sleeve: Intel Macs, Fedora and RHEL, Arch, and WSL2. On Fedora, RHEL and Arch the `system` liberator takes the wheel group as well as sudo.

## Project structure

```
Molt/
  bin/           # molt, the CLI entry point (thin coordinator); bootstrap.sh; devbin, the dev launcher
  lib/           # the framework; constants.sh holds the framework's paths and defaults
  liberators/    # one script per liberator
  templates/     # what Molt renders or copies: the molt-user/ skeleton and molt.toml.example, the claude, agents and npm files, and the AppArmor profile
  test/          # bats suites (test_helper.bash is the shared harness, and its setup gives each test a HOME of its own), liberators/ for per-liberator suites, manual/ for probes run by hand
  tools/         # test-bash32, the suite under /bin/bash 3.2 as a release gate
  packaging/     # homebrew/, the formula template
  docs/          # guides/, notes/ and blog/
  design/        # the logo
  intent/        # Intent's project files: steel threads, issues, and llm/, the docs for coding agents
```

## Dependencies

[Getting Started](docs/guides/getting-started.md#prerequisites) lists what Molt needs on a sleeve.

## Documentation

- [Getting Started](docs/guides/getting-started.md): first-time setup walkthrough
- [Creating a New User Config Repo](docs/guides/new-user.md): scaffold a `Molt-{user}` repo with `molt new-user`
- [Writing a Liberator](docs/guides/writing-a-liberator.md): how to create your own config modules
- [Template System](docs/guides/templates.md): per-instance config rendering with `envsubst`
- [Sleeve Agents](docs/guides/sleeve-agents.md): a home for each machine's local agent, and Claude Code's state moved out of `$HOME`
- [Bootstrap Runbook](docs/guides/bootstrap-runbook.md): the steps you do by hand on a new sleeve

## Status

Releases go out through Homebrew, as the [quick start](#quick-start) installs them, and [CHANGELOG.md](CHANGELOG.md) says what each one changed.

## License

MIT
