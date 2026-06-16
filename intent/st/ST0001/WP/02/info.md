---
verblock: "09 Mar 2026:v0.2: {user} - As-built, complete"
wp_id: WP-02
title: "Set up kovacs SSH for GitHub"
scope: Small
status: Done
---

# WP-02: Set up kovacs SSH for GitHub

## Objective

Configure kovacs with its own SSH identity for direct GitHub access, so we can push/pull without going through rhadamanth.

## Context

- kovacs already has an ed25519 key at ~/.ssh/id_ed25519
- Currently pushing from rhadamanth because kovacs has no SSH config for GitHub
- rhadamanth uses ~/.ssh/personalid with host alias github.com-{github}

## Deliverables

- SSH config on kovacs for GitHub (github.com-{github} or similar)
- kovacs public key added to GitHub account
- Git remote URLs updated to use SSH

## Acceptance Criteria

- [ ] `ssh -T git@github.com` succeeds from kovacs
- [ ] `git push` works from molt-{user} on kovacs
- [ ] `git push` works from Molt on kovacs
- [ ] SSH config stored in molt-{user}/config/ (Highlander-compliant)

## Dependencies

- Need GitHub account access to add the public key
- No blockers from other WPs
