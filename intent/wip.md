---
verblock: "23 Nov 2026:v1.00: Matthew Sinclair - 1.4.7 out without a formula; 0326 adoption and 1.4.8 next"
---

# Work In Progress

## DOING

- **1.4.8's cut (hv, 23 Nov):** the devbin#0326 adoption is on main at 0c2cc5c; 1.4.8 waits for devbin 0.1.29's sweep into Molt (hv), then a seat cuts it with its formula. 1.4.7 is tagged at b8daf7b and released without a formula.

## TODO

- **1.4.8's rollout (hv's, when no suite runs):** `brew upgrade molt`, then `molt upgrade` on each sleeve, which installs pigz from rhadamanth's and gyges's Brewfiles (0101); vc tells devbin-vc its START and END, and agentic-engineering-vc once pigz is on.
- **devbin's lanes runner (O2):** molt-dc's, after 1.4.8, on vc's go.
- **I7892f34's docs half:** molt-dc's, once devbin-vc has read devbin-cc's Molt plan.

- **bl0001, before print:** ac fixes its advice to publish the login PATH for GUI launches (issue 0072).
- **0081, hv's own check:** at hv's next Karabiner change, it shows as a Molt-matts diff with `~/.config/karabiner` still a link.
- **rustup on rhadamanth and gyges:** on a quieter day, booked (hv, 1 Nov).
- **gyges:** exclude `~/Devel` from Spotlight by hand when hv is next there.
- **farcaster, pihole, when next reachable:** resync the clones onto the purged histories (`intent/ref/2026-10-20-history-purge-commit-maps.md`), set `core.hooksPath .githooks`, run `intent claude upgrade --apply` and `molt upgrade`, with dev-tools on.
