---
node: vc
name: Validation Claude
role: validation
session_id: 3e603c77-1479-4763-aa34-9ca640d5aea3
heartbeat_at: 2026-11-09 07:33Z
status: active
focus: "9 Nov, after the 1.4.6 cut and rollout: v1.4.6 released at f2d262767020, annotated tag 69fa5aa1 on both remotes, formula on the tap at 94e58f54, and rolled out to rhadamanth, gyges and kovacs, each reading 'molt 1.4.6 (brew, f2d262767020)'. Issue 0099's owed proof is met on kovacs and written up on the issue itself (apparmor.service active, systemctl --failed empty, nested bwrap rc 0). Issue 0100 filed and unscheduled: the release gates demand a globally clean tree, so a peer node's pickup can red a cut, which cost this release one gate run; the fix shape is in the issue. Watchout 24 is a standing obligation to agentic-engineering-vc on two output strings. Nothing in progress, no claims, no worktrees, bats slot released and END sent; molt-dc unfrozen with nothing assigned. vc holds for hv."
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

---

_Generated by Intent v3 from the whiteboard model. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
