# `Molt-__MOLT_USER__`

Personal MOLT config repo for `__MOLT_FULL_NAME__` (`@__MOLT_GITHUB__`), on GitHub as `__MOLT_GITHUB__/molt-__MOLT_USER__`.

This is the "soul" half of MOLT: your dotfiles, manifest, and per-machine overrides. The framework lives separately in the `Molt` repo.

## Layout

- `config/`: dotfiles the liberators put in place: most are linked, and some, like `ssh/config.tmpl`, are rendered. `git` and `ssh` ship with this skeleton; add `zsh/`, `doom/`, etc. as you go.
- `instances/__MOLT_HOSTNAME__/`: this machine's manifest (`molt.toml`), template vars (`vars.sh`) and terminal colours (`instance.toml`).

## First resleeve

```
export MOLT_PRJ_DIR="$HOME/Devel/prj"   # this repo lives in the sibling ~/Devel/cfg
molt resleeve --dry-run
molt resleeve
```

Before it runs:

- molt finds this repo only by your login name, as `Molt-$(whoami)` in `MOLT_CFG_DIR`, `MOLT_PRJ_DIR` or `~`. Name its directory to match.
- The `git` liberator refuses without `git-lfs`, which this skeleton's `gitconfig` requires.
- The `ssh` liberator renders `config/ssh/config.tmpl` with `envsubst`, from gettext, and refuses without it. So does the `npm` liberator, which renders `~/.npmrc` where npm is installed.
- When `~/.ssh` holds no private key, the `ssh` liberator generates `~/.ssh/id_ed25519` with no passphrase, and tells you to add its public key, `~/.ssh/id_ed25519.pub`, to GitHub.

`instances/__MOLT_HOSTNAME__/molt.toml` is the list of what is enabled out of the box. Enable more as each one's tool is installed and its `config/<name>/`, where it needs one, is in place.

## Adding a machine

Copy `instances/__MOLT_HOSTNAME__/` to `instances/<new-host>/`, named for that machine's short hostname (`hostname -s`), and edit the hostname, vars, and manifest.
