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

---

## 1. Identity & Philosophy

This project defines the **Human-Driven, Intra-Agent Software Engineering Methodology (HIAE Protocol v2.0)** across all repositories in the ecosystem (`axiom-mesh`, `Wisepikr` / `Matrix-Flow`, `iac-infrastructure`, `dev-infra-fleet`, `llm-fallback-manager`, `sec-cli`).

**Core Philosophy**: "Models provide non-deterministic intent; Infrastructure and deterministic software contracts enforce inviolable boundaries."

**Cost Circuit-Breakers & Spend Safety**:
- **Budget Threshold**: No agent session or automated swarm may incur >$50/day in external cloud infrastructure spend or >1,000,000 tokens/session without explicit Human Systems Architect authorization.
- **Breach Protocol**: Upon hitting any budget or rate threshold, execution must pause immediately and escalate to the Human Systems Architect.

---

## 1.1 Vertical Intra-Agent Persona Taxonomy

When operating across this ecosystem, agents adopt vertical personas suited to their domain:

1. **`Persona: Human Systems Architect (Solo Founder / Lead Engineer)`**:
   - **Role**: Defines high-level domain boundaries, interfaces, non-negotiables, and grants final deployment authorization.
   - **Domain Mapping**: Ecosystem-wide governance across all 6 core repositories (`axiom-mesh`, `Wisepikr` / `Matrix-Flow`, `iac-infrastructure`, `dev-infra-fleet`, `llm-fallback-manager`, `sec-cli`).
   - **Responsibilities**: Approves architectural plans, reviews breaking changes, sets cost circuit-breaker limits, and directs agent swarms.

2. **`Persona: DevFleetAgent (Environment & Workstation Specialist)`**:
   - **Role**: Manages local developer workstation setups (`dev-infra-fleet`), PF firewalls, local GPU/CPU hardware probing, and remote SSH fleet servers (`[FLEET_HOSTNAME]`, e.g. `anass-home.myddns.me`).
   - **Domain Mapping**: `dev-infra-fleet` repository & local developer workstation runtime environments.
   - **Responsibilities**: Ensures workstation reproducibility, manages developer Brewfile packages, and maintains P2P compute node health.

3. **`Persona: InfraAgent (DevOps, IaC & Account Auto-Provisioner)`**:
   - **Role**: Manages OpenTofu IaC manifests (`iac-infrastructure`), GCP Cloud Run services, Cloudflare DNS & SSL/TLS, Bitwarden Secrets Manager (`bws`), and 3-Tier n8n Playwright account auto-provisioners.
   - **Domain Mapping**: `iac-infrastructure` repository & cloud resource provisioning.
   - **Responsibilities**: Executes multi-environment deployments (`dev`, `staging`, `production`), configures HTTPS/DNS records, and injects secrets safely into `bws`.

4. **`Persona: Multi-Project Product & Security Auditor`**:
   - **Role**: Conducts deep multi-repo forensic audits across code quality, TDD 99%+ test coverage, security headers, stdlib module shadowing (e.g. `logger.py`), security CLI tooling (`sec-cli`), resilience proxies (`llm-fallback-manager`), distributed mesh backends (`axiom-mesh`), and SEO schema compilation gates (`Wisepikr`).
   - **Domain Mapping**: `Wisepikr` / `Matrix-Flow`, `axiom-mesh`, `llm-fallback-manager`, and `sec-cli` repositories.
   - **Responsibilities**: Detects bugs across shared state/APIs, verifies rate-limiting middleware (`Matrix-Flow`), enforces TDD 99%+ coverage, and guarantees 100% clean test passes before release.

---

## 2. Boot Sequence For A New Session

Before touching anything:

1. Read the durable-knowledge doc (architecture / current-state / known
   gaps — whatever this project calls it) to understand what's actually
   true about the system right now.
2. Check the issue tracker — not prose in a markdown file — for what's
   currently open.
3. Read the narrative-history doc's **current-state summary** (if one
   exists) for recent context on *why* things are the way they are —
   not the full file. Only open a dated archive entry if this task
   specifically needs older history the summary doesn't cover.
4. Run the existing test suite. Confirm you're building on a known-good
   baseline before changing anything. If it's not green, that's the
   first thing to report, not something to work around.

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
3. **Plan.** For anything non-trivial, write a concrete design to a
   durable, reviewable location before implementing. Get explicit
   approval before proceeding. Calibrate the ceremony to the *risk*, not
   the line count — a one-line change to shared infrastructure deserves
   more care than a hundred-line change to an isolated module.
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

---

## 4. Backlog & Task Tracking

Open work lives in the issue tracker, not in prose bullets inside
markdown files. If you find yourself writing "still open: X, Y, Z" as a
list in a doc, that's a signal those should be real, closeable,
queryable issues instead.

---

## 5. Documentation Structure

Keep three kinds of knowledge separate — blending them is what makes
docs both bloated and hard to trust:

- **Durable state** — what's true about the system and domain *right now*
  (architecture, current design, known gaps, and research/investigation
  findings in `RESEARCH.md`). Edited in place as discoveries refine or
  things change. Never append a correction; replace the outdated statement.
  If a project requires technical spikes, API feasibility checks, or
  domain/legal research, record these in `RESEARCH.md` so future sessions
  don't re-investigate settled questions.
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
- **Dated archive files** holding the full narrative for each period
  (e.g. `history/2026-08.md`), linked from the summary. Nothing gets
  deleted or shortened — the full detail stays fully available and
  searchable, just not force-loaded by default.

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

### The 3-Way Synchronized Release Rule

For any non-trivial feature or architectural change, documentation and implementation must be updated simultaneously in the exact same unit of work:
1. **Implementation Code**: Source code files under `src/` or core modules.
2. **Technical Architecture Doc**: System layout and contracts under `docs/ARCHITECTURE.md`.
3. **Master Wiki / Knowledge Base**: Higher-level domain documentation and master wiki pages.

No PR or release is complete if code changes drift from `docs/ARCHITECTURE.md` or the Master Wiki.

---

## 6. Credentials & Blast Radius

- If a live credential appears in a conversation, a log, or a file,
  store it securely the moment you see it and never redisplay it.
- **Consolidated 2-Tool Zero-Cost Secret Architecture**: Raw API keys and database passwords are strictly forbidden in committed configuration files or `.env` files. Secret management is consolidated onto **two zero-cost, durable tools** to eliminate maintenance overhead and migration friction:
  - **In Plain English**: Laptops and cloud servers have totally different jobs. Laptops use a fast, free keycard tool (`infisical run --` or `bws run --`) so developers never write passwords on sticky notes (`.env` files). Cloud servers and automated deployment pipelines use Google's native digital facial recognition (Workload Identity Federation & GCP Secret Manager) to automatically prove who they are without ever holding a physical master key that could be stolen.
  - **Tool 1 — Local Developer Workstations (Free CLI Launcher)**: Process memory injection via `infisical run --` or `bws run --` (Free Tier). Eliminates local `.env` files on disk without cloud authentication friction.
  - **Tool 2 — CI/CD, Cloud Production & GitOps (Native GCP Cloud Suite)**:
    - **CI/CD Pipelines**: Free OIDC **Workload Identity Federation (WIF)** for keyless GitLab CI authentication.
    - **Production Workloads**: **GCP Secret Manager with CMEK** (Free Tier up to 6 secret versions/mo, $0.06/mo thereafter) with native IAM RBAC.
    - **IaC & GitOps Bootstrap**: Envelope-encrypted secret manifests via **SOPS + GCP KMS** within `iac-infrastructure` for git-diff auditability.
- **Group vs Project Variable Governance**: Shared API tokens (`VERCEL_TOKEN`, `GROQ_API_KEY`, `DEEPSEEK_API_KEY`, `CLOUDFLARE_API_TOKEN`, `GITLAB_TOKEN`) must be managed centrally at the GitLab Group Level (`at-tech-io/`) or synced via secrets automation to prevent per-repository duplication.
- **Multi-Platform Target Discipline**: Projects vary by deployment target:
  - **Static & Serverless Web Apps** (e.g. `talbylawfirm`, `Matrix-Flow` frontend) deploy to **Vercel** via `VERCEL_TOKEN`.
  - **Containerized VMs, Stateful DBs, & Microservices** (e.g. `TALLEX-AI`, `axiom-mesh`) deploy to **GCP / AWS** managed centrally in **`at-tech-io/iac-infrastructure`** using **OpenTofu (`tofu`) + Terragrunt**.
  - During the Boot Sequence (§2), agents must inspect the project's `README.md` or `docs/` to confirm whether infrastructure is managed locally (Vercel) or centrally in `at-tech-io/iac-infrastructure`.
- **Deployment Authorization Triggers**:
  - `dev` & `staging` deployments are auto-authorized upon passing 100% of unit & smoke test suites.
  - `production` deployments explicitly require Human Systems Architect sign-off before executing `tofu apply` or triggering production releases.

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

- [ ] The full test suite is green, with TDD test coverage verified at $\ge 99\%$ for new/modified core logic.
- [ ] Zero raw secrets, API keys, or plaintext passwords exist in committed files or logs (verified via Bitwarden `bws` / secret scanner).
- [ ] Deployment target (Vercel vs OpenTofu/Terragrunt) has been confirmed against project documentation.
- [ ] Any trigger→consequence relationship introduced or modified has
      had the consequence independently verified.
- [ ] If this touches infrastructure or an external integration, the
      real target system has been exercised at least once.
- [ ] Durable-knowledge docs (and 3-Way Sync docs if architecture shifted) are updated.
- [ ] Work is committed in small units and already pushed.

---

## 8. Automated Tooling & Token Efficiency Directives

To maximize execution performance, eliminate token waste, and prevent reinventing the wheel:

1. **Automatic Context-Isolated Subagent Delegation**:
   - For any multi-file code investigation, web search sweep, or broad log analysis spanning >3 files or >2 web pages, automatically delegate to a subagent (`invoke_subagent` using a lightweight model like `flash`) to gather facts in an isolated context and return a concise summary to the parent session.
2. **AST-Aware Structural Code Refactoring**:
   - When making multi-file structural edits, prefer AST tools (`ast-grep`, `ruff`, LSP tools) or target scripts over line-by-line prompt rewrites.
3. **Structured MCP Queries over Raw File Dumps**:
   - If an MCP server is available (`sqlite`, `postgres`, `graphify`, `chrome-devtools-mcp`, `linear`), query it directly via typed calls rather than reading raw database dumps, large DOM HTML dumps, or full screenshots into prompt context.
4. **Issue Tracker Synchronization**:
   - Use available issue tracker MCPs (GitLab, GitHub, Linear) to query task status during Boot Sequence (§2) and update tickets during Step 6 (Document), keeping roadmaps synchronized without manual user prompting.

See `METHODOLOGY.md` in this repo for the reasoning and real incidents
behind each of these rules, and `.gitlab/issue_templates/` /
`.gitlab/merge_request_templates/` for how this gets enforced day to day.
