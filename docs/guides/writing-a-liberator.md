# Writing a Liberator

A liberator is a config module that frees you from one default. Each one handles a single concern: shell config, editor setup, SSH keys, etc.

## The contract

Every liberator is a bash script in `liberators/` that implements `_check` and `_install`, and may add `_verify`. Write it in the dev tree, the checkout at `$MOLT_PRJ_DIR/Molt` (see [Which tree](#which-tree)):

```bash
# {name}_check: is this already configured?
# Return 0 if yes, non-zero if install is needed.
myapp_check() {
  ...
}

# {name}_install: configure it.
# Called only when _check returns non-zero.
myapp_install() {
  ...
}

# {name}_verify: optional. A fuller check, for the liberator's own use.
# Molt does not run it: resleeve and doctor use _check.
myapp_verify() {
  ...
}
```

The framework discovers scripts in `liberators/` and loads them on demand by sourcing the file. `molt resleeve` calls `_check`, and `_install` only when the check fails; `molt doctor` reports each enabled liberator's `_check`. `molt resleeve --dry-run`, `molt status` and `molt list` call `_check` too.

The file is `liberators/<name>.sh`, and each function is named for it, hyphens included, as in `local-bin_check`. `molt doctor` finds a liberator's check by the text `<name>_check()` at the start of a line, so define it that way.

### Which tree

Molt runs from a tree: dev, the checkout; opt, a published copy that `molt install` makes; or brew, the formula. Only the dev tree's `liberators/` is yours to write:

- In opt and brew, `liberators/` is a published copy with a manifest. A file you add there is reported as not in the manifest, and the next `molt install --force` or `brew upgrade` replaces the directory.
- `molt test` runs in the dev tree only.

So write and test a new liberator in the dev tree, commit it, and then publish it: `molt install --force` for an opt tree, or a new release for brew.

### The shell it runs in

`molt` sources a liberator into its own bash, which runs under `set -euo pipefail`, and calls `_check`, `_install`, `_upgrade` and `_maintain` inside a condition, where `set -e` does not apply. So:

- A step that fails stops nothing by itself. Return its failure, as the [minimal example](#minimal-example) does with `|| return 1`.
- `set -u` still applies. An unset variable ends the run there and then (doctor runs each check in a subshell, so only that check ends), and resleeve, `molt status` and `molt list` drop a check's stderr, so they end without saying why.
- `pipefail` fails `producer | grep -q pattern` whenever `grep` matches before the producer has finished writing. Capture the output first, then match it.
- Molt runs on macOS's bash 3.2 as well as bash 5. Under `set -u`, bash 3.2 takes an empty `"${list[@]}"` for an unset variable, so write `${list+"${list[@]}"}`.
- `_check` reports with `molt_info`, on stdout: `molt_error` writes to stderr, which resleeve drops from a check.

### Optional callbacks

```bash
# {name}_upgrade: fast config sync.
# Called by `molt upgrade`. Pull repos, sync packages, etc.
myapp_upgrade() {
  ...
}

# {name}_maintain: heavy system maintenance.
# Called by `molt maintain`. Update packages, upgrade frameworks, etc.
# This is for slow, heavier operations you run weekly/monthly.
myapp_maintain() {
  ...
}

# {name}_repo: the path of a git repo this liberator manages.
# molt git runs its git commands there as well, for an enabled liberator.
myapp_repo() {
  ...
}

# {name}_repo_git_commands: the git commands molt git may run in that repo,
# space-separated. Without it, molt git runs any.
myapp_repo_git_commands() { echo "pull status log diff fetch"; }
```

- **`_upgrade()`** = config sync (fast, safe, daily): pull repos, `doom sync`
- **`_maintain()`** = system maintenance (slow, heavier, weekly/monthly): `brew upgrade`, `doom upgrade`
- Both return non-zero when what they ran failed. `molt upgrade` and `molt maintain` name the hook, run the rest and exit 1, and the resleeve after a failed upgrade hook does not call the sleeve ready. A hook that warns and returns 0 has them report success over the failure (issue 0013).

## Rules

1. **Never install packages, except a liberator's own subject from a Homebrew tap, keyd, and Doom Emacs and the LazyVim starter.** Check that prerequisites exist and fail with a hint if they're missing; the user installs packages, and liberators handle configuration. One exception is a tool that is the liberator's subject and comes from a Homebrew tap, as cldr, Intent, Gtools and pplr do and Utilz does on a `source = "brew"` sleeve. Its `_install` runs `molt_brew_install`, passing the tap's ssh URL when the tap is private, as Gtools' is, and its `_check` and `_verify` ask `molt_brew_faults` which copy PATH runs, never only whether a link resolves. A tool with a switch of its own may run its dev or opt tree instead, as pplr and Gtools on a `source = "switch"` sleeve do: their checks name that tree by its version line and ask `molt_brew_install_faults` only whether the formula is installed. The others are the `keys` liberator, which builds keyd from source and installs it with `sudo make install`, and the `editors` liberator, which clones Doom Emacs and the LazyVim starter when they are missing.

2. **Use `molt_link`, or `molt_link_all` over a list, for static config.** It handles backup, mkdir, and idempotency.

3. **Use `molt_install_config` when templates might apply.** It auto-picks between render (`.tmpl`) and symlink based on what exists in the user's config repo.

4. **If you render, call `molt_config_stale` in your `_check`.** molt only renders when a check reports not-ok, so without it a template or `vars.sh` change never reaches the machine: the check passes, install is skipped, and the sleeve runs the old file while reporting success. See [templates.md](templates.md#detecting-stale-renders). With `molt_install_config`, check whichever form the user repo carries, as the `alacritty` liberator does: `molt_config_stale` for a `.tmpl`, and the link for a static file, which `molt_config_stale` passes since it has no template.

5. **List the links you make once, and check them with `molt_report_link_faults`.** A bare `[[ -L "$target" ]]` asks only "is there a symlink here", which a _dangling_ symlink satisfies, so a link pointing at a path that no longer exists reports ok, install never runs, and `molt resleeve` prints "Sleeve ready" over a sleeve with no config. `molt_link_healthy` catches that, and still passes a link that resolves to the wrong file. Write each link `_install` makes as a `source<TAB>target` line of one list, as the `git` liberator's `_git_links` does: `_check` and `_verify` read it with `molt_report_link_faults`, and `_install` makes it with `molt_link_all`. The message comes from the helper rather than being hard-coded: it tells a missing file, a file that is not a symlink, a broken symlink and a link to the wrong file apart, and telling someone their file "is not a symlink" when `ls -l` plainly shows an arrow is how a real debugging session gets sent the wrong way. For a single link outside a list, `molt_link_points_to` checks it, and `molt_link_fault` names what is wrong with one that does not resolve.

6. **Be idempotent.** Running a liberator twice should produce the same result. Don't duplicate backups, don't create duplicate entries.

7. **Use `molt_platform` for OS branching.** It prints `linux` or `macos`, and `unknown` on any other system.

8. **Publish a variable through the `env` liberator, never by writing a shell or GUI environment file.** `lib/env.sh`, Molt's one env writer, rebuilds its files whole from the pairs the `env` liberator gathers: `~/.config/molt/env.sh`, which `~/.zshenv` sources, and the GUI file, a LaunchAgent on macOS and an `environment.d` file on Linux. Each `<TOOL>_INSTALL_PREFIX` the sleeve's `vars.sh` exports, other than `MOLT_` ones, is gathered already. Any other variable needs a contributor: a function printing one `NAME<TAB>scope<TAB>value` line per variable, the scope `all` for both files or `gui` for the GUI file alone, as `claude_env_pairs` does, called from `_env_lines` in `liberators/env.sh`. A value that changes between runs of molt is a `command` pair, printed by `molt_env_command_pair NAME program args...` with the program's absolute path: `env.sh` at each shell start and the LaunchAgent at each login set the variable to the directory the program prints, and unset it when it prints none. `environment.d` cannot run a command, so it leaves the pair out, and the check leaves its value to the tool that prints it, as `claude_env_pairs` does with `ccusage dir`. The manifest lists its liberator before `env`, as it lists `claude`.

## Minimal example

```bash
#!/usr/bin/env bash
# myapp.sh — Liberator: MyApp
# Frees you from unconfigured MyApp defaults.

# Every link myapp_install makes, one "source<TAB>target" line each, for the
# sources the user repo $1 has. check, install and verify all read this list.
_myapp_links() {
  local user_repo="$1"
  if [[ -f "$user_repo/config/myapp/config.toml" ]]; then
    printf '%s\t%s\n' "$user_repo/config/myapp/config.toml" "$HOME/.config/myapp/config.toml"
  fi
}

myapp_check() {
  if ! command -v myapp &>/dev/null; then
    molt_info "myapp: not installed"
    return 1
  fi

  local user_repo
  user_repo="$(molt_find_user_repo 2>/dev/null || echo "")"
  if [[ -n "$user_repo" ]]; then
    molt_report_link_faults molt_info "myapp: " "$(_myapp_links "$user_repo")" || return 1
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
  molt_link_all "$(_myapp_links "$user_repo")" || return 1

  molt_info "Liberator complete: myapp"
}

myapp_verify() {
  local errors=0 user_repo

  if ! command -v myapp &>/dev/null; then
    molt_error "VERIFY FAIL: myapp not installed"
    errors=1
  fi

  if ! user_repo="$(molt_find_user_repo 2>/dev/null)"; then
    molt_error "VERIFY FAIL: user config repo not found, so no myapp link was checked"
    errors=1
  else
    molt_report_link_faults molt_error "VERIFY FAIL: " "$(_myapp_links "$user_repo")" || errors=1
  fi

  if [[ $errors -eq 0 ]]; then
    molt_info "Verified: myapp liberator is fully operational"
  fi
  return $errors
}
```

Every call that can fail in `_install` ends in `|| return 1`, `molt_link_all` included. resleeve calls `_install` inside an `if`, where `set -e` does not apply, so a failure the function does not return is reported as installed.

## Framework functions available to liberators

| Function                                    | Purpose                                                                                                                                                                                                                   |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `molt_link src dst`                         | Symlink `src` to `dst`: back up a file already there, replace a link that points elsewhere, mkdir parent                                                                                                                  |
| `molt_link_all links`                       | `molt_link` for each `source<TAB>target` line of `links`, stopping at the first that fails                                                                                                                                |
| `molt_link_healthy dst`                     | True only when `dst` is a symlink that actually resolves. Use instead of `[[ -L ]]`, which passes on dangling links                                                                                                       |
| `molt_link_fault dst`                       | Names the fault for messages: `is missing`, `is not a symlink`, `is a broken symlink` (or `resolves`)                                                                                                                     |
| `molt_link_points_to dst src`               | True when `dst` is a healthy symlink pointing at `src`. A link that resolves to the _wrong_ target still passes `molt_link_healthy`                                                                                       |
| `molt_report_link_faults log prefix links`  | Logs through `log`, after `prefix`, each `source<TAB>target` line of `links` whose target is not a link to its source, naming where a wrong one points. False when it logged one                                          |
| `molt_render tmpl dst`                      | Render template via `envsubst` with instance vars                                                                                                                                                                         |
| `molt_install_config src dst`               | Render the user repo's `src.tmpl` when there is one, else link its `src` (static); `src` is repo-relative. Warns and fails when there is neither                                                                          |
| `molt_config_stale src dst [inputs...]`     | True when `dst` no longer matches the user repo's `src.tmpl`, this sleeve's `vars.sh` and any extra inputs, or when that cannot be told; `src` is repo-relative, without `.tmpl`. Renderers **must** use this in `_check` |
| `molt_render_stale tmpl dst [inputs...]`    | `molt_config_stale` for a template named by its path, as one Molt ships under `$MOLT_ROOT/templates/` is                                                                                                                  |
| `molt_find_user_repo`                       | Print the path of the user's config repo. Fails, saying why, when there is none                                                                                                                                           |
| `molt_liberator_field name key`             | This sleeve's value of `key` on the `[[liberator]]` entry `name` in molt.toml. Fails when there is none                                                                                                                   |
| `molt_instance_file path`                   | This sleeve's path to `path` under `instances/<host>/` in the user repo, whether or not it exists. Fails, printing why, when there is no repo or no host name                                                             |
| `molt_instance_var name`                    | This sleeve's value of `name` as its `vars.sh` exports it, or nothing. Fails, printing why, when `vars.sh` cannot be read or found                                                                                        |
| `molt_brew_faults formula cmd [tap_url]`    | One line per fault between the sleeve and "Homebrew's `cmd` is what PATH runs", an untrusted formula included. Fails when nothing past the fault can be checked                                                           |
| `molt_brew_install formula [tap_url]`       | `brew install` by full formula name, tapping a private tap from `tap_url` first, and `brew trust --formula` for an installed formula Homebrew does not trust                                                              |
| `molt_path_runs_fault cmd path label`       | Names what PATH runs for `cmd` when it is not `path`                                                                                                                                                                      |
| `molt_report_faults log lead label faults`  | Logs each line of `faults` through `log`; true when there are none                                                                                                                                                        |
| `molt_gsettings args`                       | Runs the gsettings that reaches dconf, the store GNOME reads. Never call bare `gsettings`: one with no dconf module writes a keyfile GNOME never reads                                                                    |
| `molt_gsettings_unreachable log lead label` | Logs through `log`, after `lead` and `label`, and is false, when gsettings is on PATH but none reaches dconf. True when one does, or when there is none (no GNOME)                                                        |
| `molt_sudo_install src dst`                 | Puts a copy of `src` at the root-owned path `dst`, mode 644, through sudo. Fails, printing why                                                                                                                            |
| `molt_sudo_remove path...`                  | Removes root-owned files through sudo. Fails, printing why                                                                                                                                                                |
| `molt_git_pull repo label`                  | `git pull --ff-only` in `repo`, named `label` in messages. Status 2, with a warning, when it has no upstream branch, and 1, with git's words, when the pull fails                                                         |
| `molt_claude_config_dir`                    | Where Claude Code keeps its state: `$CLAUDE_CONFIG_DIR`, else `~/.claude`. Ask it at each use: the `claude` liberator exports the variable partway through a run                                                          |
| `molt_xdg_config_home`                      | `$XDG_CONFIG_HOME` when it is set and absolute, else `~/.config`: where a tool that honours it has its config linked, as `cldr` and `karabiner` do                                                                        |
| `molt_tilde path`                           | `path` for a message, written from `~` when it is under `$HOME`                                                                                                                                                           |
| `molt_platform`                             | Print `linux`, `macos` or `unknown`                                                                                                                                                                                       |
| `molt_distro`                               | Print the Linux distro's `ID` from `/etc/os-release` (eg `ubuntu`, `fedora`), `unknown` without one, and `none` off Linux                                                                                                 |
| `molt_arch`                                 | Print the architecture: `arm64`, `amd64` for x86_64, else what `uname -m` says                                                                                                                                            |
| `molt_info msg`                             | Print `Zen: msg` on stdout                                                                                                                                                                                                |
| `molt_warn msg`                             | Print `Zen [warning]: msg` on stdout                                                                                                                                                                                      |
| `molt_error msg`                            | Print `Zen [error]: msg` on stderr, which resleeve drops from a `_check`                                                                                                                                                  |
| `molt_debug msg`                            | Print `Zen [debug]: msg` on stdout, only when `MOLT_DEBUG=1`                                                                                                                                                              |

A liberator that links an executable links it into `$MOLT_LOCAL_BIN` (default `~/.local/bin`), as `utilz` and `web` do, and finds a template Molt itself ships under `$MOLT_ROOT/templates/`, as `claude` and `npm` do.

## Adding to the manifest

After creating your liberator script in the dev tree, add it to the sleeve's manifest: `instances/<host>/molt.toml` in your config repo, or the repo's top-level `molt.toml` for a sleeve without one:

```toml
[[liberator]]
name = "myapp"
enabled = true
os = ["linux", "macos"]
```

With a manifest, only the entries it enables run: `enabled` defaults to `true`, and `os` to every platform. Liberators run in the order the manifest lists them, so put an entry after any whose work it needs. A liberator can take settings of its own from its entry with `molt_liberator_field`. `utilz` reads `source`, which is `"checkout"` (the default) or `"brew"`.

## Platform-specific behavior

Use `molt_platform` to branch:

```bash
myapp_install() {
  case "$(molt_platform)" in
    linux)
      # Linux-specific setup (molt_gsettings, dconf, etc.)
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
if [[ "$(molt_platform)" == "linux" ]]; then
  molt_gsettings_unreachable molt_error "" myapp || return 1
  local favorites
  favorites="$(molt_gsettings get org.gnome.shell favorite-apps 2>/dev/null || echo "")"
  if [[ -n "$favorites" ]] && [[ "$favorites" != *"myapp.desktop"* ]]; then
    local entry="'myapp.desktop'" new_favorites
    case "$favorites" in
      "@as []" | "[]") new_favorites="[$entry]" ;;
      *) new_favorites="${favorites/]/, $entry]}" ;;
    esac
    if ! molt_gsettings set org.gnome.shell favorite-apps "$new_favorites"; then
      molt_error "myapp: could not add MyApp to the GNOME dock favorites"
      return 1
    fi
  fi
fi
```

gsettings prints an empty list as `@as []`, which takes the first entry with no `, ` ahead of it. The entry is held in a variable because bash 3.2 keeps the backslashes of `\'` in a substitution's replacement. Never call bare `gsettings`. `molt_gsettings_unreachable` fails, naming why, when gsettings is on PATH but none reaches dconf, and passes when there is no gsettings at all, which is no GNOME; `molt_gsettings` runs the one that reaches dconf, and with no gsettings it fails, so `favorites` is empty and nothing is set. The `vscode` liberator is a worked example.

## Testing

Tests run in the dev tree, with `molt test <name>` or `bats test/liberators/<name>.bats`. `molt test` runs ShellCheck over `bin/molt`, `lib/` and `liberators/` first, where ShellCheck is installed, and runs no tests while it finds anything.

A test file loads `test/test_helper.bash`, and `load_liberator <name>` sources Molt's libraries and the liberator. The helper's `setup` gives each test a HOME of its own under `$BATS_TEST_TMPDIR` (issue 0065). A file that defines its own `setup` replaces that one, so it calls `molt_test_setup` first, or exports HOME into `$BATS_TEST_TMPDIR` itself, or its tests run against your real home: `test/liberators/zsh.bats` replaces `setup`, and sets HOME in its `_zsh_env` fixture, which each test that runs `zsh_install` calls first.

The helper keeps a test off the machine's own state in other ways too. Stubs of `launchctl`, `sudo` and `apparmor_parser` come first on PATH; `load_liberator` leaves a test with no gsettings, and one that puts its own fake `gsettings` on PATH calls `gsettings_from_path`; and `install_fake_sudo` and `fake_brew_formula` stand in for sudo and a Homebrew formula. A test works out what it expects without the code under test: `test_hostname`, not `molt_hostname`, names the instance directory. CI runs the suite under bash 3.2, on macOS, only for a release candidate or tag, or on demand, so on a Mac run it with `/bin` first on PATH as well, which runs `bats` under `/bin/bash`; `bin/devbin test all` runs it both ways.
