---
st_id: ST0008
title: Molt from brew: dev, opt and brew trees
---

# ST0008: Molt from brew: dev, opt and brew trees -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### Group AC001

- AC001 molt install from a clean dev tree publishes the runtime set and a manifest to the prefix; it refuses with no prefix, from a dirty runtime set, from opt or brew, and over a prefix Molt did not write -- satisfied: yes (computed)

### Group AC002

- AC002 molt version names the running tree (dev, opt or brew), its commit and its root, from one tree-identity function -- satisfied: yes (computed)

### Group AC003

- AC003 In opt and brew, molt test and the lint are refused naming the dev tree, and doctor checks the manifest's checksums instead of requiring test/ -- satisfied: yes (computed)

### Group AC004

- AC004 molt use with no argument reports the tree ~/bin/molt serves; molt use dev|opt|brew repoints it, refusing a tree that is not there; a resleeve from any tree leaves a healthy link as it is -- satisfied: yes (computed)

### Group AC005

- AC005 molt upgrade pulls the config repos in every tree; in dev it pulls the framework as before; in opt it pulls no framework and names molt install --force; in brew it runs brew upgrade for the formula and restarts when the version changed, counting a failed brew upgrade in the verdict -- satisfied: yes (computed)

### Group AC006

- AC006 tools/formula render <tag> <out> writes a formula whose tag and revision come from git, and brew installs it from a scratch tap end to end, molt version naming brew -- satisfied: yes (computed)

### Group AC007

- AC007 (non-test) matthewsinclair/homebrew-molt exists and carries the formula for the current release; the release steps name the formula publish -- evidence: tap matthewsinclair/homebrew-molt cca72154 carries molt 1.0.0 (tag v1.0.0, rev 38422394); release steps in intent/wip.md name tools/formula publish (7582bd5) -- satisfied: yes

### Group AC008

- AC008 (non-test) rhadamanth's everyday molt runs from opt or brew, and molt upgrade there no longer refuses over the shared checkout's board views -- evidence: rhadamanth: molt use brew, molt is /opt/homebrew/bin/molt, molt 1.0.0 (brew, 38422394d8d7); molt upgrade --dry-run asks brew outdated (current), no board-view refusal (2026-10-24 15:15Z) -- satisfied: yes

### Group AC009

- AC009 (non-test) kovacs runs molt from brew only (through kovacs-sysadm), or the reason it cannot yet is recorded -- satisfied: no

### Group AC010

- AC010 (non-test) README, getting-started and the bootstrap runbook describe the three trees and molt use; all tests passing under both bashes; CI green -- satisfied: no

### Group AT001

_(no criteria in this group)_

### Group AT002

_(no criteria in this group)_

### Group AT003

_(no criteria in this group)_

### Group AT004

_(no criteria in this group)_

### Group AT005

_(no criteria in this group)_

### Group AT006

_(no criteria in this group)_

## Acceptance Tests

### Group AC001

_(no tests in this group)_

### Group AC002

_(no tests in this group)_

### Group AC003

_(no tests in this group)_

### Group AC004

_(no tests in this group)_

### Group AC005

_(no tests in this group)_

### Group AC006

_(no tests in this group)_

### Group AC007

_(no tests in this group)_

### Group AC008

_(no tests in this group)_

### Group AC009

_(no tests in this group)_

### Group AC010

_(no tests in this group)_

### Group AT001

- AT001 `test/install.bats` -- covers AC001 -- status: green -- install.bats: publishes the runtime set and a checking manifest; refuses no prefix, a dirty runtime set, opt and brew trees, and a prefix Molt did not write. All tests passing both bashes at ec5fe42 (slot 302), CI green.

### Group AT002

- AT002 `test/install.bats` -- covers AC002 -- status: green -- install.bats: molt_tree names dev, opt, brew and unknown; the version line names tree, commit and root. Passing both bashes at ec5fe42, CI green.

### Group AT003

- AT003 `test/install.bats` -- covers AC003 -- status: green -- install.bats: molt test refused in opt naming the dev tree; doctor checks the manifest checksums. Passing both bashes at ec5fe42, CI green.

### Group AT004

- AT004 `test/install.bats` -- covers AC004 -- status: green -- install.bats: molt use reports and repoints the link, refuses a missing tree; local-bin leaves a healthy link. Passing both bashes at ec5fe42, CI green.

### Group AT005

- AT005 `test/install.bats` -- covers AC005 -- status: green -- install.bats: upgrade by tree in opt (no framework pull, names install --force) and brew (current, outdated with restart, a failed brew update counted). The dev-tree pull is molt.bats' existing upgrade tests, unchanged by ST0008. Passing both bashes at ec5fe42, CI green.

### Group AT006

- AT006 `test/formula.bats` -- covers AC006 -- status: green -- formula.bats: render writes the tag and its commit from git. End to end: molt-cc's scratch-tap brew install at slot 287 (24 Oct 10:29-10:31Z) printed molt 0.3.0 (brew, 4e67722c8017) and brew test passed; teardown verified by vc.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
