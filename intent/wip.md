---
verblock: "5 Nov 2026:v0.78: Matthew Sinclair - the release is 1.4.4: a dated note never re-dates"
---

# Work In Progress

## DOING

- **Molt 1.4.4:** 0088, 0089 and 0091 are merged and closed. The 4 Nov cut of 1.4.3 stopped at its legs, GitHub giving the candidate's macOS job no runner. Its release commit 4e0714a stays on main, since hv ruled on 5 Nov that nothing goes backwards, and devbin never re-dates a dated note, so the release is 1.4.4 and brings 1.4.3's changes. molt-dc pins the macOS job to macos-15 (issue 0092), molt-vc merges, then hv's cut and the rhadamanth rollout (vc's board, doing 10).

## TODO

- **bl0001, before print:** its advice to publish the login PATH for GUI launches, which issue 0072 found reaches no macOS GUI app, is fixed in ac's read before print.
- **rhadamanth's Karabiner Settings check, hv's own:** at hv's next Karabiner setting change, the change shows as a Molt-matts diff with `~/.config/karabiner` still a link; vc records it on 0081.
- **rhadamanth and gyges:** rustup on a quieter day, booked (hv 1 Nov); 0079's rule then puts its cargo first.
- **farcaster, pihole, when next reachable:** resync the clones onto the purged histories, set `core.hooksPath .githooks`, run `intent claude upgrade --apply`, then `molt upgrade`; dev-tools goes on there.
