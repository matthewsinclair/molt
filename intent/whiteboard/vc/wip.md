---
node: vc
name: Validation Claude
role: validation
session_id: 3e603c77-1479-4763-aa34-9ca640d5aea3
heartbeat_at: 2026-11-09 05:04Z
status: active
focus: "6 Nov fold for hv's compact and travel: issue 0099 merged at 7d016ac and closed; Molt 1.4.6's cut ready but not run (slot released); nothing in progress, no claims"
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
- Molt 1.4.6 cut (carries issue 0099). BATS LANE BOOKED 9 Nov: ask 01M6ZC8RWJGJXQC96WP51GYDRB, granted by webber-vc (estate controller), bats now 1/1 full; molt-vc starts it when hv is at the keyboard and releases with --result plus an END to webber-vc. READINESS EVIDENCE IS VOID, not merely stale: the '9bfb1a6' recorded here on 6 Nov as the clean dry run is not a valid object in Molt, devbin, Molt-matts, Utilz or Gtools, and appears in no reflog, so nothing proves 1.4.6 was dry-run clean. Do not treat the 6 Nov note as a precondition met. hv runs, per decision 35: 'bin/devbin release v1.4.6 --dry-run' first, then 'bin/devbin release v1.4.6', both inside this one booking so the lane is held once. Then the CI read and END to devbin-vc (devbin-vc is not running as of 9 Nov 05:30Z, so that leg has no recipient yet). After the cut, kovacs: hv runs molt upgrade from a plain terminal with Claude Code quit; kovacs-sysadm checks only bwrap-userns-restrict of Molt's is in /etc/apparmor.d, both files under /var/lib/molt/apparmor, molt doctor passes, then on hv's go sudo systemctl reset-failed apparmor && sudo systemctl restart apparmor, and sends systemctl status apparmor (0099's owed proof). (edited)

## Holds

_(none)_

## Watch-outs

- A sleeve armed for the config-dir move fails molt upgrade and resleeve while any claude process runs; arm and move in one sitting, Chrome quit. (edited)

## Decisions

- hv 28 Oct: every security finding is filed as an issue; fixed now only if a showstopper P0. (edited)
- hv 29 Oct (folds 31-33): hv runs every full suite, push, cut, tag and deploy; a Claude may run a small targeted proof of its own fix, booked on the estate desk. Laksa and Conflab are held for code. (edited)
- hv 30 Oct: the 26 Oct rule stands: reach kovacs through kovacs-sysadm while it runs; ssh is fine when it isn't, with sudo kept out of any probe (kovacs-sysadm had cited an earlier full bar).
- hv 1 Nov (molt-vc's TUI): path_add and path_prepend stay copied in each Molt-* stack, so each stack stays self-contained at shell startup; Molt does not ship them. (edited)
- hv 3 Nov (in molt-dc's session, relayed): 'We don't Karabiner or these others on gyges.' gyges gets no karabiner, arngz, hammerspoon, herdr or menuz, and nothing more is enabled there. rhadamanth's Karabiner hand checks are hv's own. (edited)
- hv 5 Nov, in devbin-vc's window (relayed by devbin-vc, received before the clock read 2026-11-05 04:37Z by date -u): all activity is coordinated through devbin-vc. Every Claude reports to its own vc, each vc to devbin-vc, and devbin-vc to hv; molt-vc sends devbin-vc Molt's state at each step (READY, START, END, the CI read, the rollout) and routes everything for hv through it. Pplr, Cldr and Ccusage stay down until Molt and devbin are stable. 8GJE86 stays ungranted until Molt's rollout is live and hv gives the word; Molt 1.4.5's rollout went live on 5 Nov (rhadamanth, kovacs and gyges). (edited)
- hv 5 Nov, for the whole fleet (relayed by pipeliner-sc: first-hand to sc at 12:02Z, confirmed at 13:11Z): one layer of proof. A thing is proved by running it once as its user would. The commit gate's critic is the only critic. No suite that tests a suite, no planted fault beyond a guard's own one red case where it already exists, no check of a check, no hardening against setups nobody here has, no replay of a replay. A verdict is a read and at most one run. hv, on seeing checks stacked on checks: stop, it is wasting days.
- hv 9 Nov (first-hand in molt-vc's session, after kovacs-sysadm relayed it): the MELPA master-to-main rename is fixed by pinning melpa to :branch "main" in Molt-matts' Doom config. Molt ships no change for it, and hand-repair-only is rejected. rhadamanth-sysadm coordinates the change across the sleeves; no node gives the sleeves separate orders. molt-vc coordinates with rhadamanth-sysadm on how the pin is expressed, on hv's word.

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
