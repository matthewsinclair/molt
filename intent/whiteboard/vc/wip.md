---
node: vc
name: Validation Claude
role: validation
session_id: eee6bf33-7b42-4c64-b7be-60b1b4dd9d83
heartbeat_at: 2026-09-08T10:53Z
status: active
focus: "ST0001 CLOSED after six months, 15/15 WPs and 7/7 ACs; sweep found the backup liberator has zero tests and a verify that passes on nothing"
claims: []
---

# Validation Claude (vc)

Session of 2026-08-27 archived to `.history/20260827/wip.md`.

## DOING

- (nothing in flight)

## TODO

- **`test/liberators/backup.bats` is the next piece of work, and it is one job not two.** The liberator has zero tests over 477 lines and 17 functions, and `backup_verify` returns PASS having asserted nothing when away from home (`backup.sh:386`) or when the share is unmounted (`backup.sh:431`). The first control to write is "verify must FAIL when it has not checked anything" -- the same arm that caught `intent_verify`. Escalated to hv; not started.
- ST0003 (reproducible VM build) is at Triage with a 3-row contract, none satisfied. It carries the half of the old WP-07 that was never built: no build spec, no one-command build, no release artifact.
- Molt-matts ST0001 is at Triage as "Backup that runs without being asked". Naming still flagged for hv.

## Watch-outs

- **The whiteboard went dark for the whole 04-07 Sep body of work.** 38 commits landed -- kovacs decoupling, the backup-liberator rewrite, devbin vendoring -- and the last commit touching `intent/whiteboard/` is `62fd958` on 27 Aug. `intent/wip.md` was maintained (v0.17, 04 Sep) so the project snapshot is current; the LIVE channel is what was not used. A board that is 12 days stale while the tree moves is indistinguishable at pickup from a project where nothing happened.
- **The numbers in `intent/restart.md`'s handover were stale by a release cycle.** Handed 112 tests / 22 liberators; measured today 128 tests / 23 liberators. Re-measure at pickup rather than quoting a restart file.
- **`intent_verify` passes on exactly the state `intent_check` warns about.** `liberators/intent.sh:82` asks `molt_link_healthy` only, never `molt_link_points_to` -- so the mismatched link that check reports honestly, verify calls fully operational. Two functions, two answers, one estate.
- **Do NOT repair `~/bin/intent` to match the liberator.** `intent_install:69` links `$repo/bin/intent`, Intent's **v2 bash dispatcher**; both `~/bin/intent` and `~/.local/bin/intent` correctly point at the v3 Rust binary. Making the link match the liberator installs a working-looking v2 tool onto v3 trees. Fix the liberator, not the link.
- **`_intent_find_repo:6` finds the repo by probing for `bin/intent`**, so if Intent's pending "flip then burn" deletes the v2 script, Molt reports _"Intent repo not found -- Clone it"_ for a repo sitting right there. Find the repo by the repo (`.git`, `intent/.config/config.json`), not by one of its binaries.
- **`molt doctor` check 6 prints a green tick for any ratio.** `lib/molt.sh:819` emits `✓ N/M installed` unconditionally and raises no warning, so `0/16` renders as a pass, and the missing liberator is never named. Same class as the dangling-symlink and mtime defects closed on 04 Sep.
- **A `grep -qv` converted to a herestring changes its answer on an EMPTY capture.** The substitution yields the empty string, the herestring appends a newline, and `-v` matches that line -- so the predicate answers TRUE where the pipeline answered FALSE. Demonstrated: `grep -qv x <<<"$(printf '')"` returns 0. `lib/molt.sh:707` (`tr | grep -oE | grep -qvE`) is exactly that shape and is DELIBERATELY UNTOUCHED. Test emptiness explicitly before converting it.
- **An autoload file contains the BODY ONLY.** Wrapping it as `dvb() { ... }` makes the first call merely define the function and do nothing else -- it silently no-ops once, then works. `jump` and `git_current_branch` are the convention in `molt-matts/config/zsh/functions/`. devbin's `README.md:60` shows the WRAPPED form, so anyone copying from there walks into it.
- `fpath` and `autoload` are read at shell startup. A change under `config/zsh/functions/` needs a fresh shell; `source ~/.zshrc` is not enough, and testing in the current shell shows the old behaviour.
- A negative control with ONE candidate cannot see a list-formatting bug. Depth-1 failure cases prove the exit code and nothing about the output.
- `molt doctor` check 12 (`core.ignorecase=true`) is a **standing condition on macOS, not a defect**. The check says so itself. Do not set it false to clear the warning.

## Decisions

- (2026-09-08) Verified all six claims in intent-vc's cross-session brief against `liberators/intent.sh` and live link state before acting on any of them. All six hold. Changed nothing in the liberator: it is hv's call, and the ordering depends on an unexecuted decision on Intent's board.
- (2026-09-08) Three of hv's six "carried decisions" were already resolved and nobody had noticed: the `gyges-ssh-lan-hosts` branch is merged (`048d06f`), gyges reaches rhadamanth by key (`26ff1ef`, 4 Sep, verified live gyges -> rhadamanth this morning), and kovacs is absent from gyges's ssh fragment for a documented non-key reason. **A carried decision list is not self-cleaning.** Re-verify each item against as-built before putting it to hv; three of six were archaeology.
- (2026-09-08) `acceptance: exempt` is NOT reachable from the CLI -- Intent's own `known-defects.md` records it as `intent#0227`: the state has a read path and no writer, and the close gate names it as the remedy anyway. Used the documented workaround: define one criterion and satisfy it. ST0001 therefore has a minimal-but-true contract (AC001, 1/1), not a complete one.
- (2026-09-08) Fixed the `e` alias in Molt-matts (`config/zsh/zshrc:135`), routed by hv via geodica. It could never work: an alias appends arguments at the END, the body ended in `&` which terminates the command, so `e file` ran emacsclient with no file and then shell-EXECUTED the path. Now `config/zsh/functions/e`, body-only, autoloaded. Verified against a stub emacsclient -- old form captured `[--alternate-editor=emacs]` with no file plus `permission denied: /etc/hosts`; new form captures both filenames. First call fires, so the dvb no-op defect is avoided.
- (2026-09-08) ST0001 closed. WP-07 was HALF met and closing it wholesale would have been false: `molt upgrade` exists, works identically on the VM sleeve and both Macs, and is idempotent across two dry-runs -- but there is no VM build spec, no one-command build, and the v0.1.1 release carries zero assets. Split rather than fudged: the self-upgrading half became AC002-004 on ST0001 with evidence, the VM-build half became ST0003 with its own unsatisfied contract. A half-met work package closed whole is a lie that compounds, because the next reader has no way to see which half.
- (2026-09-08) WP-04 was also largely already built -- `docs/guides/bootstrap-runbook.md` existed since 16 June and was three months stale, asserting alacritty was a symlink at JetBrainsMono 14pt when it is a rendered template at MesloLGS 11. **Both remaining WPs on a six-month-old thread turned out to be mostly delivered.** Check the artefact before believing a `Not Started` status; the status field records what someone last typed, not what exists.
