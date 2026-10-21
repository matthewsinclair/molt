# Molt whiteboard -- node roster

The live cross-session coordination surface for this project. `intent/wip.md` is the post-session snapshot; the boards below are what is true right now.

The protocol itself -- file layout, the single-writer rule, the header-block format, timestamp discipline -- is documented once, in the `/in-whiteboard` skill. It is deliberately not restated here. This file declares only what is specific to Molt: who the nodes are, and who owes what to whom.

## Roster

| Node | Name              | Role       | Driven by | Notes                                                                                                                                                                                                          |
| ---- | ----------------- | ---------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `hv` | Hypervisor        | hypervisor | human     | Adjudicates scope, sequences work, owns releases. `session_id: none`; heartbeat is advisory and never marks a claim reclaimable.                                                                               |
| `vc` | Validation Claude | validation | session   | Specifies, validates and coordinates: independent check that landed or claimed work is correct, complete, and faithful to what hv asked. Reviews and merges what `cc` and `dc` build. Advisory authority only. |
| `cc` | Control Claude    | control    | session   | Builds the code: liberators, lib, tests. Works in a git worktree on a branch per work package; `vc` merges.                                                                                                    |
| `dc` | DevX Claude       | devx       | session   | Builds the developer experience: guides, README, CHANGELOG, role contracts. Same worktree discipline as `cc`.                                                                                                  |
| `ac` | Authoring Claude  | authoring  | session   | Authors prose for hv: briefs, structures and notes hv writes from (the blog brief, ST0006 WP07). Writes docs on main directly, no branch or worktree (hv, 21 Oct).                                             |

The project-Claude suffixes, as hv named them on 21 Oct 2026. Every Intent project uses the same six; Molt runs four of them for now.

| Suffix | Name              | Here |
| ------ | ----------------- | ---- |
| `sc`   | Supervisor Claude | no   |
| `vc`   | Validation Claude | yes  |
| `cc`   | Control Claude    | yes  |
| `ic`   | Interface Claude  | no   |
| `ac`   | Authoring Claude  | yes  |
| `dc`   | DevX Claude       | yes  |

A session is named `<project>-<suffix>` (`molt-vc`, `molt-cc`, `molt-dc`, `molt-ac`). Sleeve agents, which run on a machine rather than in a project, are named `<hostname>-<role>` with roles `sysadm`, `ops` and `docs` (ST0006). To add a node, create it with `intent claude ws new <moniker>` and add a row here in the same commit.

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
