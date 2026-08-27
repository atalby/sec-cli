---
name: engineering-loop
description: "Use for any non-trivial implementation task — a new feature, a bug fix touching more than a couple files, wiring in a third-party tool or service, or anything where being wrong costs real rework. Walks ground → research → plan → implement → verify → document → commit as an explicit sequence instead of jumping straight to code. If the project has an AGENTS.md, that file's Identity/Philosophy and Documentation Structure sections take precedence over this skill's generic placeholders — this skill is the loop, AGENTS.md is the project-specific content that fills it."
---

# Engineering Loop

The reusable procedure behind `AGENTS.md`'s §3 "Core Development Loop" —
extracted so it's invoked consistently instead of re-derived from
reading prose each time. See the `engineering-methodology` repo's
`METHODOLOGY.md` and wiki `Retrospective` page for the real incidents
that produced each step; this file is the "what to do," those are the
"why."

Calibrate ceremony to *risk*, not line count. A one-line change to
shared infrastructure deserves more of this than a hundred-line change
to an isolated module. For genuinely trivial changes (typo fixes,
single-line obvious corrections), skip straight to implementing —
this loop is for everything else.

**This skill is deliberately tech- and language-agnostic — it's the
process, not the mechanics.** It does not know this project's test
command, lint command, coverage tool, build system, or code-style
conventions, and it shouldn't be forked or rewritten per project or
language to add them. That's what this project's own `AGENTS.md` is
for. Before step 5 in particular, check `AGENTS.md` (or equivalent) for
the actual verification commands — "run the full test suite" means
something concrete and different in a Python repo (`pytest`), a Go repo
(`go test ./...`), or a Terraform repo (`terraform validate`/`plan`),
and that specificity belongs in the project's own doc, not duplicated
or reforked into a copy of this skill.

## 1. Ground

Before designing anything, verify current-state facts with real
citations — exact file and line, not memory, not what a doc *claims*,
not assumption. If the investigation is large, delegate it (a
sub-agent, a search), but insist on citations back, not a summary you
can't independently check.

## 2. Research the tool, before configuring it

If this task wires in a third-party CLI, library, or service: read its
actual source, CLI reference, or config schema for the *exact* surface
being used, before writing any config against it. Don't infer behavior
from what a README promises or what seems reasonable. This step alone
prevents the most expensive class of integration bug — the one that
only shows up once the real system runs it for real.

## 3. Plan

For anything matching this skill's trigger conditions: write a concrete
design to a durable, reviewable location. State what you verified in
step 1, the design, and how you'll know it worked. Get explicit
approval before implementing. A plan that turns out to be wrong once
implementation starts is cheap to discard; code that turns out to be
wrong is not.

## 4. Implement

Small, independently coherent units — not one batch at the end. Each
unit should be something that could be reviewed, tested, and reverted
on its own.

## 5. Verify

Check `AGENTS.md` for this project's actual test/lint/coverage
commands first — the steps below are the shape of what to do, not the
literal commands to run. In order, don't stop at the cheap ones:

- Local tests passing is *necessary, not sufficient*.
- Run the **full** test suite after any change to shared or global
  state, not just the tests you think are affected.
- **If a trigger is supposed to cause a consequence** (a merge triggers
  a release, an approval triggers a resume, a webhook triggers a
  notification) — **verify the consequence happened, independently.**
  Never let the trigger's own "succeeded" status stand in for proof
  that what it was supposed to cause actually did. This is the single
  most commonly skipped step and the one most worth not skipping.
- For infrastructure or integration work, verify against the real
  target system at least once — real CI, a real external API, a real
  deployed instance — before calling it done.

## 6. Document

Update the durable-knowledge doc if system state changed. Record what
was learned honestly, including what *didn't* work — a sanitized
success narrative is worse than no narrative, because it's trusted and
wrong.

If the narrative-history doc uses a current-state-summary-plus-archive
structure (see `AGENTS.md` §5): overwrite the summary's paragraph and
next-step pointer — replace, don't append — and append one dated entry
to the current period's archive file. Do this now, in the same unit of
work as the change, not as a deferred follow-up. A stale summary
misleads the next session more than no summary at all.

## 7. Commit

Small, often, pushed immediately. One commit per independently coherent
unit, never a whole task batched into one. Never `--amend` a previous
commit for follow-up work.

## Before calling it done

- [ ] Full suite green, not just touched files
- [ ] Any trigger→consequence relationship independently verified
- [ ] Real target system exercised at least once, if applicable
- [ ] Durable-knowledge docs updated if state changed
- [ ] Committed in small units, already pushed

## A blast-radius rule that applies throughout

If a blocker at any step would require a broader scope, higher-risk
action, or bigger blast radius than what was actually approved — stop
and ask. Never silently substitute something riskier to route around
an obstacle, even if it would technically work. If a live credential
appears anywhere along the way, store it securely immediately and never
redisplay it.
