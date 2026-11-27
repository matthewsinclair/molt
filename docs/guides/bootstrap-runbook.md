# Bootstrap Runbook: Manual Steps

This runbook lists the steps that you do by hand on a new sleeve, before and after `molt resleeve`. It also says what each liberator does itself. Most steps are for Linux, as on kovacs, an Ubuntu ARM64 VM under Parallels on rhadamanth.

Steps are grouped by **liberator** (config module). Each step is tagged:

- **[agnostic]**: platform-independent, works on any sleeve
- **[linux]**: Linux-specific (apt, systemd, Wayland, etc.)
- **[instance]**: specific to one machine

## What this covers, and what it does not

Documented here: `system`, `zsh`, `git`, `tmux`, `editors`, `alacritty`, `keys`, `desktop`, `dev-tools`, `mise`, `ssh`, `intent`, `claude`.

**Not documented here**: `agents`, `arngz`, `backup`, `brew`, `cldr`, `env`, `gnome-terminal`, `gtools`, `hammerspoon`, `herdr`, `iterm2`, `karabiner`, `local-bin`, `menuz`, `npm`, `pplr`, `terminal-app`, `tiling`, `utilz`, `vscode`, `web`. Read the liberator source for those; each has a `_check` that states its own preconditions.

`molt resleeve` is the install procedure. Most liberators set up configuration only, and install no package. Of those documented here, `system`, `zsh`, `git`, `tmux`, `alacritty`, `dev-tools` and `mise` check for their packages and name the install when one is missing. `editors` does the same for Emacs and Neovim. `editors` clones Doom Emacs and LazyVim itself, `keys` builds keyd from source, `intent` installs Intent from Homebrew, and `claude` installs ccstatusline with npm. The `brew` liberator installs packages too, the ones a sleeve lists in its `Brewfile`, `instances/<host>/Brewfile`. Where this runbook and a liberator disagree, the liberator is correct.

## Molt itself

[Getting Started](getting-started.md) gives the steps that install Molt from Homebrew and resleeve a sleeve.

### For the maintainer of a dev checkout

**This is for whoever works on Molt itself.** A sleeve installed from brew needs none of it.

Getting Started's [maintainer section](getting-started.md#for-the-maintainer-of-a-dev-checkout) covers `bin/bootstrap.sh`, which sets up a dev checkout on a new machine, and the dev, opt and brew trees.

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
- **Liberator**: `system` checks for sudo and, on Linux, that the user is in the sudo or wheel group. It installs nothing.

### Install base packages [linux]

```bash
sudo apt update && sudo apt install -y \
  build-essential cmake git git-lfs curl wget unzip \
  zsh tmux htop jq tree bat ripgrep fd-find fzf \
  wl-clipboard emacs-nox neovim
```

- **Why**: Baseline tools needed by everything else.
- **Gotcha**: `bat` is `batcat` on Ubuntu, and `fd-find`'s binary is `fdfind`. The zshrc aliases neither.

---

## zsh

Shell configuration and prompt. The `zsh` liberator runs `chsh -s` itself when zsh is not the login shell.

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
- **Design**: Thin coordinator. Sets env vars, history options and aliases (one-liners only), and activates tools. `zshenv` autoloads the functions, and `zprofile` builds PATH.
- Functions live in `config/zsh/functions/`, one per file.
- **Highlander**: All git shortcuts live here as shell aliases (not in gitconfig).

### Write zshenv and zprofile [agnostic]

- `~/.zshenv` links to `config/zsh/zshenv`, which sources `~/.config/molt/env.sh`, the file the `env` liberator writes.
- `~/.zprofile` links to `config/zsh/zprofile`, which builds the login PATH with `~/.local/bin` first. The `env` liberator requires that before it publishes the PATH for GUI apps.

---

## git

Version control configuration.

### Write gitconfig [agnostic]

- Config: `Molt-{user}/config/git/gitconfig`
- Symlink: `~/.gitconfig`
- Contents: identity, defaults and the git-lfs filter; read the file itself for the rest.
- **Highlander**: No `[alias]` section: all git shortcuts are shell aliases in zshrc.

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

The `editors` liberator clones Doom Emacs into `~/.config/emacs` when it is missing. It does not run `doom install`, so run it yourself after the first resleeve:

```bash
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

The `editors` liberator clones the LazyVim starter into `~/.config/nvim` when that directory is missing, and removes its `.git`.

- **Note**: Molt links no Neovim config, so LazyVim stays stock.

---

## alacritty

Terminal emulator setup.

### Install Alacritty [linux]

```bash
sudo apt install -y alacritty
```

### Write Alacritty config [agnostic]

- Template: `Molt-{user}/config/alacritty/alacritty.toml.tmpl`
- Rendered to: `~/.config/alacritty/alacritty.toml`

Molt renders this file from the template. The font comes from the instance's `vars.sh` (`MOLT_FONT_FAMILY`, `MOLT_FONT_SIZE`), the one place that declares it.

Other settings: copy-on-select, Super+C/V/X clipboard bindings for Parallels, Shift-Enter kitty-protocol encoding.

`molt doctor`'s `Checking declared font...` checks that fontconfig can resolve the declared font. Nothing installs fonts, so install the declared font yourself.

---

## keys

Keyboard remapping (keyd).

### Build and install keyd [linux]

- **Why**: evdev-level key remapping, compositor-agnostic, survives Wayland.
- **Liberator**: `keys` does this itself when keyd is missing: it clones and builds keyd, installs it through `sudo`, and enables and starts the service.

### Write keyd config [instance]

- Config: `Molt-{user}/instances/{hostname}/keyd/default.conf`
- Install target: `/etc/keyd/default.conf`. The liberator copies it there through sudo and runs `sudo keyd reload`.
- On kovacs, Parallels passes Cmd as Super, and Alacritty binds Super+C/V/X itself. So kovacs's `default.conf` maps nothing, and its `keys` liberator is disabled.

---

## desktop

GNOME desktop settings.

### Strip GNOME Super bindings [linux]

- Declare the keys in `instances/<host>/desktop/gsettings`, one `<schema> <key> <value>` per line, eg `org.gnome.mutter overlay-key ''`.
- **Liberator**: `desktop` sets each key through the gsettings that reaches dconf, and reads each one back. It sets the dock's favourites from `instances/<host>/desktop/favorite-apps`.

### GTK config [linux]

- Config: `Molt-{user}/config/gtk/gtk.css`
- Minimal styling overrides.
- Linked into both `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css`.

---

## dev-tools

CLI tools. The liberator checks for jq, tree, rg, fzf and curl, and installs none.

The `mise` liberator is off on every sleeve. It checks that mise is on PATH, and installs nothing.

### CLI tools [linux]

Already covered in the base packages under `system`: bat, ripgrep, fd-find, fzf, jq, tree, htop.

---

## ssh

SSH configuration for remote access.

### Generate SSH key [instance]

```bash
ssh-keygen -t ed25519 -C "you@example.com"
```

- Keys are per-instance secrets, NOT kept in Molt-{user}.
- **Liberator**: `ssh` generates `~/.ssh/id_ed25519` itself, with no passphrase, when it finds no private key in `~/.ssh` (it looks for `id_*`, `personalid` and `personal_id`). It then says to add the public key to GitHub, and names `cat ~/.ssh/id_ed25519.pub`.

### Write SSH config [agnostic]

- Config: `Molt-{user}/config/ssh/config.tmpl`, with each `instances/{hostname}/ssh/config.d/*.conf` fragment after it
- Rendered, not linked: `~/.ssh/config`, a regular file, as ssh requires. A static `config/ssh/config` is refused; rename it `config.tmpl`, which renders it as it stands
- Defines host aliases (eg `github.com-{github}`) with identity file references.
- **Manual step**: Public key must be added to GitHub account.

---

## intent

Intent project management integration.

The `intent` liberator installs Intent from Homebrew (`brew install matthewsinclair/intent/intent`). It checks which Intent PATH runs and which install the pre-commit gate points at, and runs `intent bootstrap` when the gate has no install.

### Install Claude skills [agnostic]

```bash
intent claude skills install --all
```

- Installs the `/in-*` skills to `skills/` in Claude Code's config dir (`~/.claude` until the sleeve moves its state)

---

## claude

Claude Code configuration. [Sleeve Agents](sleeve-agents.md) describes how the liberator moves Claude Code's state out of `$HOME`.

### Claude keybindings and instructions [agnostic]

- `Molt-{user}/config/claude/keybindings.json`, `CLAUDE.md`, `AGENTS.md` and `house-rules.md`, each linked into Claude Code's config dir (`~/.claude` until the sleeve moves its state)

### Claude status line [agnostic]

- Layout: `Molt-{user}/config/ccstatusline/settings.json`, linked to `~/.config/ccstatusline/settings.json`.
- Command: `Molt-{user}/config/claude/statusline.json` is written into the `statusLine` key of `settings.json` in Claude Code's config dir (`~/.claude` until the sleeve moves its state). No other key is touched, and the file is never linked: it holds each sleeve's own permissions, hooks and plugins.
- Program: `Molt-{user}/config/ccstatusline/package.json`, npm's own manifest, pins ccstatusline to one exact version. The liberator copies it into `~/.local/share/molt/ccstatusline` (under `$XDG_DATA_HOME` when that is set), runs `npm install` there when the copy is missing or holds another version, and links `~/.local/bin/ccstatusline` to the program. A command that runs `ccstatusline` by name then runs the pinned version. With no npm on the sleeve, nothing is installed, and the status line stays empty.

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
| claude/house-rules.md         | <config dir>/house-rules.md                       | linked   |
| claude/statusline.json        | <config dir>/settings.json, its `statusLine` key  | written  |
| claude/attribution.json       | <config dir>/settings.json, its `attribution` key | written  |
| ccstatusline/settings.json    | ~/.config/ccstatusline/settings.json              | linked   |
| ccstatusline/package.json     | ~/.local/share/molt/ccstatusline/package.json     | copied   |

Instance-specific config lives in `Molt-{user}/instances/{hostname}/`.
