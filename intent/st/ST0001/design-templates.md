# Template System Design — ST0001

## Problem

MOLT currently has two strategies for managing config files:

1. **Symlink** — file is identical across all sleeves. Lives in `molt-{user}/config/`, symlinked into `~`. Works for most dotfiles.
2. **Instance override** — file is completely different per machine. Lives in `molt-{user}/instances/{hostname}/`. Used for keyd config today.

There's a gap: config files that are _mostly_ the same across sleeves but need a few values to vary per-instance. Current examples:

| File             | What varies                                          | Current workaround                           |
| ---------------- | ---------------------------------------------------- | -------------------------------------------- |
| `alacritty.toml` | Font name/size (Nerd Font may not be on all sleeves) | Hardcoded, must manually edit                |
| `doom/config.el` | Font face and size (platform-conditional)            | Inline `IS-LINUX` / `IS-MAC` guards in elisp |
| `starship.toml`  | Potentially nothing yet, but hostname display        | Static                                       |
| `ssh/config`     | Identity file paths differ if username differs       | Hardcoded to `matts`                         |

These are not enough files to justify a heavy template engine. But without _something_, config files accumulate platform conditionals and instance-specific hardcoding.

## Design Principles

1. **Minimum viable**: The simplest thing that solves the actual problem. No Jinja2, no ERB, no dependency.
2. **Bash-native**: MOLT is a bash framework. Templates should render with tools already available (sed, envsubst, or parameter expansion).
3. **Explicit over magic**: Template files should be visually obvious — you should be able to tell at a glance that a file is a template, not a final config.
4. **Symlink-first**: Most files should remain static symlinks. Templates are the exception, not the rule.
5. **Idempotent**: Re-rendering a template with the same values produces the same output. No state accumulation.

## Proposed Approach: envsubst with `.tmpl` files

### How it works

1. Template files live alongside regular config in `molt-{user}/config/` with a `.tmpl` extension.
2. Variables are standard `${VAR_NAME}` shell syntax.
3. A new framework function `molt_render` replaces `molt_link` for template files: it reads the template, substitutes variables, and writes the output to the target path.
4. Variables are sourced from a per-instance vars file: `molt-{user}/instances/{hostname}/vars.sh`.

### File layout

```
molt-{user}/
  config/
    alacritty/
      alacritty.toml           # Static — symlinked as today (if no per-instance variation)
      alacritty.toml.tmpl      # Template — rendered to target (if variation needed)
    doom/
      custom/
        010-ui.el.tmpl         # Template for font config
  instances/
    kovacs/
      vars.sh                  # Instance variables
      keyd/default.conf        # Full instance overrides (unchanged)
    rhadamanth/
      vars.sh                  # Instance variables
```

### vars.sh

A simple bash file that exports instance-specific values:

```bash
# instances/kovacs/vars.sh — Instance variables for kovacs
export MOLT_FONT_FAMILY="JetBrainsMono Nerd Font"
export MOLT_FONT_SIZE=14
export MOLT_HOSTNAME="kovacs"
export MOLT_PLATFORM="linux"
```

```bash
# instances/rhadamanth/vars.sh — Instance variables for rhadamanth
export MOLT_FONT_FAMILY="Menlo"
export MOLT_FONT_SIZE=13
export MOLT_HOSTNAME="rhadamanth"
export MOLT_PLATFORM="macos"
```

### Template example

`config/alacritty/alacritty.toml.tmpl`:

```toml
[font]
size = ${MOLT_FONT_SIZE}

[font.normal]
family = "${MOLT_FONT_FAMILY}"

[window]
option_as_alt = "Both"
```

### Framework function

```bash
# In lib/molt.sh

molt_render() {
  local template="$1"
  local target="$2"

  if [[ ! -f "$template" ]]; then
    molt_error "Template not found: $template"
    return 1
  fi

  # Load instance vars
  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1
  local hostname
  hostname="$(hostname)"
  local vars_file="$user_repo/instances/$hostname/vars.sh"

  if [[ -f "$vars_file" ]]; then
    # Source vars in a subshell for safety, then render
    (
      source "$vars_file"
      envsubst < "$template"
    ) > "${target}.molt-tmp"
  else
    molt_warn "No vars.sh for instance $hostname — rendering template with env only"
    envsubst < "$template" > "${target}.molt-tmp"
  fi

  # Back up existing file if it's not already a molt-rendered file
  if [[ -e "$target" ]] && [[ ! -f "${target}.molt-rendered" ]]; then
    local backup="${target}.molt-backup.$(date +%Y%m%d%H%M%S)"
    molt_warn "Backing up existing file: $target -> $backup"
    mv "$target" "$backup"
  fi

  # Create parent directory if needed
  mkdir -p "$(dirname "$target")"

  mv "${target}.molt-tmp" "$target"

  # Leave a marker so we know this file was rendered (not symlinked)
  echo "rendered $(date -Iseconds) from $template" > "${target}.molt-rendered"
  molt_info "Rendered: $template -> $target"
}
```

### Liberator usage

Liberators choose between `molt_link` and `molt_render` based on whether a `.tmpl` file exists:

```bash
# In a liberator's _install function:
local user_repo
user_repo="$(molt_find_user_repo)" || return 1

local config_file="$user_repo/config/alacritty/alacritty.toml"
local template_file="${config_file}.tmpl"
local target="$HOME/.config/alacritty/alacritty.toml"

if [[ -f "$template_file" ]]; then
  molt_render "$template_file" "$target"
elif [[ -f "$config_file" ]]; then
  molt_link "$config_file" "$target"
fi
```

Or, as a helper that picks the right strategy automatically:

```bash
# Could add to lib/molt.sh
molt_install_config() {
  local source="$1"    # e.g. config/alacritty/alacritty.toml
  local target="$2"    # e.g. ~/.config/alacritty/alacritty.toml

  local user_repo
  user_repo="$(molt_find_user_repo)" || return 1

  local full_source="$user_repo/$source"
  local template="${full_source}.tmpl"

  if [[ -f "$template" ]]; then
    molt_render "$template" "$target"
  elif [[ -f "$full_source" ]]; then
    molt_link "$full_source" "$target"
  else
    molt_warn "Config not found: $source (checked template and static)"
    return 1
  fi
}
```

## How liberators change

Minimal. Most liberators keep calling `molt_link` unchanged. Only liberators that manage files with per-instance variation switch to `molt_install_config` or direct `molt_render` calls. Today that's:

- **terminal** — `alacritty.toml` font config
- **editors** — `doom/custom/010-ui.el` font config

Everything else stays as-is.

## What this does NOT do

- **No conditional logic in templates.** If you need `if platform == linux`, that stays in the liberator's bash code or in the config file's own conditional syntax (like elisp's `IS-LINUX`). Templates only substitute values.
- **No template discovery/auto-rendering.** Liberators explicitly choose when to render. No framework walks the config tree looking for `.tmpl` files.
- **No inheritance/layering.** A template is one file. There's no base + overlay model. Instance overrides (`instances/{hostname}/`) continue to work as whole-file replacements for truly different configs.
- **No external dependencies.** `envsubst` ships with `gettext` on all target platforms (pre-installed on Ubuntu, available via brew on macOS).

## Alternatives considered

### 1. sed replacements

Pattern: `sed -e 's/@@FONT@@/JetBrainsMono Nerd Font/g'`

Pro: Zero dependencies. Con: Fragile — must pick a delimiter that won't conflict, harder to read, no standard variable naming.

### 2. Bash parameter expansion (heredoc rendering)

Pattern: `eval "echo \"$(cat template)\""` or `envsubst`

Pro: Bash-native. Con: `eval` is dangerous. `envsubst` is safer and nearly as available.

### 3. m4 / mustache / ERB / Jinja2

Pro: Full logic. Con: External dependency, overkill for substituting 3 variables in 2 files.

### 4. Keep platform conditionals in config files

Pro: No framework changes. Con: Config files accumulate ugly conditionals (Doom's `IS-LINUX` guards are already getting unwieldy). Not all config formats support conditionals.

## Recommendation

Implement the `envsubst` approach. It's the minimum viable solution:

- One new function (`molt_render`) + optional helper (`molt_install_config`)
- One new convention (`.tmpl` extension, `instances/{hostname}/vars.sh`)
- No external dependencies beyond what's already available
- Liberators opt in explicitly — no breaking changes

Start with alacritty.toml and doom font config as the two pilot templates. If the pattern holds, extend to other files as needed.

## Implementation sequence

1. Add `molt_render` to `lib/molt.sh`
2. Add `molt_install_config` helper
3. Create `instances/kovacs/vars.sh` and `instances/rhadamanth/vars.sh` in molt-matts
4. Convert `config/alacritty/alacritty.toml` to `.tmpl`
5. Update `terminal` liberator to use `molt_install_config`
6. Convert doom font config to `.tmpl`
7. Update `editors` liberator
8. Add bats tests for `molt_render`
9. Register any new modules in MODULES.md
