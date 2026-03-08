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
