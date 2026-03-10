# Template System

Some config files need per-instance values — SSH key names, font families, project paths. MOLT's template system renders `.tmpl` files using `envsubst` with instance-specific variables.

## How it works

1. You create a template file (e.g. `config/ssh/config.tmpl`) with `${VARIABLE}` placeholders
2. Each instance defines its variables in `instances/{hostname}/vars.sh`
3. During resleeve, `molt_render` substitutes the variables and writes the rendered file

## Template files

Template files are regular config files with `envsubst`-style variable placeholders:

```
# config/ssh/config.tmpl
Host github.com-matthewsinclair
  HostName github.com
  User git
  IdentityFile ~/.ssh/${MOLT_SSH_KEY}
  IdentitiesOnly yes
```

Templates live alongside static config in your `config/` directory, with a `.tmpl` extension.

## Instance variables

Each instance defines its variables in `instances/{hostname}/vars.sh`. Variables **must** be exported:

```bash
# instances/kovacs/vars.sh
export MOLT_SSH_KEY="id_ed25519"
export MOLT_FONT_FAMILY="JetBrainsMono Nerd Font"
export MOLT_FONT_SIZE="14"

# instances/rhadamanth/vars.sh
export MOLT_SSH_KEY="personalid"
export MOLT_FONT_FAMILY="Menlo"
export MOLT_FONT_SIZE="12"
```

Variables are sourced in a subshell during rendering — they don't leak into the framework environment.

## Using templates in liberators

The simplest approach is `molt_install_config`, which auto-picks between rendering and symlinking:

```bash
# If config/ssh/config.tmpl exists → render with instance vars
# If config/ssh/config exists → symlink
# If neither exists → warn and return 1
molt_install_config "config/ssh/config" "$HOME/.ssh/config"
```

For direct control, use `molt_render`:

```bash
molt_render "$user_repo/config/ssh/config.tmpl" "$HOME/.ssh/config"
```

## Config fragments

Some configs benefit from instance-specific additions appended after the rendered template. The SSH liberator supports this pattern:

```
instances/
  kovacs/
    ssh/config.d/         # empty — no extra hosts
  rhadamanth/
    ssh/config.d/
      lan-hosts.conf      # LAN-specific SSH hosts
```

During install, the SSH liberator renders the template, then appends each `.conf` file from the instance's `config.d/` directory.

## Rendered file markers

When `molt_render` writes a file, it also creates a `.molt-rendered` marker file next to it (e.g. `~/.ssh/config.molt-rendered`). This marker records:

- The source template path
- The timestamp of rendering

The marker lets `molt doctor` and liberator `_check` functions distinguish rendered files from manually-created ones.

## Graceful degradation

If `vars.sh` doesn't exist for the current instance, `molt_render` warns and renders with environment variables only. Any `${VARIABLE}` without a value is replaced with an empty string — so templates still work, just with blanks where instance-specific values would go.

## Permission handling

For sensitive directories like `~/.ssh` (which has `700` permissions), `molt_render` automatically:

- Removes existing symlinks rather than backing them up (symlinks in `~/.ssh` break SSH)
- Sets rendered files and markers to `600` permissions
