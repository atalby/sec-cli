---
name: fleet-agent-coordination
description: "Use ONLY if this project runs multiple concurrent AI agent sessions across repos that need to coordinate with each other (a fleet). Covers the fleet-agent-swarm message bus protocol and the Session-Persona commit-trailer convention. Most single-engineer, single-assistant setups do not need this skill at all — check ADAPTERS.md for a 'Cross-session communication' binding before assuming it applies."
---

# Fleet Agent Coordination

This is procedural knowledge for a specific, unusual setup: multiple AI
agent sessions, possibly across different host tools (Claude Code,
antigravity-cli, etc.), running concurrently across an ecosystem of
repos and needing to talk to each other. If that's not your setup, this
skill does not apply — most projects run one engineer per assistant
session with no fleet to coordinate.

Check the project's own `ADAPTERS.md` "Cross-session communication"
section first for the concrete tool binding (bus name, port, commands)
before following this skill — this skill covers the generic procedure,
`ADAPTERS.md` covers which real tool implements it here.

## 1. Always use the shared bus, never a host tool's built-in messaging

Even when a peer session happens to be reachable through your own host
tool's built-in cross-session messaging, use the shared bus instead —
a fleet that deliberately mixes host tools (some sessions on Claude
Code, others on a different CLI) needs one provider-agnostic channel,
not a different one per host. A host-specific tool cannot reach a
session running on a different host tool at all.

## 2. The bus is async, not guaranteed-live

Check the bus's own "unread messages" / "who's listening" query rather
than assuming a sent message was seen — nothing confirms a peer is
actively subscribed at send time. Treat every send as fire-and-forget
until you've independently confirmed receipt.

## 3. Broadcast-to-all reliability is unproven

If the bus offers an "all" or broadcast target, don't assume every
peer session actually received it — this has been an open, unverified
gap in at least one real fleet deployment. Confirm delivery to
specific peers individually when a message matters, rather than
trusting a broadcast alone.

## 4. Tag commits with a Session-Persona trailer

If this project tracks fleet-wide per-agent activity from commit
trailers (check for `scripts/persona_scorecard.py` or equivalent),
append `Session-Persona: <name>` to your commit messages — this is how
a commit gets attributed to a specific session/persona instead of
every commit in every repo being indistinguishable. See
`docs/ARCHITECTURE.md` (in a project that has one) for the exact
trailer format and what consumes it — this skill doesn't restate that
format to avoid a second place it can drift from.
