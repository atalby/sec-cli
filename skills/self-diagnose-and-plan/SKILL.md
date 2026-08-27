---
name: self-diagnose-and-plan
description: "Use at the start of a session, or whenever asked what's next / what to work on / for a status check — before starting any new implementation work. Grounds the session in this project's actual current state (tests, issue tracker, durable docs, ADAPTERS.md bindings) rather than assumption or memory, then proposes a ranked next action. Distinct from engineering-loop, which is invoked once a specific task has already been chosen — this skill is what decides which task, if any, is worth doing next."
---

# Self-Diagnosis & Next-Step Planning

The reusable procedure for starting a session honestly: verify what's
actually true before proposing what to do about it. Extracted so it's
invoked consistently instead of skipped when a session feels like it
already knows the state from a prior conversation or from memory.

**This skill is deliberately tech- and project-agnostic.** It doesn't
know this project's test command, its tracker, or its durable-doc
layout — that's what `ADAPTERS.md` and this project's own `AGENTS.md`
(or equivalent) are for. If this project has no `AGENTS.md`, use
whatever boot/onboarding convention it does have; the four steps below
still apply.

## 1. Ground

Follow this project's Boot Sequence (`AGENTS.md` §2, or this project's
equivalent onboarding doc):
- Check `ADAPTERS.md` for concrete tool bindings and any opted-in
  policy packs — use what it names, don't guess or fall back to a
  tool you've seen most often in training data.
- Read the durable-state doc's current-state summary (not the full
  history) for what's actually true about the system right now.
- Check the real issue tracker — not prose inside a markdown file —
  for what's currently open, and its actual state, not what you last
  remember it being.
- Run the existing test suite. Confirm you're building on a
  known-good baseline before touching anything.

## 2. Diagnose

Compare what the docs/tracker claim against what you can verify
directly: file contents, test results, tracker state, git log. Cite
exact files/lines/issue numbers, not memory or a prior summary. Flag
any contradiction between what a doc says and what you actually
found — a contradiction here is a signal the doc has drifted, not
noise to route around.

## 3. Report

Before implementing anything, report:
- Current state in 2-3 sentences, grounded in what you just checked
- Open items, ranked by urgency and blast radius — not tracker order,
  not creation order
- A recommended next action and why — including when the honest
  answer is "nothing urgent; here's what's queued and low-priority"
- Anything found that contradicts what a doc or prior summary claimed

## 4. Wait

Stop and wait for explicit go-ahead before starting implementation,
per this project's own plan-then-approve discipline (`AGENTS.md` §3
step 3, or equivalent). Diagnosis and planning are not authorization
to start building.

---

Once a specific task is chosen and approved, the `engineering-loop`
skill (if installed) takes over for actually executing it — this
skill's job ends at "here's what's next and why," not "how to build
it."
