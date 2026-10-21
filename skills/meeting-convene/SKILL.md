---
name: meeting-convene
description: Use when several concurrent agent sessions must resolve something together in a single synchronous exchange -- a decision that spans lanes, a shared blocker, a design call -- and the answer must be one agreed outcome rather than a sequence of independent replies. Covers the request, prepare, notify, run, report cycle and the generic terms it binds per machine.
---

# Meeting Convene

Sometimes a fleet must decide something *together*, in one bounded
exchange, rather than each member replying on its own time. That is a
meeting, and this is the procedure for convening one. It is the
companion to the fleet master's charter (`fleet-master-charter`) and a
specialised use of the bus (`fleet-agent-coordination`); the model it
serves is `methodology/fleet.md`.

The terms below are deliberately generic. The concrete tool each one
binds to is per-machine fact, in that machine's profile
(`profiles/<machine>.md`) and `ADAPTERS.md`, never in this skill.

## 1. The generic register

- **convener** — the session that calls the meeting (usually the fleet
  master for the host).
- **participants** — the sessions whose input the outcome needs; a
  bounded set, named up front.
- **harness** — whatever runs a participant session.
- **session-workspace** — the workspace a participant is running in.
- **agent-channel** — the bus the convener notifies participants on.
- **supervisor** — the authority for the scope the meeting decides.
  The convener reports to it; a meeting does not grant authority it does
  not have.

## 2. Request

State the meeting before calling it. A meeting without a written request
is an interrupt. The request names: the one question to decide, the
participants, the deadline, and what a valid outcome looks like. If the
question is not decidable in one exchange, it is not one meeting — split
it, or make it an `ask` on the bus (`methodology/fleet.md` §4) instead.

## 3. Prepare

Before any participant is touched, the convener does the grounding the
meeting will otherwise waste everyone's time on: gather the current
facts, the options actually on the table, and the constraint that
decides between them. Distribute these with the request so participants
start from shared evidence, not from their own local guess about state.

## 4. Notify

Send each participant the request and the prepared material over the
agent-channel. Notification is not delivery (`fleet-agent-coordination`
§2): the convener confirms each participant is present before it relies
on them, and a participant that cannot attend is noted as absent in the
report rather than assumed to have agreed.

## 5. Run

Hold the exchange to the one written question. The convener's jobs are to
keep each participant's contribution to the question at hand, to surface
disagreement rather than smoothing it, and to close only on an outcome
the supervisor for that scope can actually ratify. A meeting that ends
"we discussed it" has not happened; it ends on a decision, or on an
explicit "undecided, because ...".

## 6. Report

The outcome is durable, not a private exchange that dies with the
sessions. The convener writes the report: the question, who attended and
who did not, the decision, the dissent (if any), and the next action with
its owner. Where the decision changes a rule rather than a task, it
enters the propose-approve-persist loop (`methodology/fleet.md` §7) at
the scope it belongs to — `core` if it is true for every fleet,
`profile:<name>` if it is true only for this machine.

## 7. Failing closed

If the convener cannot reach the participants, or the supervisor cannot
ratify, the meeting fails closed: the outcome is "not convened", reported
as such, and the question is escalated to the supervisor — never resolved
by the convener alone on the participants' behalf. A decision made by an
absent quorum is the meeting-shaped version of a lie.
