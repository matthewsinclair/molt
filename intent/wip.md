---
verblock: "1 Nov 2026:v0.68: Matthew Sinclair - Molt parked until devbin 0.1.19 ships (hv)"
---

# Work In Progress

## DOING

- **Parked until devbin 0.1.19 ships:** hv ruled on 1 Nov, through devbin-vc, that no other work happens until devbin 0.1.19 is cut and swept into the fleet. The desk grants devbin's ST0011 runs and nothing else, so Molt asks the desk for nothing, pushes nothing and puts nothing in front of hv. Every TODO below waits, except the Devbin sweep.

## TODO

- **Devbin 0.1.19 sweep:** devbin-vc commits the vendored `bin/.devbin` in Molt's tree, START and END to vc; keep the tree clean for it. hv accepted devbin's XDG cache default, `~/.cache/devbin`, and Molt, Molt-matts and Molt-flynn set neither `DEVBIN_CACHE_HOME` nor `XDG_CACHE_HOME`.
- **Issue 0079's last proof:** after hv logs out of GNOME on kovacs and back in, tell kovacs-sysadm. It checks that the systemd user manager's PATH has `~/.cargo/bin` ahead of Linuxbrew's bin and that `molt doctor`'s env check passes.
- **rhadamanth and gyges:** rustup on a quieter day, booked (hv 1 Nov); 0079's rule then puts its cargo first.
- **Molt's next release (dc):** 0078 (low): doctor's resleeve hint where only a login clears the env check, and the env liberator's PATH refusal naming zshrc. 0072's ask 2: doctor says plainly that macOS GUI apps don't get the agent's PATH.
- **gyges, on hv's word:** brew upgrade molt to 1.2.0 and the four new liberators, through gyges-sysadm. 0071 stays deferred.
- **farcaster, pihole, when next reachable:** resync the clones onto the purged histories, set `core.hooksPath .githooks`, run `intent claude upgrade --apply`, then `molt upgrade`.
- **rhadamanth backup:** hv's, after 19 Dec.
