# Bootstrap Runbook — Phase 1 Manual Resleeve

This documents every step taken to bootstrap kovacs (Ubuntu 24.04 ARM64, Parallels
on rhadamanth) from a bare VM to a fully opinionated dev environment. This runbook
serves as the specification for what MOLT liberators need to automate.

Steps are grouped by **liberator** (config module). Each step is tagged:

- **[agnostic]** — platform-independent, works on any sleeve
- **[linux]** — Linux-specific (apt, systemd, Wayland, etc.)
- **[instance]** — machine-specific (kovacs only)

---

## 1. system

Base OS setup, user creation, core packages.

### 1.1 Create user [instance]

```bash
sudo adduser matts
sudo usermod -aG sudo matts
```

- **Why**: Parallels creates a `parallels` user. We want a named user that matches
  identity across all sleeves.
- **Gotcha**: Copy SSH keys and Claude credentials from the previous user before
  switching over.

### 1.2 Install base packages [linux]

```bash
sudo apt update && sudo apt install -y \
  build-essential cmake git git-lfs curl wget unzip \
  zsh htop jq tree bat ripgrep fd-find fzf \
  wl-clipboard emacs-nox
```

- **Why**: Baseline tools needed by everything else.
- **Gotcha**: `bat` is `batcat` on Ubuntu (aliased in zshrc). `fd-find` binary is
  `fdfind` (also aliased).

### 1.3 Install mise [linux]

```bash
curl https://mise.run | sh
```

- **Why**: Manages language runtimes (Ruby, Node, Python, etc.) without polluting
  system packages. Replaces asdf.
- **Gotcha**: Activation line goes in zshrc: `eval "$(~/.local/bin/mise activate zsh)"`

---

## 2. zsh

Shell configuration and prompt.

### 2.1 Set default shell [agnostic]

```bash
chsh -s $(which zsh)
```

### 2.2 Install Starship prompt [agnostic]

```bash
curl -sS https://starship.rs/install.sh | sh
```

- **Why**: Fast, cross-platform prompt with git integration, language versions.
- Config: `molt-matts/config/starship/starship.toml`
- Symlink: `~/.config/starship.toml`

### 2.3 Write zshrc [agnostic]

- Config: `molt-matts/config/zsh/zshrc`
- Symlink: `~/.zshrc`
- **Design**: Thin coordinator. Sources functions via `fpath`, sets env vars, PATH,
  history options, aliases (one-liners only), activates tools.
- Functions extracted to `config/zsh/functions/`: `path_add`, `git_current_branch`,
  `jump`, `mark`, `unmark`, `marks`
- **Highlander**: All git shortcuts live here as shell aliases (not in gitconfig).

### 2.4 Write zshenv and zprofile [agnostic]

- `~/.zshenv` → `config/zsh/zshenv` — minimal, intentionally near-empty
- `~/.zprofile` → `config/zsh/zprofile` — empty placeholder to prevent system defaults

---

## 3. git

Version control configuration.

### 3.1 Write gitconfig [agnostic]

- Config: `molt-matts/config/git/gitconfig`
- Symlink: `~/.gitconfig`
- Contents: user.name, user.email, init.defaultBranch=main, pull.rebase=true, git-lfs filter
- **Highlander**: No `[alias]` section — all git shortcuts are shell aliases in zshrc.

### 3.2 Install git-lfs [linux]

```bash
git lfs install
```

---

## 4. tmux

Terminal multiplexer configuration.

### 4.1 Write tmux.conf [agnostic]

- Config: `molt-matts/config/tmux/tmux.conf`
- Symlink: `~/.tmux.conf`
- Key settings: Ctrl-a prefix, vi copy mode, mouse on, `|`/`-` splits,
  h/j/k/l pane nav, status bar top, 50k scrollback, escape-time 10ms

---

## 5. editors

Doom Emacs and LazyVim (Neovim).

### 5.1 Install Doom Emacs [agnostic]

```bash
git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
~/.config/emacs/bin/doom install
```

- **Gotcha**: Requires emacs already installed (step 1.2).
- Doom binary: `~/.config/emacs/bin/doom`

### 5.2 Port Doom config [agnostic]

- Config: `molt-matts/config/doom/`
- Symlink: `~/.config/doom`
- Structure:
  - `config.el` — thin coordinator, loads custom modules
  - `init.el` — Doom module declarations
  - `packages.el` — additional packages
  - `custom/*.el` — 16 modular config files (000-editor through 150-corfu)
- **Gotcha**: Font is platform-conditional (JetBrainsMono Nerd Font on Linux, Menlo on macOS).
- Run `doom sync` after config changes.

### 5.3 Install LazyVim [agnostic]

```bash
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

- **Note**: Stock LazyVim, no customizations tracked in molt-matts yet.

---

## 6. terminal

Terminal emulator setup.

### 6.1 Install Alacritty [linux]

```bash
sudo apt install -y alacritty
```

### 6.2 Write Alacritty config [agnostic]

- Config: `molt-matts/config/alacritty/alacritty.toml`
- Symlink: `~/.config/alacritty/alacritty.toml`
- Key settings: JetBrainsMono Nerd Font 14pt, copy-on-select, Shift-Enter binding

---

## 7. keys

Keyboard remapping (keyd).

### 7.1 Build and install keyd [linux]

```bash
git clone https://github.com/rvaiya/keyd
cd keyd
make && sudo make install
sudo systemctl enable keyd && sudo systemctl start keyd
```

- **Why**: evdev-level key remapping, compositor-agnostic, survives Wayland.

### 7.2 Write keyd config [instance]

- Config: `molt-matts/instances/kovacs/keyd/default.conf`
- Install target: `/etc/keyd/default.conf` (requires sudo, manual copy)
- Maps leftmeta (Cmd) to a custom layer for CUA-style shortcuts (c/v/x)
- **Status**: Config ready but Cmd key passthrough from Parallels is PARKED.
  Parallels is not sending leftmeta to the VM.

---

## 8. desktop

GNOME desktop settings.

### 8.1 Strip GNOME Super bindings [linux]

```bash
# Disable Activities overlay on Super press
gsettings set org.gnome.mutter overlay-key ''
# Disable all Super-based shortcuts
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"
# ... (additional gsettings for switch-windows, panel-main-menu, etc.)
```

- **Why**: Super key belongs to keyd/Cmd mapping, not GNOME.
- **Gotcha**: These are dconf settings, not file-based. Could capture as a script.

### 8.2 GTK config [linux]

- Config: `molt-matts/config/gtk/gtk.css`
- Minimal styling overrides.

---

## 9. dev-tools

Development tool configuration.

### 9.1 CLI tools [linux]

Already covered in system packages (step 1.2): bat, ripgrep, fd-find, fzf, jq, tree, htop.

### 9.2 mise runtimes [agnostic]

```bash
mise use --global node@lts
mise use --global python@3
# etc.
```

- Configured per-project or globally via `~/.config/mise/config.toml`

---

## 10. ssh

SSH configuration for remote access.

### 10.1 Generate SSH key [instance]

```bash
ssh-keygen -t ed25519 -C "hello@matthewsinclair.com"
```

- Keys are per-instance secrets, NOT managed by molt-matts.

### 10.2 Write SSH config [agnostic]

- Config: `molt-matts/config/ssh/config`
- Symlink: `~/.ssh/config`
- Defines host aliases (eg `github.com-matthewsinclair`) with identity file references.
- **Manual step**: Public key must be added to GitHub account.

---

## 11. intent

Intent project management integration.

### 11.1 Initialize Intent in repos [agnostic]

```bash
cd ~/Devel/prj/Molt && intent init
cd ~/Devel/prj/molt-matts && intent init
```

### 11.2 Install Claude skills [agnostic]

```bash
intent claude skills install --all
```

- Installs all 12 `/in-*` skills to `~/.claude/skills/`
- Intent added to PATH in zshrc when `~/Devel/prj/Intent` exists

---

## 12. claude

Claude Code configuration.

### 12.1 Claude keybindings [agnostic]

- Config: `molt-matts/config/claude/keybindings.json`

---

## Config Symlink Summary

| Source (molt-matts/config/) | Target                             |
| --------------------------- | ---------------------------------- |
| zsh/zshrc                   | ~/.zshrc                           |
| zsh/zshenv                  | ~/.zshenv                          |
| zsh/zprofile                | ~/.zprofile                        |
| git/gitconfig               | ~/.gitconfig                       |
| tmux/tmux.conf              | ~/.tmux.conf                       |
| doom/                       | ~/.config/doom                     |
| alacritty/alacritty.toml    | ~/.config/alacritty/alacritty.toml |
| starship/starship.toml      | ~/.config/starship.toml            |
| ssh/config                  | ~/.ssh/config                      |

Instance-specific config lives in `molt-matts/instances/{hostname}/`.

---

## Audit Notes (from WP-06)

Key findings from the Highlander/Thin Coordinator audit:

- **H1 (Fixed)**: Git aliases were in two places — unified to zshrc only
- **T1 (Fixed)**: zshrc functions extracted to `config/zsh/functions/`
- **T2 (Fixed)**: Doom config.el inline logic extracted to custom/\*.el modules
- **M1 (Fixed)**: keyd config captured in `instances/kovacs/keyd/`
- **H3 (Fixed)**: Font unified to JetBrainsMono Nerd Font in both Alacritty and Doom
