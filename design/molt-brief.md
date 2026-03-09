# MOLT — My Opinionated Local Terminal

## What it is

MOLT is a multi-OS, multi-machine personal config and shell environment tool. It takes your zsh/bash config, dotfiles, and dev environment setup and makes them portable, reproducible, and bootstrappable from a single `curl | bash` command on a fresh machine.

Think of it as what [Omarchy](https://github.com/basecamp/omarchy) does for Linux desktop config, but for shell/dev environments across macOS and Linux.

## The name

"Molt" is the biological process of shedding an exoskeleton to grow a new one. The backronym is **My Opinionated Local Terminal**. Both readings work: you shed the default shell and replace it with yours.

## Metaphor system

The naming conventions draw from two science fiction universes: _Altered Carbon_ (Richard K. Morgan) and _Blake's 7_ (Terry Nation). Both deal with the separation of identity from physical substrate — consciousness moving between bodies, systems operating across hostile infrastructure.

### Altered Carbon layer — core concepts

The central metaphor: **your config is your cortical stack. Every new machine is a new sleeve.**

| Term           | Meaning                                                           | Origin                                                                                  |
| -------------- | ----------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| **stack**      | Your dotfiles/config bundle. The portable identity.               | Cortical stack — the device that stores human consciousness.                            |
| **sleeve**     | A target machine that receives your stack.                        | Sleeve — the biological (or synthetic) body a stack is inserted into.                   |
| **needlecast** | Push your stack to a remote machine.                              | Needlecasting — transmitting consciousness across distance.                             |
| **resleeve**   | Bootstrap a fresh machine from your stack. The primary operation. | Re-sleeving — waking up in a new body.                                                  |
| **backup**     | Snapshot your current stack state.                                | Meths (Methuselahs) maintain remote backups of their stacks as insurance against death. |

### Blake's 7 layer — system components

| Term           | Meaning                                                                                | Origin                                                             |
| -------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| **Zen**        | The bootstrap runner/agent on each machine. Executes commands, reports status.         | Zen — the Liberator's ship computer. Cooperative, terse, reliable. |
| **liberators** | Config modules or plugins. Each one frees you from a default.                          | The Liberator — the ship itself, stolen from the Federation.       |
| **orac.toml**  | The manifest/lockfile. The authoritative source of truth for what your stack contains. | ORAC — the all-knowing (and opinionated) portable computer.        |

## CLI vocabulary

The primary commands should follow from the metaphor:

- `molt resleeve` — bootstrap the current machine from your stack
- `molt needlecast` — push your stack to a remote machine
- `molt backup` — snapshot your current stack
- `molt stack` — inspect or manage stack contents
- `molt sleeve` — inspect or manage the current sleeve (machine state)

## Personality

MOLT has opinions and says so. The tone is dry, terse, and functional. Output during a resleeve should feel like waking up, not like installing software.

Example bootstrap output:

```
MOLT v0.1.0 — My Opinionated Local Terminal
Needlecasting stack to new sleeve...
Zen: Loading liberators [zsh, git, tmux, starship, emacs]
Zen: Sleeve ready. Welcome back.
```

"Welcome back" is the key line. You are not setting up a new machine. You are waking up in a new body with all your memories intact.
