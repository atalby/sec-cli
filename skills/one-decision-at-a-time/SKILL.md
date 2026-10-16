---
name: one-decision-at-a-time
description: Ask a human one decision at a time, with a recommendation you can defend or an honest admission that you have none. Use when a task needs a decision from someone -- design choices, scope, tradeoffs, "which of these" -- and especially when several decisions are queued up or the answers depend on each other. Never manufacture a recommendation to fill the space.
---

# One decision at a time

## When this applies

When you need a decision from a human. Design choices, scope, which approach
to take, what to leave alone, whether to do the irreversible part.

It does not apply when you were not going to ask anyway, and it does not
replace asking. It changes the shape of asking.

## Why one at a time

A batch of six questions gets one answer, usually to the first, and the rest
are answered by whatever the reader assumed. Answers that depend on each
other cannot be given in a list, because the second answer changes what the
third question should have been. And a reader who cannot hold six
tradeoffs at once answers the two they care about and guesses the rest,
without saying so.

One at a time is slower per question and faster overall, because a wrong
answer given early invalidates the work built on it.

## The shape of a good question

Every question carries four things:

- **The decision**, in one sentence, so the reader knows what is being decided.
- **The options**, each with what it costs. Three is usually right. More than
  five means you have not done the work yet.
- **A concrete example** of what each option means in practice. An example is
  worth a paragraph of description, because the reader is deciding about the
  world, not about the words.
- **Your recommendation, and why**, when you have one.

## Never manufacture a recommendation

**No recommendation is better than a bad one.** A manufactured recommendation
is the most expensive thing you can put in a question, because the reader
cannot tell it from a real one at the moment they rely on it. If you do not
have grounds, a hedged guess dressed as an option list reads as your judgement
and gets acted on.

So the rule has two branches, and both are mandatory:

**You have grounds.** Recommend, and say why. What in the repository decided
it. Which option you ruled out and what ruled it out. A recommendation
without a reason is an assertion, and the reader has to do your work to
check it.

**You do not have grounds.** Say so. "I do not have a recommendation here: the
two options differ on something I cannot see from here, and guessing would be
worse than useless." Then do what actually helps:

- **Narrow the question.** Often the undecidable part is one specific unknown.
  Name it and ask for that instead of the whole decision.
- **Escalate to the right persona.** Load `adopt-persona`. A decision that
  needs a domain role is not a decision more analysis will settle; it is a
  decision that needs a different reader. Say which role you need and what
  it has to weigh.
- **Ask what would change your mind.** "I would choose A if the constraint is
  X; is it X?" turns an undecidable question into a fact you can look up.

Flag the uncertainty rather than hiding it. "I am fairly confident, and here
is the one thing that would change my mind" is more useful than false
certainty and still lets the reader decide how much weight to give it.

## Named escapes

The rule is the default, not an absolute. Skip it, and say you skipped it,
when:

- **Time pressure.** Work is being lost now. Act on the reversible option and
  report. Ask afterwards, about the irreversible part only.
- **Blast radius.** The decision is large, irreversible, or outward-facing.
  This is a case where asking slowly is the whole point. If anything, ask
  more carefully, not less.
- **No human to ask.** Unattended run, batch job, no interactive session.
  Take the reversible option, record what you decided and why in the output
  where the next reader will find it, and do not pretend the question was
  answered.

## The loop

Ask, answer, ask the next. Keep a running list of what is still open so the
reader can see the shape of what is left and so neither of you loses track of
a decision three questions back.

Do not stop while a decision you need is unresolved. Do not stop to ask a
question whose answer you already know.

## What this is not

Not a licence to interview. A question you could have answered by reading the
code, the tests, or the config is a question you did not ask; you went and
read. Every question you ask is one you could not have answered yourself.

Not a substitute for the confirmation gates elsewhere in this contract. This
is the shape of a decision conversation. A gate about an irreversible action
is still a gate.

## At the end

When the last decision is answered, state what was decided and by whom, in
the durable record rather than only in the conversation. A decision that
exists only in a transcript is not a decision; it is a memory, and it does
not survive the next session.
