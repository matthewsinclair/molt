---
node: vc
name: Validation Claude
role: validation
session_id: 811b3338-a050-48b0-9eb7-e07144ee6b7c
heartbeat_at: 2026-10-22 18:23Z
status: active
focus: "22 Oct, 17:10Z-ish: v0.2.0 cut, every Molt issue closed (0022 last, d25828f), kovacs on v0.2.0, B1 for rhadamanth in Molt-matts f182813. Next: hv quits every Claude and runs the runbook's rhadamanth section (B4 to B9); on the bounce from a shell opened after B7, vc closes WP04 and ST0006 with gyges carried (todo 5). Peers ac c272b9a, cc d489f3a, dc d41df40 committed and holding, not released."
claims: [ST0006]
---

# Validation Claude (vc)

## DOING

_(none)_

## TODO

- When Intent 3.2.1 reaches gyges: watch the first molt upgrade after brew upgrade repair the gate home (Intent 0527; see wip.md)
- **Weekend, when hv starts it (gyges):** deploy the Gtools Sinclair estate on gyges, visible inside the house; declare gyges' [terminal] bg_color from its live iTerm2 profile and regenerate its ssh wrapper (nothing checks the rendered wrapper, so molt upgrade will not). Start Tailscale first: gyges.lan did not resolve on 15 Oct. Changes on gyges go through gyges-infra; Gtools is gtools-vc's pen. See wip.md. (edited)
- **gyges, next time Tailscale is on (hv, 20 Oct), through gyges-infra:** (1) set gyges' utilz entry to `source = "brew"` and run molt doctor (Molt ST0005 WP03; hv agreed brew); (2) resync its Molt and Molt-matts clones onto the purged histories (nothing local, fetch, `reset --hard`, reflog expire, gc; Molt main fe17190, Molt-matts main e567a83 or later); (3) check its Claude Code attribution config, the `~/.claude/settings.json` attribution keys and the CLAUDE.md Git Commits rule, as kovacs now has.
- **farcaster and pihole, when next reachable:** resync their Molt and Molt-matts clones onto the histories purged of AI attribution on 20 Oct (same steps as kovacs). utilz is disabled on both, so ST0005 needs nothing else there.
- Intent 0612 (high, ruled 22 Oct at e248aafd9 on vc's no-objection under hv's pen; intent-dc building): an inbound message moves to the SENDER's board.json, the recipient keeps only handled marks, the inbox view renders from the sender's canon. When it ships: one re-render commit per estate touching every board (the coordinating node's or hv's), and the commit rule becomes your board.json and wip.md, every <peer>/inbox.<you>.md, and your events; watch-out 18's rule stands until then. Also filed from Molt's reports: Intent 0613 (broken-pipe panic, low), 0614 (worktree hooks sync an older store, medium, unreproduced), 0615 (stale doc comment on the settings merge, low); no lane yet.

## Holds

_(none)_

## Watch-outs

- **Molt CI's macOS runner has only bash 3.2**, and this Mac's `env bash` is Homebrew bash 5.3. A green run under 5.3 is not a pass: run the suite with `/bin` first on PATH as well, and check the CI run before calling work done. `${VAR:-{...\}}` is where the two diverged (issue 0004).
- **`backup_verify` exit 2 is normal, not a failure.** It means nothing failed but the share-side checks (SMB dialect, attach budget) could not run, which is the usual state because SuperDuper mounts the share only while copying. 0 means every check ran and passed; 1 means a check failed.
- **SuperDuper `recentRuns` records finished runs only.** A copy in flight is invisible there, and cancelled or failed runs are often hv's own interruptions, eg for an OS install. Check for a running copy and ask before calling the backup failing.
- **iTerm2 3.7.1's Claude Code onboarding offers "Mark Rewritable & Install" for dynamic profiles.** Taking it adds `"Rewritable": true`. The Molt profile is symlinked into Molt-matts, so iTerm2 then writes into git. Restored without the flag in Molt-matts `b58e0d4`; hv ruled iTerm2 does not write into terminal config unannounced.
- **`fc -AI <file>` appends nothing to a file other than the current `HISTFILE`**, and `fc -A`/`fc -W` append everything, seeded history included. Per-session history (Molt-matts `389ef6f`) therefore points `HISTFILE` at an empty scratch file and copies it out at exit, as `/etc/zshrc_Apple_Terminal` does.
- **`pgrep -x iTerm2` matches nothing while iTerm2 is running.** Use `pgrep -fl 'iTerm.app'`. An empty probe that contradicts something obvious is a probe defect, not a finding.
- **A `grep -qv` converted to a herestring changes its answer on an EMPTY capture.** The substitution yields the empty string, the herestring appends a newline, and `-v` matches that line -- so the predicate answers TRUE where the pipeline answered FALSE. Demonstrated: `grep -qv x <<<"$(printf '')"` returns 0. `molt_foreign_home_paths` (`tr | grep -oE | grep -qvE`) was exactly that shape; issue 0008 converted it with an explicit `[[ -n ]]` test, and a bats test pins the empty case. A herestring on the FIRST stage of a multi-stage pipeline fixes nothing.
- **Sourcing `lib/molt.sh` turns on `set -euo pipefail` for the caller** (line 5). bats has pipefail OFF, so the suite only sees SIGPIPE defects because `load_molt_libs` sources the real lib. A harness that stubbed it would have the hazard and no way to see it. `backup.bats` runs its errexit arms in a fresh `bash` for the same reason.
- **An autoload file contains the BODY ONLY.** Wrapping it as `name() { ... }` makes the first call merely define the function and do nothing else -- it silently no-ops once, then works. `jump`, `git_current_branch` and `e` are the convention in `Molt-matts/config/zsh/functions/`. devbin's `README.md:60` shows the WRAPPED form, so anyone copying from there walks into it.
- `fpath` and `autoload` are read at shell startup. A change under `config/zsh/functions/` needs a fresh shell; `source ~/.zshrc` is not enough, and testing in the current shell shows the old behaviour.
- A negative control with ONE candidate cannot see a preference-order or list-formatting bug. Depth-1 failure cases prove the exit code and nothing about the output.
- `molt doctor` check 12 (`core.ignorecase=true`) is a **standing condition on macOS, not a defect**. The check says so itself. Do not set it false to clear the warning.
- **After a config repo moves, every new shell starts with no zsh config until `molt resleeve` runs**, because `~/.zshenv` dangles. That includes an agent's next Bash call, which then has no `MOLT_PRJ_DIR` and so no `MOLT_CFG_DIR`. Run the mv and the resleeve in one command, with `MOLT_PRJ_DIR` set explicitly and molt called by absolute path.
- **`git rev-list --left-right --count @{u}...HEAD` prints BEHIND then AHEAD.** `0 5` means 5 unpushed commits. vc misread it once on 15 Sep.
- **Intent: rhadamanth is off limits; gyges runs it from Homebrew only** (hv, 23 Sep). Never relink, pull, bootstrap or brew-link Intent on rhadamanth -- its manifest disables Molt's intent liberator (Molt-matts 857d49c). gyges is the everyday-user test bed with no local dev tree; Intent-from-brew problems go to intent-vc, not into Molt workarounds. Changes ON gyges or kovacs go through gyges-infra / kovacs-sysadm (not kovacs-infra, hv 15 Oct). gyges is at home in the UK: while hv travels, ssh gyges cannot resolve gyges.lan, which is distance, not a fault. (edited)
- **Doom's `-!`/`--force` suppresses the rebuild along with the prompt** (`bin/doom-sync`, Doom 59cdaa32): after an Emacs version change it neither asks nor rebuilds, and leaves `$DOOMLOCALDIR/etc/sync` naming the old Emacs. Never answer a doom prompt with --force. Molt compares Doom's recorded version with the running Emacs and passes `--rebuild` itself (`_editors_doom_sync`, issue 0013).
- **An inbound ask is stored in the RECIPIENT's board.json, which is canon, and only the recipient commits it.** The sender's wb ask re-renders the recipient's inbox view and the sender commits that view with its event, but the message itself lands in <recipient>/board.json, which stays uncommitted on main until the recipient commits its own paths. Until then every fresh worktree (every builder's gate) fails doctor with view skew on that inbox: the committed view shows a message the committed canon cannot render. Found 22 Oct 18:00Z local when cc's 0015 gate refused on vc/inbox.cc.md (12018 on disk, 7254 rendered). Rule: whenever you commit anything, include your own board.json; and after a peer's ask or your own clear, commit board.json at once. A fresh detached worktree and a read-only intent doctor reproduce the gate's view.

## Decisions

- (2026-09-08) **Verify a peer's findings before acting on them, and verify a carried decision before ruling on it.** intent-vc's six claims about the `intent` liberator all held when checked against source. hv's six carried decisions did not: three were already resolved and the list did not know it. A carried-decision list is not self-cleaning.
- (2026-09-08) **Check the artefact before believing a status field.** Both "Not Started" packages on a six-month-old ST0001 turned out to be mostly delivered -- WP-07 half built, WP-04's runbook written in June and three months stale. The status records what someone last typed.
- (2026-09-08) **A half-met work package closed whole is a lie that compounds**, because the next reader cannot see which half they inherited. WP-07 was split: the delivered half took evidence-backed ACs, the unbuilt half became ST0003.
- (2026-09-08) **`intent fc` was invoked by hv, at hv's keyboard, both times.** `IN-AG-FIAT-001`. vc moved ST0003 and Molt-matts ST0001 out of Triage into WIP so the transition was legal, which is not the verb and not a route around it.
- (2026-09-15) **A verdict must say what it checked.** A skipped check reported as a pass is the defect; `backup_verify` now has a distinct exit for "passed what it could reach".
- (2026-09-15) **iTerm2 does not write into terminal config without hv knowing.** hv's ruling. No dynamic profile in Molt-matts carries `"Rewritable": true`; profile changes are made in git.
- (2026-09-15) **A local green under a different interpreter from CI's is not a pass**, and neither is a carried question copied forward without checking the artefact. Both happened this session: CI red after "179 passing", and a stale AC001 question written into wip.
- **AI attribution in a commit is purged on sight, not carried as a decision for hv** (hv, 20 Oct: "STRICTLY FORBIDDEN. Purge that from the git record immediately"). Molt-matts `e3af373`'s trailers had been carried for days as "rewriting pushed history is hv's call". The purge recipe is in done 023 and vc's memory. Every sleeve whose Claude Code commits needs the attribution keys in `~/.claude/settings.json` and the Git Commits rule in `~/.claude/CLAUDE.md`. rhadamanth and kovacs have both; gyges is unchecked.
- (2026-10-21) **MOLT_CLAUDE_CONFIG_DIR is the switch.** Everything ST0006 WP01 adds runs only on a sleeve whose vars.sh declares it, so merging changes no sleeve and hv arms the move one sleeve at a time (molt-cc's reading; on rhadamanth Chrome's native host keeps a claude process alive). The variable is published only once the state is where it points (AC011).
- (2026-10-22) **Three agent kinds, three naming schemes** (hv): sleeve agents <hostname>-<role>, project agents <project>-<suffix>, estate agents <estate>-estate (sinclair-estate, geodica-estate; the -vc suffix on those two was wrong). Estate agents are Gtools-provisioned and start in the estate's content root (GTOOLS_ESTATE), where the deployed .claude/ is; a launch above that root loads no contract, because Claude Code reads CLAUDE.md and settings from the launch dir and its parents, never a child.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
