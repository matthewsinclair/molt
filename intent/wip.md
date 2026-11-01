---
verblock: "1 Nov 2026:v0.66: Matthew Sinclair - rg removed on gyges; 0079 waits on hv's GNOME re-login"
---

# Work In Progress

## DOING

- **Issue 0079's last proof:** after hv logs out of GNOME on kovacs and back in, tell kovacs-sysadm. It checks that the systemd user manager's PATH has `~/.cargo/bin` ahead of Linuxbrew's bin and that `molt doctor`'s env check passes.

## TODO

- **Devbin 0.1.19 sweep:** devbin-vc commits the vendored `bin/.devbin` in Molt's tree, START and END to vc; keep the tree clean for it.
- **rhadamanth and gyges:** rustup on a quieter day, booked (hv 1 Nov); 0079's rule then puts its cargo first.
- **Molt's next release:** 0078 (low, dc). Doctor's resleeve hint where only a login clears the env check, and the env liberator's PATH refusal naming zshrc.
- **gyges, when reachable:** brew upgrade molt to 1.2.0, the four new liberators, and 0072's ask 2. 0071 stays deferred.
- **farcaster, pihole, when next reachable:** resync the clones onto the purged histories, set `core.hooksPath .githooks`, run `intent claude upgrade --apply`, then `molt upgrade`.
- **rhadamanth backup:** hv's, after 19 Dec.
