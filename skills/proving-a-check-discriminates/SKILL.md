---
name: proving-a-check-discriminates
description: Use when a gate, verifier, guard or alert has been seen in only one verdict — red for weeks, never red at all, or reporting "unverifiable" — and before trusting a newly written one. Prove it returns green on an explicit healthy subject and red on an explicit defective one, that its own inputs are present, and that a run which could not be evaluated cannot trigger a retry, re-send or delete.
---

# Prove a Check Discriminates Before You Trust It

A check earns trust by answering differently for a healthy subject and
a broken one. Until both answers have been observed, the check is not a
check; it is a sentence in the shape of a check.

The dangerous verdict is not the obvious false one. It is the red
produced by the check's own input surface rather than by the condition
it claims to judge: a path that did not resolve, a variable that was
unset, a directory that came up empty, an id compared in two spellings.
That verdict is indistinguishable from a real finding, so it is either
ignored ("known red") or acted on ("queue it again"). Both outcomes are
worse than having no check, because the cost is paid and the signal is
not.

## The procedure

1. **Name both subjects before touching the predicate.** One healthy
   subject that must pass, and one subject carrying exactly the defect
   the check claims to detect. Write the exact command and inputs for
   each. If you cannot construct the defective subject, stop here: that
   inability is the finding, not a reason to trust the check anyway.

2. **Run both and keep both transcripts.** Green from the healthy
   subject, red from the defective one, with the message naming the
   defect you introduced. A red that came from a typo, a missing
   binary, an empty directory or a misquoted flag is a red for your
   harness, not for the condition. Fix the input and re-run; if the red
   disappears, the check was grading its own inputs.

3. **Grade the inputs before the verdict.** State what the check needs
   to be evaluable at all, and assert it explicitly: the file exists,
   the directory has entries, the id parsed, the command was found.
   Then carry three outcomes, not two: satisfied, violated, and
   not-evaluated. Not-evaluated is never "failed"; give it its own
   exit code or verdict word and make it loud.

4. **Normalise at one boundary, on both sides.** Comparison failures
   are usually representation failures. Put both values through the
   same function before comparing: strip a `sha256:` prefix, resolve
   absolute against relative, follow a symlink to its target, map a
   service alias to its unit name. Two spellings of the same value must
   compare equal, and the test that pins this should use a real pair.

5. **Put legitimate exceptions in declared data, and check the
   declaration.** An exception belongs in an allowlist or declaration
   file with a reason, never in a widened predicate. Then check the
   declaration itself: a declared name with no matching subject is a
   finding, or the declaration quietly becomes a mute switch that
   outlives its reason.

6. **Gate the consequences on a real verdict.** Retry-queue entry,
   re-send, drain, delete, deploy: none of them may fire on
   not-evaluated. If a run could not be evaluated, the correct effect
   is zero side effects plus a visible complaint. This is the step that
   turns a bad check from an annoyance into an incident.

7. **Treat a one-verdict check as a finding.** A check that has only
   ever been red for weeks, or only ever green, is itself the defect.
   Record the last date both verdicts were observed on real subjects;
   "unknown" is an item to file, not a pass.

## Run it against a check you already own

The procedure is three runs against a throwaway tree, and it takes
minutes. Any check that takes a path works:

```sh
work=$(mktemp -d)
mkdir -p "$work/healthy"
# populate the smallest tree the check needs
<check> "$work/healthy"          # 1. must pass
cp -R "$work/healthy" "$work/broken"
# introduce exactly the defect the check claims to detect
<check> "$work/broken"           # 2. must fail, naming that defect
rm -rf "$work/broken/required-input"
<check> "$work/broken"           # 3. must report not-evaluated
```

Three runs, three different verdicts. If run 2 passes, the predicate
does not test what it claims. If run 3 reports a failure, the check
cannot tell a missing input from a real defect. If run 1 fails, the
check has never been green and no red it produces means anything yet.

Then keep the evidence: the two subjects and their expected verdicts
belong in the check's own test suite, so a later edit that reintroduces
an input-derived verdict fails a test instead of shipping.

## Two ways the failure hides

**The success line is unreachable.** A verifier can be written so that
its own pass condition cannot occur while a known, accepted exception
exists — a service unsupervised by design, awaiting an owner decision.
It then reports "not fully in place" about something nobody can action.
The fix is a declaration for the accepted exception, and the wording
that names the stake: a check that stays red for an unactionable reason
stops being read, which is worse than not having it.

**The guard is correct about a world that changed.** A name check that
refused unless a window carried a fixed name kept refusing after
another script renamed that window; the refusal ran for weeks as one
line in a log. The tempting fix is to widen the name check. The better
question is whether the action needed that guard at all — in that case
the action was deleted instead.

## Empirical origin, 2026-10-20

Four checks in one operator's tooling, each measured, each fixed:

- A session-brief sender without an explicit repo argument left its
  verification directory empty, so "was the brief typed" returned no
  answer and the send reported "typed but NOT found" on four of four
  sends that had in fact landed — then queued each one for a drain that
  would have typed a second copy. Fixed twice: the fallback learned the
  pane's own directory, and "no verification surface" became its own
  outcome that queues nothing already typed.
- A running-image verifier compared a bare hex id against the same id
  carrying a `sha256:` prefix. The equality never fired, so a correct
  install read "provenance unverifiable (not disproven)". That line was
  an acceptance criterion that had been read many times and never once
  executed.
- A supervision verifier exited non-zero because one service was
  unsupervised by design and awaiting an owner decision, making its own
  success line unreachable. The fix added a declaration file, and its
  follow-up: the declaration is checked too, so a declared name with no
  matching running unit is a finding.
- A poke refused to type unless a window's name matched a constant,
  but a restart script had renamed that window. It refused on every run
  for weeks. Fixed by deleting the poke, not by widening the check.

## Related

`diagnose-a-noisy-check` is the mirror. That skill handles a check
that fires on nearly every event — replay its predicate over history to
tell a wrong predicate from a real finding. This skill handles a check
that can never fire, or can never pass. Both reduce to one question:
has this predicate been observed in both states on real subjects? Ask
it before tuning, and before trusting.
