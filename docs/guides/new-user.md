# Creating a New User Config Repo

MOLT uses a [two-repo model](../../README.md#two-repo-model): the framework
(`molt`) and your personal config (`molt-{user}`). This guide covers creating
that personal repo from scratch with `molt new-user`.

You only do this once per person. After the repo exists, day-to-day setup is
covered by [Getting Started](getting-started.md).

## Why a generator

A personal config repo carries a small amount of identity — your name, email,
GitHub handle, the first machine's hostname — threaded through a dozen files
(`gitconfig`, the ssh config, `vars.sh`, the manifest, the README). Cloning
someone else's repo and find-replacing those by hand is error-prone and leaks
the original owner's details. `molt new-user` does it deterministically from a
tokenised skeleton.

## Usage

```bash
molt new-user <user> [--name "Full Name"] [--email you@example.com] \
                     [--github <handle>] [--hostname <host>] [--dest <dir>]
```

Anything you don't pass as a flag is prompted for. Sensible defaults:

- `--github` defaults to `<user>`
- `--name` defaults to `<user>`
- `--dest` defaults to `$MOLT_PRJ_DIR/molt-<user>` (or `./molt-<user>` if
  `MOLT_PRJ_DIR` is unset)

Example, fully specified:

```bash
molt new-user flynn \
  --name "Flynn Sinclair" \
  --email flynn.sinclair@gmail.com \
  --github flynn-sinclair \
  --hostname jormungandr
```

## The identity surface

These are the only values that vary per user. Everything else in the skeleton
is shared structure.

| Token            | Example                    | Lands in                                      |
| ---------------- | -------------------------- | --------------------------------------------- |
| `MOLT_USER`      | `flynn`                    | repo name, `molt.toml`, `vars.sh`, README     |
| `MOLT_FULL_NAME` | `Flynn Sinclair`           | `gitconfig`, `gitconfig_<github>`             |
| `MOLT_EMAIL`     | `flynn.sinclair@gmail.com` | `gitconfig`, `gitconfig_<github>`             |
| `MOLT_GITHUB`    | `flynn-sinclair`           | ssh host alias, `gitconfig_<github>` filename |
| `MOLT_HOSTNAME`  | `jormungandr`              | `instances/<hostname>/`                       |

## What it generates

```
molt-flynn/
  README.md
  .gitignore
  config/
    git/
      gitconfig                  # identity + [include] of the file below
      gitconfig_flynn-sinclair   # named after your GitHub handle
      gitignore_global
    ssh/
      config.tmpl                # rendered by the ssh liberator at resleeve
  instances/
    jormungandr/
      instance.toml
      molt.toml                  # only system/local-bin/git/ssh enabled
      vars.sh
```

Only the liberators that need no extra config (`system`, `local-bin`, `git`,
`ssh`) are enabled out of the box. Enable the rest in the instance manifest as
you add the matching `config/<name>/` directories.

## Two kinds of placeholder

The skeleton deliberately uses **two distinct delimiter styles**, and the
distinction matters:

- `__MOLT_USER__`, `__MOLT_GITHUB__`, … — **scaffold-time** tokens. `molt
new-user` substitutes these once, when the repo is created.
- `${MOLT_SSH_KEY}`, `${MOLT_FONT_FAMILY}`, … — **resleeve-time** template
  vars, rendered later by `molt_render` via `envsubst` using the instance's
  `vars.sh`.

Because the delimiters differ, scaffolding never touches the runtime vars — a
generated `config.tmpl` still contains a live `${MOLT_SSH_KEY}` for the ssh
liberator to render per machine.

## Git identity include

`gitconfig` pulls in a second identity file via:

```ini
[include]
	path = ~/.gitconfig_<github>
```

The git liberator links **any** `config/git/gitconfig_*` file to
`~/.<basename>`, so the filename can be whatever your handle is — nothing in the
framework is hardcoded to a specific person.

## Next steps

`molt new-user` prints these on completion:

```bash
cd <dest>
git init && git add -A && git commit -m "Initial molt-<user> config"
# create the GitHub repo <github>/molt-<user>, then:
git remote add origin git@github.com-<github>:<github>/molt-<user>.git
git push -u origin main
MOLT_PRJ_DIR="<parent>" molt resleeve --dry-run
```

The remote URL uses the `github.com-<github>` ssh host alias that the generated
`config/ssh/config.tmpl` defines, so it works once the ssh liberator has run.

## Adding more machines

Copy the first instance directory and edit it:

```bash
cp -R instances/<first-host> instances/<new-host>
$EDITOR instances/<new-host>/instance.toml   # hostname, os, arch
$EDITOR instances/<new-host>/vars.sh         # MOLT_HOSTNAME, fonts, etc.
$EDITOR instances/<new-host>/molt.toml       # which liberators to enable
```
