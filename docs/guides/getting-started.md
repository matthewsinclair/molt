# Getting Started

This guide walks you through setting up MOLT on a new machine.

> **Don't have a `Molt-{user}` repo yet?** Create one first with [`molt new-user`](new-user.md), then come back here to resleeve a machine.

## Prerequisites

- bash 3.2 or later
- git
- `gettext` — provides `envsubst`, used to render `.tmpl` config (macOS: `brew install gettext && brew link --force gettext`)
- `bats` — the test suite; `molt doctor` checks for it, with `envsubst`
- `timeout`, from coreutils — `molt doctor`'s GitHub check and the bootstrap run `timeout 5 ssh -T`. Linux has it; on macOS run `brew install coreutils`, or doctor reports GitHub as not authenticated
- A Nerd Font for prompt glyphs (eg `brew install --cask font-hack-nerd-font`)
- A terminal you're comfortable in

## Set MOLT_PRJ_DIR

MOLT needs to know where your repos live. There is no default — you choose the layout per machine:

```bash
export MOLT_PRJ_DIR="$HOME/Projects"
```

Add this to your `.zshenv` or `.bashrc` so it persists.

## Clone both repos

```bash
# The framework: the dev tree, exact-case Molt
git clone https://github.com/you/molt "$MOLT_PRJ_DIR/Molt"

# Your personal config
git clone https://github.com/you/molt-you "$(dirname "$MOLT_PRJ_DIR")/cfg/Molt-you"
```

The framework finds your config repo by looking for `Molt-$(whoami)` in `$MOLT_CFG_DIR`, which defaults to the `cfg/` directory beside `$MOLT_PRJ_DIR`, and then in `$MOLT_PRJ_DIR` itself.

## Put molt on PATH

```bash
export PATH="$HOME/.local/bin:$PATH"
"$MOLT_PRJ_DIR/Molt/bin/molt" use dev
```

`molt use dev` links `~/.local/bin/molt` to the checkout. Keep `~/.local/bin` first on PATH, rather than the checkout's `bin/`, or `molt doctor` reports that something else shadows the link. The bootstrap script (see below) makes the link for you.

## Preview with dry-run

```bash
molt resleeve --dry-run
```

This shows what would happen without changing anything. You'll see which liberators are already configured and which would be installed.

## Resleeve

```bash
molt resleeve
```

MOLT loads your manifest, runs each enabled liberator, and links your config into place. Existing files are backed up before being replaced.

```
MOLT v<version> — My Opinionated Local Terminal
Needlecasting stack to new sleeve...
Sleeve: <hostname> | Platform: linux

Zen: Stack found: ...
Zen: Loading liberators...
Zen: Manifest: ...

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

The bootstrap script clones the framework into `$MOLT_PRJ_DIR/Molt` and your config repo into `$MOLT_CFG_DIR/Molt-$(whoami)`, symlinks `molt` into `~/.local/bin`, shows a dry-run, and asks at the terminal before applying.

It clones the framework from `MOLT_REPO` (default `matthewsinclair/molt`) and your config repo from `$MOLT_USER_GH/molt-$(whoami)`, where `MOLT_USER_GH` defaults to your login name. Set `MOLT_USER_GH` when your GitHub handle differs from it.

## Keeping up to date

After the initial resleeve, use `molt upgrade` to update the framework and config, run upgrade hooks, then resleeve. In the dev tree it pulls the checkout; the opt tree is published again with `molt install --force`; the brew tree runs `brew update` and `brew upgrade`:

```bash
molt upgrade              # update + upgrade hooks + resleeve
molt upgrade --dry-run    # preview only
molt upgrade zsh,git      # upgrade specific liberators only
molt upgrade --no-resleeve # upgrade without resleeve
```

`upgrade` requires clean working trees in both repos (no uncommitted changes).

### Self-update

To update just the framework and config repos without running hooks or resleeving:

```bash
molt upgrade --self       # update framework + config repos only
```

This is useful as a first step before a full upgrade, or when you just want to sync the repos.

### System maintenance

`molt maintain` runs heavier system maintenance tasks — things like `brew upgrade`, `doom upgrade`, or other slow operations that you'd run weekly or monthly rather than daily:

```bash
molt maintain             # run all maintenance hooks
molt maintain --dry-run   # preview what would run
molt maintain brew        # maintain specific liberators only
```

### Recommended workflow

The typical update sequence is:

1. `molt upgrade --self` — sync repos
2. `molt upgrade` — run upgrade hooks + resleeve
3. `molt maintain` — run maintenance (when you have time)

## Checking health

```bash
molt doctor
```

Runs its diagnostic checks, among them: Molt's own directory structure, manifest validity (including that the manifest's `user_repo` still names the real directory), liberator health, external dependencies, SSH key presence, GitHub authentication, config hygiene (no other-user absolute home paths baked into your config), that the stack itself is on local storage rather than a network or guest mount, that each managed repo's `core.ignorecase` matches what its disk does with case, and the font the sleeve declares. It closes with `All checks passed.` and exits 0, or with how many of the checks that ran did not pass and exits 1.

## Your config repo

Your personal repo (`Molt-{user}`) has this layout:

```
Molt-you/
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

- [Creating a New User Config Repo](new-user.md) — scaffold a fresh `Molt-{user}` repo
- [Writing a Liberator](writing-a-liberator.md) — add your own config modules
- [Template System](templates.md) — per-instance config rendering
