---
node: vc
name: Validation Claude
role: validation
session_id: d4708625-920e-4023-b3fd-4dacdc6294c4
heartbeat_at: 2026-09-15T13:10Z
status: active
focus: "config repos moved to ~/Devel/cfg on gyges and rhadamanth; kovacs next; fixing issue 0006 (git_check link coverage)"
claims: []
---

# Validation Claude (vc)

Sessions of 2026-08-27 and 2026-09-08 archived to `.history/`. The 2026-09-15 session is recorded in `intent/done.md` 018 and in issues 0001-0004.

## DOING

- **Move the config repos from `~/Devel/prj/` to `~/Devel/cfg/`** (Molt-matts, Molt-flynn, Gtools-geodica). Plan, blast radius and steps are in `intent/wip.md`. The Molt side is shipped (`549678e`, issue 0005 closed, CI green). gyges is done: it reported at 2026-09-15 12:58Z after hv ran the move there, and was told to stand down. rhadamanth is done too: it moved once hv had stopped the CMS and Gtools.app, and gtools-vc/cc/ic were told. Next: kovacs.
- **Issue 0006: `git_check`/`git_verify` cover only `~/.gitconfig`.** The move surfaced it, because `~/.gitignore_global` was a stale regular file on both Macs. The fix is one `_git_links` list read by check, install and verify, plus tests. Before closing: run under bash 3.2 and bash 5, and confirm CI.

## TODO

- **Get hv's ruling on `pipefail_sigpipe_check.sh`** (`hv/inbox.vc.md`, 2026-09-08 10:24Z). Explained to hv live on 15 Sep with a recommendation: skip the guard and convert Molt's 8 `cmd | grep -q` pipelines to capture-then-match, as an issue. The other inbox entries are actioned or overtaken: the backup findings closed as issues 0001-0003, the schedule note is resolved, and the ST0001 AC001 revert question was overtaken on 8 Sep when ST0001 closed with seven satisfied criteria.

## Watch-outs

- **Molt CI's macOS runner has only bash 3.2**, and this Mac's `env bash` is Homebrew bash 5.3. A green run under 5.3 is not a pass: run the suite with `/bin` first on PATH as well, and check the CI run before calling work done. `${VAR:-{...\}}` is where the two diverged (issue 0004).
- **`backup_verify` exit 2 is normal, not a failure.** It means nothing failed but the share-side checks (SMB dialect, attach budget) could not run, which is the usual state because SuperDuper mounts the share only while copying. 0 means every check ran and passed; 1 means a check failed.
- **SuperDuper `recentRuns` records finished runs only.** A copy in flight is invisible there, and cancelled or failed runs are often hv's own interruptions, eg for an OS install. Check for a running copy and ask before calling the backup failing.
- **iTerm2 3.7.1's Claude Code onboarding offers "Mark Rewritable & Install" for dynamic profiles.** Taking it adds `"Rewritable": true`. The Molt profile is symlinked into Molt-matts, so iTerm2 then writes into git. Restored without the flag in Molt-matts `b58e0d4`; hv ruled iTerm2 does not write into terminal config unannounced.
- **`fc -AI <file>` appends nothing to a file other than the current `HISTFILE`**, and `fc -A`/`fc -W` append everything, seeded history included. Per-session history (Molt-matts `389ef6f`) therefore points `HISTFILE` at an empty scratch file and copies it out at exit, as `/etc/zshrc_Apple_Terminal` does.
- **`pgrep -x iTerm2` matches nothing while iTerm2 is running.** Use `pgrep -fl 'iTerm.app'`. An empty probe that contradicts something obvious is a probe defect, not a finding.
- **A `grep -qv` converted to a herestring changes its answer on an EMPTY capture.** The substitution yields the empty string, the herestring appends a newline, and `-v` matches that line -- so the predicate answers TRUE where the pipeline answered FALSE. Demonstrated: `grep -qv x <<<"$(printf '')"` returns 0. `lib/molt.sh:707` (`tr | grep -oE | grep -qvE`) is exactly that shape and is DELIBERATELY UNTOUCHED. Test emptiness explicitly before converting it. A herestring on the FIRST stage of a multi-stage pipeline fixes nothing.
- **Sourcing `lib/molt.sh` turns on `set -euo pipefail` for the caller** (line 5). bats has pipefail OFF, so the suite only sees SIGPIPE defects because `load_molt_libs` sources the real lib. A harness that stubbed it would have the hazard and no way to see it. `backup.bats` runs its errexit arms in a fresh `bash` for the same reason.
- **An autoload file contains the BODY ONLY.** Wrapping it as `name() { ... }` makes the first call merely define the function and do nothing else -- it silently no-ops once, then works. `jump`, `git_current_branch` and `e` are the convention in `Molt-matts/config/zsh/functions/`. devbin's `README.md:60` shows the WRAPPED form, so anyone copying from there walks into it.
- `fpath` and `autoload` are read at shell startup. A change under `config/zsh/functions/` needs a fresh shell; `source ~/.zshrc` is not enough, and testing in the current shell shows the old behaviour.
- A negative control with ONE candidate cannot see a preference-order or list-formatting bug. Depth-1 failure cases prove the exit code and nothing about the output.
- `molt doctor` check 12 (`core.ignorecase=true`) is a **standing condition on macOS, not a defect**. The check says so itself. Do not set it false to clear the warning.
- **Re-measure at pickup; do not quote a restart file.** The suite was 185 tests at `549678e`; count it again rather than trusting that figure.
- **After a config repo moves, every new shell starts with no zsh config until `molt resleeve` runs**, because `~/.zshenv` dangles. That includes an agent's next Bash call, which then has no `MOLT_PRJ_DIR` and so no `MOLT_CFG_DIR`. Run the mv and the resleeve in one command, with `MOLT_PRJ_DIR` set explicitly and molt called by absolute path.
- **`git rev-list --left-right --count @{u}...HEAD` prints BEHIND then AHEAD.** `0 5` means 5 unpushed commits. vc misread it once on 15 Sep.

## Holds

- (none)

## Decisions

- (2026-09-08) **Verify a peer's findings before acting on them, and verify a carried decision before ruling on it.** intent-vc's six claims about the `intent` liberator all held when checked against source. hv's six carried decisions did not: three were already resolved and the list did not know it. A carried-decision list is not self-cleaning.
- (2026-09-08) **Check the artefact before believing a status field.** Both "Not Started" packages on a six-month-old ST0001 turned out to be mostly delivered -- WP-07 half built, WP-04's runbook written in June and three months stale. The status records what someone last typed.
- (2026-09-08) **A half-met work package closed whole is a lie that compounds**, because the next reader cannot see which half they inherited. WP-07 was split: the delivered half took evidence-backed ACs, the unbuilt half became ST0003.
- (2026-09-08) **`intent fc` was invoked by hv, at hv's keyboard, both times.** `IN-AG-FIAT-001`. vc moved ST0003 and Molt-matts ST0001 out of Triage into WIP so the transition was legal, which is not the verb and not a route around it.
- (2026-09-15) **A verdict must say what it checked.** A skipped check reported as a pass is the defect; `backup_verify` now has a distinct exit for "passed what it could reach".
- (2026-09-15) **iTerm2 does not write into terminal config without hv knowing.** hv's ruling. No dynamic profile in Molt-matts carries `"Rewritable": true`; profile changes are made in git.
- (2026-09-15) **A local green under a different interpreter from CI's is not a pass**, and neither is a carried question copied forward without checking the artefact. Both happened this session: CI red after "179 passing", and a stale AC001 question written into wip.
