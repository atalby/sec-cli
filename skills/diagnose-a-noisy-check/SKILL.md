---
name: diagnose-a-noisy-check
description: Use when a lint, gate, advisory or alert fires too often to be read, and someone proposes muting it, raising a threshold, budgeting its warnings, or deleting it. Replay the predicate over real history ordered by event before changing anything; an average fire rate cannot tell a wrong predicate from a real finding.
---

# Diagnose a Noisy Check Before You Change It

A check that fires almost every time gets ignored, which is the same
outcome as deleting it but with the cost still paid. The reflex is to
turn the volume down: raise a threshold, budget the warnings, sample
them, drop the check. Every one of those assumes the check is right and
merely loud. Often it is simply wrong, and the volume is the symptom.

**Do not tune a check you have not replayed.**

## The procedure

1. **Separate the predicate from the policy.** Write down, in one
   sentence each, what the check claims to detect and what it does when
   it detects it. Noise is a property of the first. Blocking versus
   advisory is the second. Fixing the second to compensate for the first
   is how a real finding gets muted.

2. **Replay the predicate over real history.** Recompute the check's
   inputs for the last N real events, exactly as it would have seen
   them, and record a fire or no-fire per event. Not a sample, and not
   a fresh run: the inputs it had at the time.

3. **Read the result ordered by event, never as an average.** This is
   the step that decides everything and the one people skip. An average
   answers "how loud", which is not a question worth asking.
   - **Fires spread evenly across all events** means the predicate is
     keyed on something every event has. It is measuring a property of
     the environment, not a defect. Fix the predicate.
   - **Fires clustered, then stopping at an identifiable event** means
     the predicate tracks a real condition that was genuinely true and
     then genuinely got fixed. Leave it alone.

4. **Compare candidate predicates on the same replay.** Round numbers
   look reasonable in isolation and collapse on contact with data.
   Prefer a window or a boundary that an existing rule already names
   over one you invent, and be able to say which rule.

5. **State the sensitivity you are giving up.** Any predicate change
   trades false positives for false negatives. Write down the case that
   will now be missed, and confirm the original failure the check was
   built for still fires. If it no longer does, you have removed the
   check while appearing to fix it.

## Two counter-signals worth naming

**The check may be right and in the wrong place.** Before tuning the
predicate, confirm the check should be running here at all. A gate that
enforces one repository's properties, running in repositories that
cannot satisfy them, produces perfect-looking findings that are all
false. Ask what artifacts the check names and whether they exist where
it runs.

**A threshold over findings is almost never the fix.** A budget on a
check that fires only on a confirmed defect converts a gate into a
suggestion, and spending the budget is its intended use, so nothing
detects the abuse. Thresholds belong on checks that did not run, not on
checks that found something.

## Empirical origin, 2026-09-11, issue #90

A pre-commit advisory fired on 22 of the last 24 relevant commits. The
proposal on the table was a tolerance threshold over advisory counts.
Replaying the predicate showed its window was computed from a branch
fork point, which on the default branch does not exist, so the window
silently collapsed and the check's own documented allowance was
unreachable. The predicate was wrong, not loud.

The ordered reading is what settled the replacement. Averaged, the
candidate windows looked like a spectrum of fifty to ninety percent, a
difference of degree. Ordered by commit, the winning candidate's fires
were the first eleven commits of the cycle and stopped exactly at the
commit where the missing artifact first appeared. That is a difference
of kind, and no average would have shown it.

Grounding the same defect also surfaced that the check had no business
running in 30 of 33 consuming repositories, where it asked for files
that are never distributed to them.
