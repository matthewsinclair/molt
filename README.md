[![Molt Tests](https://github.com/matthewsinclair/molt/actions/workflows/tests.yml/badge.svg)](https://github.com/matthewsinclair/molt/actions/workflows/tests.yml)

# MOLT — My Opinionated Local Terminal

<p align="center">
  <img src="design/molt-logo.svg" alt="MOLT logo" width="150">
</p>

Your shell config is your identity. Every new machine is just a new body.

MOLT is a cross-platform, multi-machine personal shell environment tool. It takes your zsh/bash config, dotfiles, and dev environment setup and makes them portable, reproducible, and bootstrappable from a single command on a fresh machine.

Think of it as what [Omarchy](https://github.com/basecamp/omarchy) does for Linux desktop config, but for shell and dev environments across macOS and Linux.

## The name

"Molt" is the biological process of shedding an exoskeleton to grow a new one. The backronym is **My Opinionated Local Terminal**. Both readings work: you shed the default shell and replace it with yours.

## Framework and config repo

MOLT separates the framework from your personal config:

| Repo                              | What it contains                                              | Shared?          |
| --------------------------------- | ------------------------------------------------------------- | ---------------- |
| **Molt** (this repo)              | Framework: CLI, core libs, liberator runner, tests            | Yes — the engine |
| **Molt-{user}** (eg `Molt-flynn`) | Your config files, dotfiles, manifest, per-instance overrides | No — your soul   |

Directory names are exact-case: the framework's checkout is `Molt` and your config repo's is `Molt-{user}`, while the GitHub repos are lowercase (`molt`, `molt-{user}`). On a case-sensitive Linux disk a lowercase directory is a different directory.

The framework finds your personal repo by searching for `Molt-$(whoami)` (or `molt-$(whoami)`) in `$MOLT_CFG_DIR`, then `$MOLT_PRJ_DIR`, `~/`, and `~/.`. Your personal repo contains a `config/` directory with dotfiles and a `molt.toml` manifest declaring which liberators to run.

This separation means you can fork the framework independently from your config, and your config never contains framework code.

To create a fresh personal repo, run `molt new-user <you>` — it scaffolds a tokenised `Molt-{user}` skeleton (git + ssh identity, a first instance, a minimal manifest) ready to `git init` and push. No copy-and-find-replace.

## Quick start

### Prerequisites

Set `MOLT_PRJ_DIR` to the directory where your repos live. There is no default — every machine chooses its own layout:

```bash
export MOLT_PRJ_DIR="$HOME/Projects"  # or wherever you keep repos
```

Your config repo is configuration, not a project, so it lives in `MOLT_CFG_DIR`: the `cfg/` directory beside `MOLT_PRJ_DIR` unless you set it yourself.

### Clone and resleeve

```bash
# Framework: the dev tree, exact-case Molt
git clone https://github.com/you/molt "$MOLT_PRJ_DIR/Molt"

# Your config (contains molt.toml + config/ directory)
git clone https://github.com/you/molt-you "$(dirname "$MOLT_PRJ_DIR")/cfg/Molt-you"

# Put ~/.local/bin first on PATH, then link molt there from the checkout, once
export PATH="$HOME/.local/bin:$PATH"
"$MOLT_PRJ_DIR/Molt/bin/molt" use dev

# Preview what would happen
molt resleeve --dry-run

# Bootstrap this machine
molt resleeve
```

```
MOLT v<version> — My Opinionated Local Terminal
Needlecasting stack to new sleeve...
Sleeve: <hostname> | Platform: linux

Zen: Stack found: /home/you/cfg/Molt-you
Zen: Loading liberators...
Zen: Manifest: /home/you/cfg/Molt-you/instances/<hostname>/molt.toml

  system: ✓ ok
  zsh: ✓ installed
  git: ✓ installed
...
Zen: Sleeve ready. Welcome back.
```

"Welcome back" is the key line. You are not setting up a new machine. You are waking up in a new body with all your memories intact.

### Bootstrap script

For a fresh machine where nothing is set up yet:

```bash
MOLT_PRJ_DIR=$HOME/Projects bash <(curl -fsSL https://raw.githubusercontent.com/you/molt/main/bin/bootstrap.sh)
```

The bootstrap script clones the framework into `$MOLT_PRJ_DIR/Molt` and your config repo into `$MOLT_CFG_DIR/Molt-$(whoami)`, links molt into `~/.local/bin`, shows a dry-run, and asks at the terminal before applying.

It clones the framework from `MOLT_REPO` (default `matthewsinclair/molt`) and your config repo from `$MOLT_USER_GH/molt-$(whoami)`, where `MOLT_USER_GH` defaults to your login name. Set `MOLT_USER_GH` when your GitHub handle differs from it, eg `MOLT_USER_GH=flynn-sinclair`.

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
molt install               # Publish this dev tree as the opt tree (--prefix, --force)
molt use [dev|opt|brew]    # Choose which tree serves molt; with none, show which does
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
molt version               # Show the version, the tree (dev, opt or brew), its commit and root
molt help                  # Show help
```

`molt help` is the full list, with every flag.

How `molt upgrade` updates the framework depends on the tree molt runs from. In the dev tree it pulls the checkout. The opt tree is never pulled: publish it again from the dev tree with `molt install --force`. In the brew tree it runs `brew update`, then `brew outdated`, then `brew upgrade` when the formula is outdated.

## Configuration

### MOLT_PRJ_DIR

The only required setting. Tells molt where to find repos. Set it in your shell config (eg `.zshenv`):

```bash
export MOLT_PRJ_DIR="$HOME/Devel/prj"
```

If unset, molt searches `MOLT_CFG_DIR` when that is set, then `~/Molt-{user}`, `~/molt-{user}` and `~/.molt-{user}` as fallbacks, but the primary lookup via `MOLT_PRJ_DIR` is the intended path.

### MOLT_CFG_DIR

Where your config repo lives, kept apart from development projects. Defaults to the `cfg/` sibling of `MOLT_PRJ_DIR`, so `~/Devel/prj` gives `~/Devel/cfg`. molt searches it first and then `MOLT_PRJ_DIR`, so a machine whose config repo is still under `MOLT_PRJ_DIR` keeps working until you move it. After moving it, run `molt resleeve` from a shell that is already open: the dotfile symlinks still point at the old location until then.

### Other environment variables

| Variable         | Purpose                       | Default                          |
| ---------------- | ----------------------------- | -------------------------------- |
| `MOLT_PRJ_DIR`   | Where repos live              | _(none — must be set)_           |
| `MOLT_CFG_DIR`   | Where your config repo lives  | `$(dirname "$MOLT_PRJ_DIR")/cfg` |
| `MOLT_OPT_DIR`   | Where opt-style installs live | `$(dirname "$MOLT_PRJ_DIR")/opt` |
| `MOLT_AGT_DIR`   | Where sleeve agents live      | `$(dirname "$MOLT_PRJ_DIR")/agt` |
| `MOLT_LOCAL_BIN` | Where to symlink executables  | `~/.local/bin`                   |
| `UTILZ_HOME`     | Override Utilz repo location  | `$MOLT_PRJ_DIR/Utilz`            |
| `PPLR_HOME`      | Override Pplr repo location   | `$MOLT_PRJ_DIR/Pplr`             |

### MOLT_CLAUDE_CONFIG_DIR

Declared per sleeve, in `instances/<host>/vars.sh`, to keep Claude Code's state out of `$HOME`:

```bash
export MOLT_CLAUDE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/claude"
```

On a sleeve that declares it, the `claude` liberator moves `~/.claude` and `~/.claude.json` into that directory once, copying both beside it first. It refuses while any Claude Code runs, so run the move from a plain terminal with every session quit. Only once the state is there does it hand `CLAUDE_CONFIG_DIR` to the `env` liberator, which must be enabled after it in `molt.toml`. `env` writes `~/.config/molt/env.sh`, which `~/.zshenv` sources, and the GUI environment (`~/Library/LaunchAgents/com.molt.env.plist` on macOS, `~/.config/environment.d/molt.conf` on Linux), which takes effect for apps launched after the next login. The same files carry each `<TOOL>_INSTALL_PREFIX` the sleeve declares, and, for GUI apps, a login shell's PATH, which must start with `~/.local/bin` or it is refused and left out. It also installs a hook that refuses a Claude Code session launched in `$HOME`. A sleeve that declares nothing keeps `~/.claude`.

## Liberators

A liberator is a config module that frees you from one default. Each liberator implements a lifecycle of functions:

- `{name}_check` — Is this component already installed and configured?
- `{name}_install` — Configure it (verify prerequisites, link config, set up).
- `{name}_upgrade` — _(optional)_ Config sync hook. Fast, safe, runs during `molt upgrade`.
- `{name}_maintain` — _(optional)_ System maintenance hook. Slow, runs during `molt maintain`.
- `{name}_verify` — _(optional)_ A fuller check, for a liberator's own use. Molt does not run it: resleeve and doctor use `_check`.

Liberators **never install packages**, except a liberator's own subject from a Homebrew tap (Intent, Gtools, and Utilz on a `source = "brew"` sleeve), the `keys` liberator, which builds keyd from source, and the `editors` liberator, which clones Doom Emacs and the LazyVim starter when they are missing. Otherwise they check for prerequisites and fail with a hint if something is missing. You install packages yourself; liberators handle configuration.

The framework discovers liberator scripts in `liberators/`, loads them on demand, and runs them through the lifecycle automatically.

### Built-in liberators

| Liberator      | Concern                                         | OS           |
| -------------- | ----------------------------------------------- | ------------ |
| system         | Verify sudo (linux) or brew (macos)             | linux, macos |
| local-bin      | `~/.local/bin` directory, molt CLI symlink      | linux, macos |
| zsh            | Shell, Starship, config links, ssh tab colours  | linux, macos |
| git            | Git + git-lfs verification, gitconfig linking   | linux, macos |
| tmux           | Tmux verification, config linking               | linux, macos |
| editors        | Doom Emacs + LazyVim, config linking, dock pin  | linux, macos |
| alacritty      | Alacritty config linking, dock pin              | linux, macos |
| gnome-terminal | GNOME Terminal profile via dconf                | linux        |
| iterm2         | iTerm2 dynamic profile linking                  | macos        |
| terminal-app   | Terminal.app profile import                     | macos        |
| keys           | keyd build from source, key remapping           | linux        |
| desktop        | GNOME settings, GTK config, accessibility       | linux        |
| tiling         | Tactile GNOME extension grid tiling             | linux        |
| vscode         | VS Code settings linking, CLI setup, dock pin   | linux, macos |
| dev-tools      | CLI tools (jq, tree, rg, fzf, curl) + mise      | linux, macos |
| ssh            | SSH key detection, config rendering + fragments | linux, macos |
| utilz          | Utilz, from a checkout or Homebrew, per sleeve  | linux, macos |
| brew           | Homebrew maintenance and upgrade                | macos        |
| intent         | Intent from Homebrew, what PATH and gate run    | linux, macos |
| gtools         | Gtools from Homebrew, from its private tap      | linux, macos |
| pplr           | Pplr framework config and linking               | linux, macos |
| web            | Web browser config and linking                  | linux, macos |
| claude         | Claude Code config, and its state out of $HOME  | linux, macos |
| env            | Publishes the sleeve's variables, shell and GUI | linux, macos |
| npm            | ~/.npmrc, with npm's cache under XDG            | linux, macos |
| agents         | A home for each sleeve agent, from its role     | linux, macos |
| backup         | Checks the SuperDuper NAS backup; observes only | macos        |

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
enabled = false              # disabled — toggle when ready
os = ["linux"]
```

Instance-specific manifests can override the repo-level one. MOLT checks `instances/{hostname}/molt.toml` first, then falls back to the repo root.

A liberator may also read keys of its own from its entry. `utilz` takes `source = "checkout"`, the default, or `source = "brew"`.

A sleeve declares its agents, the local agents that do machine work on it as you, in `[[agent]]` entries:

```toml
[[agent]]
role = "sysadm"              # one of the roles under config/agents/roles/
enabled = true               # the default
harness = "claude"           # the default, and the only harness for now
```

An agent's name is derived, never written: `<hostname>-<role>`, eg `kovacs-sysadm`. The `agents` liberator renders its home at `$MOLT_AGT_DIR/<name>` from the role's `AGENTS.md.tmpl` and `settings.json.tmpl`, with `instances/<host>/agents/<role>.md` appended to `AGENTS.md` when the sleeve has one. The home is the agent's working directory, and `molt agent start <role>` starts the agent there.

## Your config repo layout

```
Molt-{user}/
  config/
    zsh/zshrc                        # -> ~/.zshrc
    zsh/zshenv                       # -> ~/.zshenv
    git/gitconfig                     # -> ~/.gitconfig
    tmux/tmux.conf                   # -> ~/.tmux.conf
    doom/                            # -> ~/.config/doom
    alacritty/alacritty.toml         # -> ~/.config/alacritty/alacritty.toml
    starship/starship.toml           # -> ~/.config/starship.toml
    ssh/config.tmpl                   # -> ~/.ssh/config (rendered via envsubst)
  instances/
    kovacs/                          # Per-machine overrides
      molt.toml                      # Instance manifest
      vars.sh                        # Template variables (MOLT_PRJ_DIR, etc)
      ssh/config.d/                   # Instance-specific SSH config fragments
      keyd/default.conf              # Machine-specific keyd config
    rhadamanth/
      molt.toml
      vars.sh
```

Liberators use `molt_link` to symlink config files from your repo into their expected locations. Existing files are backed up automatically. Template files (`.tmpl`) are rendered via `envsubst` using instance-specific variables.

## Personality

MOLT has opinions and says so. The tone is dry, terse, and functional. Output during a resleeve feels like waking up, not like installing software.

## Platform support

- macOS (Apple Silicon and Intel)
- Linux (Debian/Ubuntu, Fedora/RHEL, Arch)
- WSL2

## Project structure

```
Molt/
  bin/           # molt, the CLI entry point (thin coordinator); bootstrap.sh; devbin, the dev launcher
  lib/           # the framework; constants.sh holds every configurable path and default
  liberators/    # one script per liberator
  templates/     # what Molt renders: the molt-{user} skeleton, the claude and agents files, the AppArmor profile
  test/          # bats suites (test_helper.bash is the shared harness; a test that writes under HOME exports its own), liberators/ for each liberator's, manual/ for probes run by hand
  tools/         # formula, which writes the Homebrew formula
  packaging/     # homebrew/, the formula template
  docs/          # guides/, notes/ and blog/
```

## Dependencies

MOLT is PATH-based, not package-manager-bound. It depends on standard POSIX tools plus:

- **bash** 3.2 or later (framework scripts)
- **awk** (manifest parsing)
- **bats** (test suite; `molt doctor` checks for it)
- **envsubst**, from gettext (template rendering; `molt doctor` checks for it)
- **timeout**, from coreutils (`molt doctor`'s GitHub check and the bootstrap run `timeout 5 ssh -T`). Linux has it; on macOS run `brew install coreutils`, or doctor reports GitHub as not authenticated.

Liberators verify their own prerequisites and fail with install hints if anything is missing.

## Documentation

- [Getting Started](docs/guides/getting-started.md) — first-time setup walkthrough
- [Creating a New User Config Repo](docs/guides/new-user.md) — scaffold a `molt-{user}` repo with `molt new-user`
- [Writing a Liberator](docs/guides/writing-a-liberator.md) — how to create your own config modules
- [Template System](docs/guides/templates.md) — per-instance config rendering with `envsubst`
- [Sleeve Agents](docs/guides/sleeve-agents.md) — a home for each machine's local agent, and Claude Code's state moved out of `$HOME`
- [Bootstrap Runbook](docs/guides/bootstrap-runbook.md) — detailed manual setup reference

## Status

Early development. Sleeves in use: kovacs (Ubuntu ARM64), rhadamanth (macOS M4), gyges (macOS), farcaster (Linux) and pihole (Linux).

## License

MIT
