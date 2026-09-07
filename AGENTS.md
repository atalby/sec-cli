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
specific product's feedback pipeline directly into Hyer
itself; see `CHANGELOG.md`.

**This file is a thin core** (Phase 2,
`docs/hyer/specs/2026-08-29-methodology-storage-restructure.md`):
detail that used to live inline now lives in `methodology/*.md`
modules, part of the adopter payload. Section numbers are unchanged by
the split (nothing removed, only shortened), so existing citations
still work. `scripts/check_core_size.py` hard-fails this file above 24
KiB / 400 lines — headroom under Codex's 32 KiB silent-truncation limit.

## Module Table

If your task looks like the left column, load the module before
proceeding — same progressive-disclosure principle as `skills/REGISTRY.md`:

| Your task involves… | Load |
|---|---|
| Repo tier, cost circuit-breakers, RBAC/zero-trust, zero-file communication, cross-repo ownership, worktree lifecycle | `methodology/tiers.md` (§1.0) |
| The 4 core execution traits (laser focus, 100%-done, empirical verification, clean hand-off) | `methodology/execution-traits.md` (§1.2) |
| Starting a new session — **read this before anything else, every session** | `methodology/boot-sequence.md` (§2) |
| Full step-by-step reasoning for Ground/Research/Plan/Implement/Verify/Document/Commit, or the Auto-Moderation Protocol | `methodology/core-loop-detail.md` (§3) |
| Narrative-history mechanics, the full 3-Way Sync rule, or an external documentation-mirror hub | `methodology/documentation-structure.md` (§5) |
| Secrets, deployments, cloud IAM, TLS, or any credential-touching work | `methodology/credentials.md` (§6) |
| Subagent delegation, prompt caching, token efficiency, or shell-vs-real-language tool choice | `methodology/tooling.md` (§8, §1.3) |
| MCP servers, Skills, or Plugins architecture | `methodology/mcp-skills-plugins.md` (§9) |

## 0. Adoption Model — Hyer Is the Central Hub

**Hyer** (this repo's current name — see `WIKI.md`'s own roster row for
its naming/rename history, per this section's own project-aware-facts
rule below) is the one central, versioned hub for this contract across
every project — current and future — that adopts it. That only works
because of the split above: this repo owns *process only*.

- **Onboarding a project (current or future)**: copy this `AGENTS.md`
  file verbatim into the project root, plus a thin bridge file
  (`CLAUDE.md` with `@AGENTS.md`, `.gemini/settings.json`, etc.) — no
  edits to `AGENTS.md` needed, since it has no project-specific facts
  to adapt. Editing it to describe a specific project is the signal
  that content belongs in that project's own docs instead.
  Copying it in also means copying `skills/`, `skills/REGISTRY.md`,
  and `methodology/` (the modules the table above points at) —
  adopting Hyer means the full payload, not a hand-picked subset;
  `.claude/skills/` stays hub-internal. A version bump into an
  existing adopter follows the same rule — don't leave `skills/` or
  `methodology/` behind at an older state (see
  `METHODOLOGY.md#corrected-2026-08-25-skills-registry-elective-drift`).
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
- **The `stable` git tag**: a floating pointer to the newest reviewed
  release commit, moved (not recreated) on every release — see the
  `moving-stable-tag` skill (hub-internal — §2 step 2 for how to fetch
  its content from outside this repo) for the exact command and why
  manual-copy adopters must fetch at `stable`, never a hardcoded
  version.
- **Staying in sync**: this hub detects adopter drift from its own
  side (`scripts/check_methodology_sync.py`), but that only helps if
  someone reads its output — an adopter's own CI can gate on its own
  drift instead; see the `adopter-drift-self-check` skill (hub-internal
  — §2 step 2 for how to fetch its content from outside this repo).
- **Hyer's own repo structure stays provider-neutral.** No file or
  directory here is named after a specific agent tool, except the thin
  bridge files a tool itself requires to discover `AGENTS.md`
  (`CLAUDE.md`, `.gemini/`, `.cursor/`) and this hub's own
  `.claude/skills/` release-engineering set.
- **The boundary line**: this repo stops at *how work gets done*; it
  never grows into *what exists*. A change that would only make sense
  for one specific project is out of scope for this file.

---

## 1. Identity & Philosophy

This project defines **Hyer** — the working name for the
**Human-Driven, Intra-Agent Software Engineering Methodology
(HIAE Protocol v5.28.0)** — a general-purpose process contract
for how an AI agent (or a human following the same discipline)
works on any project that adopts it. "Hyer" is the name to
actually say out loud; "HIAE Protocol" is the formal/spec name,
used when precision or citation matters (e.g. "this project
adopts the HIAE Protocol"). The two aren't competing names —
Hyer names the thing, HIAE Protocol is what the name expands
to, the same relationship "radar" (the word everyone says) has to
RADAR (RAdio Detection And Ranging, the acronym it came from). Adopted
2026-08-26 (see `METHODOLOGY.md#found-2026-08-26-naming-edit-broke-pre-commit-parsing`)
specifically so the acronym alone wouldn't be the only handle for this
open-sourced later. Which specific repos have adopted it, and
what each one is, is ecosystem-specific fact and does not belong in this
file — see your ecosystem's own wiki/knowledge-base doc for that map.

**Vocabulary — this project is "Hyer".** In prose, in commit messages,
and in conversation, the name of this project is **Hyer**. "HIAE
Protocol" is the formal expansion, used only for citation and
versioning (e.g. "this project adopts the HIAE Protocol", "released in
HIAE Protocol vN"). Do **not** call the project "the methodology" —
that is a category, not its name. "The hub" is §0's structural term
for this repo's role in the adoption model and stays valid in that
sense; it is not a stand-in name for Hyer in running prose (see
`METHODOLOGY.md#why-say-hyer-not-the-hub`).

**Core Philosophy**: "Models provide non-deterministic intent;
Infrastructure and deterministic software contracts enforce inviolable
boundaries."

### 1.0 Repo Classification Tier

Three tiers, applied by what's actually on disk (a test suite? an
architecture doc? a deploy pipeline?), never asserted from memory:
**Product** — ships to a customer, full methodology plus a technical
architecture doc and deployment gates. **Platform** — infra/tooling
consumed by product repos; quality gates apply to its own code, an
architecture doc is encouraged not required. **Personal-infra** — a
solo developer's own machine/dotfiles setup; apply Hyer by
*intent* (grounding, planning, documenting, small commits), not
literally — no TDD-coverage or architecture-doc/deployment-trigger
requirement, and its own durable-state doc stands in for the 3-Way
Sync structure (§5). Which concrete repos are which tier is
ecosystem-specific fact — record that mapping in your ecosystem's wiki
doc, not here.

Full detail — including the Cost Circuit-Breaker & Spend Safety rules,
the Mandatory RBAC & Zero-Trust Mandate, the Zero-File Communication
Mandate, the Cross-Repo Ownership & Ask-Don't-Read Mandate, and the
Parallel Execution & Worktree Lifecycle Mandate — lives in
`methodology/tiers.md`.

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

Every agent worker MUST embody these as an inviolable baseline: 🎯
**Laser Task Focus** (zero scope drift — don't wander into unrequested
refactors); 🔨 a **"100% Done" mindset** (zero rework — a fixed bug may
be one instance of a pattern, check with one targeted search before
calling it done); 🧪 **Empirical Test Verification** (never assume code
works because it "looks right"); 🤝 **End-to-End Ownership & Clean
Hand-Off** (verify the intended consequence actually occurred, document
cleanly, commit in small units).

Full detail — including the "a hand-triggered mechanism is broken"
principle and the methodology-ceremony-overhang guard — lives in
`methodology/execution-traits.md`.

---

## 1.3 Right Tool for the Right Job

Choosing a language/tool should be a deliberate decision, not a
default: thin orchestration only in shell, a real language once a
script needs tests (can't unit-test it, can't satisfy §7 — that's the
rewrite signal). Not a mandate to mass-rewrite existing scripts today.

Full detail lives in `methodology/tooling.md`.

---

## 2. Boot Sequence For A New Session

Before touching anything: **(1)** check `ADAPTERS.md` for this
project's tool bindings and any opted-in policy packs; **(2)** check
`skills/REGISTRY.md` for an on-demand skill matching the current task;
**(3)** read the durable-knowledge doc for what's actually true about
the system right now; **(4)** check the issue tracker — not prose — for
what's currently open; **(5)** read the narrative-history doc's
current-state summary, not the full file; **(6)** run the existing test
suite and confirm a known-good baseline before changing anything.

Full detail — including the pre-commit-hook-must-never-be-a-frozen-fork
rule, the optional `~/.hyer/` cross-harness hook layer, unambiguous
cross-session messaging conventions, mid-session fact re-checking
cadence, and the Dynamic In-Session Hot-Reloading protocol — lives in
`methodology/boot-sequence.md`. **Read it before doing anything else in
a new session** — this is step 0, not optional detail just because it
lives in a module.

---

## 3. The Core Development Loop

For any non-trivial change, in order: **1. Ground** — verify
current-state facts with real citations. **2. Research third-party
tools** before configuring them. **3. Plan** — write a concrete design
to a durable, reviewable location, get explicit approval before
implementing (see the tripwire list below). **4. Implement** in small,
independently coherent units. **5. Verify** — cheapest checks first,
but don't stop there. **6. Document** — update durable-knowledge docs
and narrative history in the same unit of work as the change. **7.
Commit** small, commit often, push immediately (solo-operator default;
gate on review in a multi-contributor setting).

**The moment of noticing is the checkpoint, not the moment of
finishing.** Stop and surface *before* continuing, the moment any of
these becomes true — these are mechanical tripwires, not judgment
calls (see `METHODOLOGY.md#why-these-are-mechanical-tripwires`):

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
- about to do substantial work spanning more than one domain a
  configured persona taxonomy defines (e.g. infra work *and* a
  security/quality audit *and* documentation currency in the same
  pass), where this project has an opted-in governance pack (see
  `ADAPTERS.md`) — surface that as part of the plan and consider
  dispatching per `skills/adopt-persona/SKILL.md` rather than
  defaulting to doing it all inline. Checked once at session boot
  against whatever the task looked like at the time is not enough —
  cross-domain shape often only becomes clear once work is already
  underway, so this is a per-task check at the moment scope is
  actually decided, not a one-time registry scan

These tripwires are also mechanically re-surfaced mid-session — not
only readable once at session start — by the `~/.hyer/` hook layer
(issue #26; see `docs/hyer/specs/2026-08-26-hyer-hook-layer-design.md`;
see also `METHODOLOGY.md#prose-alone-already-failed-twice`).

Full step-by-step reasoning for each of the 7 steps, and the
Auto-Moderation Protocol, live in `methodology/core-loop-detail.md`.

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

A project-specific feedback-ingestion pipeline or similar product
feature belongs in that project's own docs, not this shared contract.

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

Full mechanics for each — the narrative-history rotation rule, the
full 3-Way Synchronized Release Rule (Product & Platform tiers), and
the optional Cross-Project Documentation Mirror — live in
`methodology/documentation-structure.md`.

---

## 6. Credentials & Blast Radius

Headline rule: if a blocker would require a broader scope, a
higher-risk action, or a bigger blast radius than what was actually
approved, **stop and ask** — never silently substitute something
riskier to route around an obstacle, even if it would technically work.

Full detail — two-tier secrets, RBAC/zero-trust, deployment discipline,
cloud identity ownership, TLS-non-negotiable, and the
git-init-inside-a-worktree guard — lives in `methodology/credentials.md`.
**Load it before any infra, secrets, or credential-touching work** —
short in core, not optional.

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

## 8. Automated Tooling & Token Efficiency Directives

To keep sessions fast and cheap: subagent-delegate any multi-file
investigation spanning >3 files or >2 web pages; prefer targeted
edits over full rewrites; keep static contract text at the top of
context for prompt-cache hits; prefer a structured query over a raw
dump; sync the issue tracker at Boot (§2) and Document (§3 step 6).

Full detail lives in `methodology/tooling.md`.

---

## 9. The MCP / Skills / Plugins Triad Architecture

Three distinct layers, kept separate on purpose: **Model Context
Protocol (MCP)** — the typed, sandboxed API bus to deterministic
external systems. **Skills (`SKILL.md`)** — on-demand procedural
playbooks, loaded only when a task triggers them, kept out of
always-loaded context. **Plugins** — namespaced bundles of the above
for single-command installation.

Full detail lives in `methodology/mcp-skills-plugins.md`.

---

## 10. Agent Self-Learning & Continuous Skill Synthesis

After resolving a non-trivial bug, receiving an explicit correction, or
overcoming an undocumented API/build hurdle, synthesize a reusable
procedure and persist it to the project's configured memory/skill store
— see the `self-learning-skill-synthesis` skill (hub-internal — §2
step 2 for how to fetch its content from outside this repo) for the
4-phase loop (Observe → Reflect → Synthesize → Persist & Hot-Reload)
and the empirical-triggering rule (no hypothetical skills).
