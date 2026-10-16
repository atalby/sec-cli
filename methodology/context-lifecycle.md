# Agent Context Lifecycle: Proactive Handoff + Restart

> Detail module for `AGENTS.md` §3. Loaded on demand — see the Module
> Table at the top of `AGENTS.md`. This file is part of the adopter payload
> (`methodology/adoption.md`: "adopting Hyer means the full payload, not
> a hand-picked subset"), copied alongside `AGENTS.md` and `skills/`.

Founder-requested 2026-10-10 (issue #293). Hyer already enforces
small, focused context (`skills/session-restart-handoff/SKILL.md`,
"reset context, don't replay it"). In practice an agent can still run
until its harness hits a hard MAX CONTEXT limit and fires an emergency
forced-compression — the exact failure that discipline exists to
prevent. Forced compression is reactive: it lands mid-task, blends
stale and active content, and risks loss or hallucination. This module
defines WHEN to restart; `session-restart-handoff` covers the mechanics.

## 1. The failure this prevents

Doing nothing is not neutral. Left to run to the ceiling, the harness
compresses the transcript under pressure, at a moment the agent did not
choose, in the middle of whatever it was doing. That is a lossy,
involuntary event, and it is exactly what a proactive restart exists to
avoid. The rule is therefore not "restart only when forced" but "restart
at a boundary you chose, while the context is still coherent."

## 2. Pre-limit signals (the trigger)

Treat any of these as the moment to hand off and restart — measured
before the ceiling, never at it:

- A long session has sprawled across several loosely-related findings
  that each deserve their own focused thread.
- A clean boundary has been reached (a release shipped, a fix merged and
  pushed, an investigation concluded) and the next unit is independent.
- The next step has moved into another session's or repo's domain — the
  work belongs where the problem lives, not where it was noticed.
- The context has grown large enough that stale and active content are
  already blending — the earliest honest sign the budget is near its
  soft threshold.

Not a fixed turn count or token number: the signals above are the
trigger, and they are meant to fire well before the harness ceiling.

## 3. The trigger is proactive, not reactive

Waiting for the harness to force a compression is the exact failure
this module exists to prevent (see §1). The moment one of §1's signals
holds, the agent performs the restart itself, on its own initiative,
rather than waiting to be told or waiting for the ceiling. Running to
the ceiling and then compressing is the thing being outlawed, not the
fallback.

## 4. Fleets restart their workers on a bounded loop

An agent that can start and stop other agents (a master or orchestrator)
manages context as a lifecycle for its whole fleet, not just itself. It
restarts its workers (master and slaves alike) on a bounded loop so that
each fresh agent context stays small and focused: a fresh context is
cheaper and less hallucination-prone than a long-lived one, and a worker
that has reached a clean scope boundary should hand off and restart
rather than accrete. This is the same discipline the sections above apply
to the orchestrator's own session, extended to the workers it owns. The
mechanics of the restart (persist, mark a resume point, clear context)
are the `session-restart-handoff` skill's; the orchestrator's job is to
schedule them at a boundary instead of waiting for a ceiling.

## 5. Context budget is a resource with a circuit-breaker

Treat the context budget exactly like the cost and rate budgets this
methodology already circuit-breaks (`methodology/tiers.md`, "Cost
Circuit-Breakers & Spend Safety"): act at a soft threshold, never at the
hard ceiling. The soft threshold is the pre-limit signal set in §1; the
hard ceiling is the harness's forced-compression point. Acting at the
soft threshold keeps the restart a deliberate, clean-boundary event;
waiting for the ceiling turns it into the reactive, mid-task emergency
this mandate exists to prevent. A context budget is not a mandate to
spend down to zero and then panic — it is a resource to hand off while
there is still room to persist state cleanly.

## 6. Relationship to existing payload

`session-restart-handoff` covers the mechanics of a restart: what to
persist, how to clean up, and how the next session discovers its own
resume point. This module is about WHEN — a proactive, threshold-driven
trigger, including the orchestrator-driven worker restarts above, so
that forced emergency compression never becomes the normal way context
ends.
