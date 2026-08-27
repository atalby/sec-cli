---
name: roadmap-reconciliation
description: "Use when auditing existing docs, git history, or prior conversations for feature ideas or open questions that were discussed but never filed as trackable issues — e.g. 'is there anything in our docs/history that isn't captured as an issue?' Reconciles a corpus of prose against the real issue tracker and applies a consistent checklist to decide, per candidate: file it now, hold it for a go/no-go decision, or drop it because it isn't an engineering decision at all. Distinct from AGENTS.md §4's reactive 'file it the moment you write it' rule, which covers new TODOs as they're introduced — this skill covers a retroactive sweep of an existing corpus."
---

# Roadmap Reconciliation

The reusable procedure for turning "we probably talked about this
somewhere but it's not tracked" into a decision, applied consistently
instead of re-derived ad hoc each time this comes up. Extracted from a
real run (Adopter-Product-1, 2026-08-23) that improvised this twice in one
session — once for the search, once for the vetting — with no
checklist to follow either time.

**This skill is deliberately tech- and project-agnostic.** It doesn't
know this project's tracker, doc layout, or policy packs — that's what
`ADAPTERS.md` and this project's own `AGENTS.md` (or equivalent) are
for.

## 1. Search

Look past current file state — a discussed idea is often edited out or
superseded before it's ever filed:

- All prose docs (READMEs, durable-state docs, narrative-history
  archives, design specs) for feature-idea or open-question language.
- Full git log, including content that was later removed
  (`git log -S"<keyword>"` / `git log --all -p -- <path>` style
  searches, not just the current diff).
- Branch history, if branches outlive their PRs in this project.

## 2. Cross-reference

Check every candidate against the real issue tracker (per
`ADAPTERS.md`'s named tool, all states — open and closed, so a
resolved or deliberately-rejected idea isn't re-filed as new). Don't
rely on memory of what "sounds like" it's already tracked; query it.

## 3. Decide, per candidate

Apply this checklist — the same one every time, so a re-run next
quarter reaches the same kind of answer, not a differently-reasoned
one:

1. **Tier/scope fit** (`AGENTS.md` §1.0, §1.2) — does this make sense
   as this repo's tier of work, or is it drift into something the repo
   isn't?
2. **Laser Task Focus actionability** (§1.2) — is this a closeable,
   issue-shaped unit right now, or a vague aspiration that needs a Plan
   (§3) before it's even issue-shaped?
3. **Cost-awareness** (§1 circuit-breakers, and any opted-in
   cost/infra pack per `ADAPTERS.md`) — does building this introduce a
   new paid API, always-on infra, or anything that breaks
   scale-to-zero?
4. **HITL/sign-off tripwires** (§3 step 3, §6) — does filing or
   eventually building this cross an explicit tripwire (new recurring
   automation, new spend, production access)?
5. **Not an engineering decision at all** — is this actually a
   business, legal, product-strategy, or pricing decision wearing a
   feature-idea costume (a business-model pivot, a new revenue
   vertical, a legal/licensing question, a marketing idea)? If so, it
   does not become an engineering issue — surface it to the project's
   designated approver as a decision to make, not a ticket to file.
   §3/§6 as written cover *operational* HITL gates (prod deploys,
   schema migrations) but not this category; naming it explicitly here
   closes that gap.
6. **Backlog hygiene**, for the *existing* open backlog encountered
   along the way (not just new candidates) — flag anything stale,
   duplicated, or already contradicted by what the code now does.

## 4. Outcome, per candidate

Sort into exactly one of three buckets and say which:

- **File as-is** — clean, actionable, no flags from step 3.
- **Hold for a go/no-go decision** — flag *what* decision is needed
  (usually cost/infra) and who makes it; don't file it as a normal
  issue until that's resolved.
- **Drop entirely** — record why (usually category 5 above) without
  creating a tracker item; surface it in the report instead.

## 5. Report before filing anything irreversible

Summarize the outcome distribution and the reasoning per bucket before
filing issues. Filing itself is low-risk and reversible (an issue can
be closed), so this isn't a hard stop the way a production action
would be — but a wrong bucket call compounds if several ideas get
mis-filed in the same pass, so a quick human skim of the bucketing
before the filing step catches that cheaply.
