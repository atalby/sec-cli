---
name: adopt-persona
description: "Use when a task naturally decomposes along multiple distinct domains (e.g. infra provisioning + cross-repo security audit + documentation currency) and this project has an opted-in governance pack defining a persona taxonomy. Documents the generic mechanism for dispatching an isolated subagent/session per persona with a real system prompt and a clean handoff contract — not the persona list itself, which stays project-specific."
---

# Adopting a Persona for a Subtask

This is a mechanism, not a persona list. `AGENTS.md` §1.1 core defines
no personas of its own — check this project's `ADAPTERS.md` for an
opted-in governance pack (e.g. `packs/solo-founder-governance`) before
assuming any persona taxonomy applies here at all. No pack, no
personas: this skill doesn't apply.

## 1. Confirm the task actually decomposes along persona lines

Don't force-fit a single-domain task into a persona. This mechanism is
for genuinely cross-domain work — a change that needs infra
provisioning judgment *and* a security/quality audit *and* documentation
currency review is a real fit; a one-file bug fix is not.

## 2. Dispatch one isolated subagent/session per persona

Use whatever isolated subagent or parallel-session primitive your own
tool provides (a subagent-spawning tool, a background/parallel session,
a fresh CLI invocation with its own context) — this skill is
deliberately silent on which one, because it must work the same way
regardless of which agent tool is running it.

Seed each subagent with:
- The persona's exact system prompt, copied verbatim from the
  governance pack — never paraphrased. `packs/solo-founder-governance/PACK.md`'s
  own "Persona system prompts" section records exactly this failure
  mode: `skills/prompt-suite/SKILL.md` (now retired) held a paraphrased
  copy of these prompts and drifted stale, hardcoding a cost-figure
  `AGENTS.md` itself had already removed — a concrete number a
  paraphrase quietly baked in, that a verbatim copy never would have.
  Copy from the pack directly each time, not from memory of a prior
  copy.
- A bounded task description scoped to that persona's domain only.
- An explicit output/handoff contract: what the orchestrating session
  needs back (a finding, a diff, a go/no-go recommendation) and in
  what form.

## 3. Never let two personas' concerns blend into one session

If a single dispatched session starts doing work outside its assigned
persona's domain, that's the signal to stop and split it into a
second, separately-dispatched session — not to let it keep going
because it's already in context.

## 4. Attribute the work

If this project tracks per-persona activity via commit trailers (see
the `fleet-agent-coordination` skill's `Session-Persona` trailer
convention — check for `scripts/persona_scorecard.py` or equivalent),
tag any commit that session produces with `Session-Persona: <name>`
rather than leaving it indistinguishable from any other commit.

## 5. Report anything worth learning back

`AGENTS.md` §10's self-learning mandate (resolve a non-trivial bug,
receive an explicit correction, work around an undocumented hurdle →
synthesize a reusable procedure and persist it via
`self-learning-skill-synthesis`) applies to every agent operating
under this methodology, not just the dispatching session — but a
freshly-dispatched persona subagent's context starts empty and won't
necessarily surface a whole-file mandate buried in `AGENTS.md` §10 on
its own. Don't leave it to chance:

- **Dispatching session**: make this explicit in the handoff contract
  — ask the subagent to invoke `self-learning-skill-synthesis` itself
  before reporting back, if its dispatch actually hit the trigger
  (a real bug fixed, a correction received, an undocumented hurdle
  worked around) — not as a hypothetical, per that skill's own
  empirical-triggering rule.
- **Dispatched persona subagent**: if the trigger was actually hit
  during this dispatch, do it before reporting back — don't let
  knowledge gained mid-dispatch evaporate when the session ends.

## 6. Advisory vs. binding

A persona whose taxonomy entry describes it as advisory-only (e.g. a
"Master Auto-Moderator" reviewing via a CLI pass) stays advisory here
too — dispatching it doesn't upgrade its findings to a binding gate
unless a real CI job actually enforces them (`AGENTS.md` §3's
Auto-Moderation Protocol). Don't let the ceremony of dispatching a
subagent imply authority the taxonomy entry itself doesn't grant.
