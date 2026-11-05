# Creating a New User Config Repo

MOLT keeps the [framework and your config apart](../../README.md#framework-and-config-repo): the framework (`Molt`) and your personal config (`Molt-{user}`). This guide covers creating that personal repo from scratch with `molt new-user`.

You only do this once per person. After the repo exists, day-to-day setup is covered by [Getting Started](getting-started.md).

## Why a generator

A personal config repo carries a small amount of identity: your user name, full name, email, GitHub handle and the first machine's hostname, threaded through several files (`gitconfig`, the ssh config, `vars.sh`, the manifest, the README). Cloning someone else's repo and find-replacing those by hand is error-prone and leaks the original owner's details. `molt new-user` does it deterministically from a tokenised skeleton.

## Usage

```bash
molt new-user <user> [--name "Full Name"] [--email you@example.com] \
                     [--github <handle>] [--hostname <host>] [--dest <dir>] \
                     [--from <template>]
```

Each of `<user>`, `--name`, `--email`, `--github` and `--hostname` you don't pass is prompted for; `--dest` and `--from` are never prompted for, so a script that passes every value meets no prompt. Sensible defaults:

- `--github` defaults to `<user>`
- `--name` defaults to `<user>`
- `--dest` defaults to `$MOLT_CFG_DIR/Molt-<user>` (or `./Molt-<user>` if `MOLT_CFG_DIR` is unset); `MOLT_CFG_DIR` defaults to the `cfg/` directory beside `MOLT_PRJ_DIR`
- `--from` defaults to Molt's own skeleton, `templates/molt-user`

Molt finds a config repo only by your login name, as `Molt-$(whoami)`, so `<user>` is your login name on the machines it will run on.

## Scaffolding from another template

`--from <template>` scaffolds from a directory of your own, such as a course's template, in place of Molt's skeleton. It goes through the same code: the same `__MOLT_*__` tokens are substituted in its file contents and its path names, so there is one scaffolder to keep. No `.git` is copied from it, at any depth, so a template that is a git checkout brings neither its history nor its objects into the new repo. Each file keeps its mode, so a script stays executable, and a file that is not text, such as an image or a font, arrives byte for byte.

`molt new-user` refuses a `--from` that is not a directory, and one that holds no `config/`, since Molt finds a stack only by its `config/`. Each refusal names the path and why, and writes nothing.

Example, fully specified:

```bash
molt new-user flynn \
  --name "Flynn Sinclair" \
  --email flynn.sinclair@gmail.com \
  --github flynn-sinclair \
  --hostname jormungandr
```

## The identity surface

These are the only values that vary per user. Everything else in the skeleton is shared structure.

| Token            | Example                    | Lands in                                                                                             |
| ---------------- | -------------------------- | ---------------------------------------------------------------------------------------------------- |
| `MOLT_USER`      | `flynn`                    | repo name, `molt.toml`, `vars.sh`, README                                                            |
| `MOLT_FULL_NAME` | `Flynn Sinclair`           | `gitconfig`, `gitconfig_<github>`, README                                                            |
| `MOLT_EMAIL`     | `flynn.sinclair@gmail.com` | `gitconfig`, `gitconfig_<github>`                                                                    |
| `MOLT_GITHUB`    | `flynn-sinclair`           | ssh host alias, `gitconfig_<github>` filename and the `gitconfig` include of it, `molt.toml`, README |
| `MOLT_HOSTNAME`  | `jormungandr`              | `instances/<hostname>/` and its `molt.toml` and `vars.sh`, README                                    |

## What it generates

```
Molt-flynn/
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
      molt.toml                  # enables only what needs no config of yours
      vars.sh
```

The instance `molt.toml` is the list of what is enabled out of the box. Enable the rest in the instance manifest as each one's tool is installed and its `config/<name>/` directory, where it needs one, is in place.

## Scaffold-time and resleeve-time placeholders

The skeleton deliberately uses **distinct delimiter styles** for each, and the distinction matters:

- `__MOLT_USER__`, `__MOLT_GITHUB__`, …: **scaffold-time** tokens. `molt new-user` substitutes these once, when the repo is created.
- `${MOLT_SSH_KEY}`, `${MOLT_FONT_FAMILY}`, …: **resleeve-time** template vars, which `envsubst` fills in at each resleeve from the instance's `vars.sh`.

Because the delimiters differ, scaffolding never touches the runtime vars: a generated `config.tmpl` still contains a live `${MOLT_SSH_KEY}` for the ssh liberator to render per machine.

## Git identity include

`gitconfig` pulls in a second identity file via:

```ini
[include]
	path = ~/.gitconfig_<github>
```

The git liberator links **any** `config/git/gitconfig_*` file to `~/.<basename>`, so the filename can be whatever your handle is: nothing in the framework is hardcoded to a specific person.

## Next steps

`molt new-user` prints these on completion:

```bash
cd "<dest>"
MOLT_CFG_DIR="<parent>" molt resleeve --dry-run
MOLT_CFG_DIR="<parent>" molt resleeve
# The resleeve links ~/.gitconfig, which gives git your name and email, and
# renders ~/.ssh/config, whose github.com-<github> host the push uses; with
# no key in ~/.ssh it makes ~/.ssh/id_ed25519: add its .pub to GitHub.
git init -b main && git add -A && git commit -m "Initial molt-<user> config"
# create the GitHub repo <github>/molt-<user>, then:
git remote add origin git@github.com-<github>:<github>/molt-<user>.git
git push -u origin main
```

The resleeve comes first because the commit and the push both need what it puts in place: your name and email in the linked gitconfig, and the `github.com-<github>` ssh host that the generated `config/ssh/config.tmpl` defines. `git init -b main` names the branch the push names, whatever git's own default is.

From a `--from` template, the next steps are the resleeve, `git init` and the first commit. The GitHub comment, repo and remote lines are the skeleton's, and are left out, since a template names its own git host, if it names one.

## Adding more machines

Copy the first instance directory to one named for the new machine's short hostname (`hostname -s`), and edit it:

```bash
cp -R instances/<first-host> instances/<new-host>
$EDITOR instances/<new-host>/instance.toml   # [terminal] colours
$EDITOR instances/<new-host>/vars.sh         # MOLT_HOSTNAME, fonts, etc.
$EDITOR instances/<new-host>/molt.toml       # which liberators to enable
```
