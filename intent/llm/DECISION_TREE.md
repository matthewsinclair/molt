---
verblock: "3 Nov 2026:v0.1: Matthew Sinclair - vc: Molt's placement tree, not the starter text (issue 0083)"
---

# DECISION_TREE.md

Where new code goes in Molt. Ask [MODULES.md](MODULES.md) first: when a module already owns the concern, the code goes there, and a new module is registered there before its file exists. [ARCHITECTURE.md](ARCHITECTURE.md) says how the pieces fit.

1. **One person's config, or one machine's?** That person's stack, `Molt-<user>`, never the framework: `config/<tool>/` for what a liberator links or renders, and `instances/<hostname>/` for one sleeve, its `molt.toml`, `vars.sh` and overlays.
2. **Setting up one tool, or one part of a sleeve?** A liberator, `liberators/<name>.sh`, written to `docs/guides/writing-a-liberator.md`, with its tests in `test/liberators/<name>.bats`. A sleeve turns it on in its own `molt.toml`, after any liberator whose work it needs.
3. **A path or a default someone may change?** `lib/constants.sh`.
4. **A helper more than one liberator needs (linking, rendering, platform, logging, Homebrew)?** `lib/molt.sh`, beside the helpers of its kind. Loading and running liberators is `lib/liberator.sh`.
5. **A variable a sleeve's shells or GUI apps get?** A contributor the `env` liberator gathers, as `claude_env_pairs` and `molt_env_prefix_pairs` are. `lib/env.sh` writes it, and nothing else writes an env file.
6. **Which tree runs (dev, opt or brew), or publishing one?** `lib/install.sh`.
7. **Sleeve agents?** `lib/agent.sh`. Their roles come from the stack's `config/agents/roles/`.
8. **A new verb?** Its logic goes in the lib that owns the concern, and `bin/molt` parses its arguments and calls it.
9. **What a new user's stack starts from?** `templates/molt-user/`. The other files Molt renders from its own templates are under `templates/` too.
10. **Something a developer runs and a sleeve never does?** `tools/`, outside the runtime set, as `tools/test-bash32` is.
