---
name: session-restart-handoff
description: "Use when a session has grown long, sprawled across several loosely-related findings, hit a clean boundary (a shipped release, a merged fix), or needs to hand off to a different session/repo's domain — and restarting with a fresh context is the right call. Covers what to persist before clearing, what to clean up, and how to make the fresh session's first prompt an actual resume point instead of a cold start."
---

# Session Restart Handoff

Restarting a session's context is not a memory-loss event if it's done
right — this methodology already keeps durable state (the issue
tracker, `WIKI.md`/`HISTORY.md`, commits) as the source of truth over
conversation memory (§4, §5). Restarting is safe exactly to the degree
that everything meaningful has actually been externalized to one of
those stores before the context is cleared, rather than living only in
the transcript.

## 1. Recognize the trigger

Not a fixed turn count or token budget — restart when any of these is
true: the session just hit a clean boundary (a release shipped, a fix
merged and pushed); the conversation has sprawled across multiple
loosely-related findings that each deserve their own focused thread;
or the next step has moved into a different session's or repo's actual
domain (e.g. an infra change that belongs to the repo owning that
infra, not the one that happened to notice the need for it).

## 2. Persist everything not-yet-durable, before clearing anything

The one rule that makes the rest of this safe: nothing that matters
should exist only in the conversation at the moment it's cleared.
Before restarting, write to the project's real durable store (an issue
comment, a commit, the relevant durable doc):
- Decisions actually made.
- Decisions still open, phrased as an actual question a fresh session
  could act on — not "discussed X" but "X needs a founder call between
  A and B, blocked on fact C."
- Any cross-repo/cross-session coordination the decision depends on.

**Prefer a live checkpoint tool over a hand-written tracker comment if
this project has one** (check `ADAPTERS.md` for a bound MCP server
exposing something like `submit_finding`/a dedicated checkpoint call) —
a structured write is less lossy than prose a fresh session has to
re-interpret. Fall back to a well-structured issue-tracker comment
otherwise; that's still a durable store, just a less structured one.
Either way, make it *discoverable without being named* — see step 5.

## 3. Clean up anything live the session spawned

Dangling subagents, monitors, or watches are session-level state, not
conversation-level — clearing the conversation doesn't stop them.
Before or immediately after restarting, enumerate what's still running
(a `ListAgents`-equivalent call) and stop anything no longer needed.
Idle isn't free forever, and a dangling agent nobody remembers spawning
is its own future confusion.

## 4. Reset context, don't replay it

Whatever your tool's equivalent of "clear this conversation's context"
is, that's the right move — not the equivalent of "reload a specific
past conversation's full transcript," which is the opposite of fresh
and will pull the exact sprawl you're trying to leave behind right
back in. (Claude Code specifically: `/clear`, never `/resume` on the
session you're trying to get away from — `/resume` is for the
deliberate case of wanting a specific past conversation back in full.)

## 5. The agent finds the resume point — never require the human to name it

**This is the part easiest to get backwards.** The whole reason durable
state exists is so a human doesn't have to remember or type out issue
numbers, comment links, or "what we were doing" — if a restart still
requires the human to compose that pointer from memory, the restart
procedure has just reintroduced the exact dependency on human memory
it exists to remove. "Resume", or nothing more specific than that, must
be enough.

For this to actually work, step 2's persisted state has to be
**discoverable without being named** — not just present somewhere in
the tracker. Concretely: mark whichever thread is the live, paused-
mid-discussion one distinctly from ordinary backlog (a label like
`active-resume-point`, or whatever this project's tracker supports) so
a freshly-restarted session can find *the* thing to resume, not just
*a* list of open issues to guess among. Apply it only to the thread
actually interrupted — not to every open issue — and remove it once
that thread is resolved or genuinely back to ordinary backlog, or it
stops meaning anything. Once issue #28-style tooling exists (a real
`get_last_checkpoint` call), that supersedes a label convention
entirely — this is the fallback for when it doesn't exist yet.

On being told to resume (with or without specifics), the agent's first
move is to find that marked thread itself — then **report back a
summary of what was happening and what it's about to resume before
continuing**, so the human is reoriented by the agent's own account
rather than needing to have retained it themselves. Resuming silently,
even correctly, defeats the purpose just as much as resuming wrong —
the human can't confirm "yes, that's right" against an action they
never saw stated.

## 6. Multi-session restarts: don't rely on the other side's memory

If a restart is happening because work is handing off to a different
session/repo (not just clearing your own context), each side persists
its *own* state independently before clearing — don't assume a
cross-session message you sent will still make sense to a peer that
also restarts. And afterward, always re-discover peers live rather
than reusing a pre-restart name or connection reference: a restarted
session is a new process as far as the fleet is concerned, and a stale
reference silently reaching an unattended session (or a *different*
session that picked up the same display name) is a real, already-seen
failure mode — see this project's own fleet-coordination discipline
(`AGENTS.md` §1's Zero-File Communication Mandate, and
`fleet-agent-coordination` if this project runs a multi-session fleet)
for why a remembered reference is never trusted over a fresh lookup.
