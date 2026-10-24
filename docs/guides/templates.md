# Template System

Some config files need per-instance values — SSH key names, font families, project paths. MOLT's template system renders `.tmpl` files using `envsubst` with instance-specific variables. Only `MOLT_*` variables are substituted; any other `$VAR` is left as written.

## How it works

1. You create a template file (eg `config/ssh/config.tmpl`) with `${MOLT_*}` placeholders
2. Each instance defines its variables in `instances/{hostname}/vars.sh`
3. During resleeve, `molt_render` substitutes the variables and writes the rendered file

## Template files

Template files are regular config files with `envsubst`-style `${MOLT_*}` placeholders:

```
# config/ssh/config.tmpl
Host github.com-you
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
export MOLT_FONT_FAMILY="MesloLGS Nerd Font"
export MOLT_FONT_SIZE=11.0

# instances/rhadamanth/vars.sh
export MOLT_SSH_KEY="personalid"
export MOLT_FONT_FAMILY="Hack Nerd Font Mono"
export MOLT_FONT_SIZE=12.0
```

Variables are sourced in a subshell during rendering — they don't leak into the framework environment.

`vars.sh` is read for more than templates. Molt also reads `MOLT_INSTALL_PREFIX` from it (where `molt install` publishes the opt tree), `MOLT_CLAUDE_CONFIG_DIR` (where the `claude` liberator keeps Claude Code's state) and `MOLT_FONT_FAMILY` (the font `molt doctor` checks for). The `env` liberator publishes each `<TOOL>_INSTALL_PREFIX` it exports, other than `MOLT_` ones, to shells and GUI apps.

## Using templates in liberators

The simplest approach is `molt_install_config`, which auto-picks between rendering and symlinking:

```bash
# If config/alacritty/alacritty.toml.tmpl exists → render with instance vars
# If config/alacritty/alacritty.toml exists → symlink
# If neither exists → warn and return 1
molt_install_config "config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
```

A liberator whose target must be a regular file renders it and never links it. `ssh` is one: ssh refuses a linked `~/.ssh/config`, so the `ssh` liberator renders `config/ssh/config.tmpl` and refuses a static `config/ssh/config`, which as `config.tmpl` renders as it stands.

For direct control, use `molt_render`:

```bash
molt_render "$user_repo/config/starship/starship.toml.tmpl" "$HOME/.config/starship.toml"
```

`ssh` does not call `molt_render`: it builds its file with fragments, as [Instance-scoped liberator config](#instance-scoped-liberator-config) describes.

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

When `molt_render` writes a file, it also creates a `.molt-rendered` marker file next to it (eg `~/.ssh/config.molt-rendered`). This marker records:

- The source template path
- The timestamp of rendering
- A `digest` line: the SHA-256 of the template concatenated with the instance `vars.sh`
- An `output` line: the SHA-256 of the file as molt wrote it

The marker lets `molt doctor` and liberator `_check` functions distinguish rendered files from manually-created ones, and the digest lets them tell whether the rendered file still matches what it was rendered from. The output hash lets the next render tell a hand edit from molt's own work: a file still as molt wrote it is replaced without a backup, and any other is backed up first. An existing symlink at the target is removed, never backed up.

## Detecting stale renders

molt renders a config only when its liberator's `_check` reports not-ok. A change to a template therefore does not propagate on its own: the check passes, install is skipped, and the machine keeps running the previous rendered file while reporting success at every step.

`molt_config_stale <source> <target>` closes that. Liberators that render **must** fold it into their `_check`:

```bash
if molt_config_stale "config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"; then
  molt_info "alacritty: ~/.config/alacritty/alacritty.toml differs from its template or instance vars — re-rendering"
  ok=1
fi
```

`<source>` is repo-relative and without `.tmpl`, and is looked for in the user repo. A liberator that renders with extra inputs, as `ssh` does with its fragments, passes them after the target. A template Molt itself ships uses `molt_render_stale`.

It compares the digest recorded in `.molt-rendered` against a freshly computed one. It is **not** an mtime comparison, deliberately:

- git rewrites mtimes. A clone stamps every file with the clone time, and `git checkout -- <file>` restamps content that never changed, so every template would read stale after ordinary git operations.
- A byte-identical template that is merely touched would read stale.
- Across two filesystems mtime produces **false negatives**. A FUSE mount that truncates mtime to whole seconds, compared against an ext4 file carrying nanoseconds inside the same second, reports "not newer" — silently skipping a render that was needed.
- A guest with no NTP has no clock authority to compare against at all.

The digest covers the instance `vars.sh` as well as the template, because `molt_render` substitutes it. A vars-only edit changes the rendered output while leaving the template untouched, and vars.sh is by definition the per-machine file — the least visible edit there is.

It **fails closed**: if the digest cannot be computed, it reports stale. Re-rendering costs a moment; skipping a needed render does not announce itself.

Installs predating the digest carry no `digest` line, so each rendered config re-renders once after upgrading. That is expected.

## Preserving hand-written entries

A template may open with a marker:

```
# @@MOLT:BEGIN@@ — managed by molt, do not edit below this line
# Add your own entries ABOVE this line.
```

When the existing file carries `@@MOLT:BEGIN@@` and the new render opens with it, on its first line, `molt_render` preserves everything above the marker from the current file and prepends it to the new render. A render with lines of its own above the marker keeps nothing, since those lines would be written again under the kept copy at every render; nor does a marker that is only mentioned further down. When lines above the marker are not kept and the file is backed up, molt warns how many of them the new render does not carry, and names the backup that holds them. Files without the marker — rendered scripts, plists — are replaced wholesale as before.

Anything _below_ the marker is molt's to own and will be replaced. Content that must survive belongs either above the marker or in the template itself.

## Graceful degradation

If `vars.sh` doesn't exist for the current instance, `molt_render` warns and renders with environment variables only. Only the `MOLT_*` variables that `vars.sh` or the environment exports are substituted: any other `${...}`, and a `MOLT_*` variable nothing sets, is left in the rendered file as written, so a missing instance value shows up as its own placeholder. A `vars.sh` that exists but cannot be read, does not parse, or stops before its end when sourced is refused, and nothing is rendered.

## Permission handling

When `molt_render` places a file:

- An existing symlink at the target is removed, never backed up, wherever it is (symlinks in `~/.ssh` break SSH)
- Where the target's parent directory is `700`, as `~/.ssh` is, the rendered file and its marker are set to `600`; elsewhere their permissions are left as they are written

## Instance-scoped liberator config

Some liberators read per-machine files from `instances/<hostname>/` rather than from `config/`, because the value is genuinely machine-specific rather than shared:

| Liberator | File                                          | Shape                                                                                                                                                                                                                                                     |
| --------- | --------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `keys`    | `instances/<host>/keyd/default.conf`          | keyd config, copied to `/etc/keyd/`                                                                                                                                                                                                                       |
| `ssh`     | `instances/<host>/ssh/config.d/*.conf`        | fragments appended to the rendered `~/.ssh/config`                                                                                                                                                                                                        |
| `desktop` | `instances/<host>/desktop/favorite-apps`      | one `.desktop` id per line; line order is dock order, blank lines and `#` comments ignored                                                                                                                                                                |
| `desktop` | `instances/<host>/desktop/gsettings`          | one `<schema> <key> <value>` per line, the value to the end of the line as `gsettings get` prints it; blank lines and lines starting with `#` ignored, a `#` later in a line being part of the value; applied on install, read back and compared by check |
| `agents`  | `instances/<host>/agents/<role>.md`           | appended to the agent's `AGENTS.md`, after the role's template, when the sleeve has one                                                                                                                                                                   |
| `zsh`     | `instances/<host>/instance.toml` `[terminal]` | `bg_color` and `ssh_bg_color`: every instance's `ssh_bg_color` and this sleeve's `bg_color` build `~/.config/molt/iterm2-ssh-colors.sh`, the iTerm2 ssh wrapper                                                                                           |

A liberator that builds a rendered file from one of these as well (as `ssh` does, putting its fragments after the template's render) builds the whole file before it is placed: `molt_render_tmp` into `<target>.molt-tmp` (which renders with `molt_render_text`), its own additions there, then `molt_render_place` with those files as extra inputs, so the sidecar's digest covers them. It passes the same files to `molt_config_stale` in `_check`; pass them to only one of the two and the digests never agree, so the liberator reinstalls on every run. A file added to after it is placed differs from every new render, so each install backs it up.

Prefer this over a `vars.sh` variable when the value is a list, when ordering matters, or when it is really a config file in its own format. Prefer `vars.sh` for scalars that a template needs to interpolate.
