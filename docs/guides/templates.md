# Template System

Some config files need per-instance values — SSH key names, font families, project paths. MOLT's template system renders `.tmpl` files using `envsubst` with instance-specific variables.

## How it works

1. You create a template file (eg `config/ssh/config.tmpl`) with `${VARIABLE}` placeholders
2. Each instance defines its variables in `instances/{hostname}/vars.sh`
3. During resleeve, `molt_render` substitutes the variables and writes the rendered file

## Template files

Template files are regular config files with `envsubst`-style variable placeholders:

```
# config/ssh/config.tmpl
Host github.com-{github}
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

When `molt_render` writes a file, it also creates a `.molt-rendered` marker file next to it (eg `~/.ssh/config.molt-rendered`). This marker records:

- The source template path
- The timestamp of rendering
- A `digest` line: the SHA-256 of the template concatenated with the instance `vars.sh`

The marker lets `molt doctor` and liberator `_check` functions distinguish rendered files from manually-created ones, and the digest lets them tell whether the rendered file still matches what it was rendered from.

## Detecting stale renders

molt renders a config only when its liberator's `_check` reports not-ok. A change to a template therefore does not propagate on its own: the check passes, install is skipped, and the machine keeps running the previous rendered file while reporting success at every step.

`molt_config_stale <source> <target>` closes that. Liberators that render **must** fold it into their `_check`:

```bash
if molt_config_stale "config/ssh/config" "$HOME/.ssh/config"; then
  molt_info "ssh: ~/.ssh/config differs from its template or instance vars — re-rendering"
  ok=1
fi
```

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

When both the existing file and the new render carry `@@MOLT:BEGIN@@`, `molt_render` preserves everything above the marker from the current file and prepends it to the new render. Files without the marker — rendered scripts, plists — are replaced wholesale as before.

Anything _below_ the marker is molt's to own and will be replaced. Content that must survive belongs either above the marker or in the template itself.

## Graceful degradation

If `vars.sh` doesn't exist for the current instance, `molt_render` warns and renders with environment variables only. Any `${VARIABLE}` without a value is replaced with an empty string — so templates still work, just with blanks where instance-specific values would go.

## Permission handling

For sensitive directories like `~/.ssh` (which has `700` permissions), `molt_render` automatically:

- Removes existing symlinks rather than backing them up (symlinks in `~/.ssh` break SSH)
- Sets rendered files and markers to `600` permissions
