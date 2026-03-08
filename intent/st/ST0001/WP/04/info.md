---
verblock: "08 Mar 2026:v0.1: matts - Initial version"
wp_id: WP-04
title: "Document Phase 1 bootstrap steps"
scope: Medium
status: Not Started
---

# WP-04: Document Phase 1 bootstrap steps

## Objective

Capture the manual steps performed during Phase 1 (resleeve of kovacs) as structured documentation. This becomes the reference for what MOLT's automation needs to replicate.

## Context

Phase 1 was done manually across several Claude Code sessions. The steps are scattered across session history and memory files. We need a single, ordered document that could serve as both human-readable instructions and a specification for future automation.

## Deliverables

- Bootstrap runbook document in the Molt repo (docs/ or intent/docs/)
- Ordered list of every step from bare VM to working environment
- Notes on which steps are platform-specific vs platform-agnostic
- Notes on which steps are user-specific vs universal

## Acceptance Criteria

- [ ] Document covers all Phase 1 steps in order
- [ ] Each step notes: what was done, why, and any gotchas
- [ ] Platform-specific vs agnostic steps are clearly marked
- [ ] Document is in the Molt repo (not molt-matts)

## Dependencies

- Relies on memory/context from Phase 1 sessions
- No technical blockers
