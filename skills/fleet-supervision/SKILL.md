---
name: fleet-supervision
description: "Use when directing another agent session's work rather than doing it yourself -- a master checking whether a lane it runs is actually progressing, or any session answering a peer's question. Covers the read/understand/verify/drive discipline: liveness is not progress, and a lane parked with work left is the defect to remove."
---

# Fleet Supervision (read, understand, verify, drive)

This is procedural knowledge for a specific role: you are responsible for
another agent session's work, and your job is to tell the difference
between a lane that is working and a lane that is merely running, then
to move it. The model is `methodology/fleet.md`. The charter for the
role -- what it is for, what it must not do, the order it works in -- is
`fleet-master-charter`; the bus mechanics are `fleet-agent-coordination`;
the leadership and scope mechanics are `fleet-leader-election`. This
skill is the supervision discipline itself.

Four moves, per lane, in order: **read**, **understand**, **verify**,
**drive**. Each is a gate on the next. Skipping one is the failure this
skill exists to prevent, and the two cheapest skips are the two that get
made:

- A live pane, a heartbeat, or a timestamp is not evidence of progress.
- A lane parked at a prompt with work left is not a lane at rest. It is
  the defect a supervisor exists to remove.

## 1. Read the actual work, never the liveness signal

Read, in this order:

1. The lane's tracker -- open items, and the newest comment on the one it
   is ostensibly on.
2. `git log --oneline -5` and `git status` in **its** repo, not in yours.
3. Only then the tail of its output, and only to find what it is waiting
   for.

If you cannot say which unit of work the lane last completed, you have
not read it. A session list showing every member live while nothing
advances is the normal shape of a stalled fleet, not a healthy one.

## 2. Understand by naming the unit of work

State it in one sentence: the issue, the files, the hypothesis.

> Lane N is on issue `#123`, editing these two files, and testing
> whether the gate fires on an empty input.

If that sentence needs hedging ("doing something with the tests"), keep
reading -- the hedge is the evidence. Distinguish a lane that is blocked
from a lane that is merely slow, and say which you believe and why,
because the two get different instructions.

## 3. Verify one load-bearing claim, yourself

Pick the claim the instruction you are about to send depends on, and
check that one yourself: run the test, read the commit, query the
tracker or the pipeline. Trust the artifact over the narrative. Not every
claim -- one, chosen for leverage, so that the next instruction rests on
something you saw rather than something a lane reported.

State how you verified it, or label it unverified. The honesty rule
applies to you before it applies to them (`fleet-master-charter` §5): a
negative claim -- "no open work", "the lane is idle" -- needs its own
check before you assert it, and a claim you cannot verify is reported as
unverified rather than smoothed over.

## 4. Drive with the informed next instruction, or escalate

Send the one next unit, and make it specific enough to act on: the issue,
the file, the approach, and the evidence you are relying on. The tracker
is the channel into a headless lane -- a lane with no prompt to type into
is still reachable, and that is where the instruction belongs.

If the next step needs a decision the lane cannot make -- a cross-repo
change, a credential, a runner, a scope claim that belongs to someone
else -- escalate it to the party who can decide, and say plainly that you
have. Do not leave the lane parked on a question you could have raised;
park it with its state recorded and its blocker named.

The same four moves are what you owe a peer who asks you something
(`fleet-agent-coordination` §4): read the question, work out what it
actually asks, verify the claim it rests on, then answer with the
evidence -- or say that you cannot and why. "I will look into it" with no
artifact attached is not an answer.

## 5. Supervision is not doing the work

You direct; you do not take over. Do not merge the lane's branch, do not
edit its files to unblock it, and do not accept the lane's own report as
the verification of its own work. Merging a lane's work is the lane's act
(`fleet-leader-election` §8) and a supervisor that starts writing code
has stopped supervising.

Equally: do not confuse an instruction sent with a result obtained. The
step is done when the consequence is observable -- the commit exists, the
gate passes, the tracker item closed -- not when you explained what to do.
