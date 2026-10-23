# TN0001: Molt and Conflab

**Date:** 2026-03-07
**Status:** Proposal, not built. Molt has no `conflab` liberator.
**Author:** {user}

## Summary

Molt would provide a `conflab` liberator. That would be the entire integration story.

Molt is about the human developer's portable exoskeleton — your shell, your tools, your config, waking up on a new machine. Conflab is the channel through which agents collaborate on your behalf. These are complementary concerns with a clean boundary: Molt carries your identity, Conflab connects it.

## The boundary

| Concern                            | Owner                |
| ---------------------------------- | -------------------- |
| Install the `conflab` CLI          | Molt (via liberator) |
| Install `conflabd` daemon          | Molt (via liberator) |
| Provision `~/.conflab/profiles/`   | Molt (via liberator) |
| Start the daemon on boot           | Molt (via liberator) |
| Agent registration, messaging, PAP | Conflab              |
| Flab management, task scoping      | Conflab              |
| MCP integration with Claude Code   | Conflab              |

Molt would ensure Conflab is installed, configured, and running — the same way it ensures git is configured or tmux is ready. It would not replicate Conflab's commands, manage flabs, or interact with the Conflab API. It would just make sure your Conflab identity is part of your sleeve.

Installing the CLI and daemon would make the liberator an exception to the rule that liberators never install packages, as Intent's and Utilz's Homebrew installs and the `keys` liberator's keyd build are. If Conflab ships from a Homebrew tap, the liberator would use `molt_brew_install` and `molt_brew_faults` as they do.

## The conflab liberator

The `conflab` liberator would handle:

1. **CLI installation** — install the `conflab` binary (platform-appropriate)
2. **Daemon installation** — install `conflabd` with launchd (macOS) or systemd (Linux)
3. **Profile provisioning** — copy Conflab profiles from your stack to `~/.conflab/profiles/`
4. **Daemon startup** — ensure `conflabd` is running after resleeve
5. **Agent credentials** — your agent auth tokens would travel with your stack, so `^ORAC` wakes up with you

### Example molt.toml entry

A liberator's own settings go on its `[[liberator]]` entry, where `molt_liberator_field` reads them. A sub-table such as `[liberator.conflab]` would end the entry, and its keys would belong to none.

```toml
[[liberator]]
name = "conflab"
os = ["macos", "linux"]
profile = "production"
server = "https://app.conflab.com"
auto_start_daemon = true
```

### Example resleeve output

```
Zen: Running liberator: conflab (install)
Zen: conflab cli installed
Zen: conflabd registered (launchd)
Zen: profile "production" provisioned
Zen: conflabd running — agents online
```

## What we would not do

- **Don't make Conflab a dependency.** Molt works standalone. The conflab liberator would be opt-in like any other.
- **Don't store stacks in Conflab.** Conflab is a messaging platform, not a config store. Git is the source of truth for stacks.
- **Don't wrap Conflab commands.** There would be no `molt conflab ...` command. If you need Conflab, you use `conflab`.
- **Don't manage flabs from Molt.** Flab membership, agent registration, and task scoping are Conflab's domain.

## Optional: Conflab-aware events

These are future possibilities, not requirements. Neither `molt needlecast` nor `molt backup` exists as a command today:

- **Needlecast notifications** — when a `molt needlecast` completes, it would post a receipt to a designated ops flab so the team sees new sleeves come online.
- **Backup receipts** — a `molt backup` would post a snapshot summary to a flab as an audit trail.
- **Zen as a participant** — Zen could optionally post resleeve progress to a flab during bootstrap.

All of these would require the conflab liberator to be active and would be strictly opt-in.

## Mental model

> Molt is about _my_ `@human` devx.
> Conflab is how `^AGENTS` collaborate.
> Molt would provide a conflab liberator — your Conflab identity would be just another part of you that wakes up on a new machine.
