---
name: self-learning-skill-synthesis
description: Turn a resolved bug, an explicit correction, or an undocumented hurdle into a durable procedure, and offer it to the fleet when it is general enough. Use when something non-trivial went wrong and cost time, when a human corrects you, or when you solve something the repository did not document. Does not fire on routine work, and does not fire on a hypothetical.
---

# Self-learning and skill synthesis

## What this is for

Two failures this prevents. The first is the same problem being solved
wrong in the same repository every few weeks, by an agent that never heard
how it was solved last time. The second is a procedure that one repository
learns well and forty others never see, because the store it was written to
belongs to one repository.

Synthesis is the first fix. Sharing is the second. Both are in scope here,
because a procedure that cannot leave the repository it was learned in has
not been synthesised, only written down.

## When this fires, and when it does not

Fires on three triggers, all of them empirical:

- A non-trivial bug was resolved, and the wrong path to it was the obvious
  one. The cost was real time or a real mistake.
- A human explicitly corrected you. This is the strongest trigger and the
  easiest to skip, because it feels like a conversation rather than an event.
  It is an event: the model of the task was wrong, and you are holding the
  corrected model now.
- An undocumented API, build, or tooling hurdle was crossed, and the answer
  exists nowhere in the repository.

Does not fire on routine work, on a first-attempt success, or on anything
hypothetical. **A skill written for a problem you have not hit is a guess
wearing a procedure's clothes**, and it will be loaded later by an agent who
cannot tell it was never tested. An empirical trigger is required, and if you
cannot name the incident, there is no skill.

## The four phases

**One: name the incident.** What went wrong, what it cost, and what the
repository said or failed to say. Write this down before anything else; it
is the evidence, and a skill whose evidence cannot be stated is a skill whose
scope cannot be bounded.

**Two: extract the procedure.** Not the story. The procedure is what a
reader does, in what order, and what tells them they have got it wrong.
Strip everything specific to the incident except what is genuinely part of
the procedure.

**Three: write it as a skill.** Frontmatter with a `name` matching its
directory and a `description` that names the trigger, so an agent knows when
to load it. The description is what makes it discoverable, so it must carry
the trigger condition and not a summary of the content.

**Four: verify it.** Load it in a fresh context on a real instance of the
incident. A skill that has never been followed by an agent other than its
author has not been tested. If you cannot run that verification, say so in
the skill rather than implying it was tested.

## The substitution test, before anything leaves the repository

The question is whether the procedure is about *this* repository or about
*work like this*. Apply the substitution test:

> Replace every path, filename, service, and tool name with a placeholder.
> Is the procedure still executable by an agent that has never seen this
> repository?

If yes, it is general and worth proposing. If what survives is "run the
project's own migration script", it is not; it is a fact about one
repository wearing a procedure's clothes.

Where a specific name is genuinely load-bearing, keep it but mark it as the
one thing to substitute, with a sentence saying what varies.

## How a proposal travels

**A proposal is an issue, not a push.** It is filed against the hub with the
skill inline: the trigger, the procedure, the verification you ran, and the
substitution-test result. It is never pushed into shared payload by the agent
that learned it.

**Promotion is a human decision.** A person reads the proposal and either
promotes it into payload, declines it, or asks for changes. This is not a
formality and it is not slow: a procedure promoted without review reaches
every adopting repository, and a bad procedure is worse than a missing one,
because it is followed.

**The same store is not the only store.** A repository keeps whatever is
specific to it, forever, with no obligation to propose anything. Sharing is
offered, not required, and a repository that never proposes is working
correctly.

## What this is not

Not a licence to write a skill for everything that went slightly wrong. The
empirical trigger is the gate, and it is strict on purpose: a store full of
unused skills is a store nobody reads, which is worse than an empty one
because it looks populated.

Not a licence to widen a procedure while generalising it. If making it
general required adding a hedge, the honest version is narrower and stays
local.

Not self-modification. An agent writes into its repository's store and files
a proposal. It does not edit the payload every other repository installs.
