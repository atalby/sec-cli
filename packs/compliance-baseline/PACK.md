# Pack: compliance-baseline

Pack version: v1.0.0

## What this is — and is NOT

A starting engineering-process checklist for a Product-tier repo that
serves customers and has (or is pursuing) real compliance obligations —
SOC2, GDPR, HIPAA, or similar. **This is not legal or compliance
advice, and adopting it does not make a project compliant with
anything.** Real certification (a SOC2 audit), legal determinations
(whether a specific incident is GDPR-reportable), and binding
agreements (a DPA with a customer or processor) require a real
auditor and/or lawyer — this pack scopes to what an engineering
process can mechanically own and hand to that professional, not a
replacement for them.

`AGENTS.md` core takes no position on compliance regimes at all — this
is one concrete instantiation a project opts into via its own
`ADAPTERS.md`, same mechanism as every other pack.

## 1. Audit logging

- Every mutating action on customer/tenant data (create, update,
  delete, export, permission change, login, denied-access attempt)
  gets a log entry: who, what, when, from where.
- The log itself is append-only — no `UPDATE`/`DELETE` grant on the
  audit table for the application's own database role, or an
  object-lock/WORM-backed store if using one. Verify this is actually
  enforced (a schema permission check, not just a written intention),
  not merely assumed from the ORM's model design.
- Access to the audit log itself is logged — who viewed it, when.
- **Retention period is a real, project-specific fact — do not
  hardcode one here.** Record the actual period this project commits
  to in `ADAPTERS.md` (see below); common baselines (SOC2 ~12mo
  auditor-expected minimum, HIPAA 6yr, SOX 7yr+) are starting
  reference points, not defaults to copy without checking which
  regime actually applies.

## 2. Data retention & PII minimization

- Collect only what a specific, currently-real purpose needs — no
  speculative "might need it later" fields on customer/PII data.
- Every PII-bearing data category gets an explicit retention/deletion
  timeline, recorded in `ADAPTERS.md`, not left implicit.
- Review retained PII periodically (a real, calendared cadence — not
  "eventually") and delete what's no longer justified by an active
  purpose.

## 3. Breach-response procedure (stub — escalation only)

This is an internal escalation path, not a legal filing procedure:

1. Whoever discovers a suspected breach escalates immediately to the
   project's designated approver (see `ADAPTERS.md` / an opted-in
   governance pack) — do not wait for full technical certainty first.
2. The designated approver determines whether real legal/compliance
   counsel needs to be engaged, and whether any regulatory clock has
   started (e.g. GDPR's 72-hour authority-notification window, if
   personal data of EU/UK data subjects is involved — an example of
   why speed matters, not a determination this pack makes for you).
3. Document the incident internally regardless of whether it turns
   out to be reportable — facts, effects, and remedial action taken.
   GDPR requires this documentation even for breaches assessed as
   not requiring notification.
4. The actual notification decision and filing, if any, is made by
   real legal/compliance counsel, not inferred from this checklist.

## 4. `ADAPTERS.md` binding

Add a section like this to a project's own `ADAPTERS.md` to record its
actual compliance posture — this pack ships no defaults for any of
these, because they're real facts specific to one org and one
regulatory footprint:

```markdown
## Compliance posture

- **Applicable regime(s)**: [e.g. "SOC2 Type II (Security +
  Availability)", "GDPR (EU/UK customers)", "none currently"]
- **Real accountable contact**: [who, if a breach or audit inquiry
  comes in — may differ from the general designated approver]
- **Audit log location & retention**: [where it actually lives, actual
  retention period committed to]
- **Legal/compliance counsel**: [firm/contact, if engaged]
```
