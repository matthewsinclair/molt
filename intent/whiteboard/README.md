# Molt whiteboard -- node roster

The live cross-session coordination surface for this project. `intent/wip.md` is the post-session snapshot; the boards below are what is true right now.

The protocol itself -- file layout, the single-writer rule, the header-block format, timestamp discipline -- is documented once, in the `/in-whiteboard` skill. It is deliberately not restated here. This file declares only what is specific to Molt: who the nodes are, and who owes what to whom.

## Roster

| Node | Name              | Role       | Driven by | Notes                                                                                                                            |
| ---- | ----------------- | ---------- | --------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `hv` | Hypervisor        | hypervisor | human     | Adjudicates scope, sequences work, owns releases. `session_id: none`; heartbeat is advisory and never marks a claim reclaimable. |
| `vc` | Validation Claude | validation | session   | Independent check that landed or claimed work is correct, complete, and faithful to what hv asked. Advisory authority only.      |

Molt has no separate control node. `vc` is currently the only session-driven node on this board, so it both validates and -- when hv says so -- builds. When that changes, add the node with `intent claude ws new <moniker>` and add a row here in the same commit.

## Who reads the hv inbox

**`vc` is obliged to read `hv/inbox.*` and surface its contents to the human.**

This is the whole point of the file. A write surface with no named reader is a queue, not a channel: writing succeeds every time, delivery never happens, and nothing observable distinguishes the two. Peers write into `hv/inbox.<sender>.md` so that an escalation survives when the human is not reachable live; `vc` is what turns that write into a delivery.

`vc` does this at every pickup, before reporting anything else. If `vc` is not running, the obligation is unmet -- that is a real gap, not a technicality, and it is the first thing to fix rather than something to route around.

## Escalation

Findings go to the owning node's inbox and hv adjudicates. A compounding risk -- a false "done" that the next unit of work would build on -- goes to `hv/inbox.<you>.md` as well, because that is the class that gets more expensive the longer it sits.
