# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `molt_config_stale` and `molt_config_digest`: liberators that render configs can now detect when a rendered file no longer matches its inputs. molt renders only when a `_check` reports not-ok, so before this a template change never propagated -- the check passed, install was skipped, and the sleeve ran the previous rendered file while reporting success. Wired into `ssh`, `zsh` and `backup`, the three liberators that render
- `molt doctor` check (11th): the stack itself must be on local storage. Rejects `fuse*`, `nfs*`, `smb*`, `cifs`, `9p`, `virtiofs` and friends. Catches a sleeve running out of another machine's checkout over a guest or network mount, which check 10 cannot see because the coupling is structural rather than textual
- `claude` liberator: owns `~/.claude/keybindings.json`. It was version-controlled in the user repo but no liberator created it, so it existed only where it had been linked by hand and a fresh sleeve never got it
- `desktop` liberator manages GNOME dock favourites from `instances/<host>/desktop/favorite-apps` (one `.desktop` id per line, order = dock order). The dock silently outranks every default-terminal setting: a sleeve with alacritty set as default by both gsettings and `/etc/alternatives` still launched gnome-terminal, because both were pinned and the icon was what got clicked
- `desktop` liberator links `gtk-4.0/gtk.css` as well as `gtk-3.0`. GTK4 apps are now the common case, and molt could not repair a gtk-4.0 link because it never created one
- `molt_link_points_to`: true only when a link resolves _to the expected source_. `molt_link_healthy` asks whether a link resolves, not whether it resolves to what the liberator installs
- `molt doctor` check (12th): warns when `core.ignorecase=true` in the managed repos. Framed as a standing condition expected on macOS, with the remedy at rename time (`git mv -f`, then confirm it staged) -- explicitly _not_ "set it false", which would make git assert something untrue about the filesystem in order to silence a check. A case-only rename is then not committed, so a case-sensitive sleeve pulls the old spelling and every symlink to it dangles -- the mechanism that hid the repo rename
- `molt doctor` check 4 now asserts the manifest's `user_repo` still names the real directory. The key is never read by anything, so as prose it drifted silently; asserting it turns dead documentation into a live check
- `molt_link_healthy` and `molt_link_fault`: symlink checks that test whether a link _resolves_, plus a helper that names which of the four states a target is in for user-facing messages
- `molt_fstype`: filesystem type for a path, branching on platform rather than probing (BSD `stat` reads GNU's `-f -c %T` as a format string and prints `-c` instead of failing)
- `molt_render` honours the `@@MOLT:BEGIN@@` marker its own templates advertise: content above the marker in an existing file is preserved across re-renders. Previously the whole file was replaced, so "add your own entries ABOVE this line" was not true
- `molt upgrade` warns about unpushed commits and untracked files. Unpushed commits are the damaging case: `git pull --ff-only` cannot fast-forward past them, so it is skipped with a soft warning and every other sleeve upgrades to a tree without the fixes while reporting success
- `docs/guides/templates.md`: sections on detecting stale renders and on preserving hand-written entries
- `molt new-user` command: scaffolds a new `molt-{user}` config repo from a tokenised skeleton (`templates/molt-user/`), substituting name, email, GitHub handle, and first hostname. Implemented in `lib/newuser.sh` with `test/newuser.bats` (10 tests)
- `docs/guides/new-user.md` guide explaining the scaffold, the identity surface, and the scaffold-time vs resleeve-time placeholder split
- `git_install` config-linking tests in `test/git.bats` (arbitrary identity name, multiple includes, empty-glob guard)
- `molt doctor` check (10th) for config files that bake in another user's absolute home path, including JSON-escaped `\/Users\/<x>` exports (`molt_foreign_home_paths`)
- `molt doctor` external-dependency check now also verifies `envsubst` (gettext), required for template rendering
- `web` liberator test (`test/liberators/web.bats`)

### Changed

- `backup` liberator rewritten for SuperDuper 4.0.5, which creates and owns its own sparsebundle on the SMB share. It no longer creates, attaches or detaches the disk image -- anything competing for the image can permanently break the job's destination binding. `maintain` refuses to tear down the share while the image is open. `MOLT_BACKUP_VOLUME` removed; `MOLT_BACKUP_IMAGE` now names the sparsebundle. A missing image is a warning, not an error
- `backup-mount` mounts via NetAuth rather than `mount_smbfs`. `/Volumes` is `root:wheel drwxr-xr-x`, so the previous `mkdir -p` could never succeed as a normal user; it failed silently and the mount only worked when Finder had already created the mount point. Also logs the tool's real stderr, password scrubbed, and trims its log to 30 days
- `editors_maintain` runs `doom sync -u` unconditionally. `doom upgrade` short-circuits before the package sync when Doom itself is current, so packages orphaned by a failed run were never retried while maintain reported success
- `editors_check` warns when `emacs-plus` is linked against ImageMagick, which breaks Emacs at launch on every imagemagick soname bump

- `git` liberator now links any `config/git/gitconfig_*` identity include instead of a hardcoded filename
- `bootstrap.sh` no longer assumes a fixed GitHub owner for the config repo: `MOLT_REPO` and the new `MOLT_USER_GH` are overridable (default `whoami`)
- Removed hardcoded personal identity strings throughout framework docs and project artifacts; the framework now reads as generic `{user}`/`{github}`
- `molt new-user` skeleton defaults `MOLT_FONT_FAMILY` to `Hack Nerd Font Mono` (a Nerd Font, matching the iTerm2 profile) so the prompt glyphs render out of the box

### Fixed

- `molt new-user` scaffolded a lowercase `molt-{user}` directory and a lowercase `user_repo`, against the capitalised convention every other project directory follows. A repo scaffolded this way resolved only through `constants.sh`'s compatibility fallback. The GitHub repo name stays lowercase -- the two conventions differ deliberately
- `intent_check` reported ok about a symlink it does not govern. `~/bin/intent` resolved to a Rust release binary that `intent_install` never created, and PATH resolved a different copy again. It now says so instead of passing, without repairing a link something else placed
- `desktop_verify` never checked the GTK stylesheet its own `_install` links
- `molt test` reported a pass when it had run nothing. A ShellCheck failure aborts under `set -e` before bats starts, printing no test output at all -- and "no `not ok` lines" reads as success. It now says TESTS DID NOT RUN. It also refuses to pass when the collected files declare zero `@test` blocks, which is what a new `.bats` file with no `load` line produces
- ssh `config.d` fragments never propagated. `ssh_install`'s append loop is correctly idempotent, but it only runs when `ssh_check` fails, and the check inspected neither the fragments nor their sentinels -- and `molt_config_digest` hashed only template + `vars.sh`, so a fragment ADDED or EDITED changed the rendered result while nothing marked it stale. `molt_config_digest` and `molt_config_stale` now accept extra inputs, and `ssh` passes its fragments. Third appearance of this same bug: template, then `vars.sh`, now fragments
- `molt_config_record_digest`: re-stamps a rendered file's sidecar to cover extra inputs. Without it the check digests the fragments and the sidecar does not, so they never agree and the liberator reinstalls on every run
- Dangling symlinks reported healthy. Every link check tested `[[ -L "$target" ]]` -- "is there a symlink here" -- which a _dangling_ symlink satisfies. After the user repo was renamed on a case-sensitive filesystem, every dotfile link pointed at a path that no longer existed, every check reported ok, install never ran, and `molt resleeve` printed "Sleeve ready. Welcome back." over a sleeve with no `.zshrc`, no git identity and no Doom config. Invisible on macOS, where case folding keeps the old path resolving. Replaced at 24 sites with `molt_link_healthy`
- Link checks that covered fewer targets than the matching install. `zsh` linked `.zshrc`, `.zshenv` and `.zprofile` but checked only `.zshrc` (and verified only `.zshrc` even after the check was widened); `vscode` linked `settings.json` and `keybindings.json` but checked only the former. A break in an unchecked file passed both phases
- Link failure messages that stated something untrue. All of them read "is not a symlink" or "not linked", including for a dangling link -- where it IS a symlink, and that is the entire fault. Someone debugging runs `ls -l`, sees the arrow, concludes the tool is wrong and stops looking, which is the wrong place to stop. Messages now come from `molt_link_fault` and name the actual path and fault. `vscode` also named `settings.json` whichever of its two files was broken
- `molt_render` now fails cleanly when `envsubst` is missing instead of writing an un-substituted file while reporting success (eg a literal `${MOLT_SSH_KEY}` left in `~/.ssh/config`)
- `web` liberator now detects the repo by `go.mod`/`.git` and links the platform binary (`web-<os>-<arch>`) or a locally built `./web`, instead of requiring a binary literally named `web` that a fresh clone never has

## [0.1.1] - 2026-03-23

### Added

- Cross-instance aggregation: `molt_instances_field()` reads TOML fields from all instances
- iTerm2 SSH background colors now generated at resleeve time from `instance.toml` data
- `[terminal]` section in `instance.toml` for host identity metadata (e.g., `ssh_bg_color`)
- Stub instance support: minimal `instance.toml` for non-Molt hosts (shrike, yggdrasil)
- ShellCheck integrated into `molt test` (runs before bats, fails on any warning)
- 6 new bats tests for cross-instance aggregation (`test/instances.bats`)
- `molt upgrade --self` for clean framework/config pull without hooks or resleeve
- `molt maintain` command for system maintenance (brew upgrade, doom upgrade, etc.)
- `molt maintain --dry-run` to preview maintenance actions
- Targeted upgrade/maintain: `molt upgrade zsh,git`, `molt maintain brew`
- `--resleeve`/`--no-resleeve` flags for `molt upgrade`
- `molt git` command for running git across managed repos
- Liberator lifecycle hooks: `_upgrade()` and `_maintain()`
- New liberators: `brew`, `intent`, `pplr`, `web`
- Third sleeve: gyges (macOS)
- VERSION file as single source of truth for version number
- CHANGELOG.md
- CI/CD via GitHub Actions (tests on Linux + macOS, ShellCheck, PR checks)

### Changed

- ShellCheck is now blocking in CI (was non-blocking)
- Generated SSH colors output to `~/.config/molt/iterm2-ssh-colors.sh` (was hardcoded in zsh config)
- zshrc sources SSH colors from `~/.config/molt/` instead of relative to zshrc symlink
- `constants.sh` reads version from VERSION file instead of hardcoding

### Fixed

- All ShellCheck warnings across 25 scripts (SC2155, SC2046, SC2001, SC2164, SC2088, SC2129, SC2043)

### Removed

- Hardcoded hostname-to-color mapping from `config/zsh/iterm2-ssh-colors.sh` (replaced by generation)

## [0.1.0] - 2025-01-01

### Added

- Initial MOLT framework: two-repo model, liberator system, CLI
- Core commands: `resleeve`, `upgrade`, `status`, `list`, `doctor`, `test`, `version`
- 17 built-in liberators covering shell, git, editors, terminals, SSH, and more
- `molt.toml` manifest system with per-instance overrides
- Template rendering via `envsubst` with instance variables
- Bootstrap script for fresh machines
- Bats test suite with HOME-sandboxed test isolation
- Platform support: macOS (Apple Silicon + Intel), Linux (Debian/Ubuntu, Fedora/RHEL, Arch), WSL2
