# Pack: human-team-coordination

Pack version: v1.0.0

## What this is

Mechanics for how multiple HUMANS on a team coordinate with each
other and with the agent sessions they're each directing — pairing,
on-call, incident postmortems, and resolving conflicts between
concurrent sessions touching overlapping code. Distinct from the
code-level review gate (`AGENTS.md` §3 step 7), which is about a
single change's own merge gate, not standing team process.
`AGENTS.md` core defines none of this — genuinely varies by team size,
timezone spread, and org culture.

## 1. Pairing

- No universal cadence prescribed here — record your team's actual
  convention in `ADAPTERS.md` (ad hoc, scheduled rotation, none).
- When pairing on agent-directed work, one human drives the
  conversation with the agent at a time — two humans simultaneously
  steering the same session produces contradictory instructions the
  agent can't reconcile.

## 2. On-call & escalation

- Record the real rotation and escalation path in `ADAPTERS.md` — who
  is on call, how they're paged, and who's next if they don't respond.
- An agent session that hits something matching `AGENTS.md` §3's
  Breach Protocol escalation criteria (a real spend alert, a session
  visibly out of scope) escalates to the on-call contact if one is
  configured, not just the general designated approver, when the two
  differ.

## 3. Incident postmortems

- Blameless by convention: the review is of the system and process
  that allowed an incident, not of the individual (human or agent
  session) that triggered it — matches Hyer's own existing
  ethos (`AGENTS.md` §3 step 6: "record what didn't work... a
  sanitized success narrative is worse than no narrative").
- A postmortem for an incident an agent session was directly involved
  in includes that session's own account, not just a human's
  reconstruction after the fact — the session's real transcript is
  usually still available and cheaper than reconstructing intent from
  logs alone.
- Record where postmortems actually live (a doc, a tracker template)
  in `ADAPTERS.md` — this pack doesn't prescribe a specific tool.

## 4. Conflict resolution — concurrent sessions on overlapping code

The one piece of this pack grounded in mechanisms that already exist
elsewhere in Hyer, not invented fresh:

- **Real branch protection is the actual backstop**, not agent
  discipline alone — a protected trunk that requires review before
  merge (already covered, §3 step 7) means two concurrent sessions'
  conflicting changes surface as a real merge conflict or review
  comment, not a silent overwrite.
- If this project has a cross-session coordination channel configured
  (see `ADAPTERS.md`'s "Cross-session communication" section, or the
  `fleet-agent-coordination` skill if adopted), a session about to
  touch a file another live session has recently touched checks for
  conflicts *before* starting, rather than discovering them at merge
  time — cheaper to resolve as a conversation between two sessions
  than as a merge conflict between two humans who weren't in the loop.
- Never resolve a conflict by silently discarding the other session's
  work — surface it to a human, the same "stop and ask" discipline
  `AGENTS.md` §6 already requires for any action beyond what was
  actually approved.

## `ADAPTERS.md` binding

```markdown
## Team coordination

- **Pairing convention**: [e.g. "ad hoc, no fixed cadence"]
- **On-call rotation & escalation**: [tool/schedule, or "N/A — solo"]
- **Postmortem location**: [e.g. "docs/postmortems/, one file per incident"]
- **Cross-session coordination**: [see also "Cross-session
  communication" section above, if configured]
```
