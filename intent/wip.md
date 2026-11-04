---
verblock: "4 Nov 2026:v0.74: Matthew Sinclair - 1.4.1 and 1.4.2 out; 1.4.3 in hand with Molt's nodes"
---

# Work In Progress

## DOING

- **Molt 1.4.3:** molt-dc builds 0088 (Ccusage 0003's step 2, design B), 0089 (tests.yml without its tag trigger), 0090 (hv's calls on the docs and Molt-matts) and the deletion of `templates/env/retired/`. molt-vc reviews and merges each, pplr-vc grants the runs after devbin 0.1.20's, and hv cuts with `bin/devbin release v1.4.3` (hv, 4 Nov; vc decision 47).

## TODO

- **bl0001, before print:** its advice to publish the login PATH for GUI launches, which issue 0072 found reaches no macOS GUI app, is fixed in ac's read before print.
- **rhadamanth's Karabiner Settings check, hv's own:** at hv's next Karabiner setting change, the change shows as a Molt-matts diff with `~/.config/karabiner` still a link; vc records it on 0081.
- **rhadamanth and gyges:** rustup on a quieter day, booked (hv 1 Nov); 0079's rule then puts its cargo first.
- **farcaster, pihole, when next reachable:** resync the clones onto the purged histories, set `core.hooksPath .githooks`, run `intent claude upgrade --apply`, then `molt upgrade`; dev-tools goes on there.
