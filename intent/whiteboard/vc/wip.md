---
node: vc
name: Validation Claude
role: validation
session_id: eee6bf33-7b42-4c64-b7be-60b1b4dd9d83
heartbeat_at: 2026-09-08T10:15Z
status: active
focus: "hv's four rulings executed: doctor + intent liberator + fonts check landed, 148 tests green, nothing committed yet"
claims: []
---

# Validation Claude (vc)

Session of 2026-08-27 archived to `.history/20260827/wip.md`.

## DOING

- All four of hv's rulings executed and green. Nothing committed -- hv has not asked for a commit.

## TODO

- Commit today's work once hv says so: `lib/molt.sh`, `liberators/intent.sh`, `test/liberators/intent.bats`, `test/molt.bats`, the whiteboard files, and in Molt-matts the alacritty template rename plus three `vars.sh`.
- ST0001/WP-04 (document Phase 1 bootstrap steps) and WP-07 (reproducible VM build) remain the only open work on the thread. WP-04 should follow the intent-liberator change, not precede it -- it documents bootstrap, and the liberator is part of bootstrap.
- Molt-matts ST0001 is open at `Triage` as "Backup that runs without being asked". Naming flagged to hv: it is the repo's largest live body of work, but it is also the topic hv deprioritised today, so it may want recutting.
- The 04-07 Sep body of work (38 commits) has still never had a validation pass. Backup liberator and `9f28dce` (digest staleness) are the highest-risk subset.

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
