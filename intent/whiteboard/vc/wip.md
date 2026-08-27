---
node: vc
name: Validation Claude
role: validation
session_id: a7914a82-c12a-4ded-b8ea-a8e5141a1786
heartbeat_at: 2026-08-27T21:52Z
status: paused
focus: "localfold done -- dvb landed and verified, hv node + roster stood up, snapshots re-cut off March"
claims: []
---

# Validation Claude (vc)

Session of 2026-08-27 archived to `.history/20260827/wip.md` -- settled work and settled decisions live there.

## DOING

- (nothing in flight)

## TODO

- ST0001/WP-04 (document Phase 1 bootstrap steps) and WP-07 (reproducible VM build) are the open work on the only open thread. WP-07 is partly met already -- `molt upgrade` exists with `--self`, `--dry-run` and targeted liberators -- so its acceptance rows want an hv ruling before anyone treats it as untouched.
- `molt-matts` is an Intent project with ZERO steel threads, and the `dvb` work landed there untracked. Whether to open its first thread is hv's call, not a fold action.

## Watch-outs

- **An autoload file contains the BODY ONLY.** Wrapping it as `dvb() { ... }` makes the first call merely define the function and do nothing else, so it silently no-ops once and works thereafter -- worse than failing outright. `jump` and `git_current_branch` are the convention in `molt-matts/config/zsh/functions/`. devbin's `README.md:60` shows the WRAPPED form, so anyone copying from there walks into it.
- `fpath` and `autoload` are read at shell startup. A change under `config/zsh/functions/` needs a fresh shell; `source ~/.zshrc` is not enough, and testing in the current shell shows the old behaviour.
- The `dvb` body exists in three places -- `devbin/README.md:60`, `devbin/usage-rules.md:66` (prose), and `molt-matts/config/zsh/functions/dvb` -- and has already diverged: the README still carries both defects fixed here. The durable fix is devbin shipping `devbin shell-init zsh`. devbin-vc holds that pen, not Molt.
- A negative control with ONE candidate cannot see a list-formatting bug. The `/tmp` test in devbin-cc's brief passed while `${^tried}` collapsed every path onto one line, because from `/tmp` there is only one path to collapse. Depth-1 failure cases prove the exit code and nothing about the output.
- `readlink -f ~/.zshrc` resolves to `Molt-matts` (capital M) while the symlink target is lowercase. Same inode, verified on three paths -- a case-insensitive filesystem, not a second checkout.

## Decisions

- (archived to `.history/20260827/wip.md`; all three are recorded permanently in `a4e6cb2` and `intent/whiteboard/README.md`)
