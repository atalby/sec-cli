# Repo Classification Tier

> Detail module for `AGENTS.md` §1.0. Loaded on demand — see the module
> table in `AGENTS.md` §0. This file is part of the adopter payload
> (§0: "adopting Hyer means the full payload, not a hand-picked
> subset"), copied alongside `AGENTS.md` and `skills/`.

Not every repo that adopts Hyer ships to a customer, and its
stricter requirements (TDD coverage gates, an architecture doc, deployment
triggers) should apply by tier, not uniformly:

- **Product tier** — ships to a customer or end user. Full methodology
  applies, including a technical architecture doc and deployment gates.
- **Platform tier** — infra/tooling consumed by product repos, not
  customer-facing itself. Quality gates apply to its own code; an
  architecture doc is encouraged, not required, until one is actually
  needed.
- **Personal-infra tier** — a solo developer's own machine/dotfiles setup,
  not a shipped product. Apply Hyer by intent (grounding,
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
  accumulate history under the old one (see
  `METHODOLOGY.md#verified-2026-08-17-the-1023-turn-session`).
- **Breach Protocol**: real spend/rate limits (a cloud billing budget
  alert, a provider's own rate limit) are each project's own concern,
  built and enforced at the infrastructure layer that can actually act
  on them — not a dollar or token figure restated in this file, which
  nothing here enforces (see `METHODOLOGY.md#why-breach-protocol-has-no-number`).
  Upon a project's own real alert firing, or a session
  visibly running far outside its intended scope, pause and escalate to
  the project's designated approver (see `ADAPTERS.md` / an opted-in
  governance pack for who that is) rather than continuing.

**Mandatory RBAC & Zero-Trust Mandate** (worked examples:
`METHODOLOGY.md#worked-examples-rbac-capability-bounds-and-high-risk-ops`):
- All tool execution gateways, API endpoints, and background workers
  MUST enforce RBAC and least-privilege capability scoping.
- `HIGH_RISK` operations MUST enforce an explicit Human-in-the-Loop
  (`approved=True`) gate prior to execution.
- A request/invocation lacking explicit role, tenant, or valid session
  JWT claims MUST fail closed (`401`/`403`), never fall back to
  permissive access.

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
  durable-knowledge docs in §5, commit messages, and Hyer's
  own docs are committed artifacts a human is meant to read, not
  agent-to-agent scratch. Don't use this mandate as a reason to skip
  documenting real decisions in §5's docs.
- **If a project has no persisted memory/knowledge-graph tool configured
  yet, that's a gap to fix**, not license to fall back to scratch files.
- **Keep the persisted store lightweight** (see
  `METHODOLOGY.md#why-the-persisted-store-must-stay-lightweight`); treat
  sustained growth past roughly 10MB as the concrete signal to prune, not
  a number to hit before worrying.
- **Never persist a specific agent/session reference as a fact to
  reuse later.** A session's identity is ephemeral — always re-run live
  agent discovery immediately before addressing another agent, not from
  a remembered reference (see
  `METHODOLOGY.md#found-2026-08-25-stale-agent-reference`).
- Any further "next-era" features beyond this (AST-aware read guards, a
  reactive event bus, automatic tool-call rejection) belong in a separate
  proposal doc, explicitly labeled proposed-not-adopted, until they are
  actually built and enforced by real tooling — never asserted as current
  behavior in this contract before that's true.

**Cross-Repo Ownership & Ask-Don't-Read Mandate** (added v5.28.0;
replaces the persona-to-repo table an earlier `WIKI.md` roster carried
and then dropped for going stale/unverifiable — see
`METHODOLOGY.md#why-ownership-is-declared-per-repo-not-centrally`):
- **Ownership is declared per-repo, not centrally.** A hand-maintained
  central table mapping every repo to whoever's responsible for it goes
  stale the moment anyone's assignment changes without updating one more
  file nobody's looking at. Instead, each repo's own `ADAPTERS.md`
  carries a "Repo ownership" field naming who (a human, a named
  persona, or an explicit "unowned") is currently responsible for it —
  local to the repo that fact actually describes, updated by whoever is
  actually working it as part of normal session boot/handoff, not
  reconciled from outside.
- **Check before you touch, not after.** Before reading or modifying
  any file in a repo/domain that is not the one your current task
  session was started in, check that repo's own `ADAPTERS.md`
  ownership field and, where this fleet runs live inter-session
  messaging (`fleet-agent-coordination`), whether a session is actually
  online for it right now.
- **If it's owned, ask — never read or edit it yourself.** A declared
  or live owner means you message them and let them act in their own
  repo, even for something that looks trivial or read-only-safe from
  outside. Reaching in yourself — even "just to check," even with good
  intentions — bypasses whatever that owner's own session state,
  in-flight work, or context you can't see from outside actually is.
  This applies to a session's own dispatched subagents identically: a
  subagent given a task in another repo/domain is still bound by this
  mandate, not exempted because a human didn't type the request
  directly.
- **Unowned or explicitly "ask first for anything beyond read access"
  is not a blank check either** — read what you need to answer the
  question at hand, but any actual change still gets surfaced to a
  human or the declared approver before you make it, same as any other
  cross-domain action under this contract.

**Parallel Execution & Worktree Lifecycle Mandate** (added v5.22.0; see
`docs/hyer/specs/2026-08-28-parallel-execution-worktree-mandate.md`
for the reasoning and the two real collisions behind it):
- **Isolate genuinely concurrent work.** When more than one agent
  session (or a human plus an agent) will touch the *same repo* in
  overlapping time, each task MUST run in its own `git worktree`
  (`git worktree add ../<repo>-<task> -b <branch>`) or an equivalent
  branch workspace — never two sessions editing the same working tree
  on the same branch at once. A single session working a repo alone,
  with no other session active in it, may work the trunk directly
  (this is §3 step 7's solo-operator default, unchanged).
- **Finish what you start; a worktree is execution space, not
  storage.** Every task that opens one completes this sequence *in the
  same session*, not as a deferred follow-up:
  1. Gates green — full test suite plus pre-commit / 3-Way Sync.
  2. Integrate — merge to the base branch, or open the MR/PR, per this
     project's own review rules (§3 step 7). Unmerged work left in an
     abandoned worktree is a lost feature and a drift source.
  3. Remove the worktree (`git worktree remove <path>`).
  4. Delete the merged branch.
- **No abandoned worktrees.** At session close, run `git worktree list`
  and clean up any whose branch is already merged, or that have sat
  untouched across more than a task or two.
- The *how* lives in the `using-git-worktrees` and
  `finishing-a-development-branch` skills — discipline plus those
  skills, no tooling audits this yet (see
  `METHODOLOGY.md#worktree-mandate-enforcement-status`).
