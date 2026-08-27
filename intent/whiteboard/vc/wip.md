---
node: vc
name: Validation Claude
role: validation
session_id: a7914a82-c12a-4ded-b8ea-a8e5141a1786
heartbeat_at: 2026-08-27T21:15Z
status: active
focus: "dvb landed in molt-matts with two fixes and verified through the real config; hv node + roster stood up; wip/restart refreshed off March"
claims: []
---

# Validation Claude (vc)

## DOING

- (nothing in flight)

## TODO

- ST0001/WP-04 (document Phase 1 bootstrap steps) and WP-07 (reproducible VM build) are the open work on the only open thread. WP-07 is partially met already -- `molt upgrade` exists with `--self`, `--dry-run` and targeted liberators -- so its AC set wants an hv ruling on which rows to tick before anyone treats it as untouched.
- Commit the three landed changes when hv says so: two files in molt-matts, and `intent/{wip,restart}.md` + `intent/whiteboard/` here.

## Watch-outs

- **An autoload file contains the BODY ONLY.** Wrapping it as `dvb() { ... }` makes the first call merely define the function and do nothing else, so it silently no-ops once and works thereafter -- worse than failing outright. `jump` and `git_current_branch` are the convention in `molt-matts/config/zsh/functions/`. devbin's `README.md:60` shows the WRAPPED form, so anyone copying from there walks into it.
- `fpath` and `autoload` are read at shell startup. A change under `config/zsh/functions/` needs a fresh shell; `source ~/.zshrc` is not enough, and testing in the current shell will show the old behaviour.
- The `dvb` body now exists in three places: `devbin/README.md:60`, `devbin/usage-rules.md:66` (prose), and `molt-matts/config/zsh/functions/dvb`. Copies drift. The durable fix is devbin shipping `devbin shell-init zsh` so the body is versioned with the thing it launches -- devbin-vc holds that pen, not Molt.
- A negative control with ONE candidate cannot see a list-formatting bug. The `/tmp` test in devbin-cc's brief passed while `${^tried}` was collapsing every path onto one line, because from `/tmp` there is only one path to collapse. Depth-1 failure cases prove the exit code and nothing about the output.

## Decisions

- (2026-08-27) `dvb` lands in `molt-matts` (hv's shell config), not the Molt framework. Devbin's own `usage-rules.md:66` says to put it in shell config and never in a project, and the framework would otherwise hard-code one project's launcher into every sleeve for users who may not run devbin. The `intent.sh` liberator is not a counter-precedent: it installs a tool rather than defining a shortcut for one.
- (2026-08-27) A `bin/devbin` that exists but is not executable stops the walk at rc=126 rather than being skipped. Skipping it silently ran a PARENT project's launcher from inside a child project, which is a wrong-thing-succeeded failure and worse than a clean stop.
- (2026-08-27) `vc` is the node obliged to read `hv/inbox.*` and surface it to the human -- recorded in `intent/whiteboard/README.md`, which is the roster's job. Molt has no control node; `vc` both validates and, when hv says so, builds.
