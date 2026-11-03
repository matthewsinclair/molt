---
verblock: "3 Nov 2026:v0.70: Matthew Sinclair - Molt 1.4.0 released; rhadamanth rollout next"
---

# Work In Progress

## DOING

- **Molt 1.4.0 rollout on rhadamanth:** 1.4.0 is released (tag at d0a4518, tap 814de96), carrying the karabiner liberator (0081), mise as its own liberator, off everywhere (0082), and doctor's fixes (0078, 0072 ask 2). In order: hv runs `brew upgrade molt`; vc enables karabiner in Molt-matts' rhadamanth `molt.toml`; hv quits Karabiner's Settings window and runs `molt upgrade`; then 0081's proof; then rhadamanth-sysadm uninstalls Homebrew's mise and asdf.

## TODO

- **kovacs and gyges to 1.4.0, on hv's word:** kovacs through kovacs-sysadm (it runs 1.3.0, doctor green); gyges through gyges-sysadm, where karabiner waits until its live `karabiner.json` is compared with the repo's. Whether mise comes off kovacs and gyges is hv's call. 0071 stays deferred.
- **rhadamanth and gyges:** rustup on a quieter day, booked (hv 1 Nov); 0079's rule then puts its cargo first.
- **farcaster, pihole, when next reachable:** resync the clones onto the purged histories, set `core.hooksPath .githooks`, run `intent claude upgrade --apply`, then `molt upgrade`; dev-tools goes on there, as it no longer needs mise.
- **rhadamanth backup:** hv's, after 19 Dec.
