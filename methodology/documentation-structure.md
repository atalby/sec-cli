# Documentation Structure — full detail

> Detail module for `AGENTS.md` §5. Loaded on demand — see the module
> table in `AGENTS.md` §0. This file is part of the adopter payload
> (§0: "adopting Hyer means the full payload, not a hand-picked
> subset"), copied alongside `AGENTS.md` and `skills/`.
>
> `AGENTS.md` §5 core keeps the top-level "three kinds of knowledge"
> framing. This module carries the concrete mechanics for each kind.

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

## The 3-Way Synchronized Release Rule (Product & Platform tiers)

For any non-trivial feature or architectural change in a Product- or
Platform-tier repo (§1.0), documentation and implementation must be
updated simultaneously in the exact same unit of work:
1. **Implementation Code**: Source code files under `src/` or core
   modules.
2. **Technical Architecture Doc**: System layout and contracts.
3. **Master Wiki / Knowledge Base**: Higher-level domain documentation.

No PR or release is complete if code changes drift from the architecture
doc or the wiki.

Personal-infra tier repos use their own equivalent (a durable-state doc +
narrative history) per §1.0, not this 3-file structure.

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
