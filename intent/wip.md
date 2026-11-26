---
verblock: "26 Nov 2026:v1.13: Matthew Sinclair - Cycle 5 fold: Molt pushed, rustup waits"
---

# Work In Progress

## DOING

_(none)_

## TODO

- **bl0001, before print:** ac fixes its advice to publish the login PATH for GUI launches (issue 0072).
- **0081, hv's own check:** at hv's next Karabiner change, it shows as a Molt-matts diff with `~/.config/karabiner` still a link.
- **rustup on rhadamanth and gyges, today after the estate batch (hv, 26 Nov):** on devbin-vc's word after the batch's last cut. Route C: `brew install rustup`, a `rustup-init` symlink to the keg's `libexec/bin/rustup` in a scratch dir, `rustup-init -y --no-modify-path`. rhadamanth-sysadm and gyges-sysadm hold the steps. Keep brew `rust`: it is a build dependency of Utilz, gtools and other formulae. Proof: `which -a cargo` and `cargo --version` in a fresh login shell.
- **gyges:** exclude `~/Devel` from Spotlight by hand when hv is next there.
- **farcaster, pihole, when next reachable:** resync the clones onto the purged histories (`intent/ref/2026-10-20-history-purge-commit-maps.md`), set `core.hooksPath .githooks`, run `intent claude upgrade --apply` and `molt upgrade`, with dev-tools on.
