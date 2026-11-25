---
verblock: "25 Nov 2026:v1.09: Matthew Sinclair - close-out for rhadamanth's reboot"
---

# Work In Progress

## DOING

- Nothing.

## TODO

- **Next Molt release:** main holds doctor's pass-warning fix (2142620b), in CHANGELOG `[Unreleased]`, and MOLT_WARN_PREFIX (bfb7fd12). It cuts after devbin 0.1.33 is swept into Molt (hv, 25 Nov): the formula check, dry run, cut and rollout, each booked on the Desk.
- **After the cut, the status line:** molt-dc builds one ccstatusline version setting in Molt that `molt upgrade` applies (S; hv, 25 Nov). Until it lands, the version is set in two places: the npx pin in Molt-matts `config/claude/statusline.json` and rhadamanth's npm global.
- **templates/env/retired/:** vc asks gyges-sysadm whether gyges runs the env liberator. cc deletes the directory in the first release after it does (cc hold 16).
- **bl0001, before print:** ac fixes its advice to publish the login PATH for GUI launches (issue 0072).
- **0081, hv's own check:** at hv's next Karabiner change, it shows as a Molt-matts diff with `~/.config/karabiner` still a link.
- **rustup on rhadamanth and gyges:** on a quieter day, booked (hv, 1 Nov).
- **gyges:** exclude `~/Devel` from Spotlight by hand when hv is next there.
- **farcaster, pihole, when next reachable:** resync the clones onto the purged histories (`intent/ref/2026-10-20-history-purge-commit-maps.md`), set `core.hooksPath .githooks`, run `intent claude upgrade --apply` and `molt upgrade`, with dev-tools on.
