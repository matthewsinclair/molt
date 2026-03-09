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
| **molt-{user}** (eg `molt-matts`) | Your config files, dotfiles, manifest, per-instance overrides | No — your soul   |

The framework knows how to find your personal repo by searching for `molt-$(whoami)` in standard locations (`~/Devel/prj/`, `~/`, `~/.`). Your personal repo contains a `config/` directory with dotfiles and a `molt.toml` manifest declaring which liberators to run.

This separation means you can fork the framework independently from your config, and your config never contains framework code.

## Quick start

Clone both repos, then resleeve:

```bash
# Framework
git clone https://github.com/you/molt ~/Devel/prj/Molt

# Your config (contains molt.toml + config/ directory)
git clone https://github.com/you/molt-you ~/Devel/prj/molt-you

# Add molt to PATH
export PATH="$HOME/Devel/prj/Molt/bin:$PATH"

# Bootstrap this machine
molt resleeve
```

```
MOLT v0.1.0 — My Opinionated Local Terminal
Needlecasting stack to new sleeve...
Zen: Stack found: /home/you/Devel/prj/molt-you
Zen: Loading liberators...
Zen: Running liberator: zsh (install)
Zen: Running liberator: git (install)
...
Zen: Sleeve ready. Welcome back.
```

"Welcome back" is the key line. You are not setting up a new machine. You are waking up in a new body with all your memories intact.

## Concepts

MOLT's naming draws from two science fiction universes: _Altered Carbon_ (Richard K. Morgan) and _Blake's 7_ (Terry Nation). Both deal with the separation of identity from physical substrate.

### Your config is your cortical stack

The central metaphor from _Altered Carbon_: your configuration is your consciousness. Every machine is just a sleeve it gets loaded into.

| Term           | What it means                                           |
| -------------- | ------------------------------------------------------- |
| **stack**      | Your dotfiles and config bundle. The portable identity. |
| **sleeve**     | A target machine that receives your stack.              |
| **needlecast** | Push your stack to a remote machine.                    |
| **resleeve**   | Bootstrap a fresh machine from your stack.              |
| **backup**     | Snapshot your current stack state.                      |

### System components from Blake's 7

| Term           | What it means                                                                      |
| -------------- | ---------------------------------------------------------------------------------- |
| **Zen**        | The bootstrap runner on each machine. Executes commands, reports status.           |
| **liberators** | Config modules. Each one frees you from a default.                                 |
| **molt.toml**  | The manifest file. The authoritative source of truth for what your stack contains. |

## CLI

```bash
molt resleeve              # Bootstrap the current machine from your stack
molt status                # Show sleeve state and liberator status
molt list                  # List liberators with enabled/installed status
molt doctor                # System diagnostics and health checks
molt test [liberator]      # Run bats test suite (all or one liberator)
molt version               # Show version
molt help                  # Show help
```

## Liberators

A liberator is a config module that frees you from one default. Each liberator implements three functions:

- `{name}_check` — Is this component already installed?
- `{name}_install` — Install and configure it.
- `{name}_verify` — Confirm the installation is correct.

The framework discovers liberator scripts in `liberators/`, loads them on demand, and runs them through the lifecycle automatically.

### Built-in liberators

| Liberator | Concern                                      | OS           |
| --------- | -------------------------------------------- | ------------ |
| system    | Base packages, package manager, sudo         | linux        |
| local-bin | `~/bin` directory, molt CLI symlink          | linux, macos |
| zsh       | Shell, Starship prompt, config linking       | linux, macos |
| git       | Git + git-lfs, gitconfig linking             | linux, macos |
| tmux      | Tmux, config linking                         | linux, macos |
| editors   | Doom Emacs + LazyVim, config linking         | linux, macos |
| terminal  | Alacritty, config linking                    | linux        |
| keys      | keyd build from source, key remapping        | linux        |
| desktop   | GNOME settings, GTK config                   | linux        |
| dev-tools | CLI tools (bat, rg, fd, fzf) + mise          | linux, macos |
| ssh       | SSH key generation, config linking           | linux, macos |
| utilz     | Utilz framework, bats-core, `~/bin` symlinks | linux, macos |

### molt.toml

The manifest lives in your personal config repo (`molt-{user}/molt.toml`). It declares which liberators to run and on which platforms:

```toml
[stack]
name = "my-stack"
version = "0.1.0"
user_repo = "molt-matts"

[sleeve]
# Machine-specific overrides (optional)

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
  molt.toml                          # Stack manifest
  config/
    zsh/zshrc                        # -> ~/.zshrc
    zsh/zshenv                       # -> ~/.zshenv
    git/gitconfig                    # -> ~/.gitconfig
    tmux/tmux.conf                   # -> ~/.tmux.conf
    doom/                            # -> ~/.config/doom
    alacritty/alacritty.toml         # -> ~/.config/alacritty/alacritty.toml
    starship/starship.toml           # -> ~/.config/starship.toml
    ssh/config                       # -> ~/.ssh/config
  instances/
    kovacs/                          # Per-machine overrides
      keyd/default.conf              # Machine-specific keyd config
```

Liberators use `molt_link` to symlink config files from your repo into their expected locations. Existing files are backed up automatically.

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
  lib/
    constants.sh           # All configurable paths and defaults (single source of truth)
    molt.sh                # Core: logging, platform detection, symlinks, manifest parsing
    liberator.sh           # Liberator loading, execution, and discovery
  liberators/
    system.sh              # Base system setup
    zsh.sh                 # Shell + Starship prompt
    git.sh                 # Git + git-lfs
    tmux.sh                # Tmux
    editors.sh             # Doom Emacs + LazyVim
    terminal.sh            # Alacritty
    keys.sh                # keyd
    desktop.sh             # GNOME settings
    dev-tools.sh           # CLI tools + mise
    ssh.sh                 # SSH
    local-bin.sh           # ~/bin setup
    utilz.sh               # Utilz framework
  templates/
    molt.toml.example      # Example stack manifest
  test/
    test_helper.bash       # Shared test infrastructure (HOME-sandboxed)
    molt.bats              # CLI tests
    constants.bats         # Constants tests
    liberator.bats         # Framework tests
    manifest.bats          # Manifest parsing tests
    liberators/
      zsh.bats             # Exemplar liberator test
  docs/
    bootstrap-runbook.md   # Phase 1 manual resleeve specification
```

## Dependencies

MOLT is PATH-based, not package-manager-bound. It depends on standard POSIX tools plus:

- **bash** 4+ (framework scripts)
- **awk** (manifest parsing)
- **bats** (test suite — optional, for `molt test`)

Liberators declare their own dependencies (eg `apt`, `curl`, `git`).

## Status

Early development. The framework has a working CLI, core library, 12 liberators, manifest-driven execution, and a 42-test bats suite. The first sleeve (kovacs — Ubuntu 24.04 ARM64) is bootstrapped and operational.

## License

MIT
