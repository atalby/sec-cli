---
name: jev-decision-support
description: "Use when a decision needs a typed, confidence-scored proposal before a human decides -- persona or skill selection, tripwire radar, roadmap file-hold-drop, or a go/no-go score. The advisory intention layer, its three primitives, and the escalation inversion that keeps every low-confidence call with the human."
---

# JEV Decision Support

An advisory intention layer for decisions this contract already asks a
human to make. It sharpens a proposal; it never makes one. Nothing here
is wired into a gate. Proposal and rationale: issue #155.

The layer wraps a hosted decision model that answers with typed
primitives -- Choice, Score and Boolean -- each carrying a confidence,
returned in roughly 70 to 500 milliseconds. It produces no natural
language reasoning and cannot explain itself. The vendor claims about
67.8% accuracy and that number is not independently validated, so treat
it as a claim about the vendor, not a property of your decisions.

## Why it is advisory and never a gate

AGENTS.md section 1 settles this: models provide non-deterministic
intent, and infrastructure plus deterministic software contracts enforce
inviolable boundaries. A model that cannot explain itself belongs on the
intent side of that line. Handing it a boundary inverts the philosophy
and removes the auditable why that the durable docs exist to record.

Section 3's tripwires are prose-only by deliberate design. Asking such a
model whether something is a schedule, a webhook or a retry loop would
convert a judgement a human is meant to make into a boolean nobody can
audit.

## The escalation inversion

The vendor's documented pattern is confidence routing: act on high
confidence, escalate on low. This methodology inverts it, because it is
Human-Driven.

| Model output | What happens |
|---|---|
| low confidence | escalates to the human, always |
| high confidence | sharpens the proposal; the human still approves |

A high-confidence answer never auto-execute. It buys a better-shaped
question, nothing more. Approval lands with the project's designated
approver exactly as it would without this layer.

## The three primitives

| Primitive | Carries | Used for |
|---|---|---|
| Choice | one option from a closed set, with a confidence | persona or skill selection, roadmap file-hold-drop |
| Score | a numeric judgement, with a confidence | go/no-go gates, effort ranking |
| Boolean | true or false, with a confidence | tripwire radar -- does this look like a repeat-acting thing |

Each answer is advisory input to a human decision. None of them is a
verdict, and none of them is a boundary.

## Where it attaches

Two points in the core loop, both before a human decides:

1. Boot sequence: as a pre-filter over persona and skill selection, so
   the agent arrives with a shortlist rather than a blank page.
2. Ground step: as a tripwire radar and a roadmap sorter, feeding the
   planning conversation that a person still has to approve.

It never attaches to a step that blocks or permits a commit, a deploy or
a credential action.

## The honest limit

The model cannot explain itself, so nothing here can be audited the way
a gate is audited. That is precisely why it is confined to the intention
side. If a decision needs a defensible why in the durable record, ask the
model for an option and then write the reason yourself.

## Enabling it per project

The layer is off unless a project opts in. A project that does not
declare it does not load the skill, and the methodology is unchanged for
that project.

The switch is a project fact, so it lives in the adopter's `ADAPTERS.md`
-- the governance surface this contract already uses for opted-in packs
and for the persona taxonomy a project binds (AGENTS.md section 0 and
section 1.1). The hub defines the mechanism and the contract; what a
given project opts into is that project's declaration, made and recorded
in its own adapter file rather than in the hub or in an ad hoc local
file. A project that declares the opt-in there loads the layer; one that
declares nothing, or declares a refusal, does not -- and either way the
methodology is unchanged for it.

## Credentials and cost

The model is a hosted service. Credentials follow the rules in
`methodology/credentials.md`: the key lives in the vault and is resolved
at the moment of use, never in a file, never in a committed config,
never in a log. Calls cost money and add latency, so it is a pre-filter
on decisions a person is already making, not a step in a hot loop.

## When not to use it

Skip the layer when the decision is already deterministic, when the
answer would need to be defensible in the durable record, or when the
project has not opted in. An agent that cannot reach the service simply
proceeds without it; the absence of a proposal is never a reason to stop.
