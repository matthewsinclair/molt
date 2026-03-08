---
verblock: "08 Mar 2026:v0.1: matts - Initial version"
wp_id: WP-05
title: "MOLT framework scaffolding"
scope: Large
status: Not Started
---

# WP-05: MOLT framework scaffolding

## Objective

Create the initial structure and scaffolding for the MOLT framework in the molt repo. This is where templates, scripts, and tooling will live — the shared infrastructure that any user's molt-{userid} repo builds on.

## Context

Currently the molt repo has Intent artifacts, design docs, and a README, but no actual framework code. This WP establishes the directory structure and initial tooling.

## Deliverables

- Directory structure: templates/, scripts/, lib/ (or similar)
- Initial bootstrap script concept (what `molt sleeve` or equivalent would do)
- Template system design (how config templates get rendered per-instance)
- README updates reflecting the framework structure

## Acceptance Criteria

- [ ] molt repo has a clear, documented directory structure for framework code
- [ ] At least one working script or template demonstrating the pattern
- [ ] README explains the two-repo model (molt + molt-{userid})
- [ ] Design decisions captured in ST0001/design.md

## Dependencies

- WP-04 (documenting Phase 1 steps) informs what the framework needs to automate
- Can start scaffolding in parallel, but automation details depend on WP-04
