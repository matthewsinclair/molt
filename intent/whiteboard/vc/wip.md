---
node: vc
name: Validation Claude
role: validation
session_id: 06e18903-885b-49b1-849a-a441be7fdbe1
heartbeat_at: 2026-10-24 06:36Z
status: active
focus: "24 Oct: ST0008 Molt from brew; cc builds, vc validates and pushes; issues 0043-0046 done"
claims: [ST0006, ST0008]
---

# Validation Claude (vc)

## DOING

- ST0008, Molt from brew (dev, opt and brew trees): cc built WP01-04 (5bf482a, 3add4f8, unpushed). The vc review found 4 must-fix items (D5 restart keys on commit not keg, drift hardcodes the runtime dirs, --force over a non-Molt manifest, local-bin replaces non-tree links) and 7 smaller ones, all sent to cc, who fixes them together with the D4/D6 shadow and no-bin-link work. Design D4 corrected in a0c1b2e. Next: cc commits; vc pushes and checks CI; cc runs the scratch-tap end to end (hv: go); vc creates matthewsinclair/homebrew-molt (hv: approved); WP05 sleeves. (edited)

## TODO

- **farcaster and pihole, when next reachable:** resync their Molt and Molt-matts clones onto the histories purged of AI attribution on 20 Oct (same steps as kovacs). utilz is disabled on both, so ST0005 needs nothing else there. If a clone's `.git/hooks/pre-commit` carries the hand-wired formatter stanza below Intent's chain block, cut it: Molt's config.json declares the formatter since 22 Oct and the shipped guard runs the check. (edited)
- **kovacs (through kovacs-sysadm), farcaster and pihole, at each one's next resync:** opt its Molt clone into the tracked gate (bef8f14, pushed 23 Oct) with `git config core.hooksPath .githooks`, then `intent claude upgrade --apply` to write the .intent carriers, then `intent doctor`. Its old `.git/hooks` stop running, so the formatter-stanza cut in the todos above is moot once this is done. gyges did this on 23 Oct (rhadamanth-sysadm). (edited)

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
- **After a config repo moves, every new shell starts with no zsh config until `molt resleeve` runs**, because `~/.zshenv` dangles. That includes an agent's next Bash call, which then has no `MOLT_PRJ_DIR` and so no `MOLT_CFG_DIR`. Run the mv and the resleeve in one command, with `MOLT_PRJ_DIR` set explicitly and molt called by absolute path.
- **`git rev-list --left-right --count @{u}...HEAD` prints BEHIND then AHEAD.** `0 5` means 5 unpushed commits. vc misread it once on 15 Sep.
- **Intent: rhadamanth is off limits; gyges runs it from Homebrew only** (hv, 23 Sep). Never relink, pull, bootstrap or brew-link Intent on rhadamanth; its manifest disables Molt's intent liberator (Molt-matts 857d49c). The one sanctioned write there is `intent issues add|edit` in ~/Devel/prj/Intent. gyges is the everyday-user test bed with no local dev tree; Intent-from-brew problems go to intent-vc, not into Molt workarounds. Changes on gyges or kovacs go through their sleeve agents (gyges-sysadm, kovacs-sysadm), reached through rhadamanth-sysadm or hv. (edited)
- **Doom's `-!`/`--force` suppresses the rebuild along with the prompt** (`bin/doom-sync`, Doom 59cdaa32): after an Emacs version change it neither asks nor rebuilds, and leaves `$DOOMLOCALDIR/etc/sync` naming the old Emacs. Never answer a doom prompt with --force. Molt compares Doom's recorded version with the running Emacs and passes `--rebuild` itself (`_editors_doom_sync`, issue 0013).
- **A whiteboard message lives in its SENDER's board.json (board@4.0, Intent 0612, live 22 Oct 19:08Z, Molt 2805f6a); the recipient's board.json carries only handled marks; inbox views render from the sender's canon and show no (handled).** Commit exactly what your verb prints on its `wrote:` lines, at once; a `re-rendered:` line names another node's file, leave it. The lesson that outlives the old shape: a view committed without the canon that renders it fails every peer's fresh-worktree gate with view skew (seen 22 Oct 18:00Z local on vc/inbox.cc.md under board@3.0, where the message landed in the RECIPIENT's board.json). A fresh detached worktree and a read-only intent doctor reproduce the gate's view. (edited)
- **A sleeve armed for the config-dir move (its vars.sh declares MOLT_CLAUDE_CONFIG_DIR) fails every `molt upgrade` and `molt resleeve` while any Claude process runs.** The claude liberator refuses the move and names each process, the run exits 1, and an `&&` chain stops there: hv's `molt upgrade --self && molt upgrade && molt maintain` on 23 Oct never reached maintain, which runs no liberators and can run alone. The agents liberator still installs the floor in the same run, so a refused move leaves the floor in and the state in ~/.claude (rhadamanth, 22 Oct 21:56Z). Arm and move in one sitting, with Chrome quit: its native host is a claude process.
- **A hook whose script is missing blocks every call it guards.** The interpreter exits 2 when it cannot open its script (python3 does), and 2 is a PreToolUse hook's block code, so the hook fails closed whatever fail-open logic the script itself carries. On rhadamanth's move (23 Oct) a hand-installed hook named its script under `~/.claude/` by path; the script moved and the line did not, and every Bash call in every session was refused until the line was repointed. Before a move, check the user settings for paths under `~/.claude/` (issue 0038).
- **Resolve a path before calling it a duplicate.** On rhadamanth ~/bin is a symlink to .local/bin, so two PATH entries named one directory, and the 'stray' ~/.local/bin/molt was hv's only molt link; vc removed it on 24 Oct and briefly left hv with no molt. Compare inodes (stat -f %i) or resolved dirs before removing, and treat a doctor shadow check the same way: compare resolved directories, never path strings.

## Decisions

- (2026-09-08) **Verify a peer's findings before acting on them, and verify a carried decision before ruling on it.** intent-vc's six claims about the `intent` liberator all held when checked against source. hv's six carried decisions did not: three were already resolved and the list did not know it. A carried-decision list is not self-cleaning.
- (2026-09-08) **Check the artefact before believing a status field.** Both "Not Started" packages on a six-month-old ST0001 turned out to be mostly delivered -- WP-07 half built, WP-04's runbook written in June and three months stale. The status records what someone last typed.
- (2026-09-08) **A half-met work package closed whole is a lie that compounds**, because the next reader cannot see which half they inherited. WP-07 was split: the delivered half took evidence-backed ACs, the unbuilt half became ST0003.
- (2026-09-15) **A verdict must say what it checked.** A skipped check reported as a pass is the defect; `backup_verify` now has a distinct exit for "passed what it could reach".
- **AI attribution in a commit is purged on sight, not carried as a decision for hv** (hv, 20 Oct: "STRICTLY FORBIDDEN. Purge that from the git record immediately"). The purge recipe is in done 023 and vc's memory. Since issue 0040 the claude liberator writes the `attribution` object from Molt-matts `config/claude/attribution.json`, so a sleeve gets it at its next resleeve; the Git Commits rule is in the user-scope CLAUDE.md Molt links. (edited)
- (2026-10-21) **MOLT_CLAUDE_CONFIG_DIR is the switch.** Everything ST0006 WP01 adds runs only on a sleeve whose vars.sh declares it, so merging changes no sleeve and hv arms the move one sleeve at a time (molt-cc's reading; on rhadamanth Chrome's native host keeps a claude process alive). The variable is published only once the state is where it points (AC011).
- (2026-10-22) **Three agent kinds, three naming schemes** (hv): sleeve agents <hostname>-<role>, project agents <project>-<suffix>, estate agents <estate>-estate (sinclair-estate, geodica-estate; the -vc suffix on those two was wrong). Estate agents are Gtools-provisioned and start in the estate's content root (GTOOLS_ESTATE), where the deployed .claude/ is; a launch above that root loads no contract, because Claude Code reads CLAUDE.md and settings from the launch dir and its parents, never a child.
- **One dev/opt/brew contract for Molt, Utilz, Intent and devbin** (hv, 24 Oct, by TUI). (B) your links first: formulas link into brew's bin as normal; Molt-matts puts ~/.local/bin ahead of brew's bin on every sleeve; <tool> use dev|opt|brew switches the per-user link set in ~/.local/bin (no link means brew); doctor names a shadow, comparing resolved dirs. The one contract text lives in Devbin's docs, drafted by devbin-vc, agreed SAME by molt-vc, utilz-vc and intent-vc before anything lands. Molt consequences: revert D6's links-nothing, MOLT_LOCAL_BIN moves to ~/.local/bin (kovacs has them as different dirs), and the zshrc PATH order change.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
