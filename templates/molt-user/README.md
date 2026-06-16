# `molt-__MOLT_USER__`

Personal MOLT config repo for `__MOLT_FULL_NAME__` (`@__MOLT_GITHUB__`).

This is the "soul" half of the MOLT two-repo model: your dotfiles, manifest,
and per-machine overrides. The framework lives separately in the `molt` repo.

## Layout

- `config/` — dotfiles linked into place by liberators (`git` and `ssh` ship
  with this skeleton; add `zsh/`, `doom/`, etc. as you go).
- `instances/__MOLT_HOSTNAME__/` — this machine's manifest + template vars.

## First resleeve

```
export MOLT_PRJ_DIR="$HOME/Devel/prj"
molt resleeve --dry-run
molt resleeve
```

Only `system`, `local-bin`, `git`, and `ssh` are enabled out of the box.
Enable more liberators in `instances/__MOLT_HOSTNAME__/molt.toml` as you add
their config.

## Adding a machine

Copy `instances/__MOLT_HOSTNAME__/` to `instances/<new-host>/` and edit the
hostname, vars, and manifest.
