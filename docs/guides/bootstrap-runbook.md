# Bootstrap Runbook: Phase 1 Manual Resleeve

This documents every step taken to bootstrap kovacs (Ubuntu 24.04 ARM64 at the time, Parallels on rhadamanth) from a bare VM to a fully opinionated dev environment, by hand, before the liberators existed. It is the record the liberators were built from, not a specification of what they do now.

Steps are grouped by **liberator** (config module). Each step is tagged:

- **[agnostic]**: platform-independent, works on any sleeve
- **[linux]**: Linux-specific (apt, systemd, Wayland, etc.)
- **[instance]**: machine-specific (kovacs only)

## What this covers, and what it does not

**It covers some of the framework's liberators, not all: the lists below name which.**

Stating the gap rather than implying completeness is deliberate: a runbook that silently covers half the system is indistinguishable from one that covers all of it, and the reader has no way to tell which they are holding. The same principle the framework's own checks are held to.

Documented here: `system`, `zsh`, `git`, `tmux`, `editors`, `alacritty`, `keys`, `desktop`, `dev-tools`, `mise`, `ssh`, `intent`, `claude`.

**NOT documented here**: these arrived after the Phase 1 resleeve and their steps have never been captured: `agents`, `arngz`, `backup`, `brew`, `cldr`, `env`, `gnome-terminal`, `gtools`, `hammerspoon`, `herdr`, `iterm2`, `karabiner`, `local-bin`, `menuz`, `npm`, `pplr`, `terminal-app`, `tiling`, `utilz`, `vscode`, `web`. Read the liberator source for those; each has a `_check` that states its own preconditions.

This is a record of what was done BY HAND on kovacs. It is not the install procedure: that is `molt resleeve`. The liberators automate the configuration recorded here, but mostly not the packages. Of those documented here, `system`, `zsh`, `git`, `tmux`, `alacritty`, `dev-tools` and `mise` check for theirs and name the install when one is missing, and `editors` does the same for Emacs and Neovim. `editors` clones Doom Emacs and LazyVim itself, `keys` builds keyd from source, and `intent` installs Intent from Homebrew. Where this record and a liberator disagree, the liberator is authoritative and this document is stale.

## Molt itself

A sleeve gets Molt from Homebrew, on macOS and on Linux alike, then resleeves from it. Resleeve needs `MOLT_PRJ_DIR` set and the sleeve's config repo cloned first, as [Getting Started](getting-started.md) sets out:

```bash
export MOLT_PRJ_DIR="$HOME/Devel/prj"
git clone https://github.com/you/molt-you "$(dirname "$MOLT_PRJ_DIR")/cfg/Molt-you"
brew install matthewsinclair/molt/molt
molt resleeve --dry-run
molt resleeve
```

`molt version` names the install, as `molt <version> (brew, <commit>)`, and `molt upgrade` moves it to the next release with `brew upgrade`.

### For the maintainer of a dev checkout

**This is for whoever works on Molt itself.** A sleeve installed from brew needs none of it.

kovacs was bootstrapped in Phase 1 from a dev checkout of Molt. `bin/bootstrap.sh`, which came after Phase 1, sets one up at `$MOLT_PRJ_DIR/Molt` and links `~/.local/bin/molt` to it. A dev checkout stays a supported install. Getting Started's [maintainer section](getting-started.md#for-the-maintainer-of-a-dev-checkout) covers the dev, opt and brew trees, `molt use` and `molt install`. kovacs itself has since moved to brew only (ST0008): on 4 Nov 2026 the only `molt` on its PATH was Homebrew's, 1.4.2, with no `~/bin/molt` or `~/.local/bin/molt` left. `~/bin` and `~/.local/bin` are different directories there.

---

## system

Base OS setup, user creation, core packages.

### Create user [instance]

```bash
sudo adduser {user}
sudo usermod -aG sudo {user}
```

- **Why**: Parallels creates a `parallels` user. We want a named user that matches identity across all sleeves.
- **Gotcha**: Copy SSH keys and Claude credentials from the previous user before switching over.

### Install base packages [linux]

```bash
sudo apt update && sudo apt install -y \
  build-essential cmake git git-lfs curl wget unzip \
  zsh htop jq tree bat ripgrep fd-find fzf \
  wl-clipboard emacs-nox
```

- **Why**: Baseline tools needed by everything else.
- **Gotcha**: `bat` is `batcat` on Ubuntu, and `fd-find`'s binary is `fdfind`. The zshrc aliases neither.

### Install mise [linux]

```bash
curl https://mise.run | sh
```

- **Why**: Manages language runtimes (Ruby, Node, Python, etc.) without polluting system packages. Replaces asdf.
- **Gotcha**: Activation line goes in zshrc: `eval "$(~/.local/bin/mise activate zsh)"`
- **Liberator**: `mise`, off on every sleeve since 3 Nov 2026 (issue 0082). It checks that mise is on PATH and installs nothing.

---

## zsh

Shell configuration and prompt.

### Set default shell [agnostic]

```bash
chsh -s $(which zsh)
```

- **Now**: the `zsh` liberator runs this `chsh` itself when zsh is not the login shell.

### Install Starship prompt [agnostic]

```bash
curl -sS https://starship.rs/install.sh | sh
```

- **Why**: Fast, cross-platform prompt with git integration, language versions.
- Config: `Molt-{user}/config/starship/starship.toml.tmpl`, rendered, or a static `starship.toml`, linked
- Installed at: `~/.config/starship.toml`

### Write zshrc [agnostic]

- Config: `Molt-{user}/config/zsh/zshrc`
- Symlink: `~/.zshrc`
- **Design**: Thin coordinator. Sets env vars, history options and aliases (one-liners only), and activates tools. At the time it also loaded the functions through `fpath` and built PATH; now `zshenv` autoloads the functions and `zprofile` builds PATH.
- Functions live in `config/zsh/functions/`, one per file.
- **Highlander**: All git shortcuts live here as shell aliases (not in gitconfig).

### Write zshenv and zprofile [agnostic]

- `~/.zshenv` → `config/zsh/zshenv`: minimal, intentionally near-empty at the time
- `~/.zprofile` → `config/zsh/zprofile`: at the time an empty placeholder to prevent system defaults
- **Now**: `zshenv` sources `~/.config/molt/env.sh`, which the `env` liberator writes, and `zprofile` builds the login PATH with `~/.local/bin` first, which the `env` liberator requires before it publishes that PATH for GUI apps.

---

## git

Version control configuration.

### Write gitconfig [agnostic]

- Config: `Molt-{user}/config/git/gitconfig`
- Symlink: `~/.gitconfig`
- Contents: identity, defaults and the git-lfs filter; read the file itself for the rest.
- **Highlander**: No `[alias]` section: all git shortcuts are shell aliases in zshrc.

### Install git-lfs [linux]

```bash
git lfs install
```

---

## tmux

Terminal multiplexer configuration.

### Write tmux.conf [agnostic]

- Config: `Molt-{user}/config/tmux/tmux.conf`
- Symlink: `~/.tmux.conf`
- Key settings: Ctrl-a prefix, vi copy mode, mouse on, `|`/`-` splits, h/j/k/l pane nav, status bar top, 50k scrollback, escape-time 10ms

---

## editors

Doom Emacs and LazyVim (Neovim).

### Install Doom Emacs [agnostic]

```bash
git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
~/.config/emacs/bin/doom install
```

- **Gotcha**: Requires emacs already installed (see the base packages under `system`).
- Doom binary: `~/.config/emacs/bin/doom`

### Port Doom config [agnostic]

- Config: `Molt-{user}/config/doom/`
- Symlink: `~/.config/doom`
- Structure:
  - `config.el`: thin coordinator, loads custom modules
  - `init.el`: Doom module declarations
  - `packages.el`: additional packages
  - `custom/*.el`: modular config files
- **Gotcha**: Font is platform-conditional (JetBrainsMono Nerd Font on Linux, Menlo on macOS).
- Run `doom sync` after config changes.

### Install LazyVim [agnostic]

```bash
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

- **Note**: Stock LazyVim, no customizations tracked in Molt-{user} yet.

---

## alacritty

Terminal emulator setup. **There is no `terminal` liberator any more.** ST0001's WP-09 split it per emulator, so this section is `alacritty` and its siblings are `gnome-terminal`, `iterm2` and `terminal-app`, none of which are documented here.

### Install Alacritty [linux]

```bash
sudo apt install -y alacritty
```

### Write Alacritty config [agnostic]

- Template: `Molt-{user}/config/alacritty/alacritty.toml.tmpl`
- Rendered to: `~/.config/alacritty/alacritty.toml`

**This is rendered, not symlinked.** The font comes from the instance's `vars.sh` (`MOLT_FONT_FAMILY`, `MOLT_FONT_SIZE`) so the declared value is the effective one. It was previously declared in both places and had already diverged. kovacs runs **MesloLGS Nerd Font at 11.0**, chosen in Molt-matts `25713b0` and declared in kovacs's `vars.sh` since `1adb536`.

Other settings: copy-on-select, Super+C/V/X clipboard bindings for Parallels, Shift-Enter kitty-protocol encoding.

`molt doctor`'s `Checking declared font...` asserts the declared font is one fontconfig can resolve; nothing installs fonts, so a fresh sleeve gets the config naming the font and none of the font.

---

## keys

Keyboard remapping (keyd).

### Build and install keyd [linux]

```bash
git clone https://github.com/rvaiya/keyd
cd keyd
make && sudo make install
sudo systemctl enable keyd && sudo systemctl start keyd
```

- **Why**: evdev-level key remapping, compositor-agnostic, survives Wayland.
- **Now**: the `keys` liberator does this itself when keyd is missing: it clones and builds keyd, installs it through `sudo`, and enables and starts the service.

### Write keyd config [instance]

- Config: `Molt-{user}/instances/kovacs/keyd/default.conf`
- Install target: `/etc/keyd/default.conf`. The liberator copies it there through sudo and runs `sudo keyd reload`.
- At the time it mapped leftmeta (Cmd) to a custom layer for CUA-style shortcuts (c/v/x).
- **Status** at the time: config ready, but Cmd key passthrough from Parallels was PARKED, as Parallels was not sending leftmeta to the VM.
- **Now**: since Molt-matts `a355f32` (10 Mar 2026) the Parallels profile passes Cmd as Super, Alacritty binds Super+C/V/X itself, and `default.conf` maps nothing. The `keys` liberator is disabled on kovacs.

---

## desktop

GNOME desktop settings.

### Strip GNOME Super bindings [linux]

```bash
# Disable Activities overlay on Super press
gsettings set org.gnome.mutter overlay-key ''
# Disable all Super-based shortcuts
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"
# ... (additional gsettings for switch-windows, panel-main-menu, etc.)
```

- **Why**: Super key belongs to keyd/Cmd mapping, not GNOME.
- **Now**: the liberator sets each key `instances/<host>/desktop/gsettings` declares, through the gsettings that reaches dconf, and reads each one back. It sets the dock's favourites from `instances/<host>/desktop/favorite-apps`.

### GTK config [linux]

- Config: `Molt-{user}/config/gtk/gtk.css`
- Minimal styling overrides.
- Linked into both `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css`.

---

## dev-tools

CLI tools. The liberator checks for jq, tree, rg, fzf and curl, and installs none.

### CLI tools [linux]

Already covered in the base packages under `system`: bat, ripgrep, fd-find, fzf, jq, tree, htop.

### mise runtimes [agnostic]

```bash
mise use --global node@lts
mise use --global python@3
# etc.
```

- Configured per-project or globally via `~/.config/mise/config.toml`
- **Liberator**: `mise`, off on every sleeve since 3 Nov 2026 (issue 0082).

---

## ssh

SSH configuration for remote access.

### Generate SSH key [instance]

```bash
ssh-keygen -t ed25519 -C "you@example.com"
```

- Keys are per-instance secrets, NOT kept in Molt-{user}.
- **Now**: when it finds no private key in `~/.ssh` (it looks for `id_*`, `personalid` and `personal_id`), the liberator generates `~/.ssh/id_ed25519` itself, with no passphrase, and says to add its public key to GitHub, naming `cat ~/.ssh/id_ed25519.pub`.

### Write SSH config [agnostic]

- Config: `Molt-{user}/config/ssh/config.tmpl`, with each `instances/{hostname}/ssh/config.d/*.conf` fragment after it
- Rendered, not linked: `~/.ssh/config`, a regular file, as ssh requires. A static `config/ssh/config` is refused; rename it `config.tmpl`, which renders it as it stands
- Defines host aliases (eg `github.com-{github}`) with identity file references.
- **Manual step**: Public key must be added to GitHub account.

---

## intent

Intent project management integration.

**The `intent` liberator has changed since this record.** It installs Intent from Homebrew (`brew install matthewsinclair/intent/intent`) and checks which Intent PATH runs and which install the pre-commit gate points at. There is no checkout and no link of Molt's own. The steps below are what was done by hand at the time.

### Initialize Intent in repos [agnostic]

```bash
cd ~/Devel/prj/Molt && intent init
cd ~/Devel/cfg/Molt-{user} && intent init
```

### Install Claude skills [agnostic]

```bash
intent claude skills install --all
```

- Installs the `/in-*` skills to `skills/` in Claude Code's config dir (`~/.claude` until the sleeve moves its state)

---

## claude

Claude Code configuration. What the liberator does now, the config-dir move above all, is in [Sleeve Agents](sleeve-agents.md).

### Claude keybindings and instructions [agnostic]

- `Molt-{user}/config/claude/keybindings.json`, `CLAUDE.md` and `AGENTS.md`, each linked into Claude Code's config dir (`~/.claude` until the sleeve moves its state)

### Claude's state out of $HOME [agnostic]

- A sleeve that declares `MOLT_CLAUDE_CONFIG_DIR` in its `vars.sh` has its state moved there once, with every Claude Code quit. The liberator repoints the paths into `~/.claude` that the moved `settings.json` names, installs a guard and a hook that refuse a session launched in `$HOME`, at the agents root or below an agent home, or one that did not get `CLAUDE_CONFIG_DIR`, and hands `CLAUDE_CONFIG_DIR` to the `env` liberator, which runs after it and publishes it.

### Claude status line [agnostic]

- Layout: `Molt-{user}/config/ccstatusline/settings.json`, linked to `~/.config/ccstatusline/settings.json`. kovacs linked it by hand on 15 Oct 2026, before the liberator managed it, and the liberator adopts that link as it stands.
- Command: `Molt-{user}/config/claude/statusline.json` is written into the `statusLine` key of `settings.json` in Claude Code's config dir (`~/.claude` until the sleeve moves its state). No other key is touched, and the file is never linked: it holds each sleeve's own permissions, hooks and plugins.

### Claude attribution [agnostic]

- `Molt-{user}/config/claude/attribution.json` is written into the `attribution` key of the same `settings.json`, the same way: it sets the trailer Claude Code adds to commits and pull requests, and `sessionUrl`. No other key is touched. `includeCoAuthoredBy` is not written: the `attribution` object supersedes it.

---

## Config Summary

| Source (Molt-{user}/config/)  | Target                                            | How      |
| ----------------------------- | ------------------------------------------------- | -------- |
| zsh/zshrc                     | ~/.zshrc                                          | linked   |
| zsh/zshenv                    | ~/.zshenv                                         | linked   |
| zsh/zprofile                  | ~/.zprofile                                       | linked   |
| git/gitconfig                 | ~/.gitconfig                                      | linked   |
| git/gitignore_global          | ~/.gitignore_global                               | linked   |
| git/gitconfig\_<name>         | ~/.gitconfig\_<name>                              | linked   |
| tmux/tmux.conf                | ~/.tmux.conf                                      | linked   |
| doom/                         | ~/.config/doom                                    | linked   |
| alacritty/alacritty.toml.tmpl | ~/.config/alacritty/alacritty.toml                | rendered |
| starship/starship.toml.tmpl   | ~/.config/starship.toml                           | rendered |
| gtk/gtk.css                   | ~/.config/gtk-3.0/gtk.css and gtk-4.0/            | linked   |
| ssh/config.tmpl               | ~/.ssh/config                                     | rendered |
| claude/keybindings.json       | <config dir>/keybindings.json                     | linked   |
| claude/CLAUDE.md              | <config dir>/CLAUDE.md                            | linked   |
| claude/AGENTS.md              | <config dir>/AGENTS.md                            | linked   |
| claude/statusline.json        | <config dir>/settings.json, its `statusLine` key  | written  |
| claude/attribution.json       | <config dir>/settings.json, its `attribution` key | written  |
| ccstatusline/settings.json    | ~/.config/ccstatusline/settings.json              | linked   |

Instance-specific config lives in `Molt-{user}/instances/{hostname}/`.

---

## Audit Notes (from WP-06)

Key findings from the Highlander/Thin Coordinator audit:

- **H1 (Fixed)**: Git aliases were in two places, unified to zshrc only
- **T1 (Fixed)**: zshrc functions extracted to `config/zsh/functions/`
- **T2 (Fixed)**: Doom config.el inline logic extracted to custom/\*.el modules
- **M1 (Fixed)**: keyd config captured in `instances/kovacs/keyd/`
- **H3 (Fixed, then regressed, then fixed again)**: the font was unified to JetBrainsMono Nerd Font here in March. It did not stay unified: Molt-matts `25713b0` switched kovacs's `alacritty.toml` to MesloLGS while `vars.sh` still said JetBrainsMono, and the two sat diverged until 2026-09-08. The durable fix was not to re-unify the values but to remove the second place they could disagree: the config is now rendered from `vars.sh`. Copies of one fact drift; the fix is one copy, not matching copies.
