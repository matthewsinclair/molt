# Restart

## DOING

- Nothing in progress; vc holds for hv.

## TODO

- **After a compact:** `/in-session` and its pickup as vc, put hv's inboxes in front of hv, then hold for hv's word; molt-dc holds the same way.
- **Molt 1.4.6 rollout (vc todo 52):** released 9 Nov, tag at f2d262767020, formula on the tap at 94e58f54; per sleeve `brew upgrade molt`, then `molt use brew`, and `molt --version` reads 1.4.6. Word to the sleeves goes through rhadamanth-sysadm.
- **kovacs, 0099's owed proof:** hv runs `molt upgrade` from a plain terminal with Claude Code quit; kovacs-sysadm checks `/etc/apparmor.d` and `/var/lib/molt/apparmor`, then on hv's go `sudo systemctl reset-failed apparmor && sudo systemctl restart apparmor`. Until that lands, any reboot or apparmor restart lets the distro's unpriv_bwrap win again; `sudo apparmor_parser -r /etc/apparmor.d/bwrap-userns-restrict` repairs it, and its audit-deny lines for other capabilities are by design.
- **Issue 0100, not scheduled:** release gates require a globally clean tree, so a peer node's whiteboard pickup can red a cut; it cost 1.4.6 one gate run.
