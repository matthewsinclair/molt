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
- Molt 1.4.6 cut (carries issue 0099): dry run clean at 9bfb1a6; book bats lane with devbin-vc, hv runs bin/devbin release v1.4.6; then CI read and END to devbin-vc. After it, kovacs: hv runs molt upgrade from a plain terminal with Claude Code quit; kovacs-sysadm checks only bwrap-userns-restrict of Molt's is in /etc/apparmor.d, both files under /var/lib/molt/apparmor, molt doctor passes, then on hv's go sudo systemctl reset-failed apparmor && sudo systemctl restart apparmor, and sends systemctl status apparmor (0099's owed proof).
- Doom/MELPA rename: the pin is EXECUTED in Molt-matts at b168c86 (verified by read) and PUSHED on hv's word 9 Nov (upstream/main 95a73a4..b168c86, all three commits: b168c86 over b2c8818 markdownlint and 9643bef frame position). Only the sleeve pickup is outstanding. hv's decision 52 shape, as rhadamanth-sysadm built it: a recipe override in config/doom/init.el lines 22-24, above (doom!), '(defvar straight-recipe-overrides nil)' then setf of (alist-get 'melpa (alist-get nil straight-recipe-overrides)) to Doom's own recipe plus :branch "main". init.el rather than packages.el or cli.el because Doom registers its recipe repos after init.el loads and before packages.el, and init.el is loaded by both the doom CLI and startup; rhadamanth-sysadm's 'doom sync -u' on rhadamanth exits 0 with no recipe-conflict warning, which is this fix's one layer of proof. Molt ships no change: editors_maintain (liberators/editors.sh:330-364) keeps surfacing the fault, which is correct. OUTSTANDING: each sleeve pulls Molt-matts and runs 'doom sync -u'; a pull alone suffices, since config/doom is a plain symlink and needs no molt upgrade. rhadamanth-sysadm drives the sleeves (it tells kovacs-sysadm and gyges-sysadm; molt-vc sends them nothing, so it is said once). The Dropbox 'local' mirror is at 95a73a4, three behind upstream, which is its normal state and nobody's owed step. Untested by either of us and NOT covering it: whether :branch repairs an already-stale single-branch clone; expected not to, since straight fetches with the clone's own refspec, so a stale clone still needs rhadamanth-sysadm's hand repair. If upstream Doom adds :branch "main", this override becomes identical and inert. Archive when the sleeves have it, on rhadamanth-sysadm's word. (edited)

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
