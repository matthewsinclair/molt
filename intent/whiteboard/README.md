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

**`hv` is Matthew, personally. Not a proxy, not a role account, not a session.** Nothing reads `hv/inbox.*` on its own, because the node has no session loop -- so a write there reaches a human only if some other node carries it.

**`vc` is that carrier. Everything addressed to `hv` routes `peer -> hv/inbox.<sender>.md -> vc -> hv for review.`**

That third hop is the one worth stating, because it is the one that does not happen by itself:

- **`vc` reads every `hv/inbox.*` at every pickup, before reporting anything else**, and surfaces the contents to hv in the session -- quoted or summarised, but delivered, in the conversation, where hv will see it.
- **The same applies to whiteboard notes generally**, not only inbox entries. A `## Decisions` line, a `## Watch-outs` entry or a `focus:` on a peer board that hv needs to rule on is surfaced the same way. The inbox is the durable surface; it is not the only thing that needs a reader.
- **`vc` presents these for hv's REVIEW, and does not action them on hv's behalf.** Escalations exist because a decision is needed. Deciding it and reporting it as handled removes the decision from the person whose decision it was.

A write surface with no named reader is a queue, not a channel: writing succeeds every time, delivery never happens, and **nothing observable distinguishes the two**. Peers write into `hv/inbox.<sender>.md` so an escalation survives when hv is not reachable live; `vc` is what turns that write into a delivery.

If `vc` is not running, the obligation is unmet -- that is a real gap, not a technicality, and it is the first thing to fix rather than something to route around. **An entry that `vc` has read but not put in front of hv is also unmet**, and it looks identical from the file's side.

## Escalation

Findings go to the owning node's inbox and hv adjudicates. A compounding risk -- a false "done" that the next unit of work would build on -- goes to `hv/inbox.<you>.md` as well, because that is the class that gets more expensive the longer it sits.
