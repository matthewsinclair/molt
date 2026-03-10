# MOLT — My Opinionated Local Terminal

<p align="center">
  <img src="design/molt-logo.svg" alt="MOLT logo" width="150">
</p>

Your shell config is your identity. Every new machine is just a new body.

MOLT is a cross-platform, multi-machine personal shell environment tool. It takes your zsh/bash config, dotfiles, and dev environment setup and makes them portable, reproducible, and bootstrappable from a single command on a fresh machine.

Think of it as what [Omarchy](https://github.com/basecamp/omarchy) does for Linux desktop config, but for shell and dev environments across macOS and Linux.

## The name

"Molt" is the biological process of shedding an exoskeleton to grow a new one. The backronym is **My Opinionated Local Terminal**. Both readings work: you shed the default shell and replace it with yours.

## Two-repo model

MOLT separates the framework from your personal config:

| Repo                              | What it contains                                              | Shared?          |
| --------------------------------- | ------------------------------------------------------------- | ---------------- |
| **molt** (this repo)              | Framework: CLI, core libs, liberator runner, tests            | Yes — the engine |
| **molt-{user}** (eg `molt-matts`) | Your config files, dotfiles, manifest, per-instance overrides    | No — your soul   |

The framework finds your personal repo by searching for `molt-$(whoami)` in `$MOLT_PROJECTS_DIR`, `~/`, and `~/.`. Your personal repo contains a `config/` directory with dotfiles and a `molt.toml` manifest declaring which liberators to run.

This separation means you can fork the framework independently from your config, and your config never contains framework code.

## Quick start

### Prerequisites

Set `MOLT_PROJECTS_DIR` to the directory where your repos live. There is no default — every machine chooses its own layout:

```bash
export MOLT_PROJECTS_DIR="$HOME/Projects"  # or wherever you keep repos
```

### Clone and resleeve

```bash
# Framework
git clone https://github.com/you/molt "$MOLT_PROJECTS_DIR/molt"

# Your config (contains molt.toml + config/ directory)
git clone https://github.com/you/molt-you "$MOLT_PROJECTS_DIR/molt-you"

# Add molt to PATH (or use the bootstrap script)
export PATH="$MOLT_PROJECTS_DIR/molt/bin:$PATH"

# Preview what would happen
molt resleeve --dry-run

# Bootstrap this machine
molt resleeve
```

```
MOLT v0.1.0 — My Opinionated Local Terminal
Needlecasting stack to new sleeve...
Zen: Stack found: /home/you/Projects/molt-you
Zen: Loading liberators...
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
MOLT_PROJECTS_DIR=$HOME/Projects bash <(curl -fsSL https://raw.githubusercontent.com/you/molt/main/bin/bootstrap.sh)
```

The bootstrap script clones both repos, links molt into `~/bin`, shows a dry-run, and prompts before applying.

## Concepts

In Molt, your config is your cortical stack, your consciousness. Every machine is just a sleeve it gets loaded into.

| Term           | What it means                                                                      |
| -------------- | ---------------------------------------------------------------------------------- |
| **stack**      | Your dotfiles and config bundle. The portable identity.                              |
| **sleeve**     | A target machine that receives your stack.                                         |
| **needlecast** | Push your stack to a remote machine.                                               |
| **resleeve**   | Bootstrap a fresh machine from your stack.                                         |
| **backup**     | Snapshot your current stack state.                                                 |
| **zen**        | The bootstrap runner on each machine. Executes commands, reports status.           |
| **liberators** | Config modules. Each one frees you from a default.                                  |
| **molt.toml**  | The manifest file. The authoritative source of truth for what your stack contains.  |

## CLI

```bash
molt resleeve              # Bootstrap the current machine from your stack
molt resleeve --dry-run    # Preview what resleeve would do, without changing anything
molt upgrade               # Pull latest framework + config, then resleeve
molt upgrade --dry-run     # Preview what upgrade would do
molt status                # Show sleeve state and liberator status
molt list                  # List liberators with enabled/installed status
molt doctor                # System diagnostics and health checks (9 checks)
molt test [liberator]      # Run bats test suite (all or one liberator)
molt version               # Show version
molt help                  # Show help
```

## Configuration

### MOLT_PROJECTS_DIR

The only required setting. Tells molt where to find repos. Set it in your shell config (eg `.zshenv`):

```bash
export MOLT_PROJECTS_DIR="$HOME/Devel/prj"
```

If unset, molt will search `~/molt-{user}` and `~/.molt-{user}` as fallbacks, but the primary lookup via `MOLT_PROJECTS_DIR` is the intended path.

### Other environment variables

| Variable            | Purpose                       | Default                     |
| ------------------- | ----------------------------- | --------------------------- |
| `MOLT_PROJECTS_DIR` | Where repos live              | _(none — must be set)_      |
| `MOLT_LOCAL_BIN`    | Where to symlink executables  | `~/bin`                     |
| `UTILZ_HOME`        | Override Utilz repo location  | `$MOLT_PROJECTS_DIR/Utilz`  |
| `INTENT_HOME`       | Override Intent repo location | `$MOLT_PROJECTS_DIR/Intent` |

## Liberators

A liberator is a config module that frees you from one default. Each liberator implements three functions:

- `{name}_check` — Is this component already installed and configured?
- `{name}_install` — Configure it (verify prerequisites, link config, set up).
- `{name}_verify` — Confirm the installation is correct.

Liberators **never install packages**. They check for prerequisites and fail with a hint if something is missing. You install packages yourself; liberators handle configuration.

The framework discovers liberator scripts in `liberators/`, loads them on demand, and runs them through the lifecycle automatically.

### Built-in liberators

| Liberator      | Concern                                         | OS           |
| -------------- | ----------------------------------------------- | ------------ |
| system         | Verify sudo (linux) or brew (macos)             | linux, macos |
| local-bin      | `~/bin` directory, molt CLI symlink             | linux, macos |
| zsh            | Shell default, Starship prompt, config linking   | linux, macos |
| git            | Git + git-lfs verification, gitconfig linking     | linux, macos |
| tmux           | Tmux verification, config linking                 | linux, macos |
| editors        | Doom Emacs + LazyVim, config linking, dock pin   | linux, macos |
| alacritty      | Alacritty config linking, dock pin               | linux, macos |
| gnome-terminal | GNOME Terminal profile via dconf                 | linux        |
| iterm2         | iTerm2 dynamic profile linking                   | macos        |
| terminal-app   | Terminal.app profile import                      | macos        |
| keys           | keyd build from source, key remapping           | linux        |
| desktop        | GNOME settings, GTK config, accessibility        | linux        |
| tiling         | Tactile GNOME extension grid tiling             | linux        |
| vscode         | VS Code settings linking, CLI setup, dock pin   | linux, macos |
| dev-tools      | CLI tools (bat, rg, fd, fzf) + mise             | linux, macos |
| ssh            | SSH key detection, config rendering + fragments  | linux, macos |
| utilz          | Utilz framework, bats-core, `~/bin` symlinks    | linux, macos |

### molt.toml

The manifest lives in your personal config repo. It declares which liberators to run and on which platforms:

```toml
[stack]
name = "my-stack"
version = "0.1.0"
user_repo = "molt-matts"

[sleeve]
hostname = "mymachine"
projects_dir = "~/Projects"

[[liberator]]
name = "zsh"
enabled = true
os = ["linux", "macos"]
depends = ["system"]

[[liberator]]
name = "keys"
enabled = false              # disabled — toggle when ready
os = ["linux"]
```

Instance-specific manifests can override the repo-level one. MOLT checks `instances/{hostname}/molt.toml` first, then falls back to the repo root.

## Your config repo layout

```
molt-{user}/
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
      vars.sh                        # Template variables (MOLT_PROJECTS_DIR, etc)
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
molt/
  bin/
    molt                   # CLI entry point (thin coordinator)
    bootstrap.sh           # One-liner bootstrap for fresh machines
  lib/
    constants.sh           # All configurable paths and defaults (single source of truth)
    molt.sh                # Core: logging, platform detection, symlinks, manifest parsing
    liberator.sh           # Liberator loading, execution, and discovery
  liberators/
    system.sh              # Base system verification
    zsh.sh                 # Shell + Starship prompt
    git.sh                 # Git + git-lfs
    tmux.sh                # Tmux
    editors.sh             # Doom Emacs + LazyVim
    alacritty.sh           # Alacritty
    gnome-terminal.sh      # GNOME Terminal
    iterm2.sh              # iTerm2
    terminal-app.sh        # Terminal.app
    keys.sh                # keyd
    desktop.sh             # GNOME settings
    tiling.sh              # Tactile grid tiling
    vscode.sh              # VS Code
    dev-tools.sh           # CLI tools + mise
    ssh.sh                 # SSH
    local-bin.sh           # ~/bin setup
    utilz.sh               # Utilz framework
  test/
    test_helper.bash       # Shared test infrastructure (HOME-sandboxed)
    molt.bats              # CLI tests
    constants.bats         # Constants tests
    liberator.bats         # Framework tests
    manifest.bats          # Manifest parsing tests
    templates.bats         # Template rendering tests
    liberators/
      zsh.bats             # Exemplar liberator test
```

## Dependencies

MOLT is PATH-based, not package-manager-bound. It depends on standard POSIX tools plus:

- **bash** 4+ (framework scripts)
- **awk** (manifest parsing)
- **bats** (test suite — optional, for `molt test`)

Liberators verify their own prerequisites and fail with install hints if anything is missing.

## Documentation

- [Getting Started](docs/guides/getting-started.md) — first-time setup walkthrough
- [Writing a Liberator](docs/guides/writing-a-liberator.md) — how to create your own config modules
- [Template System](docs/guides/templates.md) — per-instance config rendering with `envsubst`
- [Bootstrap Runbook](docs/guides/bootstrap-runbook.md) — detailed manual setup reference

## Status

Early development. Two sleeves operational: kovacs (Ubuntu 24.04 ARM64) and rhadamanth (macOS M4).

## License

MIT
