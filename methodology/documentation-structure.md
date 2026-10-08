# Documentation Structure — full detail

> Detail module for `AGENTS.md` §5. Loaded on demand — see the Module
> Table at the top of `AGENTS.md`. This file is part of the adopter payload
> (`methodology/adoption.md`: "adopting Hyer means the full payload, not
> a hand-picked subset"), copied alongside `AGENTS.md` and `skills/`.
>
> `AGENTS.md` §5 core keeps the top-level "three kinds of knowledge"
> framing. This module carries the concrete mechanics for each kind.

## Rationale never shares a file with rule

There is a fourth kind of knowledge alongside the three `AGENTS.md` §5
names, and it is the one that quietly bloats a contract: **rationale**.
Why a rule exists, which incident produced it, what was tried first.

A human wants it. An agent pays for it on every read, in every adopting
repo, forever. So it lives in its own file and is never adopter payload:
in this hub that file is `METHODOLOGY.md`, "Why Hyer looks the way it
does", and it is the human companion to `AGENTS.md`. The contract states
the rule; that file carries the reasoning. Neither is generated from the
other, because rationale is not derivable from a rule and a rule is not
derivable from rationale. They are disjoint content, not two views of
the same content, which is why they cannot drift apart the way two
copies of one fact do.

**The test, so this stays checkable rather than a matter of taste**:
delete the paragraph and ask whether any agent behaviour changes. If
nothing changes, it is rationale and belongs in the companion file. If
behaviour changes, it is a rule and stays in the contract, in exactly
one wording that both audiences read.

Do not write a "human edition" and an "agent edition" of the same rule.
Two editions of one rule are two rules, and they will disagree. This
repo has been bitten by hand-maintained duplication repeatedly (frozen
pre-commit forks, one regex living in two files, adopters at stale
versions); the answer is one copy of each rule plus a separate file for
the reasoning, not a second copy of everything.

## The narrative-history file, concretely

Don't let this become one ever-growing file that every session reads
in full — that recreates the exact problem this rule exists to
prevent, just delayed. Structure it as:

- A short **current-state summary** at the top — a few sentences: what
  was just done, what's next, nothing more. This is what a new session
  actually reads by default.
- **Dated archive files** holding the full narrative for each period,
  linked from the summary. Nothing gets deleted or shortened — the full
  detail stays fully available and searchable, just not force-loaded by
  default.

**Keeping the summary honest is the hard part, not writing it once**
(see `METHODOLOGY.md#measured-not-assumed-the-boot-sequence-had-a-real-cost`).
Three things make it actually happen instead of silently rotting:

1. **Make the update mechanical, not judgment-based.** "Update the
   summary paragraph, append one dated line to this period's archive
   file" is cheap enough that skipping it costs more than doing it.
   "Update the docs if relevant" invites skipping.
2. **Attach it to step 6 (Document) of the core development loop, in
   the same unit of work as step 7's commit** — not a separate ritual.
   Piggyback on a habit already being followed reliably, don't invent a
   new one that nothing enforces.
3. **Treat a contradiction as a signal, not noise.** If step 1
   (Ground) ever turns up a fact that contradicts what the summary
   claims, that's the summary drifting — fix it as part of that task's
   documentation step, don't work around it and leave it stale for the
   next session too.

## The Declared Doc Set Rule (Product & Platform tiers)

For any non-trivial feature or architectural change in a Product- or
Platform-tier repo (§1.0), implementation and the repo's companion
documents must be updated in the same unit of work.

**Which documents is a per-project fact**, declared in `ADAPTERS.md`
under "Declared doc set": the code scope that triggers the rule, and the
companion documents that must move with it. A repo that declares nothing
gets the historical pair, a technical architecture doc and a wiki, so
declaring is only needed to change the set. This rule was formerly
"3-Way Sync", which hardcoded those two filenames into a contract that
carries no project-specific fact; some repos need a fourth document, and
some have neither.

**A document belongs in the set only if a commit could plausibly change
code without touching it.** A file that changes on nearly every commit
discharges the rule for free. This stays a judgment on purpose: it is a
counterfactual, and the one mechanical proxy tried -- how much of a
document is duplicated elsewhere -- ranked a healthy architecture doc as
worse than a 37 KB narrative blob.

**An update must name what changed.** A companion-doc edit discharges the
rule only if one of its added lines names something the commit changed,
such as a changed file. Before this, any byte in a qualifying file
satisfied the gate, and a single wiki cell grew to 37 KB one appended
clause at a time. This is a floor, not a grader: a lazy but truthful line
naming the file still passes.

A document that does not exist is not required unless the set declares
it; declaring a document is the assertion that it should exist.

Personal-infra tier repos use their own equivalent (a durable-state doc +
narrative history) per §1.0, and should say so in `ADAPTERS.md` with
`_Not applicable: <reason>_` rather than leaving the section blank.

## Cross-Project Documentation Mirror (optional)

If an ecosystem has adopted an external documentation hub (e.g.
Confluence, Notion, an internal wiki-of-wikis) to aggregate multiple
projects' documentation for human readers: that hub **mirrors** each
project's durable docs one-way — it is never the place new decisions get
authored, and per-repo docs remain the actual source of truth. Two-way
sync (or worse, writing there first) creates exactly the two-sources-of-
truth problem this section exists to prevent. §1.1 core defines no
personas of its own; a project that has opted into a governance pack
naming a Documentation Curator persona (see e.g.
`packs/solo-founder-governance/PACK.md`, if adopted) uses that binding
for who is responsible for this once real automation exists — absent
that, it's an open responsibility, not assigned anywhere by core.
