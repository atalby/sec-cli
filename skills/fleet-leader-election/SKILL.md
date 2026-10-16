---
name: fleet-leader-election
description: Use when several agent sessions (or workers) coordinate over a shared bus and exactly one must act as the authoritative integrator while the others work partitioned scopes -- in particular when leadership must survive the master session dying without split-brain, without flapping, and without a stale member reasserting a dead term. Covers the term fence, deterministic election, one-owner claims, sync-reply join, durable single-writer state, health, and serial integration.
---

# Fleet Leader Election

A procedure for running a fleet of peer sessions where exactly one member
-- the master -- is the single integrator to the shared branch, and every
other member owns a disjoint piece of work. It sits one layer above
`fleet-agent-coordination`: that skill covers how to talk on the bus and
how to treat what arrives; this one covers who leads, how leadership
moves, and how work is owned.

The whole design exists to make one question safe: what happens when the
master session dies mid-flight. The answer must be "the survivors elect a
new master and the work continues" -- not "two masters both integrate",
and not "the fleet flaps between candidates every few seconds".

## 1. The fence is a monotonic term

Leadership is an integer TERM that only ever increases. Every message a
member sends carries the sender's current term, and a receiver applies a
message only when its term is not below its own current state. Below, it
is dropped.

This is the entire split-brain guard, and it is worth being precise about
why: a member that was partitioned, or that woke from a stale checkpoint,
still holds an old term. When it rejoins and announces itself, its
messages are below the current term and are ignored, so it cannot reassert
a leadership that the rest of the fleet has already moved past. Without a
monotonically increasing fence, "the leader is whoever last spoke" lets a
slow straggler seize the fleet by speaking out of order.

## 2. Election is deterministic, and it does not preempt

A new election is needed when the current master is gone or has given up.
The winner is deterministic: among the live members, the one with the
lowest `(host_rank, member)` pair.

- `host_rank` is a configured host-preference order -- earlier means
  preferred, and an unknown host sorts last. A fleet of machines with
  different reliability or connectivity is expressed here, not in ad hoc
  tie-breaks.
- `member` is the tie-break, so two members on the same rank still resolve
  to exactly one winner.
- The new term is `max(seen terms) + 1`, never a reuse of an old one.

Because the ordering is total and the live set is known, there is exactly
one winner and no flapping: the same inputs always name the same master.
The subtle rule is non-preemption -- a preferred host that was offline and
comes back does NOT take leadership from a healthy sitting master. It only
wins at a natural election. Preemption is what produces the flap: the
returning host grabs the role, the old master keeps working for a moment,
and for that moment there are two integrators. A recovered preferred host
waits its turn; this is a deliberate trade of "the best host leads
immediately" for "there is never more than one master".

## 3. Work is partitioned into one-owner claims

The master does not hand out tasks from a central queue. Instead work is
divided into SCOPES, and a member owns a scope by CLAIM. A claim is
refused to any member that is not already the owner, and a release is
honoured only from the owner. One owner per scope is the invariant.

This is what lets members work in parallel without a scheduler: the
partition is the coordination, and a scope can be released and
re-dispatched when its owner is found dead (section 6).

## 4. Join by sync-reply, never by replaying the backlog

When a member joins, it does not reconstruct the world from the raw bus
history. It drains the pre-join backlog for liveness and diagnostics, then
learns term, master, claims and membership from the master's SYNC-REPLY.
Two members parsing the same old mail independently will disagree about
who owns what; a single authoritative snapshot cannot.

The rule to hold onto: backlog is not state. A message describing a claim
is evidence that an event happened, not the current ledger.

## 5. Durable state is single-writer and atomic

Coordination state lives in one file per repository, git-ignored, written
atomically (write a temp file, fsync it, then rename over the target), and
written by exactly one process: the master. Members keep no durable
coordination state of their own.

A single writer removes the write-write races outright, and the atomic
rename means a crash cannot leave a truncated state file that a reader
would parse as a real, half-written fleet.

## 6. Health is heartbeat freshness, and dead scopes are re-dispatched

The master tracks each member's last heartbeat. A member silent past a
timeout is unreachable: its scope is released and made available again.
Being slow is not the same as being dead, which is why the threshold is an
explicit timeout rather than "hasn't spoken since the last tick". The
master also tracks each member's branch cleanliness and last gate result,
so a member is not just alive but healthy.

## 7. Prove currency before a member works

Before a member does any work, prove its checkout is current against the
hub it follows (compare the version banner it carries to the hub's stable
tag). A stale checkout must not work: it would land a change written
against an old contract. Currency is checked at join and before dispatch,
not assumed.

## 8. Serial integration, one unit of lifecycle

Workers never push the integration branch. Each task gets one worktree and
one branch off current main; the worker pushes its branch. Only the
master integrates, and it does so serially: fetch, rebase the branch onto
main, run the full test suite and the project's release gate, merge, push.
The lifecycle closes in the same unit: gates green, integrate, remove the
worktree, delete the branch. No orphaned worktrees, no branch left open
after its work is on main.

## 9. Scale within a cap, and down only gracefully

Grow the fleet only up to a fixed cap and only onto a claimed, disjoint
scope -- adding a member that would touch an owned scope is not scaling,
it is a collision. Shrink only gracefully: hand off the scope, get an
acknowledgement, let the member finish or park, stop it, then remove its
worktree and branch if its work was merged. Never remove a member that
still holds unmerged work.

## 10. Doing it in this repository

`scripts/hyer/fleet.py` implements exactly the above over the hyer bus:
`FleetState`/`Member`, `host_rank`, `elect`, `resolve_master`, the
term-fenced `apply_envelope`, `claim_scope`/`release_scope`,
`sync_reply_payload`, `health_report`, atomic `load_state`/`save_state`,
and a CLI (`heartbeat`, `status`, `elect`, `health`, `sync`, `claim`,
`release`, `currency`). Durable state is `.hyer/fleet-state.json`, which
is git-ignored. `scripts/tests/test_hyer_fleet.py` pins each property
above. The reference protocol this was adopted from is dev-infra-fleet's
`orchestration.py`; read it before changing the rules here, because the
failure modes it encodes (fencing, non-preemption, one-owner claims) are
the reason the design looks the way it does.
