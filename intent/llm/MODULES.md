# Module Registry

> **The Highlander Rule**: There can be only one module per concern.
> ALWAYS check this file before creating a new script or helper function.
> If a module already owns that concern, use it.
> When you must create a new module, register it here FIRST, then create the file.

## Framework

| Module                | File               | Concern                                                            |
| --------------------- | ------------------ | ------------------------------------------------------------------ |
| molt (CLI)            | `bin/molt`         | Main entry point, arg parsing, command dispatch                    |
| molt (constants)      | `lib/constants.sh` | All configurable paths and defaults (single source of truth)       |
| molt (core)           | `lib/molt.sh`      | Logging, platform detection, symlink management, dependency checks |
| liberator (framework) | `lib/liberator.sh` | Liberator loading, execution, verification, discovery              |

## Liberators

| Module         | File                           | Concern                                                 |
| -------------- | ------------------------------ | ------------------------------------------------------- |
| system         | `liberators/system.sh`         | Base system setup, package manager, sudo                |
| zsh            | `liberators/zsh.sh`            | Shell installation, Starship prompt, config linking     |
| git            | `liberators/git.sh`            | Git + git-lfs installation, gitconfig linking           |
| tmux           | `liberators/tmux.sh`           | Tmux installation, config linking                       |
| editors        | `liberators/editors.sh`        | Doom Emacs + LazyVim installation, config linking       |
| alacritty      | `liberators/alacritty.sh`      | Alacritty config linking (linux, macos)                 |
| gnome-terminal | `liberators/gnome-terminal.sh` | GNOME Terminal dconf profile management (linux)         |
| iterm2         | `liberators/iterm2.sh`         | iTerm2 dynamic profile linking (macos)                  |
| terminal-app   | `liberators/terminal-app.sh`   | Terminal.app profile import and default setting (macos) |
| keys           | `liberators/keys.sh`           | keyd build from source, config from instance (Linux)    |
| desktop        | `liberators/desktop.sh`        | GNOME settings, GTK config (Linux)                      |
| dev-tools      | `liberators/dev-tools.sh`      | CLI tools (bat, rg, fd, etc.) + mise                    |
| ssh            | `liberators/ssh.sh`            | SSH key generation, config linking                      |
| local-bin      | `liberators/local-bin.sh`      | ~/bin directory, molt CLI symlink                       |
| intent         | `liberators/intent.sh`         | Intent project management framework, ~/bin symlinks     |
| pplr           | `liberators/pplr.sh`           | Pplr people/contacts manager, ~/bin symlinks            |
| utilz          | `liberators/utilz.sh`          | Utilz framework, bats-core, ~/bin symlinks              |
| web            | `liberators/web.sh`            | Web scraper for LLMs, ~/bin symlink                     |

## Testing

| Module      | File                    | Concern                                |
| ----------- | ----------------------- | -------------------------------------- |
| test_helper | `test/test_helper.bash` | Shared BATS test infrastructure        |
| templates   | `test/templates.bats`   | Template rendering (molt_render) tests |

## Templates

| Module    | File                          | Concern                |
| --------- | ----------------------------- | ---------------------- |
| molt.toml | `templates/molt.toml.example` | Stack manifest example |

## Documentation

| Module            | File                        | Concern                                                |
| ----------------- | --------------------------- | ------------------------------------------------------ |
| bootstrap-runbook | `docs/bootstrap-runbook.md` | Phase 1 manual resleeve steps, liberator specification |
