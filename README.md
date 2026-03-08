# MOLT — My Opinionated Local Terminal

<p align="center">
  <img src="design/molt-logo.svg" alt="MOLT logo" width="150">
</p>

Your shell config is your identity. Every new machine is just a new body.

MOLT is a cross-platform, multi-machine personal shell environment tool. It takes your zsh/bash config, dotfiles, and dev environment setup and makes them portable, reproducible, and bootstrappable from a single command on a fresh machine.

Think of it as what [Omarchy](https://github.com/basecamp/omarchy) does for Linux desktop config, but for shell and dev environments across macOS and Linux.

## The name

"Molt" is the biological process of shedding an exoskeleton to grow a new one. The backronym is **My Opinionated Local Terminal**. Both readings work: you shed the default shell and replace it with yours.

## Quick start

```bash
curl -sL https://molt.sh/install | bash
```

Then on any new machine:

```bash
molt resleeve
```

```
MOLT v0.1.0 — My Opinionated Local Terminal
Needlecasting stack to new sleeve...
Zen: Loading liberators [zsh, git, tmux, starship, emacs]
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
molt needlecast <host>     # Push your stack to a remote machine
molt backup                # Snapshot your current stack
molt stack                 # Inspect or manage stack contents
molt sleeve                # Inspect the current sleeve (machine state)
```

## What goes in a stack

A stack is a collection of **liberators** — config modules that each handle one concern. Example liberators:

- `zsh` — shell config, aliases, functions
- `git` — gitconfig, gitignore, commit templates
- `tmux` — tmux.conf and plugin setup
- `starship` — prompt configuration
- `emacs` — editor config and packages
- `ssh` — SSH config and key management
- `homebrew` — macOS package list (auto-skipped on Linux)
- `apt` — Linux package list (auto-skipped on macOS)

Each liberator declares what OS it supports, what it depends on, and how to install/update itself.

### molt.toml

The manifest lives at the root of your stack:

```toml
[stack]
name = "my-stack"
version = "0.1.0"

[sleeve]
# Machine-specific overrides go here

[[liberator]]
name = "zsh"
os = ["macos", "linux"]

[[liberator]]
name = "homebrew"
os = ["macos"]

[[liberator]]
name = "git"
os = ["macos", "linux"]
depends = ["zsh"]
```

## Personality

MOLT has opinions and says so. The tone is dry, terse, and functional. Output during a resleeve feels like waking up, not like installing software.

## Platform support

- macOS (Apple Silicon and Intel)
- Linux (Debian/Ubuntu, Fedora/RHEL, Arch)
- WSL2

## Project structure

```
bin/
  molt                 # CLI entry point
lib/
  molt.sh              # Core functions (logging, platform detection, symlinks)
  liberator.sh         # Liberator loading and execution framework
liberators/
  zsh.sh               # Shell + Starship prompt
templates/
  molt.toml.example    # Example stack manifest
docs/
  bootstrap-runbook.md # Phase 1 manual resleeve steps
```

Each liberator implements three functions: `{name}_check`, `{name}_install`, and
`{name}_verify`. The framework discovers and runs them automatically.

## Status

Early development. The exoskeleton is still forming. The framework has a working
CLI (`bin/molt`), core library, liberator runner, and one exemplar liberator (zsh).

## License

MIT
