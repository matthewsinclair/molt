# Getting Started

This guide walks you through setting up MOLT on a new machine.

## Prerequisites

- bash 4+
- git
- A terminal you're comfortable in

## 1. Set MOLT_PRJ_DIR

MOLT needs to know where your repos live. There is no default — you choose the layout per machine:

```bash
export MOLT_PRJ_DIR="$HOME/Projects"
```

Add this to your `.zshenv` or `.bashrc` so it persists.

## 2. Clone both repos

```bash
# The framework
git clone https://github.com/you/molt "$MOLT_PRJ_DIR/molt"

# Your personal config
git clone https://github.com/you/molt-you "$MOLT_PRJ_DIR/molt-you"
```

The framework finds your config repo by looking for `molt-$(whoami)` in `$MOLT_PRJ_DIR`.

## 3. Add molt to PATH

```bash
export PATH="$MOLT_PRJ_DIR/molt/bin:$PATH"
```

Or use the bootstrap script (see below) which handles this for you.

## 4. Preview with dry-run

```bash
molt resleeve --dry-run
```

This shows what would happen without changing anything. You'll see which liberators are already configured and which would be installed.

## 5. Resleeve

```bash
molt resleeve
```

MOLT loads your manifest, runs each enabled liberator, and links your config into place. Existing files are backed up before being replaced.

```
MOLT v0.1.0 — My Opinionated Local Terminal
Needlecasting stack to new sleeve...
  system: ✓ ok
  zsh: ✓ installed
  git: ✓ installed
  editors: ✓ ok
  ...
Zen: Sleeve ready. Welcome back.
```

## Bootstrap script

For a completely fresh machine where nothing is set up yet:

```bash
MOLT_PRJ_DIR=$HOME/Projects \
  bash <(curl -fsSL https://raw.githubusercontent.com/you/molt/main/bin/bootstrap.sh)
```

The bootstrap script clones both repos, symlinks `molt` into `~/bin`, shows a dry-run, and prompts before applying.

## Keeping up to date

After the initial resleeve, use `molt upgrade` to pull the latest framework and config, then re-run resleeve:

```bash
molt upgrade              # pull + resleeve
molt upgrade --dry-run    # preview only
```

`upgrade` requires clean working trees in both repos (no uncommitted changes).

## Checking health

```bash
molt doctor
```

Runs 9 diagnostic checks: directory structure, manifest validity, liberator health, external dependencies, SSH key presence, and GitHub authentication.

## Your config repo

Your personal repo (`molt-{user}`) has this layout:

```
molt-you/
  config/
    zsh/zshrc               # -> ~/.zshrc
    zsh/zshenv              # -> ~/.zshenv
    git/gitconfig           # -> ~/.gitconfig
    doom/                   # -> ~/.config/doom
    alacritty/alacritty.toml
    starship/starship.toml
    ssh/config.tmpl         # rendered with per-instance vars
    vscode/settings.json
  instances/
    mymachine/
      molt.toml             # what to install on this machine
      vars.sh               # template variables for this machine
      ssh/config.d/         # SSH config fragments appended after render
```

Each machine gets its own directory under `instances/` with a manifest and optional overrides. See [Template System](templates.md) for how `.tmpl` files work.

## Next steps

- [Writing a Liberator](writing-a-liberator.md) — add your own config modules
- [Template System](templates.md) — per-instance config rendering
