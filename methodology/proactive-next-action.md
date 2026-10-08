# Proactive Next-Action & Bounded-Autonomy Mandate

> Detail module for `AGENTS.md` §3. Loaded on demand — see the Module
> Table at the top of `AGENTS.md`. This file is part of the adopter payload
> (`methodology/adoption.md`: "adopting Hyer means the full payload, not
> a hand-picked subset"), copied alongside `AGENTS.md` and `skills/`.

Added v5.29.0, founder-requested (see
`docs/hyer/specs/2026-09-07-proactive-next-action-mandate-design.md`):
an agent should not simply stop once an explicit task is done — it
should propose the best next action, and, bounded, act on it if
unanswered. This is a narrow, bounded exception to §3's tripwire
list — it does not weaken that list; see §3 below for the boundary.

## 1. Trigger

End of a turn or session where no further explicit instruction is
queued — nothing left in the current ask, no outstanding question only
the founder (or this project's designated approver) can answer.

## 2. Mechanics

1. **Determine the best next action.** Check the issue tracker (§4 —
   never prose), any `active-resume-point`-labeled issue, and open
   backlog priority. Where this project has opted into a governance
   pack with a persona taxonomy (`ADAPTERS.md` / `packs/`), route the
   judgment through whichever persona's domain the top candidate falls
   under, per `skills/adopt-persona/SKILL.md` — the same dispatch logic
   §3 already uses for cross-domain work, applied proactively instead
   of only when asked.
2. **Propose, don't just act.** Present the recommendation via
   `AskUserQuestion`, with it pre-selected as the first option — not a
   new UI pattern, just a proactive trigger for one already in use.
3. **Bounded timeout auto-proceed**, harness permitting (§4).
4. **Git-flag the result** (§5) so an auto-decided commit is
   distinguishable from one taken with an explicit human yes.

## 3. The tripwire boundary (load-bearing)

This mandate does **not** touch `AGENTS.md` §3's existing tripwire
list. A candidate next-action that itself trips a tripwire — a
production/live-credential call, a new standing mechanism, cross-domain
governance-pack work, anything beyond an explicit yes already heard in
the conversation — is **never** eligible for timeout auto-proceed,
regardless of whether it is genuinely "the best next action." For such
a candidate, the question is asked plainly, with no pre-selected
default, and genuinely waits for an explicit reply no matter how long
that takes. Only a non-tripwired candidate — continuing backlog work,
git hygiene, non-destructive investigation, documentation currency —
is eligible for §2 step 3. A session cannot use this mandate to
self-clear the tripwire list by waiting out a timer.

## 4. Harness capability

Some harnesses expose an auto-answer timeout that implements step 2.3
directly — set the closest supported value to whatever reply window this
project's `ADAPTERS.md` records (there is no exact-minute granularity;
round down toward faster auto-proceed rather than silently rounding up,
and record which value was actually used and why in `ADAPTERS.md`, not
just "2 minutes" verbatim). On a harness without an equivalent
mechanism, step 2.2 still applies — propose the best next action — but
step 2.3 does not: no hard auto-continue, the agent proposes and waits.
**Known gap, not an unresearched one (2026-09-08, issue #64):** several
major harnesses offer only a binary interactive-vs-bypass-everything
choice with no timeout in between. None of them expose the "auto-answer
a specific unanswered prompt after N seconds" shape — this is a real,
tracked capability gap (see this project's own issue tracker for the
follow-up), not something to fake with a sleep-and-poll loop, and not
something to re-research from scratch next time this file is read —
re-check only when harness docs are known to have changed.

## 5. Git-flagging

Any commit produced from a timeout-driven auto-proceed carries a
trailer:

```
Agent-Decision: auto-selected (no reply within <timeout>)
```

alongside the existing `Session-Persona:` trailer
(`skills/fleet-agent-coordination/SKILL.md` §5) where this project
tracks persona activity. Where this project's git host supports merge
request / pull request labels, also apply an `agent-auto-decided` label
to any MR/PR produced this way, so it is visible in the MR/PR list view
without reading commit messages.
