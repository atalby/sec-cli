---
name: fleet-master-charter
description: Use when standing up or running the per-host control plane that starts, supervises and drives a host's concurrent agent sessions (the fleet master), or when deciding whether a host needs one at all -- as opposed to a single session coordinating with peers, or electing one integrator within a repo. The model is in methodology/fleet.md; this is how to charter and run the role.
---

# Fleet Master Charter

The fleet master is the per-host control plane for a fleet of concurrent
agent sessions. The model -- the two roles, the invariants, the profile
split -- is `methodology/fleet.md`; read it first. This skill is the
charter: what the role is *for*, what it must not do, and the order in
which it does its job. The mechanics of talking on the bus are
`fleet-agent-coordination`; the mechanics of leading and owning scopes
are `fleet-leader-election`.

This skill applies when a *host* is being given a master, not when one
session is coordinating with peers and not when a repo needs one
integrator. Those are the two skills above.

## 1. One per host, and it owns no code

There is exactly one live fleet master per host. Before chartering one,
prove no live master already holds the host (ask the bus, read the
ledger); a second master is the split-brain failure the term fence exists
to prevent, and starting one by hand is the most common way to cause it.

The fleet master owns the *fleet* and zero product code. If you find
yourself editing a lane's files, stop: you have drifted into a lane
master's work. The roles are separate authorities held by separate
sessions on purpose.

## 2. Bind the profile before driving anything

A fleet master is useless without the per-machine binding. Before it
drives a session, its profile (`profiles/<machine>.md`, modelled on
`profiles/_generic/PROFILE_TEMPLATE.md`) must name the real bus client,
the session-workspace start/stop/list commands, the workspace root, and
the host-preference order. Bind from the profile and `ADAPTERS.md`; never
hardcode a bus endpoint or a host name into a script that ships.

## 3. What the master does, in order

1. **Reconcile the roster.** Read the ledger's live members and their
   terms; ask the bus who is present. A member the ledger believes live
   but the bus does not is a dead scope to re-dispatch (section 5).
2. **Hold or win leadership.** If no master is live, run the
   deterministic, non-preemptive election (`fleet-leader-election` §2).
   As sitting master, fence every message against the current term
   (§1) and ignore below-term traffic.
3. **Drive the never-park loop.** For each lane master, keep exactly one
   next unit in flight. A lane parked at a prompt with work left is the
   defect the master exists to remove; hand it the next unit
   (`methodology/proactive-next-action.md`). An instruction sent is not a
   unit done: reading what the lane actually did, and driving the step
   after it, is `fleet-supervision`.
4. **Keep the ledger.** Single-writer, atomic, git-ignored
   (`fleet-leader-election` §5). Members hold no durable state of their
   own.
5. **Supervise.** A live session is not a working session: confirm each
   lane master is progressing on *its own* repo, using its enabled tools,
   and not merely keeping a pane alive. Watch for a near-full context
   that has started to hallucinate, and for a lane failing on a mystery
   error that a live pane hides. How to tell progress from liveness, and
   what you owe a peer who asks you something, is `fleet-supervision`.
6. **Integrate nothing.** Merging a lane's work is the lane master's act
   (`fleet-leader-election` §8), not the fleet master's.

## 4. Growing and shrinking the fleet

Grow only onto a claimed, disjoint scope and only up to the host's cap:
adding a member that would touch an owned scope is a collision, not
scaling. Shrink only gracefully -- hand off the scope, get an
acknowledgement, let the member finish or park, stop it, and remove its
workspace only once its work is merged. Never remove a member that still
holds unmerged work (`fleet-leader-election` §9).

## 5. Dead scopes, and the honesty rule

A member silent past the health timeout is unreachable: release its scope
and make it available again. Being slow is not being dead, which is why
the threshold is an explicit timeout, not "hasn't spoken this tick".

And the master above all else does not lie. Every status it reports
states how it was verified or is labelled unverified; a negative claim
("no open work", "the lane is idle") needs its own check before it is
asserted. If the master finds that a record it relied on is false, that
is a DANGER ZONE stop (`methodology/fleet.md` §9): stop, record the
finding as a tracked item, surface it, then continue -- never quietly
patch it and move on.
