---
node: vc
name: Validation Claude
role: validation
session_id: eee6bf33-7b42-4c64-b7be-60b1b4dd9d83
heartbeat_at: 2026-09-08T12:09Z
status: active
focus: "folded and holding for instructions; one live finding: backup_verify passes on nothing and its liberator has no tests"
claims: []
---

# Validation Claude (vc)

Sessions of 2026-08-27 and 2026-09-08 archived to `.history/`. Both are settled and executed; nothing live was folded into them.

## DOING

- (nothing in flight)

## TODO

- **`test/liberators/backup.bats`.** The only live finding from the 04-07 Sep sweep, and it is one job not two. `liberators/backup.sh` has ZERO tests over 477 lines and 17 functions, and `backup_verify` returns PASS having asserted nothing -- away from `MOLT_BACKUP_HOST` (`backup.sh:386`) or with the share unmounted (`backup.sh:431`). The verify hole is what an untested 477-line liberator grows, so the tests fix both. First control to write: **verify must FAIL when it has not checked anything** -- the arm that caught `intent_verify`. Escalated to hv in `hv/inbox.vc.md`; not started, and not covered by any thread since hv fiat-closed the rest.

## Watch-outs

- **`molt doctor` check 6 reports `15/16`, missing `backup`.** That is live and correct, not a defect in the check -- the check was fixed on 8 Sep to say so. hv has ruled the backup itself not a concern; the SuperDuper tile carries no `recentRuns` because the job was recreated, which loses run history without losing the backup. `backup_check`'s message conflates the two and states as fact something the tile cannot tell it.
- **A `grep -qv` converted to a herestring changes its answer on an EMPTY capture.** The substitution yields the empty string, the herestring appends a newline, and `-v` matches that line -- so the predicate answers TRUE where the pipeline answered FALSE. Demonstrated: `grep -qv x <<<"$(printf '')"` returns 0. `lib/molt.sh:707` (`tr | grep -oE | grep -qvE`) is exactly that shape and is DELIBERATELY UNTOUCHED. Test emptiness explicitly before converting it. A herestring on the FIRST stage of a multi-stage pipeline fixes nothing.
- **Sourcing `lib/molt.sh` turns on `set -euo pipefail` for the caller** (line 5). bats has pipefail OFF, so the suite only sees SIGPIPE defects because `load_molt_libs` sources the real lib. A harness that stubbed it would have the hazard and no way to see it.
- **An autoload file contains the BODY ONLY.** Wrapping it as `name() { ... }` makes the first call merely define the function and do nothing else -- it silently no-ops once, then works. `jump`, `git_current_branch` and now `e` are the convention in `Molt-matts/config/zsh/functions/`. devbin's `README.md:60` shows the WRAPPED form, so anyone copying from there walks into it.
- `fpath` and `autoload` are read at shell startup. A change under `config/zsh/functions/` needs a fresh shell; `source ~/.zshrc` is not enough, and testing in the current shell shows the old behaviour.
- A negative control with ONE candidate cannot see a preference-order or list-formatting bug. Depth-1 failure cases prove the exit code and nothing about the output.
- `molt doctor` check 12 (`core.ignorecase=true`) is a **standing condition on macOS, not a defect**. The check says so itself. Do not set it false to clear the warning.
- **Re-measure at pickup; do not quote a restart file.** The 8 Sep handover said 112 tests / 22 liberators against a real 128 / 23, and named a session state twelve days stale.

## Holds

- (none)

## Decisions

- (2026-09-08) **Verify a peer's findings before acting on them, and verify a carried decision before ruling on it.** intent-vc's six claims about the `intent` liberator all held when checked against source. hv's six carried decisions did not: three were already resolved and the list did not know it. A carried-decision list is not self-cleaning.
- (2026-09-08) **Check the artefact before believing a status field.** Both "Not Started" packages on a six-month-old ST0001 turned out to be mostly delivered -- WP-07 half built, WP-04's runbook written in June and three months stale. The status records what someone last typed.
- (2026-09-08) **A half-met work package closed whole is a lie that compounds**, because the next reader cannot see which half they inherited. WP-07 was split: the delivered half took evidence-backed ACs, the unbuilt half became ST0003.
- (2026-09-08) **`intent fc` was invoked by hv, at hv's keyboard, both times.** `IN-AG-FIAT-001`. vc moved ST0003 and Molt-matts ST0001 out of Triage into WIP so the transition was legal, which is not the verb and not a route around it.
