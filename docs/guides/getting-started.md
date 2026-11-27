# Getting Started

This guide walks you through setting up MOLT on a new machine.

> **Don't have a `Molt-{user}` repo yet?** Create one first with [`molt new-user`](new-user.md), then come back here to resleeve a machine.

## Prerequisites

- [Homebrew](https://brew.sh), on macOS or Linux
- bash 3.2 or later
- git
- `gettext`, which provides `envsubst`, used to render `.tmpl` config (macOS: `brew install gettext && brew link --force gettext`)
- `bats`, the test suite: `molt doctor` checks for it where molt runs from a dev checkout, the one tree `molt test` runs in, and for `envsubst` everywhere
- `timeout`, from coreutils: the bootstrap runs `timeout 5 ssh -n -T`, and clones over HTTPS without it; `molt doctor`'s git host check uses it where it is installed, to bound each host's whole exchange, and otherwise relies on ssh's own connect bound. Linux has it; on macOS run `brew install coreutils`
- A Nerd Font for prompt glyphs (eg `brew install --cask font-hack-nerd-font`)
- A terminal you're comfortable in

## Install molt

```bash
brew install matthewsinclair/molt/molt
```

The formula installs Molt into its keg and links `molt` into Homebrew's `bin`, so the `molt` on your PATH is it. `molt version` names the install, as `molt <version> (brew, <commit>)`. It needs two things more before it can resleeve: `MOLT_PRJ_DIR` and your config repo, the next two steps.

## Set MOLT_PRJ_DIR

MOLT needs to know where your repos live. There is no default. You choose the layout per machine:

```bash
export MOLT_PRJ_DIR="$HOME/Projects"
```

Add this to your `.zshenv` or `.bashrc` so it persists. Once the `zsh` liberator has run, `~/.zshenv` is a link to your config repo's `config/zsh/zshenv`, so set it there.

## Clone your config repo

```bash
git clone https://github.com/you/molt-you "$(dirname "$MOLT_PRJ_DIR")/cfg/Molt-you"
```

Molt finds your config repo by looking for `Molt-$(whoami)` in `$MOLT_CFG_DIR`, which defaults to the `cfg/` directory beside `$MOLT_PRJ_DIR`, then in `$MOLT_PRJ_DIR` itself, then in your home directory, and takes the first that holds a `config/` directory.

## Preview with dry-run

```bash
molt resleeve --dry-run
```

This shows what would happen without changing anything. You'll see which liberators are already configured and which would be installed.

## Resleeve

```bash
molt resleeve
```

MOLT loads your manifest, runs each enabled liberator, and links your config into place. A file of yours that it replaces is backed up first, beside it, as `<file>.molt-backup.<timestamp>`.

```
MOLT v<version> — My Opinionated Local Terminal
Needlecasting stack to new sleeve...
Sleeve: <hostname> | Platform: linux

Zen: Stack found: ...
Zen: Loading liberators...
Zen: Manifest: ...

  system: ✓ ok
Zen: Running liberator: zsh (install)
...
  zsh: ✓ installed
  git: ✓ ok
  editors: ✓ ok
  ...

Zen: Sleeve ready. Welcome back.
```

## Keeping up to date

After the initial resleeve, use `molt upgrade` to bring Molt and your config forward, run upgrade hooks, then resleeve:

```bash
molt upgrade              # upgrade Molt + pull config + upgrade hooks + resleeve
molt upgrade --dry-run    # preview only
molt upgrade zsh,git      # only these liberators' upgrade hooks: no pull, and no resleeve without --resleeve
molt upgrade --no-resleeve # upgrade without resleeve
```

From brew, `molt upgrade` runs `brew update`, asks `brew outdated` whether the formula has a new release, and runs `brew upgrade matthewsinclair/molt/molt` when it has, then carries on in the new install. A failed update or upgrade is named in the verdict. `--dry-run` skips `brew update` and says so. `brew upgrade matthewsinclair/molt/molt` on its own does the same for Molt alone.

`upgrade` requires a clean working tree in your config repo (no uncommitted changes).

### Self-update

To update just Molt and your config repo without running hooks or resleeving:

```bash
molt upgrade --self       # Molt + config repo only
```

This is useful as a first step before a full upgrade, or when you just want to sync the repos.

### System maintenance

`molt maintain` runs heavier system maintenance tasks, such as `brew upgrade`, `doom upgrade`, or other slow operations that you'd run weekly or monthly rather than daily:

```bash
molt maintain             # run all maintenance hooks
molt maintain --dry-run   # preview what would run
molt maintain brew        # maintain specific liberators only
```

### Recommended workflow

The typical update sequence is:

1. `molt upgrade --self`: sync repos
2. `molt upgrade`: run upgrade hooks + resleeve
3. `molt maintain`: run maintenance (when you have time)

## Checking health

```bash
molt doctor
```

Runs Molt's health checks and prints a line for each, with any details under it. It ends with `All checks passed.` and exits 0, or with how many checks did not pass, and exits 1.

## Your config repo

The [README](../../README.md#your-config-repo-layout) shows the layout of your `Molt-{user}` repo.

Each machine gets its own directory under `instances/` with a manifest and optional overrides. See [Template System](templates.md) for how `.tmpl` files work.

## For the maintainer of a dev checkout

**This section is for whoever works on Molt itself, in a dev checkout of its repository.** A user installs from brew ([Install molt](#install-molt)) and needs none of it.

Molt reaches a machine from one of its trees, dev, opt or brew, which are dev, stage and prod, as devbin's `docs/dev-opt-brew.md` has them for every tool released through Homebrew:

```
$MOLT_PRJ_DIR/Molt                 dev    the git checkout: edited, committed, tested
~/Devel/opt/molt                   opt    published from the checkout, only from a CLEAN tree
$HOMEBREW_PREFIX/opt/molt/libexec  brew   the formula, published from a release tag
```

The checkout is the bleeding edge. The opt install is a published copy of it, which keeps what works apart from what is mid-development. The brew formula is the one publish to prod: what users install. (`opt` names the tier; Homebrew's own `opt/` path, on the brew line, is a different thing.)

**devbin publishes and switches every tree, and Molt does neither.** `bin/devbin install` and `bin/devbin use`, run in the checkout, are the one implementation every Homebrew'd tool shares. `molt install` and `molt use` refuse, and name the `bin/devbin` verb to run. Molt still reads every tree, so `molt version`, `molt doctor` and `molt upgrade` work on a sleeve that has no `bin/devbin`.

### The dev checkout

```bash
git clone https://github.com/matthewsinclair/molt "$MOLT_PRJ_DIR/Molt"
export PATH="$HOME/.local/bin:$PATH"
cd "$MOLT_PRJ_DIR/Molt"
bin/devbin use dev
```

The clone is the dev tree, exact-case `Molt`. `bin/devbin use dev` links `~/.local/bin/molt` to it (see the switch, below). devbin needs bash 5, which `brew install bash` gives a Mac.

### The switch: `bin/devbin use`

`~/.local/bin/molt` is the switch, and `bin/devbin use`, run in the checkout, is the one verb that moves it:

```bash
bin/devbin use          # show which tree serves molt, and change nothing
bin/devbin use dev      # link ~/.local/bin/molt to the checkout
bin/devbin use opt      # link it to the opt install
bin/devbin use brew     # remove it, so Homebrew's molt answers
```

**No link means brew.** A user who never switches has no `~/.local/bin/molt`, and runs Homebrew's. For the switch to take, `~/.local/bin` must come before Homebrew's `bin` on PATH, ahead of the first one `brew shellenv` adds. When another `molt` runs instead, `molt doctor` marks the check not passed, naming it. Resleeve never moves the switch: from a dev or opt tree with no link, the `local-bin` liberator names `bin/devbin use` rather than making one, unless Homebrew's `molt` is what PATH runs.

### Publishing to opt: `bin/devbin install`

```bash
cd "$MOLT_PRJ_DIR/Molt"
bin/devbin install            # publish to install.prefix; refuses a dirty tree
bin/devbin install --force    # replace the opt install with this commit
bin/devbin use opt
```

The prefix is `install.prefix` in `bin/.devbin/config.yaml`, `~/Devel/opt/molt`, or `--prefix <dir>`. devbin copies the places the config's `install:` block names, `bin/molt`, `lib/`, `liberators/`, `templates/` and `VERSION`, and writes a checksum manifest, `.molt-install`, that `molt doctor` checks the install against. An opt install is never pulled: `molt upgrade` there names `bin/devbin install --force` and the checkout's commit when it is ahead. `molt test` runs only in the checkout.

### Bootstrap script

For a completely fresh machine where nothing is set up yet, the bootstrap script sets up a dev checkout:

```bash
MOLT_PRJ_DIR=$HOME/Projects \
  bash <(curl -fsSL https://raw.githubusercontent.com/matthewsinclair/molt/main/bin/bootstrap.sh)
```

It clones the framework into `$MOLT_PRJ_DIR/Molt` and your config repo into `$MOLT_CFG_DIR/Molt-$(whoami)`, links `molt` into `~/.local/bin`, shows a dry-run, and asks at the terminal before applying.

It clones the framework from `MOLT_REPO` (default `matthewsinclair/molt`) and your config repo from `$MOLT_USER_GH/molt-$(whoami)`, where `MOLT_USER_GH` defaults to your login name. Set `MOLT_USER_GH` when your GitHub handle differs from it. In a dev tree, `molt upgrade` pulls the checkout and requires a clean working tree in both repos.

## Next steps

- [Creating a New User Config Repo](new-user.md): scaffold a fresh `Molt-{user}` repo
- [Writing a Liberator](writing-a-liberator.md): add your own config modules
- [Template System](templates.md): per-instance config rendering
