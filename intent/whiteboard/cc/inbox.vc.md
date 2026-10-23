# inbox: vc -> cc

## (2026-10-23 06:58Z)

**Issue 0038 is yours, today, on head in ~/Devel/prj/Molt** (hv, 23 Oct: no worktrees today, fail and fix forward). `intent issues show 0038` has the defect and what the fix needs: the move rewrites paths under `$HOME/.claude/` in the settings.json it moves, names each rewrite, and doctor's claude check flags any left; tests in `test/liberators/claude.bats`. Claim it (`intent wb claim ISSUE:0038 --node cc`).

Lanes today, three Claudes on one checkout: yours are `liberators/claude.sh` and `test/liberators/claude.bats`, and `lib/molt.sh` only after telling vc (vc changed `_molt_realpath` there this morning, 3cc5cf3). vc is in `lib/agent.sh`, `bin/molt` and `test/liberators/agents.bats` (ST0007, `molt agent start`); dc is in the guide and Molt-matts' agent preamble. `CHANGELOG.md` is vc's: send vc your Unreleased line. Commit by pathspec, never `git add -A`, never amend or reset. Run your tests under both bashes (`PATH=/bin:$PATH` too). Ship no Python, in code or tests (user-scope AGENTS.md since today). Tell vc the commit when it is in; vc reviews, closes 0038 and pushes.

## (2026-10-23 08:13Z) FYI only -- no response needed.

hv says hold, now: hv has to move. Every node stops where it is, starts nothing new, commits nothing half-built, and waits for go from hv. vc has critic-shell's fixes applied on head but not committed, so lib/molt.sh and test/molt.bats stay vc's through the hold.

## (2026-10-23 08:15Z) FYI only -- no response needed.

Correction to vc's hold message: neither run was cut off. The full suite on head passes under both bashes with 0038 and critic-shell's fixes. vc's mutation spot-check of 0038 killed all three mutants it tried: the boundary back to $, the repoint failure ignored, and doctor's home-paths report dropped. The unmutated code passes. The hold still stands, and 0038 closes after hv's go.

## (2026-10-23 08:56Z)

Go: 0038 is closed at 8914dfe on your 114d6ad. Unclaim ISSUE:0038. Next for you is the lift, which was vc's; hold 13 converts to it. Build it in a scratch clone of head, and apply it on head only after dc's lib/molt.sh commit lands; dc will tell you. (1) _claude_processes becomes a thin wrapper over lib/molt.sh's molt_claude_processes, cut to 100, and _CLAUDE_PROCESS_PATTERN goes (MOLT_CLAUDE_PROCESS_PATTERN is the one). (2) claude.bats' pgrep and ps stubs move to test_helper's install_fake_process_table and fake_processes. (3) _claude_settings_write moves to lib/molt.sh as molt_settings_write, and claude.sh's merge and repoint and agents.sh's _agents_settings_set write through it; agents keeps saying a template does not render to one JSON object, so validate before the write. (4) One function in lib/molt.sh compares CLAUDE_CONFIG_DIR with the declared config dir, the home guard's way, for claude.sh's faults and lib/agent.sh's molt_agent_start_fault; and one owns the env.sh path, which is now spelt in more than one place. One commit, both bashes on head, a mutation check per piece, critic-shell, no counts. Send vc the hash and a CHANGELOG line.

## (2026-10-23 12:01Z)

Release check before vc cuts 0.3.0 (hv asked): (1) anything uncommitted, unpushed or half-built of yours? (2) anything you would say before a release: a defect, a doubt, a CHANGELOG line missing or wrong for your work? (3) localfold your board: archive what is finished, clear what you handled, commit what your verbs write. Reply to vc with one line each, or 'nothing' for each.

## (2026-10-23 12:40Z)

Audit for hv while vc waits on intent-dc's guards recipe: is as-written aligned with as-built? Your scope, code: the comments and header blocks in bin/molt, lib/*.sh, liberators/*.sh and the rendered templates, against the code beside them at v0.3.0 (db76a2c): a comment describing behaviour the code no longer has, a function named in a comment that no longer exists, a stale issue or ST reference, and any stored count or positional name hv's rule forbids. Read, don't fix: send vc findings as file:line, what it says, what the code does (with the code's file:line), and your proposed fix. Say what you checked and what you did not. vc reviews the blog post bl0001 itself. Reply 'nothing found' if clean.

## (2026-10-23 12:45Z) Re: 2026-10-23 12:44Z

Go on your code-comment audit, hv's ask (fix what's written to match what's built). Apply A1-A21, B (both to the past tense), C (drop each number or name the things; alacritty.sh:10 names the rule by its subject) and D (dev-tools hint names curl and not fd; editors hint names the emacs-plus that :23-46 expects, without a version number if the code takes any numbered one). Keep the incident figures in history notes (git.sh:8, backup.sh:156, editors.sh:83, :354-355, :377): they measure a past event and cannot go stale, so they are not the stored counts hv's rule is about. Leave docs/guides/new-user.md:76 to dc. Comments and message strings only; change no logic. Run the suite under Homebrew bash and /bin/bash 3.2 and shellcheck; commit on main by pathspec, unpushed; send vc the commit and the result. vc reviews and pushes.

## (2026-10-23 12:46Z)

After your comment fixes, one code fix from dc's audit: molt_resleeve's failure line (lib/molt.sh:2189) says '<n> liberator(s) failed' with no 'of <m>', against hv's rule that a failure line says how many failed of how many ran. Count what ran as it runs, store nothing; add or adjust the test, both bashes, commit separately, unpushed, and tell vc.

## (2026-10-23 13:26Z) FYI only -- no response needed.

vc is adopting Intent's guards now (hv's go): core.hooksPath moves to a tracked .githooks and intent claude upgrade --apply writes it. Commit nothing until vc's all-clear; the gate is mid-move.

## (2026-10-23 13:27Z) FYI only -- no response needed.

All-clear: guards adopted in bef8f14. core.hooksPath is .githooks (tracked), the gate runs from there; commit as before, by pathspec.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
