---
name: adr-capture
description: "Use when an architectural decision between alternatives is reached during planning or implementation. Capture it as a structured ADR — Nygard-style context, decision, alternatives, and rationale — so future sessions understand why the codebase is shaped the way it is."
---

# ADR Capture

Architectural decisions made during a session and then forgotten are
decisions made twice. This skill captures them in a durable, searchable
format so that the next session — or the next human — does not have to
reverse-engineer why the code looks the way it does.

ADRs belong to `AGENTS.md`'s step 3 (Plan) of the core development
loop: the moment a design choice is made and approved, before
implementation begins. They are also durable state in the sense of
`AGENTS.md` section 5 — once written, they do not drift, they get
superseded when the context changes.

## When to activate

The skill fires when an architectural decision is reached, whether
explicitly requested or implicitly indicated. An architectural decision
is any choice between alternatives that constrains future work — not
variable naming or formatting, but framework selection, data model
design, API surface, deployment strategy, or security posture.

**Explicit signals**: the user says "record this as an ADR," "let's
capture that decision," or any variant of "ADR this."

**Implicit signals** (suggest recording, do not auto-create without
confirmation): concluding a comparison of two frameworks, settling a
schema design with stated rationale, choosing between architectural
patterns, selecting an auth strategy, or picking deployment
infrastructure after evaluating options.

## ADR format

Use the lightweight format proposed by Michael Nygard, adapted for
agent-assisted development:

```
# ADR-NNNN: [Decision Title]

**Date**: YYYY-MM-DD
**Status**: proposed | accepted | deprecated | superseded by ADR-NNNN
**Deciders**: [who was involved]

## Context

What is the issue motivating this decision or change?

[2-5 sentences: the situation, constraints, and forces at play]

## Decision

What is the change being proposed and/or done?

[1-3 sentences stating the decision clearly]

## Alternatives Considered

### Alternative 1: [Name]
- **Pros**: [benefits]
- **Cons**: [drawbacks]
- **Why not**: [specific reason this was rejected]

### Alternative 2: [Name]
- **Pros**: [benefits]
- **Cons**: [drawbacks]
- **Why not**: [specific reason this was rejected]

## Consequences

What becomes easier or more difficult because of this change?

### Positive
- [benefit 1]
- [benefit 2]

### Negative
- [trade-off 1]
- [trade-off 2]

### Risks
- [risk and mitigation]
```

Keep every ADR readable in under two minutes. If the context section
exceeds 10 lines, it is too long — tighten the framing.

## Directory structure

ADRs live in `docs/adr/`, one file per decision, with a README index:

```
docs/
  adr/
    README.md              <- index table of all ADRs
    0001-use-nextjs.md
    0002-postgres-over-mongo.md
    template.md            <- blank template for manual use
```

### Index format

The README maintains a single table for fast scanning:

```
# Architecture Decision Records

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [0001](0001-use-nextjs.md) | Use Next.js as frontend framework | accepted | 2026-01-15 |
| [0002](0002-postgres-over-mongo.md) | PostgreSQL over MongoDB | accepted | 2026-01-20 |
```

## Capturing a new ADR

1. **Initialize (first time only)** -- if `docs/adr/` does not exist,
   ask for confirmation before creating the directory, a README seeded
   with the index table header, and a blank `template.md`. Do not
   create files without explicit consent.
2. **Identify the decision** -- extract the core architectural choice
   from the conversation or planning session.
3. **Gather context** -- what problem prompted this? What constraints
   exist? Ground this in the same way `AGENTS.md` step 1 (Ground)
   grounds investigation: with real citations, not assumption.
4. **Document alternatives** -- what other options were considered and
   why were they rejected? If alternatives were not explicitly
   discussed, say so rather than fabricating them.
5. **State consequences** -- what trade-offs were accepted? What
   becomes easier or harder?
6. **Assign a number** -- scan existing ADRs in `docs/adr/` and
   increment from the highest number found.
7. **Confirm and write** -- present the draft ADR for review. Only
   write to `docs/adr/NNNN-decision-title.md` after explicit approval.
   If declined, discard the draft without writing files. This mirrors
   the confirmation-before-proceeding discipline of `AGENTS.md` step 3.
8. **Update the index** -- append the new entry to `docs/adr/README.md`.

## Reading existing ADRs

When asked "why did we choose X?":

1. If `docs/adr/` does not exist, report that no ADRs have been
   recorded and offer to start.
2. Scan the README index for relevant entries.
3. Read matching ADR files and present the Context and Decision
   sections.
4. If no match is found, say so and offer to record one.

## Lifecycle

An ADR moves through four states:

```
proposed -> accepted -> [deprecated | superseded by ADR-NNNN]
```

- **proposed**: under discussion, not yet committed.
- **accepted**: in effect and being followed.
- **deprecated**: no longer relevant (feature removed, context
  dissolved).
- **superseded**: a newer ADR replaces this one; the old file must
  link to the replacement.

When a decision is superseded, do not delete the old ADR. Mark it
deprecated or superseded and record the date, so that future sessions
can trace the history of a choice even after it is no longer active.
This is durable state: replacements are appended, originals are never
silently removed (see `AGENTS.md` section 5 on documentation
structure).

## Categories worth recording

| Category | Examples |
|----------|---------|
| Technology choices | Framework, language, database, cloud provider |
| Architecture patterns | Monolith vs microservices, event-driven, CQRS |
| API design | REST vs GraphQL, versioning strategy, auth mechanism |
| Data modeling | Schema design, normalization decisions, caching |
| Infrastructure | Deployment model, CI/CD pipeline, monitoring |
| Security | Auth strategy, encryption, secret management |
| Testing | Framework choice, coverage targets, test balance |
| Process | Branching strategy, review process, release cadence |

## Quality guidelines

**Do**:
- Be specific: "Use Prisma ORM" not "use an ORM."
- Record the why: the rationale matters more than the what.
- Include rejected alternatives: future sessions need to know what
  was considered.
- State consequences honestly: every decision has trade-offs.
- Use present tense: "We use X" not "We will use X."

**Do not**:
- Record trivial decisions: variable naming and formatting are not
  architectural.
- Write essays: keep context sections concise.
- Omit alternatives: "we just picked it" is not a valid rationale.
- Backfill without noting it: if recording a past decision, note the
  original date.
- Let ADRs go stale: superseded decisions must reference their
  replacement.

## Integration with the core loop

ADRs anchor to `AGENTS.md`'s core development loop:

- **Step 3 (Plan)**: when a plan includes an architectural choice
  between alternatives, capture that choice as an ADR before
  implementation begins. The ADR *is* the plan's durable record for
  that decision.
- **Step 6 (Document)**: if an implementation diverges from what the
  ADR specified, update or supersede the ADR in the same unit of work
  as the code change and the documentation update, not as a deferred
  follow-up.
- **Verification**: after an ADR is accepted and implemented, the
  verification step (`AGENTS.md` step 5) should confirm the decision
  was actually followed in the code. If it was not, the ADR is either
  wrong or the implementation is — either way, one of them needs
  fixing before calling it done.

ADRs are durable state per `AGENTS.md` section 5: they live alongside
the code, they are never appended to fix a mistake (replace the
statement), and they are superseded rather than deleted when context
changes.
