# Implementation - ST0001: Bootstrap

## Implementation

### Phase 1 (Complete)

All work done in Claude Code sessions on kovacs, with config committed to molt-matts.

1. **System setup**: apt packages, keyd from source, matts user
2. **Shell**: zsh + Starship, clean .zshrc with Highlander compliance
3. **Git**: user config, aliases, git-lfs
4. **tmux**: Ctrl-a prefix, vi mode, mouse, 256color
5. **Editors**: Doom Emacs (cloned, installed, config ported from macOS), LazyVim
6. **Terminal**: Alacritty installed and configured
7. **Config migration**: All dotfiles moved into molt-matts/config/, symlinked
8. **Desktop**: GNOME Super bindings stripped via gsettings
9. **Intent**: Initialized in both molt and molt-matts, skills installed

### Phase 2: Framework (Mature)

MOLT framework built out in the molt repo with working CLI, test suite, and two configured sleeves.

1. **CLI** (`bin/molt`): Thin coordinator dispatching to lib functions
2. **Core lib** (`lib/molt.sh`): Logging, platform detection, symlinks, template rendering, manifest parsing, CLI commands
3. **Constants** (`lib/constants.sh`): Single source of truth for all configurable paths. No hardcoded defaults for `MOLT_PRJ_DIR`.
4. **Liberator framework** (`lib/liberator.sh`): Load, check, install, verify lifecycle with batch operations and discovery
5. **15 liberators** (`liberators/*.sh`): system, local-bin, zsh, git, tmux, editors, alacritty, gnome-terminal, iterm2, terminal-app, keys, desktop, dev-tools, ssh, utilz
6. **Manifest** (`molt.toml`): Declarative enabled/disabled/OS-filtered liberator list with per-instance overrides
7. **Test suite** (`test/`): bats tests across 6 files -- CLI, constants, liberator framework, manifest parsing, templates, exemplar liberator
8. **Doctor** (`molt doctor`): 9-step diagnostic
9. **Dry-run** (`molt resleeve --dry-run`): Preview mode, reports what would be installed
10. **Bootstrap** (`bin/bootstrap.sh`): Fresh-machine one-liner, requires `MOLT_PRJ_DIR`

### Design principles (as-built)

- **Liberators never install packages.** They verify prerequisites and fail with hints.
- **`MOLT_PRJ_DIR` must be set.** No hardcoded default. Enforced at constants.sh level.
- **`hostname -s`** used everywhere for macOS compatibility (rhadamanth.lan vs rhadamanth).
- **One liberator failure doesn't abort resleeve.** Error is reported, remaining liberators continue.
- **Rendered files are backed up** if their content changed since last render.
- **SSH config.d fragments are idempotent** via sentinel comments.
- **Doom Emacs is hands-off.** Molt clones and links config; user runs doom install/sync manually.

### Key file locations on kovacs

| Config    | Source (molt-matts)               | Symlink target          |
| --------- | --------------------------------- | ----------------------- |
| zsh       | config/zsh/zshrc                  | ~/.zshrc                |
| zshenv    | config/zsh/zshenv                 | ~/.zshenv               |
| git       | config/git/gitconfig              | ~/.gitconfig            |
| tmux      | config/tmux/tmux.conf             | ~/.tmux.conf            |
| doom      | config/doom/                      | ~/.config/doom          |
| alacritty | config/alacritty/alacritty.toml   | ~/.config/alacritty/... |
| starship  | config/starship/starship.toml     | ~/.config/starship.toml |
| ssh       | config/ssh/config.tmpl (rendered) | ~/.ssh/config           |

## Challenges & Solutions

### Cmd key passthrough (RESOLVED)

- **Problem**: Parallels was intercepting Cmd+key combos and converting them to Ctrl+key before they reached the VM. `keyd monitor` showed `leftcontrol + c` when pressing Cmd+C, not `leftmeta + c`.
- **Solution**: Configured Parallels keyboard shortcuts (on rhadamanth) to map Cmd+C/V/X → Ctrl+Shift+C/V/X. Translation happens at hypervisor level. keyd is not involved — config reduced to minimal.
- **Principle preserved**: Cmd != Ctrl. Cmd+C = copy (Ctrl+Shift+C), Ctrl+C = SIGINT.

### Parallels mount paths

- /media/psf/Home/ is the LIVE mount (not /media/psf/matts/ which is stale)
- ~/Devel/prj is symlinked to /media/psf/Home/Devel/prj for convenience

### Doom Emacs Nerd Fonts

- Nerd fonts installed on kovacs (WP-03 done)
- Need to run M-x nerd-icons-install-fonts if icons missing

### macOS hostname

- macOS `hostname` returns FQDN (eg rhadamanth.lan)
- Fixed by using `hostname -s` everywhere for instance directory lookups
