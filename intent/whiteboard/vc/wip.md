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
- Doom/MELPA stale clone, all three sleeves (kovacs-sysadm and gyges-sysadm, 9 Nov, FYI; hand-repaired, nothing owed): MELPA renamed master to main and deleted master. Each sleeve's straight clone at ~/.config/emacs/.local/straight/repos/melpa is single-branch with remote.origin.fetch hard-wired to master, and Doom's recipe names no :branch, so straight never heals it: 'doom sync -u' fails at 'Updating recipe repos' with "fatal: couldn't find remote ref refs/heads/master". editors_maintain (liberators/editors.sh:330-364) runs that command and molt_errors on it, so molt maintain fails on every Doom sleeve exactly once. Repaired by hand on rhadamanth, kovacs and gyges (melpa at 9a715f54 tracking origin/main, only origin/main left; molt maintain then rc 0 on both reporting sleeves, 190 packages current, init.31.1.el built). For hv to rule, Molt-side: (a) have the editors hook detect a recipe repo whose configured fetch refspec names a branch the remote no longer publishes and repoint it to the remote HEAD before doom sync, which is general; (b) pin melpa to :branch "main" in Molt-matts' Doom config, which is narrower and only fixes this rename; (c) leave it to hand, since every current sleeve is already fixed and a new sleeve clones main. Nothing started, no issue filed. (edited)

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

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
