# vc archive -- 2026-08-27

Archived at localfold. Live board keeps only standing Watch-outs and open TODO; everything below is settled.

## DONE this session

- **First pickup on an empty board.** `vc` was the only node; no roster, no inboxes, no `hv`. Took a baseline read of the repo (112 tests, 22 liberators, VERSION 0.1.1, `intent doctor` 0 findings) so later claims had something to be checked against.
- **Verified devbin-cc's `dvb` brief before acting on it.** Every factual claim reproduced: molt-matts clean at `e834d2a`; six bare-body files in `config/zsh/functions/`; `zshrc:11` the autoload line; `dvb` absent from all four zsh init files with no bash init files; devbin carrying zero `dvb` references in `bin/ lib/ tests/ docs/` and two in prose; `9ce1c88` deleting `bin/db`. Its three tests reproduced exactly (rc=0 / rc=127 / rc=2).
- **Found two defects its own tests could not structurally reach**, and fixed both before landing: `${^tried}` collapsing the candidate list onto one line (invisible at depth 1, which is what the `/tmp` negative control was), and `-x` with no `-f` arm letting a mode-644 `bin/devbin` be stepped over so the walk ran a PARENT project's launcher and returned rc=0. devbin-cc reproduced both independently and accepted both.
- **Landed `dvb`** in molt-matts (`a4e6cb2`) and verified it through the real config in a fresh shell: rc=0 in a devbin project, rc=127 with a multi-line candidate list from `$HOME`, rc=126 on the non-executable case, rc=2 passed through from a failing child. hv confirmed it live in their own shell afterwards.
- **Stood up the escalation surface** (`131642d`): provisioned `hv`, seeded inboxes both directions, wrote `intent/whiteboard/README.md` naming `vc` as the node obliged to read `hv/inbox.*` and surface it to the human.
- **Re-cut the project snapshots off March.** `intent/wip.md` and `intent/restart.md` claimed 83 tests / 19 liberators / v0.1.0 and were five months stale. Also fixed the unsubstituted `{user}` author placeholder in wip.md's verblock that `fc20931` missed.
- **Checked ST0001 and found nothing to repair.** WP-04 and WP-07 are genuinely Not Started; the earlier "Phase 1-6 COMPLETE" was a different axis (phases map to the numbered focus items, not WP numbers), so there was no contradiction.

## Decisions (settled, now recorded permanently elsewhere)

- (2026-08-27) `dvb` lands in `molt-matts` (hv's shell config), not the Molt framework. Devbin's own `usage-rules.md:66` says shell config and never a project, and the framework would otherwise hard-code one project's launcher into every sleeve for users who may not run devbin. The `intent.sh` liberator is not a counter-precedent: it installs a tool rather than defining a shortcut for one. Recorded in `a4e6cb2`.
- (2026-08-27) A `bin/devbin` that exists but is not executable stops the walk at rc=126 rather than being skipped. Skipping it silently ran a PARENT project's launcher from inside a child project -- a wrong-thing-succeeded with a clean exit code, worse than a clean stop. Recorded in `a4e6cb2`.
- (2026-08-27) `vc` is the node obliged to read `hv/inbox.*` and surface it to the human. Recorded permanently in `intent/whiteboard/README.md` (`131642d`), which is the roster's job, so it no longer needs to live on the board.
