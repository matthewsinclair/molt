---
verblock: "08 Mar 2026:v0.1: matts - Initial capture"
wp_id: WP-07
title: "Reproducible VM build and self-upgrading Molt"
scope: Large
status: Not Started
---

# WP-07: Reproducible VM build and self-upgrading Molt

## Objective

Two related but distinct capabilities:

1. **Reproducible VM build**: Build a complete, standalone VM image from scratch
   containing the canonically opinionated Molt environment. This VM is a release
   artifact in the Molt GitHub repo — downloadable and bootable on any machine
   that can run the VM.

2. **Self-upgrading Molt**: Any Molt installation — whether inside the Molt VM
   or installed on bare metal / an existing machine — can upgrade itself using
   agreed normal upgrade protocols. The VM is just one delivery mechanism; Molt
   itself is the thing that stays current.

## Design Considerations

### VM build

- **Build from source**: The VM image is built on demand from a declarative spec,
  not hand-crafted. Think Packer, cloud-init, or similar.
- **Delivery format TBD**: Docker container image? QEMU/qcow2? OVA? Parallels
  .pvm? Multiple formats? Needs investigation into what's most portable and
  practical for macOS host usage.
- **Release artifact**: Published to GitHub Releases on the Molt repo.
- **Build frequency**: Not common — Molt instances should be upgradeable in-situ.
  VM rebuilds are for fresh starts or major version bumps.

### Self-upgrading Molt

- **In-situ upgrades**: A running Molt installation can pull framework updates
  (from the molt repo) and config updates (from molt-{user} repo) without
  rebuilding the VM.
- **Upgrade protocol**: Needs definition. Likely: `molt upgrade` pulls latest
  framework, re-runs liberators in check/update mode, reports drift.
- **Idempotent**: Running upgrade on an already-current system is a no-op.
- **Works everywhere**: Same upgrade path whether Molt is in the VM, on bare
  metal Linux, on macOS, or in WSL2.

## Open Questions

- What VM format is best for macOS (Parallels, UTM/QEMU, Docker)?
- Can a single build spec produce multiple VM formats?
- How does the VM image relate to the base OS (Ubuntu 24.04)? Is the VM just
  "Ubuntu + Molt resleeve", or is there more customization?
- What does the upgrade protocol look like? Git pull + re-run liberators?
  Something more structured?
- Version pinning: should molt.toml lock liberator versions?

## Dependencies

- WP-05 (Framework scaffolding) — needs the liberator framework to exist
- WP-04 (Bootstrap runbook) — the runbook defines what the VM build automates

## Acceptance Criteria

- [ ] VM build spec exists (Packer, Dockerfile, or equivalent)
- [ ] VM can be built from scratch with a single command
- [ ] VM image published as GitHub Release artifact
- [ ] `molt upgrade` command exists and works
- [ ] Upgrade works identically inside VM and on bare metal
- [ ] Upgrade is idempotent
