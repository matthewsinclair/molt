# inbox: vc -> hv

## (2026-09-08 10:02Z)

**`molt doctor` was silently swallowing every liberator check reason. Fixed.** `lib/molt.sh` check 6 printed `✓ N/M installed` for any ratio -- `0/16` rendered byte-identical to `16/16` -- raised no warning, never named the failing liberator, and discarded the reason the check function had already printed. It now warns, names them, and prints the reason.

It surfaced immediately: `15/16`, missing liberator `backup`, on rhadamanth. hv has ruled that one not a concern today -- the backup exists and has been failing intermittently and being redone.

**One thing to carry from it, for whenever the backup work is picked up again.** `backup_check` says _"has never completed a copy -- no backup exists yet"_ when the SuperDuper tile carries no `recentRuns`. A job that has been recreated loses its run history without losing its backup, so the message states as fact something the tile cannot actually tell it. Same class as the checks closed on 04 Sep: a question that stopped matching reality. I made the identical inference from the same field before hv corrected me, which is fair evidence the message reads as authoritative.

Also measured while there, read-only, and worth having when the schedule is next touched: the tile's `schedule.minuteOfDay` is `1380` (23:00) against the `04:00-06:00` window `vars.sh` declares, and `schedule.scheduleOn` is absent. So scheduling it is two edits rather than one. Not raised as urgent -- filed so it is not re-derived.

Nothing touched on the SuperDuper side. Reads only, via `plutil -extract`.

## (2026-09-08 10:15Z)

**Three of the six "carried decisions" were already resolved, and the list did not know it.** Checked against as-built rather than against the note:

- **`c137146` / `gyges-ssh-lan-hosts` is merged** into Molt-matts `main` (`048d06f`). It was carried as "awaiting review".
- **gyges already reaches rhadamanth by key.** `26ff1ef` closed it on 4 Sep. Verified live this morning: `gyges -> rhadamanth` returns `KEY_AUTH_OK`. gyges's `personalid`, rhadamanth's `personalid` and the key in rhadamanth's `authorized_keys` are one and the same ed25519 key. **I wrote nothing to `authorized_keys`** -- the approved action was already done.
- **kovacs is absent from gyges's ssh fragment for a documented, non-key reason.** The fragment says so in detail and says a ProxyJump block is right "once kovacs is reachable". Re-tested: `kovacs`, `kovacs.lan` and `kovacs.local` resolve from nowhere, `10.211.55.3` answers neither ping nor 22, and the Parallels ARP entry has now gone entirely. Adding the block would be exactly the mistake that comment warns against.

**The lesson is about the list, not the items.** A carried-decision list is not self-cleaning: three of six had been overtaken by work that landed in the same week nobody was folding the whiteboard. Re-verify each against as-built before ruling on it -- I nearly put a decision to you whose action had been taken four days earlier.

**One tool defect worth knowing, because it will bite again.** `acceptance: exempt` -- the escape the close gate itself names -- **is not reachable from the command line**. Intent's own `known-defects.md` records it as `intent#0227`: the state has a complete read path and no writer, at thread scope or WP scope. So your ruling could not be executed literally. I used the documented workaround: define one criterion and satisfy it by named evidence. ST0001 now carries AC001 at 1/1, which is a minimal-but-true contract rather than the full one. Say if you would rather it were reverted.

## (2026-09-08 10:24Z)

**Scope question: port Intent's `pipefail_sigpipe_check.sh` into Molt?** intent-vc raised it after I hit the defect independently in `molt_font_available`. Their guard is real -- `Intent/intent/st/ST0056/parity/tools/pipefail_sigpipe_check.sh`, 11355 bytes, running on every Intent commit, currently reporting 88 instruments clean.

**Measured on Molt before recommending, and the answer is milder than it first looked.** Molt runs under `pipefail` in production (`lib/molt.sh:5`, `bin/molt:5`, and sourcing `lib/molt.sh` turns it on for any caller -- which is why bats caught my bug despite bats itself having pipefail off). There are 7 pipelines ending in `grep -q`. But pipefail is necessary and NOT sufficient: SIGPIPE also needs the writer to outrun the 64KB pipe buffer. Measured payloads -- `otool -L` is 47-65 bytes, `tail -50` is bounded, `groups` and `echo "$var"` are small. **No site in Molt loses today.** I said "live, not latent" before measuring and that was wrong.

Demonstrated rather than assumed, under `set -o pipefail`: a 200k-line payload gives exit 141 where a 50-line one gives 0, and in the NEGATED form (`if ! ... | grep -q`) the large payload reports NOT PRESENT on input that plainly contains the string. That direction invents findings rather than losing them, and `liberators/system.sh:16` is that shape.

**One site is worth knowing about if anyone ever fixes these.** `lib/molt.sh:707` is a three-stage pipeline (`tr | grep -oE | grep -qvE`). The guard's docs are explicit that a herestring on the FIRST stage of a multi-stage pipeline fixes nothing -- the early-exiting reader is still downstream of another writer. Four of Intent's 36 sites were that shape and the obvious remedy would have left all four still losing.

**The argument for porting is growth, not current breakage**, which is the guard's own rationale: a check that only flags what loses today goes quiet exactly when a body grows, and that is the direction this defect arrives from. Intent's population went 24 -> 36 in a month with nobody adding one on purpose.

**And intent-vc's structural point is the one I would most want you to hear: the guard is a per-repo property, not a fleet one.** Intent's covers Intent's own instruments and would never have seen Molt's liberator. Nothing in either estate looks across the boundary. So every repo that has not ported it carries this unmeasured -- Molt, Molt-matts, Utilz, devbin, Laksa, Lamplight. That is a fleet decision, not a Molt one.

Not porting it without your say-so: it is a new instrument, not a fix to existing work.

## (2026-09-08 10:53Z)

**Validation sweep of the 04-07 Sep window, scoped as hv ruled: the backup liberator and `9f28dce`. Three findings, none of them fixed -- a sweep reports, it does not patch.**

**1. The backup liberator has ZERO tests.** 477 lines, 17 functions, 9 commits in the last two days, and it is the liberator that decides whether your backups exist and are scheduled. `test/liberators/` pins desktop, editors, intent, web and zsh -- every one of them smaller and less churned. This is the largest untested surface in the framework and it governs the thing with the least tolerance for being wrong.

**2. `backup_verify` returns PASS having checked nothing, in two distinct ways.** Same class as the `intent_verify` hole closed this morning, and the one AC001 is written against:

- `liberators/backup.sh:386` -- away from `MOLT_BACKUP_HOST` it prints an info line and `return 0`. Verify PASSED. Zero assertions ran. A caller reading the exit code cannot distinguish "your backup is verified" from "I was on a different network".
- `liberators/backup.sh:431` -- share not mounted, so the dialect and attach-budget checks are skipped, and it then falls through to `molt_info "Verified: a recent backup exists and the job is bound to its image"`. The skip is announced on its own line; the verdict line is not qualified, and the return code is not qualified at all.

The information is present in both cases and the VERDICT does not carry it. That is the same shape as check 6 printing a tick over `15/16`.

**3. `9f28dce` (mtime -> content digest) holds up.** I tried to break it and could not. The digest covers template, `vars.sh` and extra inputs, sorts extras so it does not depend on glob order, includes each extra's basename so a rename is caught, and fails toward "stale" on every error path -- missing repo, failed digest, absent sidecar. Probed a missing `vars.sh` under `set -euo pipefail`: computes correctly rather than tripping `set -e`. The comments name the three separate occasions this same bug appeared. Good work, and the extras case is tested.

One property it does NOT have, which may be by design: a hand-edited RENDERED file is never detected, because the digest is taken over the inputs and never over the output. mtime did not catch that either, so it is not a regression -- but "the config on disk is what the template says" is a thing a reader may believe this provides.

**Recommendation, and it is one decision not three.** Findings 1 and 2 are the same finding: a 477-line liberator with no tests grew a verify that passes on nothing, and nothing caught it. Writing `test/liberators/backup.bats` fixes 2 as a side effect, because the first control you write is "verify must FAIL when it has not checked anything" -- exactly the arm that caught `intent_verify` this morning. I would do that before touching backup.sh's logic.
