---
st_id: ST0006
title: Sleeve agents: a named, role-bound home for a machine's local agent
---

# ST0006: Sleeve agents: a named, role-bound home for a machine's local agent -- Acceptance

> **THIS FILE IS A GENERATED VIEW, AND A ROW AUTHORED HERE IS DISCARDED BY THE NEXT SYNC.** The acceptance contract is canon in the thread model; this file renders it. Acceptance Criteria (AC) are the ratified completeness boundary; Acceptance Tests (AT) are the small red-to-green tests that prove them.
>
> Done = every AC is covered by a GREEN AT, or (for a non-test AC) its named evidence is satisfied, AND the AC set is the ratified full boundary. Done is read from this map, never from a hand-ticked box.
>
> Test-backed satisfaction is COMPUTED from covering green ATs and never stored -- storing it would be double truth. An AC has four states, not two: beyond satisfied and unsatisfied, a requirement can be **descoped** to a named thread or **withdrawn** with its reason on the record. Both are non-blocking and both are reported separately, so a thread that descoped half its contract looks like one.

## Acceptance Criteria

### Group AC001

- AC001 With CLAUDE_CONFIG_DIR set, the claude liberator reads and writes only under it, and no path under $HOME/.claude is touched -- satisfied: yes (computed)

### Group AC002

- AC002 The one-time move refuses while any Claude Code process runs, naming it, and otherwise moves ~/.claude and ~/.claude.json into the config dir with backups -- satisfied: yes (computed)

### Group AC003

- AC003 The UserPromptSubmit hook exits 2 with the launch-from-an-agent-home message when cwd is $HOME and exits 0 for any other cwd; merging it leaves every other user settings key byte-identical -- satisfied: yes (computed)

### Group AC004

- AC004 molt doctor reports CLAUDE_CONFIG_DIR unset, ~/.claude or ~/.claude.json present while the config dir is elsewhere (the XDG paths the native installer owns are not faults), and the env file, GUI file or hook missing or stale -- satisfied: yes (computed)

### Group AC005

- AC005 An enabled [[agent]] entry renders its home (AGENTS.md from the role template plus the instance overlay when the sleeve has one, CLAUDE.md, .claude/settings.json with autoMemoryDirectory=<home>/memory, memory/, work/) with a name derived as <hostname>-<role>; re-render is a no-op while digests match and happens when the template or overlay changes; an undefined role is a fault naming it -- satisfied: no (computed)

### Group AC006

- AC006 molt agent list names every declared agent with role, home and currency; molt agent config <name> prints the effective permissions with each rule tagged by its layer, and fails on an undeclared name listing the declared ones -- satisfied: no (computed)

### Group AC007

- AC007 (non-test) sysadm, ops and docs contracts and profiles exist in Molt-matts and are declared on rhadamanth, gyges and kovacs; molt doctor is green on each reachable host with its homes rendered -- satisfied: no

### Group AC008

- AC008 (non-test) kovacs-sysadm runs from ~/Devel/agt/kovacs-sysadm with its memory in the home; ~/.claude and ~/.claude.json are gone from $HOME and the verify script says so -- satisfied: no

### Group AC009

- AC009 (non-test) docs/guides/sleeve-agents.md records the naming, roles, layers, move and doctor reports; README and CHANGELOG updated -- satisfied: no

### Group AC010

- AC010 sysadm's deny floor is rendered into the managed-settings.d drop-in and molt agent config shows those rules as managed -- satisfied: no (computed)

### Group AC011

- AC011 The move refuses a non-empty config dir, naming its contents, and never merges; after any refusal the env file and GUI file are not written in that run, and after a successful move they are -- satisfied: yes (computed)

### Group AC012

- AC012 When the user repo has config/claude/CLAUDE.md and AGENTS.md, the claude liberator links them into the config dir, backing up a regular file found there; check reports the link pending and doctor reports it broken or missing -- satisfied: yes (computed)

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

### Group AT007

_(no criteria in this group)_

### Group AT008

_(no criteria in this group)_

### Group AT009

_(no criteria in this group)_

### Group AT010

_(no criteria in this group)_

### Group AT011

_(no criteria in this group)_

### Group AT012

_(no criteria in this group)_

### Group AT013

_(no criteria in this group)_

### Group AT014

_(no criteria in this group)_

### Group AT015

_(no criteria in this group)_

### Group AT016

_(no criteria in this group)_

### Group AT017

_(no criteria in this group)_

### Group AT018

_(no criteria in this group)_

### Group AT019

_(no criteria in this group)_

### Group AT020

_(no criteria in this group)_

### Group AT021

_(no criteria in this group)_

### Group AT022

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

### Group AC011

_(no tests in this group)_

### Group AC012

_(no tests in this group)_

### Group AT001

- AT001 `test/liberators/claude.bats` -- covers AC001 -- status: green -- @test "with CLAUDE_CONFIG_DIR set, claude_install, check and verify use only it, and write nothing into ~/.claude". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT002

- AT002 `test/liberators/claude.bats` -- covers AC001 -- status: green -- @test "with CLAUDE_CONFIG_DIR set and no ~/.claude, claude_install creates none". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT003

- AT003 `test/liberators/claude.bats` -- covers AC001 -- status: green -- @test "on a sleeve whose state has moved, claude_install writes only the config dir though this shell lacks CLAUDE_CONFIG_DIR". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT004

- AT004 `test/liberators/claude.bats` -- covers AC002, AC011 -- status: green -- @test "the move refuses while Claude Code runs, names each process, and moves and publishes nothing". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT005

- AT005 `test/liberators/claude.bats` -- covers AC002, AC011 -- status: green -- @test "the move takes ~/.claude and ~/.claude.json into the config dir, copies both beside it first, then publishes it". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT006

- AT006 `test/liberators/claude.bats` -- covers AC002 -- status: green -- @test "a native or node-run Claude Code counts as running; a grep, npm ls or molt run naming it does not". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT007

- AT007 `test/liberators/claude.bats` -- covers AC011 -- status: green -- @test "a config dir that already holds anything is refused, named with its contents, and nothing is merged or published". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT008

- AT008 `test/liberators/claude.bats` -- covers AC011 -- status: green -- @test "an empty config dir counts as absent, and the move goes ahead". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT009

- AT009 `test/liberators/claude.bats` -- covers AC011 -- status: green -- @test "a ~/.claude that is a symlink is not moved, and nothing is published". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT010

- AT010 `test/liberators/claude.bats` -- covers AC011 -- status: green -- @test "a declared config dir that is relative, holds a quote, or is ~/.claude itself is refused before anything moves". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT011

- AT011 `test/liberators/claude.bats` -- covers AC011 -- status: green -- @test "on a sleeve Claude Code has not run on, install creates the config dir and publishes it". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT012

- AT012 `test/liberators/claude.bats` -- covers AC011 -- status: green -- @test "the GUI file is a LaunchAgent on macOS and an environment.d file on Linux, and nothing published names Molt's checkout". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT013

- AT013 `test/liberators/claude.bats` -- covers AC003 -- status: green -- @test "the home guard exits 2 with the agent-home message when cwd is $HOME, and 0 anywhere else". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT014

- AT014 `test/liberators/claude.bats` -- covers AC003 -- status: green -- @test "the home guard exits 1, saying so, when jq is missing or the input names no cwd". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT015

- AT015 `test/liberators/claude.bats` -- covers AC003 -- status: green -- @test "the hook merge adds the guard once, keeps every other key and hook as it was, and a second install writes nothing". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT016

- AT016 `test/liberators/claude.bats` -- covers AC004 -- status: green -- @test "check reports CLAUDE_CONFIG_DIR unset where molt runs, or naming another dir, and passes once it names the config dir". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT017

- AT017 `test/liberators/claude.bats` -- covers AC004 -- status: green -- @test "check reports ~/.claude or ~/.claude.json present while the config dir is elsewhere, whether a directory, a file or a link". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT018

- AT018 `test/liberators/claude.bats` -- covers AC004 -- status: green -- @test "the native installer's own paths under ~/.local and ~/.cache are not faults". Passes on main as well: it pins that no check reaches these paths, and before WP01 none looked (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT019

- AT019 `test/liberators/claude.bats` -- covers AC004 -- status: green -- @test "check and verify report env.sh, the GUI file or the guard missing or stale, and the hook missing from settings.json". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT020

- AT020 `test/liberators/claude.bats` -- covers AC004 -- status: green -- @test "check and verify report a move still pending, naming what is in $HOME". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT021

- AT021 `test/liberators/claude.bats` -- covers AC012 -- status: green -- @test "CLAUDE.md and AGENTS.md are linked into the config dir, and a regular file there is backed up first". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

### Group AT022

- AT022 `test/liberators/claude.bats` -- covers AC012 -- status: green -- @test "check and verify report a CLAUDE.md link that is broken". Red on main: fails against liberators/claude.sh before WP01 (molt-cc, 21 Oct). Green on branch st0006-wp01 under bash 5.3 and /bin/bash 3.2.

---

_Generated by Intent v3 from the thread canon. Do not edit this file -- it is rendered from the model, and `intent doctor` reports any hand-edit as skew._
