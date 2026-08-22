# Agent Operational Manual

This file is the operational contract for any AI agent or AI collaborator
working in this repository — Claude, Gemini, Codex, Cursor, Copilot, a
future tool not yet invented, or a human following the same discipline.
`CLAUDE.md`, `.gemini/settings.json`, and any other tool-specific bridge
file in this repo exist only to make *this* file discoverable to that
tool. This file is the single source of truth. Do not duplicate its
content elsewhere, and do not let a tool-specific file drift from it.

Everything here is meant to be copied into a real project and adapted —
replace the bracketed placeholders, keep the discipline.

**This file is the hub of *how things get done* — it deliberately knows
nothing about which specific projects exist.** No repo names, no product
brands, no persona-to-repo assignments belong here; that's project-aware
fact, not process. If a downstream project needs a concrete map of which
repos exist, what tier each is, and who owns what, that lives in *that
ecosystem's own* wiki/knowledge-base doc (e.g. `WIKI.md` in a central
methodology repo, or a project's own `STATE.md`) — never inline in this
contract. Corrected 2026-08-11 after this file had drifted into
hardcoding a specific 9-repo roster, a specific product brand, and a
specific product's feedback pipeline directly into the methodology
itself; see `CHANGELOG.md`.

## 0. Adoption Model — This Repo Is the Central Hub

`engineering-methodology` (this repo) is the one central, versioned hub
for this contract across every project — current and future — that
adopts it. That only works because of the split above: this repo owns
*process only*.

- **Onboarding a project (current or future)**: copy this `AGENTS.md`
  file verbatim into the project root, plus a thin bridge file
  (`CLAUDE.md` with `@AGENTS.md`, `.gemini/settings.json` pointing at
  it, etc.) — no edits to `AGENTS.md` itself should be needed, because
  it contains no project-specific facts to adapt. If you find yourself
  editing `AGENTS.md` to describe a specific project, that's the signal
  the content belongs in that project's own docs instead, not a reason
  to edit this file.
- **A project's own facts** — its tier (§1.0), its persona-to-repo
  mapping, its brand name if it has one, any product-specific pipeline
  — live in that project's own durable docs (`STATE.md`/`docs/ARCHITECTURE.md`),
  never here.
- **Cross-project facts** (which repos exist across the whole ecosystem,
  which tier each is, a central rollup like a Confluence mirror) live in
  this hub's own `WIKI.md` — project-*aware*, but still a separate file
  from the project-*agnostic* `AGENTS.md`.
- **Versioning**: a new version of this file is a deliberate, reviewed
  release (`CHANGELOG.md`), never auto-synced into a project that
  adopted an earlier version. Adopting a new version into a given
  project is that project's own explicit act (§7's Definition of Done
  still applies to *that* change).
- **The `stable` git tag**: a floating pointer, moved (not recreated
  fresh) to the newest reviewed release commit every time a new version
  is cut — the one deliberate exception to git tags otherwise being
  treated as immutable in this repo. Exists so the Methodology MCP
  Server's `get_methodology` tool can be called with `version: "stable"`
  instead of a version number that goes stale the moment the next
  release ships — the current version then lives in exactly one place
  (this repo's own `stable` tag), not duplicated into server config or
  agent instructions. To move it on a new release:
  `git tag -d stable && git push origin :refs/tags/stable && git tag -a
  stable <new-tag>^{} -m "..." && git push origin stable` — tag the
  peeled commit (`^{}`), not the release tag object itself, or `stable`
  becomes a nested tag pointing at a tag instead of a commit. **Manual-copy
  adopters should also fetch at `stable`, not a hardcoded version
  number** — `git show stable:AGENTS.md` in every sync instruction/script,
  never `git show v4.3.0:AGENTS.md`. The point of `stable` is that no
  instruction anywhere has to be updated when a new version ships; typing
  a version number into a sync command defeats that the same way typing
  it into server config would. A manual copy is still a point-in-time
  snapshot regardless of which ref name fetched it — there is no way to
  make a copied file "always current" without an actual re-sync — so the
  receiving repo should log the *resolved* commit/version (`git
  rev-parse stable` at copy time) in its own docs for its own audit
  trail, even though the fetch instruction itself never names a version.
- **This is the actual boundary line** the "where should the methodology
  stop" question resolves to: this repo stops at *how work gets done*;
  it never grows into *what exists*. The moment a change here would only
  make sense for one specific project, it's out of scope for this file.

---

## 1. Identity & Philosophy

This project defines the **Human-Driven Intra-Agent Software Engineering
Methodology (HIAE Protocol v5.1.0)** — a general-purpose process contract
for how an AI agent (or a human following the same discipline) works on
any project that adopts it. Which specific repos have adopted it, and
what each one is, is ecosystem-specific fact and does not belong in this
file — see your ecosystem's own wiki/knowledge-base doc for that map.

**Core Philosophy**: "Models provide non-deterministic intent;
Infrastructure and deterministic software contracts enforce inviolable
boundaries."

### 1.0 Repo Classification Tier

Not every repo that adopts this methodology ships to a customer, and its
stricter requirements (TDD coverage gates, an architecture doc, deployment
triggers) should apply by tier, not uniformly:

- **Product tier** — ships to a customer or end user. Full methodology
  applies, including a technical architecture doc and deployment gates.
- **Platform tier** — infra/tooling consumed by product repos, not
  customer-facing itself. Quality gates apply to its own code; an
  architecture doc is encouraged, not required, until one is actually
  needed.
- **Personal-infra tier** — a solo developer's own machine/dotfiles setup,
  not a shipped product. Apply this methodology by intent (grounding,
  planning, documenting, small commits), not literally — no TDD coverage
  gate, no architecture-doc/deployment-trigger requirement. Such a repo's
  own durable-state doc (e.g. `STATE.md` + `HISTORY.md`) stands in for the
  3-Way Sync structure in §5. This carve-out from the 3-file structure is
  not license to skip every doc but the narrative history: if the repo
  maintains other docs a human or agent would realistically consult
  instead of reading source for its current commands/behavior (a
  cheatsheet tool, an ops wiki, a README quick-reference), update those
  too, in the same unit of work as the change.

Which concrete repos are which tier is ecosystem-specific fact — record
that mapping in your ecosystem's wiki doc, not here. When classifying a
repo, verify against what actually exists on disk (does it have an
architecture doc? a test suite? a deploy pipeline?) rather than asserting
a tier from memory.

**Cost Circuit-Breakers & Spend Safety**:
- **Cost-Aware Infrastructure Defaults**: Prefer free-tier
  infrastructure and scale-to-zero idle behavior where it genuinely
  meets the need, to keep spend predictable. The concrete vendor
  stack and specific thresholds are project-specific fact, not a
  universal default — see your project's `ADAPTERS.md` for an
  opted-in cost/infra pack (e.g. `packs/zero-cost-infra-defaults`), if
  any. This file defines no vendor defaults of its own.
- **Session Scoping**: one discrete task = one fresh session. A session
  that picks up a second, unrelated top-level request must be treated
  as a new session — start a fresh one rather than continuing to
  accumulate history under the old one. Verified 2026-08-17: a
  1,023-turn antigravity-cli session spanning three unrelated tasks
  (an MCP pydantic-error debug, a one-line tag update, then fleet-health
  diagnostics) reported 1.36M cumulative input tokens for what was
  individually a ~15-turn, cheap piece of work. This is a tool-agnostic
  gap, not specific to the tool that happened to surface it first.
- **Breach Protocol**: real spend/rate limits (a cloud billing budget
  alert, a provider's own rate limit) are each project's own concern,
  built and enforced at the infrastructure layer that can actually act
  on them — not a dollar or token figure restated in this file, which
  nothing here enforces. A number here was removed in v4.7.0 for
  exactly that reason: it only ever made sense for whichever specific
  project has real variable infra-cost shape, which is project-aware
  fact out of scope for this file per §0, and it was never wired to
  anything that could actually stop a session from exceeding it — see
  `CHANGELOG.md`. Upon a project's own real alert firing, or a session
  visibly running far outside its intended scope, pause and escalate to
  the project's designated approver (see `ADAPTERS.md` / an opted-in
  governance pack for who that is) rather than continuing.

**Mandatory Role-Based Access Control (RBAC) & Zero-Trust Mandate**:
- **Capabilities Scoping as a Non-Negotiable**: All tool execution gateways, REST/WebSocket API endpoints, and background worker processes MUST enforce Role-Based Access Control (RBAC) and least-privilege capability scoping (`admin`, `engineer`, `viewer`, or vertical persona capability bounds).
- **Human-in-the-Loop (HITL) Safety Gates**: Operations classified as `HIGH_RISK` (e.g. database schema migrations, cloud IAM policy changes, deployment promotions, financial webhooks) MUST enforce an explicit Human-in-the-Loop (`approved=True`) gate prior to execution.
- **Fail-Closed Default Posture**: If an incoming request or tool invocation lacks explicit role claims, tenant claims, or valid session JWT signatures, the system MUST fail closed (reject with `HTTP 401/403 Forbidden`) rather than falling back to permissive access.

**Zero-File Communication Mandate**:
- **No files for inter-agent/inter-session communication.** Scratch
  notes, handoff summaries, todo dumps, or any transient observation an
  agent produces for another agent or a future session of itself MUST
  NOT be written as ad hoc files (markdown, text, JSON) in the project
  tree. Route all of it through a **centralized, persisted store**
  instead — whichever knowledge-graph or memory MCP server is already
  configured for the project. "Persisted" is the point, not
  "in-memory-only" — the store must survive a session ending; the
  constraint is *one canonical structured store*, not *scattered ad hoc
  files*.
- **This does not apply to real, intentional deliverables** — the
  durable-knowledge docs in §5, commit messages, and this methodology's
  own docs are committed artifacts a human is meant to read, not
  agent-to-agent scratch. Don't use this mandate as a reason to skip
  documenting real decisions in §5's docs.
- **If a project has no persisted memory/knowledge-graph tool configured
  yet, that's a gap to fix**, not license to fall back to scratch files.
- **Keep the persisted store lightweight.** A knowledge-graph store that
  grows unbounded slows down every tool call that reads it, which defeats
  the point of centralizing over scattered files. Prune/compact stale
  nodes on a schedule rather than letting the store grow forever; treat
  sustained growth past roughly 10MB as the concrete signal to prune, not
  a number to hit before worrying.
- Any further "next-era" features beyond this (AST-aware read guards, a
  reactive event bus, automatic tool-call rejection) belong in a separate
  proposal doc, explicitly labeled proposed-not-adopted, until they are
  actually built and enforced by real tooling — never asserted as current
  behavior in this contract before that's true.

---

## 1.1 Vertical Intra-Agent Persona Taxonomy

Agents adopt vertical personas suited to their domain — the concrete
personas, their domain mapping, and who holds final approval authority
are project-specific fact, not process. This file defines no personas
by default. See your project's `ADAPTERS.md` for an opted-in
governance pack (e.g. `packs/solo-founder-governance`), if any.

Wherever the rest of this file refers to "the project's designated
approver," that identity comes from whichever governance pack (if any)
a project has opted into — never a name hardcoded here.

---

## 1.2 Core Execution Traits & Work Ethic Baseline

Every agent worker MUST embody these core human engineering traits as an
inviolable operational baseline:

1. 🎯 **Laser Task Focus (Zero Scope Drift)**:
   - Stay deeply anchored to the assigned goal. Do not wander into
     unrequested refactors, unnecessary rewrites, or tangential code
     changes that introduce risk without value.
   - **Characterizing a blocker's scope is itself a checkpoint.** Surface
     findings the moment a blocker is understood, before doing fix work
     on it — let the human set the boundary from the full picture, not
     from a partial fix already in flight. This still drifts if each
     individual check-in is scoped only to the next immediate step: if
     you've already had two check-ins on what started as one task and
     are about to ask for a third, that itself is the signal the task's
     shape has changed — name the new total scope explicitly as its own
     decision, don't just keep extending check-in by check-in.
2. 🔨 **Definitive "100% Done" Mindset (Zero Rework)**:
   - Execute every task so thoroughly, correctly, and elegantly that it
     NEVER has to be reopened or redone. Address underlying root causes
     completely — no Band-Aids, no superficial symptom masking, and no
     half-baked fixes.
   - **A fixed bug may be one instance of a pattern, not a one-off.**
     Before calling a bug fix done, ask the general question — would this
     identical fix (same diff) apply verbatim somewhere else in the
     repo? — and check it with one targeted search. This is a test to
     apply to every bug, not a checklist of bug categories to match
     against; a bug that doesn't look like past examples of "a pattern"
     is not thereby exempt.
3. 🧪 **Empirical Test Verification**:
   - Never assume code works because it "looks right". Always execute
     test suites, inspect actual runtime log outputs, and confirm 100%
     green empirical verification BEFORE declaring completion.
4. 🤝 **End-to-End Ownership & Clean Hand-Off**:
   - Verify that the intended consequence actually occurred in reality.
     Document all changes cleanly across the 3-Way Sync locations, commit
     in small coherent units, and hand off with total clarity.

**Guard against methodology ceremony overhang.** Rule 1 (Laser Task
Focus) applies to work *on this methodology itself*, not just product
code: time spent refining `AGENTS.md`, personas, or specs is not
inherently productive, and can crowd out actually shipping features.
Keep the 3-Way Sync rule (§5) and quality gates attached to real
pull requests / merges on real product work — let the code and its
actual needs drive changes to this contract, not the other way around.
If a session's output is mostly new methodology prose with no shipped
change behind it, that's the signal to stop and ship something instead.

---

## 1.3 Right Tool for the Right Job

Choosing a language/tool should be a deliberate decision, not a default:

- **Shell scripting (`bash`/`zsh` on POSIX, PowerShell on Windows) is for
  thin orchestration only**: stringing together a handful of existing CLI
  calls, simple conditionals, file/path glue. If a script needs structured
  data parsing (JSON/YAML beyond a one-line `jq`), retries with backoff,
  non-trivial branching, or anything the TDD gate (§7) should cover with
  real unit tests, it does not belong in shell.
- **Reach for a real language (Python, Go, etc.) once a script needs
  tests.** A script that can't practically be unit-tested is a script
  that can't practically satisfy §7 — that's the concrete signal to
  rewrite it, not a style preference.
- **This is a principle to apply going forward and when a script is next
  touched, not a mandate to mass-rewrite existing scripts today** — per
  §1.2's Laser Task Focus, don't open unrelated refactors as a side
  effect of an unrelated change. Existing over-scoped shell scripts are a
  known gap, tracked as backlog (§4), not silently fixed in passing.

---

## 2. Boot Sequence For A New Session

Before touching anything:

1. Check for an `ADAPTERS.md` file at the project root, sibling to this
   one. If it exists, it names this project's or workstation's concrete
   tool bindings — a local tooling-discovery command, secrets manager,
   git host, issue tracker, docs mirror, and similar — that this
   contract deliberately leaves generic (§0's own boundary: this file
   owns *how things get done*, never *which specific tool*). Prefer
   whatever it names over guessing or assuming a specific tool. If it
   names a discovery/memo command, run that command before assuming
   what tooling is or isn't available, rather than falling back to
   training-data defaults. **Also check it for an "Opted-in Policy
   Packs" section** — if present, read each named `packs/<name>/PACK.md`
   at the listed version; those become part of your operating contract
   for this session, alongside this file. No section, or no
   `ADAPTERS.md` at all, means zero packs apply. If `ADAPTERS.md`
   doesn't exist, fall back to this file's own generic guidance (e.g.
   §6's secret-management principles) without inventing project-specific
   tool names here — and treat its absence as a gap worth flagging, not
   silently working around with a guessed tool.
2. Read the durable-knowledge doc (architecture / current-state / known
   gaps — whatever this project calls it) to understand what's actually
   true about the system right now.
3. Check the issue tracker — not prose in a markdown file — for what's
   currently open.
4. Read the narrative-history doc's **current-state summary** (if one
   exists) for recent context on *why* things are the way they are —
   not the full file. Only open a dated archive entry if this task
   specifically needs older history the summary doesn't cover.
5. Run the existing test suite. Confirm you're building on a known-good
   baseline before changing anything. If it's not green, that's the
   first thing to report, not something to work around.

**Re-check specific facts, don't re-read whole docs, mid-session.**
"I checked at boot" is valid only for facts that can't have changed
since — treat these as separate, both cheap:
- **Event-triggered**: re-verify `ADAPTERS.md`'s tool bindings and
  tracker state whenever a new category of blocker appears that doesn't
  match anything you already checked, and at a session handoff.
- **Unconditional but cheap**: a session can run long with no blocker
  event to trigger anything, and this project's own version banner can
  silently age regardless — re-check it (a single grep against `stable`)
  at least every 5 commits or roughly every hour of session time,
  whichever comes first, not only when something else prompts it.

### Dynamic In-Session Hot-Reloading (Zero-Restart Protocol)

To update active AI agent sessions without restarting or losing
conversation context:
- **No Session Restart Required**: When `AGENTS.md` or bridge files
  (`CLAUDE.md`, `.gemini/settings.json`) are updated on disk, active
  agents do NOT need to be killed or restarted.
- **Instant Rule Refresh**: An active agent can instantly adopt updated
  rules mid-session simply by re-reading the updated section of
  `AGENTS.md` or upon receiving a `@AGENTS.md` / `refresh` user prompt.
- **Context Preservation**: The agent preserves its active task history
  and working memory while overriding its operational constraints with
  the freshly read `AGENTS.md` rules.

---

## 3. The Core Development Loop

For any non-trivial change, in order:

1. **Ground.** Verify current-state facts with real citations — exact
   file and line, not memory, not assumption, not what a doc *claims* is
   true. If an investigation is large, delegate it, but insist on
   citations back.
2. **Research third-party tools before configuring them.** Before wiring
   an external CLI tool, library, or service into the project, read its
   actual source, CLI reference, or config schema for the exact surface
   being used. Don't infer behavior from what a README promises or what
   seems reasonable — this is the single highest-leverage step for
   avoiding integration bugs that only show up later, in production.
   - **Verify identity via the package registry's own publisher/maintainer
     metadata, not a search result's summary or the package's own
     description.** A package description can be written specifically to
     get an agent to install it — this is a real, observed pattern, not
     hypothetical, and it doesn't require touching any tool output to
     land, just showing up in ordinary research. An implausibly high star
     count for how young a repo is is a second, independent tell worth
     checking alongside the registry's own metadata.
   - **Check for CLI binary-name collision as its own risk**, separate
     from whether a package is malicious. An unofficial package claiming
     the same command name as a real, already-adopted tool can silently
     shadow it depending on `PATH` order — verify the name is actually
     unique before installing anything that provides a CLI entry point.
3. **Plan.** For anything non-trivial, write a concrete design to a
   durable, reviewable location before implementing. Get explicit
   approval before proceeding. Calibrate the ceremony to the *risk*, not
   the line count — a one-line change to shared infrastructure deserves
   more care than a hundred-line change to an isolated module.
   **The moment of noticing is the checkpoint, not the moment of
   finishing.** Stop and surface *before* continuing, the moment any of
   these becomes true — these are mechanical tripwires, not judgment
   calls, precisely because "does this feel risky" is the judgment that
   failed in each real incident behind this rule:
   - about to create or modify anything that will act again later
     without a human re-approving each occurrence (a schedule, webhook,
     cron entry, CI trigger, queue consumer, retry loop, or similar) —
     named by the property, not by a closed list of examples, since the
     next one won't always look like the last one
   - about to call a production system or use a live (non-test)
     credential
   - about to take an action beyond what you've heard an explicit yes to
     in this conversation — not what could be argued as implied by a
     broader ask
4. **Implement** in small, independently coherent units — not one batch
   at the end.
5. **Verify.** In order of cost, cheapest first, but don't stop at the
   cheap ones:
   - Local tests passing is *necessary, not sufficient*.
   - Run the *full* test suite after any change to shared or global
     state, not just the tests you think are affected — cross-file and
     cross-session pollution from shared state is a real, recurring bug
     class, not a hypothetical one.
   - **If a trigger is supposed to cause a consequence** (a merge
     triggers a release, an approval triggers a resume, a webhook
     triggers a notification), **verify the consequence happened,
     independently.** Never let the trigger's own "succeeded" status
     stand in for proof that what it was supposed to cause actually did.
   - For infrastructure or integration work, verify against the real
     target system at least once — real CI, a real external API, a real
     deployed instance — before declaring it done. A local simulation
     passing is not the same claim.
6. **Document.** Update the durable-knowledge doc if system state
   changed. Record what was learned honestly, including what *didn't*
   work and wrong turns taken — a sanitized success narrative is worse
   than no narrative, because it's trusted and wrong. If this project's
   narrative-history doc has a current-state summary (see §5): overwrite
   its summary paragraph and next-step pointer — replace, don't append —
   and append one dated entry to the current period's archive file. Do
   this in the same unit of work as the change itself, not as a
   separate, skippable follow-up.
7. **Commit small, commit often, push immediately.** One commit per
   independently coherent unit of work, not a whole phase batched into
   one. Never `--amend` a previous commit for follow-up work — a new
   commit, always.

### Auto-Moderation Protocol (Claude Code Supervision) — Advisory, Not Binding

- **Advisory Supervision**: Major architectural plans, code refactors, or
  quality gate checks may be spot-audited by an agent CLI (e.g.
  `claude -p`) as an informal second reviewer.
- **Not Binding by default**: These audits are advisory input, not a
  binding gate, unless a real CI job exists in this repo that runs it and
  fails the pipeline on a negative finding — verify that before claiming
  "binding supervisory authority." A methodology doc asserting binding
  authority that no actual CI enforces is exactly the kind of unverified
  claim §3 step 5 exists to catch.

---

## 4. Backlog & Task Tracking

- **Zero-Cost Free Tier Infrastructure Mandate**: Prefer free-tier
  infrastructure (issue tracker, CI/CD minutes, cloud free tiers) where
  it genuinely meets the need, to keep cost circuit-breakers (§1)
  meaningful.
- **Issue Tracker, Not Prose**: Open work lives in a real issue tracker
  (GitLab/GitHub/Linear/Jira — whichever this project has adopted), not
  in prose bullets inside markdown files. Query the tracker during the
  Boot Sequence (§2), don't assume its state from memory.
  - **File it the moment you write it, not after.** The moment you type
    "TODO," "FIXME," "still open," "known issue," or similar into any
    file, stop and open a real issue before continuing to write — a
    grep for these keywords outside the tracker (`grep -rn
    "TODO\|FIXME"`) finding a hit is itself evidence this was skipped.
  - This keyword check is a floor, not the whole rule — it's easy to
    describe an unresolved question in prose without using any of those
    words. The actual trigger is broader: **finishing an investigation
    with a question you raised still unresolved is itself the moment to
    file it, regardless of the words used to describe it** — including
    when a different, adjacent bug got fixed in the same pass. An
    adjacent fix is not evidence the original question is answered.

A project-specific feedback-ingestion pipeline, notification protocol, or
similar product feature belongs in *that project's own* docs — not in
this shared methodology contract, even if several projects happen to
implement something similar.

---

## 5. Documentation Structure

Keep three kinds of knowledge separate — blending them is what makes
docs both bloated and hard to trust:

- **Durable state** — what's true about the system and domain *right now*
  (architecture, current design, known gaps, and research/investigation
  findings in a dedicated research doc). Edited in place as discoveries
  refine or things change. Never append a correction; replace the
  outdated statement. If a project requires technical spikes, API
  feasibility checks, or domain/legal research, record these there so
  future sessions don't re-investigate settled questions.
- **Structured backlog** — discrete, closeable units of open work.
  Lives in the issue tracker, not here.
- **Narrative history** — what happened and why, for session-to-session
  continuity. This is the one thing that's legitimately append-only —
  but it needs a rotation or archival rule *before* it becomes large
  enough to dominate the cost of loading context for a new session, not
  after.

### The narrative-history file, concretely

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

**Keeping the summary honest is the hard part, not writing it once.**
A stale pointer is worse than no pointer — it actively misleads instead
of just being absent. Three things make it actually happen instead of
silently rotting:

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

### The 3-Way Synchronized Release Rule (Product & Platform tiers)

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

### Cross-Project Documentation Mirror (optional)

If an ecosystem has adopted an external documentation hub (e.g.
Confluence, Notion, an internal wiki-of-wikis) to aggregate multiple
projects' documentation for human readers: that hub **mirrors** each
project's durable docs one-way — it is never the place new decisions get
authored, and per-repo docs remain the actual source of truth. Two-way
sync (or worse, writing there first) creates exactly the two-sources-of-
truth problem this section exists to prevent. See §1.1's Documentation
Curator persona for who is responsible for this once real automation
exists.

---

## 6. Credentials & Blast Radius

- If a live credential appears in a conversation, a log, or a file,
  store it securely the moment you see it and never redisplay it.
- **Two-Tier Secret Architecture**: Raw API keys and database passwords
  are strictly forbidden in committed configuration files or `.env`
  files. Secret management follows a **two-tier pattern**; the
  concrete tools are project-specific fact — see your project's
  `ADAPTERS.md` for what's actually used, or an opted-in cost/infra
  pack (e.g. `packs/zero-cost-infra-defaults`) for one real-world
  instantiation:
  - **In Plain English**: Laptops and cloud servers have totally
    different jobs. Laptops use a local secrets-injection CLI so
    developers never write passwords on sticky notes (`.env` files).
    Cloud servers and automated deployment pipelines use the cloud
    provider's native workload identity federation to automatically
    prove who they are without ever holding a physical master key that
    could be stolen.
  - **Tier 1 — Local Developer Workstations**: Process memory
    injection via a CLI secrets tool. Eliminates local `.env` files on
    disk without cloud authentication friction.
  - **Tier 2 — CI/CD, Cloud Production & GitOps**:
    - **CI/CD Pipelines**: Keyless workload identity federation (OIDC)
      for CI authentication, where the CI provider and cloud both
      support it.
    - **Production Workloads**: A native cloud secret manager with
      envelope encryption and IAM RBAC.
    - **IaC & GitOps Bootstrap**: Envelope-encrypted secret manifests
      for git-diff auditability.
- **Group vs Project Variable Governance**: Shared API tokens should be
  managed centrally at the organization level or synced via secrets
  automation to prevent per-repository duplication.
- **Multi-Platform Target Discipline**: Projects vary by deployment
  target — static/serverless UIs typically deploy to a serverless
  hosting platform; containerized/stateful services typically deploy to
  a cloud provider via IaC, managed centrally in a dedicated infra
  repo. Which platform this project actually uses is project-specific
  fact — see your project's `ADAPTERS.md` for what's configured, or an
  opted-in cost/infra pack for one real-world instantiation. During
  the Boot Sequence (§2), confirm which applies to *this* project from
  its own `README.md`/`docs/` rather than assuming.
- **UI & Frontend Deployment Protocols** (where applicable):
  - **Preview Deployments**: Automated preview builds are auto-authorized
    on feature branches upon passing 100% of unit/smoke test suites.
  - **Empirical Visual Verification**: Agents MUST inspect the live
    preview URL to verify visual layout and zero browser console errors
    before declaring completion.
  - **Production UI Promotions**: Promoting a build to production or
    updating production DNS routing explicitly requires sign-off from
    the project's designated approver (see `ADAPTERS.md` / an
    opted-in governance pack for who that is).
- **Deployment Authorization Triggers**:
  - `dev` & `staging` deployments are auto-authorized upon passing 100%
    of unit & smoke test suites.
  - `production` deployments explicitly require sign-off from the
    project's designated approver (see `ADAPTERS.md` / an opted-in
    governance pack for who that is).

- If a blocker would require a broader scope, a higher-risk action, or a
  bigger blast radius than what was actually approved, **stop and ask.**
  Never silently substitute something riskier to route around an
  obstacle, even if it would technically work.
- **Adopting this methodology into an existing project is additive, not
  a restructuring.** Before moving, renaming, or relocating any existing
  file to match this template's suggested layout (including `AGENTS.md`
  itself), check every real reference to it first — relative links in
  other docs, explicit "read this file" instructions, other tools'
  config paths. A working project's existing cross-reference web is
  worth more than matching a generic convention. Point new tooling *at*
  wherever the file already lives; don't move the file to match the
  tooling. Bridge-file import mechanisms generally support arbitrary
  relative paths, not just root-level files — use that instead of
  relocating anything.

---

## 7. Definition of Done

A task is not done until:

- [ ] The full test suite is green; Product/Platform-tier repos
      additionally verify their TDD coverage target for new/modified
      core logic (not required for Personal-infra tier, §1.0).
- [ ] Zero raw secrets, API keys, or plaintext passwords exist in
      committed files or logs.
- [ ] For Product/Platform-tier repos: deployment target has been
      confirmed against project documentation.
- [ ] Any trigger→consequence relationship introduced or modified has
      had the consequence independently verified.
- [ ] If this touches infrastructure or an external integration, the
      real target system has been exercised at least once.
- [ ] Durable-knowledge docs (and 3-Way Sync docs if architecture
      shifted) are updated.
- [ ] Work is committed in small units and already pushed.

---

## 8. Automated Tooling, Token Efficiency & Smart Prompt Engineering Directives

To maximize execution performance, eliminate token waste, optimize API
prompt caching, and prevent reinventing the wheel:

1. **Automatic Context-Isolated Subagent Delegation**:
   - For any multi-file code investigation, web search sweep, or broad
     log analysis spanning >3 files or >2 web pages, delegate to a
     subagent to gather facts in an isolated context and return a
     concise summary to the parent session.
2. **AST-Aware & Targeted Chunk Editing**:
   - When making code modifications, use AST tools or targeted
     line-range edits rather than rewriting or reading full large files
     into prompt context.
3. **API Prompt Caching Optimization**:
   - System prompts, skills, and static operational contracts MUST be
     placed at the top of context windows in unvarying order to maximize
     LLM API prompt cache hit rates.
4. **Structured MCP Queries over Raw File Dumps**:
   - If an MCP server is available, query it directly via typed calls
     rather than reading raw database dumps, large DOM HTML dumps, or
     full screenshots into prompt context.
5. **Issue Tracker Synchronization**:
   - Use available issue tracker MCPs to query task status during Boot
     Sequence (§2) and update tickets during Step 6 (Document), keeping
     roadmaps synchronized without manual user prompting.
6. **Per-Project Token Usage & Intra-Agent Efficiency Reporting**
   (roadmap item, adopt only once actually implemented):
   - A per-project token usage report tracking prompt input/output
     tokens, prompt cache hit ratios, and session spend is a reasonable
     target for Product-tier repos. Don't claim it as a current "MUST"
     in a project that doesn't actually maintain one — adopt it there
     only when implemented, and document that at the same time (§5/§6
     sync discipline applies to this rule too).

---

## 9. The MCP / Skills / Plugins Triad Architecture

To standardize agent capabilities, knowledge organization, and tool
interoperability:

1. **Model Context Protocol (MCP) — The Hardware & API Bus Layer**:
   - Connects LLM agents to deterministic external systems. MCP tools
     are typed JSON-RPC interfaces that execute safely within sandboxed
     execution boundaries.
2. **Skills (`SKILL.md`) — Procedural SOPs & Workflow Playbooks**:
   - Markdown instruction packages (`SKILL.md` with YAML metadata +
     helper scripts) loaded strictly on-demand into prompt context
     windows when specific domain tasks trigger them. Prevents root
     system prompt bloat and maximizes prompt caching efficiency.
3. **Plugins — Namespaced Capability Bundles**:
   - Higher-level self-contained packages that bundle MCP servers,
     Skills, Sidecars, and Hooks into namespaced, shareable units for
     single-command installation.

See `METHODOLOGY.md` in the central methodology repository for the
reasoning and real incidents behind each of these rules, and this
project's own issue/merge-request templates for how this gets enforced
day to day.

---

## 10. Agent Self-Learning & Continuous Skill Synthesis Architecture

To transform agents from static instruction followers into self-evolving engineering workers that continuously learn from experience, corrections, and resolved incidents:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                          AGENT SELF-LEARNING FEEDBACK LOOP                                  │
├─────────────────┬─────────────────┬─────────────────────────┬───────────────────────────────┤
│  1. OBSERVE     │   2. REFLECT    │  3. SYNTHESIZE SKILL    │  4. PERSIST & HOT-RELOAD      │
│  Incident /     │   Root-Cause &  │  Reusable SOP /         │  Whichever memory/skill       │
│  User Correction│   Abstraction   │  Executable Pattern     │  store this tool provides     │
└─────────────────┴─────────────────┴─────────────────────────┴───────────────────────────────┘
```

### 10.1 The 4 Core Directives of Agent Self-Learning

1. 🔄 **Empirical Triggering (Learn from Real Incidents Only)**:
   - Self-learning is triggered whenever an agent resolves a non-trivial bug, receives an explicit user correction, or overcomes an un-documented API/build hurdle. Agents MUST NOT invent hypothetical skills without empirical runtime proof.

2. 🧠 **Procedural Skill Synthesis**:
   - Upon discovering a new reusable solution, the agent synthesizes a structured, reusable procedure — a step-by-step SOP, edge-case warnings, and optional verification steps — in whichever skill/procedure format and location this tool and project use (per `ADAPTERS.md`, §2). This file deliberately does not name a specific format or path — that's a concrete tool binding, out of scope here per §0.

3. 💾 **Centralized Memory Persistence over Ad Hoc Files**:
   - In accordance with §1.0's Zero-File Communication Mandate, learned observations, gotchas, and architectural insights MUST be written to whichever centralized, persisted knowledge-graph or memory store is already configured for the project (per `ADAPTERS.md`) — never to scattered ad hoc files.

4. ⚡ **Zero-Restart Dynamic Skill Hot-Reloading**:
   - During Step 2 (Boot Sequence), active agent sessions query the project's configured memory store and skill/procedure location to hot-reload freshly learned patterns into their working memory without requiring process restarts.

