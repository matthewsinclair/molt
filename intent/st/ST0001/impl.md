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

### Phase 2: Framework (In Progress)

MOLT framework built out in the molt repo with working CLI and test suite.

1. **CLI** (`bin/molt`): Thin coordinator dispatching to lib functions
2. **Core lib** (`lib/molt.sh`): Logging, platform detection, symlinks, manifest parsing, CLI commands (doctor, test, list, version)
3. **Constants** (`lib/constants.sh`): Single source of truth for all configurable paths
4. **Liberator framework** (`lib/liberator.sh`): Load, check, install, verify lifecycle with batch operations and discovery
5. **12 liberators** (`liberators/*.sh`): system, local-bin, zsh, git, tmux, editors, terminal, keys, desktop, dev-tools, ssh, utilz
6. **Manifest** (`molt.toml`): Declarative enabled/disabled/OS-filtered liberator list
7. **Test suite** (`test/`): 42 bats tests across 6 files — CLI, constants, liberator framework, manifest parsing, exemplar liberator
8. **Doctor** (`molt doctor`): 7-step diagnostic checking structure, repos, manifest, liberators, dependencies

### Key file locations on kovacs

| Config    | Source (molt-matts)           | Symlink target          |
| --------- | ----------------------------- | ----------------------- |
| zsh       | config/zsh/.zshrc             | ~/.zshrc                |
| git       | config/git/.gitconfig         | ~/.gitconfig            |
| tmux      | config/tmux/.tmux.conf        | ~/.tmux.conf            |
| doom      | config/doom/                  | ~/.config/doom          |
| alacritty | config/alacritty/             | ~/.config/alacritty     |
| starship  | config/starship/starship.toml | ~/.config/starship.toml |
| claude    | config/claude/                | ~/.claude/              |

## Challenges & Solutions

### Cmd key passthrough (UNRESOLVED)

- **Problem**: Parallels is not sending leftmeta (Cmd) to the VM
- **Symptom**: keyd config is correct but Cmd key never arrives
- **Investigated**: Parallels keyboard profiles, GNOME/Mutter compositor
- **Status**: Parked. Requires investigation into Parallels keyboard settings or possibly a macOS-level remapping before the key enters Parallels.
- **Principle**: Cmd ≠ Ctrl. They must remain distinct modifiers.

### Parallels mount paths

- /media/psf/Home/ is the LIVE mount (not /media/psf/matts/ which is stale)
- ~/Devel/prj is symlinked to /media/psf/Home/Devel/prj for convenience

### Doom Emacs Nerd Fonts

- Nerd fonts not yet installed on kovacs
- Need to run M-x nerd-icons-install-fonts or install via package manager
