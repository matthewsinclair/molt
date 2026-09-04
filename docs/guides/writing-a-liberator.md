# Writing a Liberator

A liberator is a config module that frees you from one default. Each one handles a single concern: shell config, editor setup, SSH keys, etc.

## The contract

Every liberator is a bash script in `liberators/` that implements three functions:

```bash
# {name}_check — Is this already configured?
# Return 0 if yes, non-zero if install is needed.
myapp_check() {
  ...
}

# {name}_install — Configure it.
# Called only when _check returns non-zero.
myapp_install() {
  ...
}

# {name}_verify — Confirm installation is correct.
# Called after install to validate the result.
myapp_verify() {
  ...
}
```

The framework discovers scripts in `liberators/`, loads them on demand by sourcing the file, and calls these functions in order during `molt resleeve`.

### Optional callbacks

```bash
# {name}_upgrade — Fast config sync.
# Called by `molt upgrade`. Pull repos, sync packages, etc.
myapp_upgrade() {
  ...
}

# {name}_maintain — Heavy system maintenance.
# Called by `molt maintain`. Update packages, upgrade frameworks, etc.
# This is for slow, heavier operations you run weekly/monthly.
myapp_maintain() {
  ...
}
```

- **`_upgrade()`** = config sync (fast, safe, daily) — pull repos, `doom sync`
- **`_maintain()`** = system maintenance (slow, heavier, weekly/monthly) — `brew upgrade`, `doom upgrade`

## Rules

1. **Never install packages.** Check that prerequisites exist and fail with a hint if they're missing. The user installs packages; liberators handle configuration.

2. **Use `molt_link` for static config.** It handles backup, mkdir, and idempotency.

3. **Use `molt_install_config` when templates might apply.** It auto-picks between render (`.tmpl`) and symlink based on what exists in the user's config repo.

4. **If you render, call `molt_config_stale` in your `_check`.** molt only renders when a check reports not-ok, so without it a template or `vars.sh` change never reaches the machine — the check passes, install is skipped, and the sleeve runs the old file while reporting success. See [templates.md](templates.md#detecting-stale-renders).

5. **Check symlinks with `molt_link_healthy`, and describe them with `molt_link_fault`.** A bare `[[ -L "$target" ]]` asks only "is there a symlink here", which a _dangling_ symlink satisfies — so a link pointing at a path that no longer exists reports ok, install never runs, and `molt resleeve` prints "Sleeve ready" over a sleeve with no config. Check every target your `_install` links, in both `_check` and `_verify`, and get the message from `molt_link_fault` rather than hard-coding one: it distinguishes missing, not-a-symlink and broken-symlink, and telling someone their file "is not a symlink" when `ls -l` plainly shows an arrow is how a real debugging session gets sent the wrong way.

6. **Be idempotent.** Running a liberator twice should produce the same result. Don't duplicate backups, don't create duplicate entries.

7. **Use `molt_platform` for OS branching.** Returns `linux` or `macos`.

## Minimal example

```bash
#!/usr/bin/env bash
# myapp.sh — Liberator: MyApp
# Frees you from unconfigured MyApp defaults.

myapp_check() {
  if ! command -v myapp &>/dev/null; then
    molt_info "myapp: not installed"
    return 1
  fi

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]] && [[ -f "$user_repo/config/myapp/config.toml" ]]; then
    if [[ ! -L "$HOME/.config/myapp/config.toml" ]]; then
      molt_info "myapp: config not linked"
      return 1
    fi
  fi

  return 0
}

myapp_install() {
  if ! command -v myapp &>/dev/null; then
    molt_error "MyApp not found. Install it first: https://myapp.dev/install"
    return 1
  fi

  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1

  if [[ -f "$user_repo/config/myapp/config.toml" ]]; then
    molt_link "$user_repo/config/myapp/config.toml" "$HOME/.config/myapp/config.toml"
  fi

  molt_info "Liberator complete: myapp"
}

myapp_verify() {
  local errors=0

  if ! command -v myapp &>/dev/null; then
    molt_error "VERIFY FAIL: myapp not installed"
    errors=1
  fi

  if [[ ! -L "$HOME/.config/myapp/config.toml" ]]; then
    molt_error "VERIFY FAIL: myapp config not linked"
    errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: myapp liberator is fully operational"
  fi
  return $errors
}
```

## Framework functions available to liberators

| Function                      | Purpose                                                                                                                             |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `molt_link src dst`           | Symlink `src` to `dst`, backup existing, mkdir parent                                                                               |
| `molt_link_healthy dst`       | True only when `dst` is a symlink that actually resolves. Use instead of `[[ -L ]]`, which passes on dangling links                 |
| `molt_link_fault dst`         | Names the fault for messages: `is missing`, `is not a symlink`, `is a broken symlink` (or `resolves`)                               |
| `molt_link_points_to dst src` | True when `dst` is a healthy symlink pointing at `src`. A link that resolves to the _wrong_ target still passes `molt_link_healthy` |
| `molt_render tmpl dst`        | Render template via `envsubst` with instance vars                                                                                   |
| `molt_install_config`         | Auto-pick render (`.tmpl`) or link (static)                                                                                         |
| `molt_config_stale`           | True when a rendered file no longer matches its template + instance vars. Renderers **must** use this in `_check`                   |
| `molt_find_user_repo`         | Return path to the user's config repo                                                                                               |
| `molt_platform`               | Return `linux` or `macos`                                                                                                           |
| `molt_distro`                 | Return distro name (eg `ubuntu`, `fedora`, `macos`)                                                                                 |
| `molt_arch`                   | Return architecture (eg `arm64`, `x86_64`)                                                                                          |
| `molt_info msg`               | Print info message (prefixed with `Zen:`)                                                                                           |
| `molt_warn msg`               | Print warning                                                                                                                       |
| `molt_error msg`              | Print error                                                                                                                         |

## Adding to the manifest

After creating your liberator script, add it to your `molt.toml`:

```toml
[[liberator]]
name = "myapp"
enabled = true
os = ["linux", "macos"]
depends = ["zsh"]           # optional: run after these liberators
```

## Platform-specific behavior

Use `molt_platform` to branch:

```bash
myapp_install() {
  case "$(molt_platform)" in
    linux)
      # Linux-specific setup (gsettings, dconf, etc.)
      ;;
    macos)
      # macOS-specific setup (defaults write, etc.)
      ;;
  esac
}
```

Set `os` in the manifest to restrict which platforms a liberator runs on. If a liberator is Linux-only, set `os = ["linux"]` and it will be skipped on macOS.

## GNOME dock integration

For Linux apps that should appear in the GNOME dock:

```bash
if [[ "$(molt_platform)" == "linux" ]] && command -v gsettings &>/dev/null; then
  local favorites
  favorites="$(gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "")"
  if [[ -n "$favorites" ]] && [[ "$favorites" != *"myapp.desktop"* ]]; then
    local new_favorites
    new_favorites="$(echo "$favorites" | sed "s/]/, 'myapp.desktop']/")"
    gsettings set org.gnome.shell favorite-apps "$new_favorites"
  fi
fi
```

## Testing

See `test/liberators/zsh.bats` for an example of how to test a liberator using the HOME-sandboxed bats test infrastructure.
