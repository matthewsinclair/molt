---
node: vc
name: Validation Claude
role: validation
session_id: 3e603c77-1479-4763-aa34-9ca640d5aea3
heartbeat_at: 2026-11-09 05:36Z
status: active
focus: "9 Nov: MELPA closed on all three Doom sleeves (todo 51 archived at c6663e2; decision 52 stands). Bats lane booked for the 1.4.6 cut: ask 01M6ZC8RWJGJXQC96WP51GYDRB, granted by webber-vc, 1/1 full, covering hv's dry run and release as one occupancy; vc starts it on hv's word and releases with --result. 1.4.6's readiness is UNPROVED: the 9bfb1a6 recorded on 6 Nov as its clean dry run is a valid object in no repo on this machine. Live-board sha sweep otherwise clean: 7d016ac is a Molt commit on main, 29943b5 is Ccusage's own as todo 49 says."
claims: []
---

# Validation Claude (vc)

## DOING

_(none)_

## TODO

- farcaster, pihole, when next reachable: resync the Molt and Molt-matts clones onto the purged histories (intent/ref/2026-10-20-history-purge-commit-maps.md), set core.hooksPath .githooks, run intent claude upgrade --apply, then molt upgrade with dev-tools on. (edited)
- gyges: exclude ~/Devel from Spotlight by hand when hv is next there. (edited)
- rhadamanth and gyges: install rustup with its own installer and --no-modify-path on a quieter day, booked on the desk; it puts rustup at ~/.cargo/bin/rustup, which the 0079 rule tests, so its cargo then comes first (hv 1 Nov). (edited)
- 0081: when hv next changes a Karabiner setting on rhadamanth, check it shows as a Molt-matts diff with ~/.config/karabiner still a link, and record it on 0081 (hv's own check; Caps Lock as Control on both keyboards is confirmed, 3 Nov). (edited)
- ccusage 0.1.9 renames account selection to `ccusage activate` (Ccusage ISSUE:0007, 29943b5); when it ships, reword liberators/claude.sh:496's comment ('which `ccusage use` changes between') to activate. Comment only, nothing in Molt runs it (ccusage-vc's FYI, 6 Nov).
- Molt 1.4.6 rollout COMPLETE on all three sleeves, 9 Nov; only 0099's apparmor restart is owed. hv ran 'molt upgrade --self && molt upgrade && molt maintain' himself on rhadamanth, gyges and kovacs. Evidence, first-hand per sleeve: rhadamanth read by vc on the machine, 'molt 1.4.6 (brew, f2d262767020)', brew keg 1.4.6, not outdated, no ~/.local/bin/molt link; gyges read by gyges-sysadm, same version line, brew list agrees, doctor's complete output all passed; kovacs read by kovacs-sysadm, same version line, doctor rc 0. Tap: 94e58f54, formula pinning tag v1.4.6 at revision f2d2627670208c73d92ae3efb5ad559f5d50fe77. Gap recorded rather than closed: no sleeve has a captured log of hv's own maintain run, only the state afterwards, which is first-hand everywhere. 0099 PROVEN on kovacs, the only sleeve that performs the migration: only Molt's bwrap-userns-restrict left in /etc/apparmor.d, both .molt-orig and .molt-rendered under /var/lib/molt/apparmor, doctor's sandbox and managed floor checks passing. OWED, hv's go: 'sudo systemctl reset-failed apparmor && sudo systemctl restart apparmor' on kovacs, then kovacs-sysadm sends systemctl status. apparmor.service still reads failed from BEFORE the upgrade, which is the stale state reset-failed exists for; the restart is the first start with only the profile in /etc/apparmor.d and is 0099's last acceptance. ANSWERED for both sysadms, no Molt change needed: doctor's missing 'env' check is not a check gone quiet. env_check is the env liberator's, and its reporters (molt_env_report_faults at lib/env.sh:354, refusals, session) emit a line only on a fault or a pending session, so a clean env check is silent by design and doctor folds it into 'Checking enabled liberators... all installed'. Its 1.4.5 warning on gyges disappearing means it now PASSES, most likely because molt upgrade re-ran env_install and republished the pairs into launchd's GUI domain. gyges-sysadm's distrust of 'launchctl getenv' was already answered on 30 Oct by 9416519, an ancestor of v1.4.5: the check reads launchctl print's environment block (_molt_env_launchd_vars) on macOS and systemctl --user show-environment on Linux, so the check it distrusted is not the check that ran. 1.4.6 carrying only 0099 stands. Also answered: the iTerm2 ssh wrapper DOES have a staleness check now, _zsh_iterm2_ssh_colors_fault at liberators/zsh.sh:131 called from zsh_check at 208, covered by test/liberators/zsh.bats:159, green as test 668 in today's gate, so gyges-sysadm's 23 Oct report against e9e37f8 is fixed. Still genuinely open and NOT settled by the passing check: whether launchd's published PATH reaches a newly started macOS GUI app, which is issue 0072's finding and already tracked there. (edited)

## Holds

_(none)_

## Watch-outs

- A sleeve armed for the config-dir move fails molt upgrade and resleeve while any claude process runs; arm and move in one sitting, Chrome quit. (edited)
- AE's courseware depends on ONE Molt string, not two formats: the resleeve MESSAGE 'Sleeve ready. Welcome back.' and doctor's final line 'All checks passed.'. Molt owes agentic-engineering-vc a word before either MESSAGE changes, and owes nothing about molt_info's 'Zen:' prefix, because AE's lines quote the message as a suffix with 'ends', so a prefix change or a move off molt_info leaves them true (AE's ac wrote it that way; AE's vc confirmed the immunity 9 Nov). Printed forms: doctor's is a bare echo at lib/molt.sh:2517 with no prefix; resleeve's is molt_info at 2708, which molt_log prefixes with 'Zen:' (lib/molt.sh:17-32), so it prints 'Zen: Sleeve ready. Welcome back.'. Suite cover: test/molt.bats:107 asserts doctor's whole output equals its line exactly; test/molt.bats:802 asserts the resleeve message as a substring, which is what AE's suffix claim needs; test/molt.bats:987 pins molt_info's format exactly as 'Zen: hello', which is Molt's own interest and not AE's. Residual, noted and deliberately not work: 802 would stay green if text were appended after the message on the same line, which would break AE's 'ends'. AE's lines: deck-prose.md:48 and deck.md:85 quote the resleeve message; exercises.md:61 and reference.md:32 quote doctor's. hv can overrule the obligation. (edited)

## Decisions

- hv 28 Oct: every security finding is filed as an issue; fixed now only if a showstopper P0. (edited)
- hv 29 Oct (folds 31-33): hv runs every full suite, push, cut, tag and deploy; a Claude may run a small targeted proof of its own fix, booked on the estate desk. Laksa and Conflab are held for code. (edited)
- hv 30 Oct: the 26 Oct rule stands: reach kovacs through kovacs-sysadm while it runs; ssh is fine when it isn't, with sudo kept out of any probe (kovacs-sysadm had cited an earlier full bar).
- hv 1 Nov (molt-vc's TUI): path_add and path_prepend stay copied in each Molt-* stack, so each stack stays self-contained at shell startup; Molt does not ship them. (edited)
- hv 3 Nov (in molt-dc's session, relayed): 'We don't Karabiner or these others on gyges.' gyges gets no karabiner, arngz, hammerspoon, herdr or menuz, and nothing more is enabled there. rhadamanth's Karabiner hand checks are hv's own. (edited)
- hv 5 Nov, in devbin-vc's window (relayed by devbin-vc, received before the clock read 2026-11-05 04:37Z by date -u): all activity is coordinated through devbin-vc. Every Claude reports to its own vc, each vc to devbin-vc, and devbin-vc to hv; molt-vc sends devbin-vc Molt's state at each step (READY, START, END, the CI read, the rollout) and routes everything for hv through it. Pplr, Cldr and Ccusage stay down until Molt and devbin are stable. 8GJE86 stays ungranted until Molt's rollout is live and hv gives the word; Molt 1.4.5's rollout went live on 5 Nov (rhadamanth, kovacs and gyges). (edited)
- hv 5 Nov, for the whole fleet (relayed by pipeliner-sc: first-hand to sc at 12:02Z, confirmed at 13:11Z): one layer of proof. A thing is proved by running it once as its user would. The commit gate's critic is the only critic. No suite that tests a suite, no planted fault beyond a guard's own one red case where it already exists, no check of a check, no hardening against setups nobody here has, no replay of a replay. A verdict is a read and at most one run. hv, on seeing checks stacked on checks: stop, it is wasting days.
- hv 9 Nov (first-hand in molt-vc's session, after kovacs-sysadm relayed it): the MELPA master-to-main rename is fixed by pinning melpa to :branch "main" in Molt-matts' Doom config. Molt ships no change for it, and hand-repair-only is rejected. rhadamanth-sysadm coordinates the change across the sleeves; no node gives the sleeves separate orders. molt-vc coordinates with rhadamanth-sysadm on how the pin is expressed, on hv's word.
- hv 9 Nov (in molt-vc's session, asked and answered before the tag was pushed): the v1.4.6 tag stays at f2d262767020, which is vc's board commit 'wb(vc): commit vc's focus line...', not at its parent a7456a33 'release: v1.4.6'. The resume took HEAD as the release commit because VERSION already carried the stamp and the tree was clean there, and HEAD was vc's fix for the red leg. Deliberate, not an accident to be tidied; nobody re-tags or rewrites it.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
