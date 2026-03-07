# TN0001: Molt and Conflab

**Date:** 2026-03-07
**Status:** Draft
**Author:** matts

## Summary

Molt provides a `conflab` liberator. That's the entire integration story.

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

Molt ensures Conflab is installed, configured, and running — the same way it ensures git is configured or tmux is ready. It doesn't replicate Conflab's commands, manage flabs, or interact with the Conflab API. It just makes sure your Conflab identity is part of your sleeve.

## The conflab liberator

The `conflab` liberator handles:

1. **CLI installation** — install the `conflab` binary (platform-appropriate)
2. **Daemon installation** — install `conflabd` with launchd (macOS) or systemd (Linux)
3. **Profile provisioning** — copy Conflab profiles from your stack to `~/.conflab/profiles/`
4. **Daemon startup** — ensure `conflabd` is running after resleeve
5. **Agent credentials** — your agent auth tokens travel with your stack, so `^ORAC` wakes up with you

### Example orac.toml entry

```toml
[[liberator]]
name = "conflab"
os = ["macos", "linux"]

[liberator.conflab]
profile = "production"
server = "https://app.conflab.com"
auto_start_daemon = true
```

### Example resleeve output

```
Zen: Loading liberator [conflab]
Zen: conflab cli installed
Zen: conflabd registered (launchd)
Zen: profile "production" provisioned
Zen: conflabd running — agents online
```

## What we don't do

- **Don't make Conflab a dependency.** Molt works standalone. The conflab liberator is opt-in like any other.
- **Don't store stacks in Conflab.** Conflab is a messaging platform, not a config store. Git is the source of truth for stacks.
- **Don't wrap Conflab commands.** There is no `molt conflab ...` command. If you need Conflab, you use `conflab`.
- **Don't manage flabs from Molt.** Flab membership, agent registration, and task scoping are Conflab's domain.

## Optional: Conflab-aware events

These are future possibilities, not requirements:

- **Needlecast notifications** — when `molt needlecast` completes, post a receipt to a designated ops flab so the team sees new sleeves come online.
- **Backup receipts** — `molt backup` posts a snapshot summary to a flab as an audit trail.
- **Zen as a participant** — Zen could optionally post resleeve progress to a flab during bootstrap.

All of these require the conflab liberator to be active and are strictly opt-in.

## Mental model

> Molt is about _my_ `@human` devx.
> Conflab is how `^AGENTS` collaborate.
> Molt provides a conflab liberator — your Conflab identity is just another part of you that wakes up on a new machine.
