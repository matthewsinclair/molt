# Module Registry

> **The Highlander Rule**: There can be only one module per concern.
> ALWAYS check this file before creating a new script or helper function.
> If a module already owns that concern, use it.
> When you must create a new module, register it here FIRST, then create the file.

## Framework

| Module                | File               | Concern                                                            |
| --------------------- | ------------------ | ------------------------------------------------------------------ |
| molt (CLI)            | `bin/molt`         | Main entry point, arg parsing, command dispatch                    |
| molt (core)           | `lib/molt.sh`      | Logging, platform detection, symlink management, dependency checks |
| liberator (framework) | `lib/liberator.sh` | Liberator loading, execution, verification, discovery              |

## Liberators

| Module | File                | Concern                                             |
| ------ | ------------------- | --------------------------------------------------- |
| zsh    | `liberators/zsh.sh` | Shell installation, Starship prompt, config linking |

## Templates

| Module    | File                          | Concern                |
| --------- | ----------------------------- | ---------------------- |
| molt.toml | `templates/molt.toml.example` | Stack manifest example |

## Documentation

| Module            | File                        | Concern                                                |
| ----------------- | --------------------------- | ------------------------------------------------------ |
| bootstrap-runbook | `docs/bootstrap-runbook.md` | Phase 1 manual resleeve steps, liberator specification |
