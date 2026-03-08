---
verblock: "08 Mar 2026:v0.1: matts - Initial version"
wp_id: WP-01
title: "Fix Cmd key passthrough from Parallels"
scope: Medium
status: Not Started
---

# WP-01: Fix Cmd key passthrough from Parallels

## Objective

Get the Cmd (leftmeta) key from the macOS host (rhadamanth) through Parallels and into the Linux VM (kovacs), so that keyd can map it to a custom layer for CUA-style shortcuts. Cmd must remain distinct from Ctrl.

## Context

- keyd config is correct and ready (/etc/keyd/default.conf)
- The Cmd key was briefly working, then stopped after Parallels keyboard config changes
- Parallels appears to be swallowing Cmd at the hypervisor level
- Matt reset Parallels to defaults but Cmd is still not arriving in the VM
- Possible causes: Parallels keyboard profile, GNOME/Mutter compositor grab

## Deliverables

- Working Cmd key passthrough from macOS → Parallels → kovacs
- Verified keyd mapping: Cmd+C/V/X for copy/paste/cut in the VM
- Documentation of the fix for future sleeves

## Acceptance Criteria

- [ ] `evtest` or `keyd monitor` shows leftmeta keypress when Cmd is pressed
- [ ] keyd mac layer activates on Cmd hold
- [ ] Cmd+C/V/X work in Alacritty and other apps
- [ ] Ctrl remains a separate modifier (Cmd ≠ Ctrl)

## Dependencies

- Requires access to Parallels settings on rhadamanth (macOS side)
- May require macOS-level key remapping (Karabiner-Elements or similar)

## Status: PARKED

Needs further investigation. Not blocking other work.
