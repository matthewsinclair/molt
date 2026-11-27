# Molt Usage Rules

This file is the prescriptive DO / NEVER contract for working in Molt. Narrative and rationale live in `AGENTS.md` and the project's docs. Each file has one job.

`intent --version` names the Intent this project runs. `intent claude skills list` and `intent claude subagents list` show the Intent-provided surface.

## Project conventions

Molt's own must and never rules are in `intent/llm/RULES.md`, and are not repeated here.

## Intent-provided tooling

### Skills

- `/in-session`: session bootstrap. Run it at session start and after `/compact` or a context reset. It loads the skills for the languages the project declares. Molt declares only shell, which has no essentials skill: its rules come from `intent claude rules list --lang shell`.
- `/in-essentials`: the universal Intent workflow rules.
- `/in-review`, `/in-verify`, `/in-finish`: review, verification and wrap-up flows.
- `/in-whiteboard`: coordination between the project's Claude sessions.

Full list: `intent claude skills list`.

### Subagents (invoke via `Task()`)

- `critic-<lang>`: the rule-library critics. Molt's is `critic-shell`, and `critic-prose` reviews prose.
- `socrates`: CTO review mode, for architectural and strategic dialog.

Full list: `intent claude subagents list`.

### Rule library

The installed Intent tool serves the coding rules: the Rule Library section of `AGENTS.md` lists the commands that read them.

## Session Hooks

`.claude/settings.json` wires:

- `SessionStart`: prints the project's context when a session starts, resumes, clears or compacts.
- `UserPromptSubmit` (strict): blocks the first prompt until `/in-session` runs in the conversation.
- `Stop`: reminds to run `/in-finish` at wrap-up.
- `PostToolUse`: after a Write or Edit, an advisory when the file is not registered in `intent/llm/MODULES.md`.

## Critics and pre-commit

The pre-commit gate is `.githooks/pre-commit`, which git runs through `core.hooksPath`. It chains to Intent's gate, `pre-commit.intent`, which `intent claude upgrade --apply` writes: the shipped guards, `intent critic shell` on the staged files, and `intent doctor`. `.intent_critic.yml` sets the severity threshold and any disabled rules. Molt keeps the defaults: `severity_min: warning`, no disabled rules, and the per-edit critic advisory off.

## NEVER DO

- Never edit `AGENTS.md` directly: `intent agents sync` generates it.
- Never edit `.claude/settings.json`'s hook stanzas by hand: re-apply them with `intent claude upgrade --apply`.
- Never bypass `.githooks/pre-commit` with `--no-verify` on shared branches without an explicit justification in the commit message.
- Never create steel thread or work package directories by hand: use `intent st new` and `intent wp new`.
- Never hand-edit a thread's `info.md`, the thread index or `intent/todo.md`: they are views of Intent's store. Change state with Intent's verbs, eg `intent st done` and `intent wp start`.

## See also

- `AGENTS.md`: project navigation, generated, with Intent's own docs under Additional Resources.
- `CLAUDE.md`: the Claude-specific overlay.
