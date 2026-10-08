# Agent Operational Manual

The operational contract for any AI agent or human working here. Bridge
files exist only to make *this* file discoverable; it is the single
source of truth, so don't duplicate it or let a bridge drift from it.
**It knows nothing about which projects exist** — no repo names, brands,
or persona mappings; that's project-aware fact, not process.

## Module Table

If your task looks like the left column, load the module before
proceeding. This table is the only route into the modules; a section
that needs one points here, never at a file path of its own.

| Your task involves… | Load |
|---|---|
| Onboarding a repo, a version bump, the `stable` tag, or what belongs in this file vs. a project's own docs | `methodology/adoption.md` (§0) |
| Repo tier, cost circuit-breakers, RBAC/zero-trust, zero-file communication, cross-repo ownership, worktree lifecycle | `methodology/tiers.md` (§1.0) |
| The 4 core execution traits (laser focus, 100%-done, empirical verification, clean hand-off) | `methodology/execution-traits.md` (§1.2) |
| Starting a new session — **read this before anything else, every session** | `methodology/boot-sequence.md` (§2) |
| Full step-by-step reasoning for Ground/Research/Plan/Implement/Verify/Document/Commit, the Auto-Moderation Protocol, or proactive next-action / bounded-autonomy timeout behavior | `methodology/core-loop-detail.md` (§3), `methodology/proactive-next-action.md` (§3) |
| Narrative-history mechanics, the declared doc set rule, or an external documentation-mirror hub | `methodology/documentation-structure.md` (§5) |
| Secrets, deployments, cloud IAM, TLS, or any credential-touching work | `methodology/credentials.md` (§6) |
| Subagent delegation, prompt caching, token efficiency, or shell-vs-real-language tool choice | `methodology/tooling.md` (§8, §1.3) |
| MCP servers, Skills, or Plugins architecture | `methodology/mcp-skills-plugins.md` (§9) |

## 0. Adoption Model — Hyer Is the Central Hub

Hyer is the one central, versioned hub for this contract across every
project that adopts it, and that works only because this repo owns
*process only*. Onboarding, the full-payload rule, versioning, the
`stable` tag, and where a project's own facts belong: see the table.

## 1. Identity & Philosophy

This project defines **Hyer**, the working name for the Human-Driven,
Intra-Agent Software Engineering Methodology
(HIAE Protocol v5.39.1) — a general-purpose process contract for how an
agent, or a human following the same discipline, works on any project
that adopts it.

**Vocabulary**: call it **Hyer**, never "the methodology" — that's a
category, not a name (`METHODOLOGY.md#why-say-hyer-not-the-hub`).

**Core Philosophy**: "Models provide non-deterministic intent;
Infrastructure and deterministic software contracts enforce inviolable
boundaries."

### 1.0 Repo Classification Tier

Three tiers, applied by what's actually on disk (a test suite? an
architecture doc? a deploy pipeline?), never asserted from memory.
**Product** — ships to a customer; full methodology, architecture doc,
deployment gates. **Platform** — infra/tooling consumed by product
repos; quality gates apply to its own code, architecture doc encouraged
not required. **Personal-infra** — a solo developer's own machine setup;
apply Hyer by *intent* (grounding, planning, documenting, small
commits), not literally — no TDD-coverage or architecture-doc
requirement, and its durable-state doc stands in for the declared doc set (§5).

## 1.1 Vertical Intra-Agent Persona Taxonomy

Agents adopt vertical personas suited to their domain, but the concrete
personas and who holds final approval authority are project-specific
fact. This file defines none; see `ADAPTERS.md` for an opted-in
governance pack, if any. Wherever this file says "the project's
designated approver," that identity comes from that pack.

## 1.2 Core Execution Traits & Work Ethic Baseline

Every agent worker MUST embody these as an inviolable baseline.
**Laser Task Focus** (zero scope drift — don't wander into unrequested
refactors). **A "100% Done" mindset** (zero rework — a fixed bug may be
one instance of a pattern, check with one targeted search before calling
it done). **Empirical Test Verification** (never assume code works
because it "looks right"). **End-to-End Ownership & Clean Hand-Off**
(verify the intended consequence actually occurred, document cleanly,
commit in small units).

## 1.3 Right Tool for the Right Job

Choosing a language/tool is a deliberate decision, not a default: thin
orchestration only in shell, a real language once a script needs tests
(can't unit-test it, can't satisfy §7 — that's the rewrite signal). Not
a mandate to mass-rewrite existing scripts today.

## 2. Boot Sequence For A New Session

Before touching anything, look things up rather than reading whole
files: **(1)** check `ADAPTERS.md` for this project's tool bindings and
opted-in policy packs; **(2)** check `skills/REGISTRY.md` for a skill
matching the task; **(3)** query the durable-knowledge doc for what the
task touches; **(4)** check the issue tracker — not prose — for what's
open; **(5)** read only the narrative-history doc's current-state
summary; **(6)** run the test suite and confirm a known-good baseline.
`AGENTS.md` already in your context is not read again.

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
these becomes true — mechanical tripwires, not judgment calls (see
`METHODOLOGY.md#why-these-are-mechanical-tripwires`). Nothing
mechanically enforces the first three; this prose is the only control:

- about to create or modify anything that will act again later without
  a human re-approving each occurrence (a schedule, webhook, cron entry,
  CI trigger, queue consumer, retry loop) — named by the property, not
  a closed list, since the next one won't look like the last one
- about to call a production system or use a live (non-test) credential
- about to take an action beyond what you've heard an explicit yes to in
  this conversation — not what a broader ask could be argued to imply
- about to do substantial work spanning more than one domain a
  configured persona taxonomy defines, where this project has an
  opted-in governance pack — surface it in the plan and consider
  dispatching per `skills/adopt-persona/SKILL.md`. Cross-domain shape
  usually only becomes clear once work is underway, so check per task,
  not once at boot

## 4. Backlog & Task Tracking

- **Issue Tracker, Not Prose**: Open work lives in a real issue tracker,
  not in prose bullets inside markdown files. Query the tracker during
  the Boot Sequence (§2), don't assume its state from memory.
  - **File it the moment you write it, not after.** The moment you type
    "TODO," "FIXME," "still open," "known issue," or similar into any
    file, stop and open a real issue before continuing to write — a
    grep for these keywords outside the tracker (`grep -rn
    "TODO\|FIXME"`) finding a hit is itself evidence this was skipped.
  - That keyword check is a floor, not the whole rule: **finishing an
    investigation with a question you raised still unresolved is itself
    the moment to file it**, whatever words describe it. An adjacent
    bug fixed in the same pass is not evidence the original question
    is answered.

## 5. Documentation Structure

Keep three kinds of knowledge separate — blending them is what makes
docs both bloated and hard to trust:

- **Durable state** — what's true *right now* (architecture, design,
  known gaps, research findings). Edited in place: never append a
  correction, replace the outdated statement.
- **Structured backlog** — closeable units of open work, in the tracker.
- **Narrative history** — what happened and why. The one thing
  legitimately append-only, but it needs a rotation rule *before* it
  dominates the cost of loading context.

## 6. Credentials & Blast Radius

Headline rule: if a blocker would require a broader scope, a
higher-risk action, or a bigger blast radius than what was actually
approved, **stop and ask** — never silently substitute something
riskier to route around an obstacle, even if it would technically work.

## 7. Definition of Done

A task is not done until:

- [ ] The full test suite is green; Product/Platform-tier repos
      additionally verify their TDD diff coverage for new/modified
      core logic (not required for Personal-infra tier, §1.0).
- [ ] Zero raw secrets, API keys, or plaintext passwords exist in
      committed files or logs.
- [ ] Any trigger-to-consequence relationship introduced or modified has
      had the consequence independently verified.
- [ ] If this touches infrastructure or an external integration, the
      real target system has been exercised at least once, and
      Product/Platform-tier deployment targets confirmed against docs.
- [ ] Durable-knowledge docs (and the declared doc set if architecture
      shifted) are updated, and work is committed in small units and
      already pushed.

## 8. Automated Tooling & Token Efficiency Directives

To keep sessions fast and cheap: subagent-delegate any multi-file
investigation spanning >3 files or >2 web pages; prefer targeted
edits over full rewrites; keep static contract text at the top of
context for prompt-cache hits; prefer a structured query over a raw
dump; sync the issue tracker at Boot (§2) and Document (§3 step 6).

**Plain text in every agent-facing file.** No emoji, no status glyphs,
no box-drawing diagrams, no decorative rules in anything an agent is
told to read or that tooling executes: this contract, `ADAPTERS.md`,
`methodology/`, `skills/`, `scripts/`, `packs/`, `templates/`, the
durable-knowledge and narrative-history docs. **Documents written for a
person to read are out of scope** -- their formatting is a readability
choice, not your call. So is a live reply on someone's terminal.
**CLI output convention.** When one tool-machine's stdout is consumed
as a parse target by another, the producer MUST emit one `[ TAG ]`
line per event (`[ OK ]`, `[WARN]`, `[INFO]`, `[ERROR]`), never
reworded or re-spaced when checked; prose is never a parse target.
**Never comment code, docstrings included.** The why lives in commits and specs.

## 9. The MCP / Skills / Plugins Triad Architecture

Three distinct layers, kept separate on purpose: **MCP** — the typed,
sandboxed API bus to external systems. **Skills (`SKILL.md`)** —
on-demand procedural playbooks, kept out of always-loaded context.
**Plugins** — namespaced bundles of the above.

## 10. Agent Self-Learning & Continuous Skill Synthesis

After resolving a non-trivial bug, receiving an explicit correction, or
overcoming an undocumented API/build hurdle, synthesize a reusable
procedure and persist it to the project's configured memory/skill store
— see the `self-learning-skill-synthesis` skill (hub-internal — §2
step 2 for how to fetch its content from outside this repo) for the
4-phase loop and the empirical-triggering rule (no hypothetical skills).
