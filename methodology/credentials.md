# Credentials & Blast Radius

> Detail module for `AGENTS.md` §6. Loaded on demand — see the Module
> Table at the top of `AGENTS.md`. This file is part of the adopter payload
> (`methodology/adoption.md`: "adopting Hyer means the full payload, not
> a hand-picked subset"), copied alongside `AGENTS.md` and `skills/`. Load this
> before any infra, secrets, deployment, or credential-touching work —
> `AGENTS.md` §6 core keeps only the headline "stop and ask" rule.

- If a live credential appears in a conversation, a log, or a file,
  store it securely the moment you see it and never redisplay it.
- **Two-Tier Secret Architecture**: Raw API keys and database passwords
  are strictly forbidden in committed configuration files or `.env`
  files. Secret management follows a **two-tier pattern**; the
  concrete tools are project-specific fact — see your project's
  `ADAPTERS.md` for what's actually used, or an opted-in cost/infra
  pack (e.g. `packs/zero-cost-infra-defaults`) for one real-world
  instantiation (see `METHODOLOGY.md#in-plain-english-two-tier-secrets`
  for the plain-English version of why the split works this way):
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
  a cloud provider via IaC. Which platform this project actually uses
  is project-specific
  fact — see your project's `ADAPTERS.md` for what's configured, or an
  opted-in cost/infra pack for one real-world instantiation. During
  the Boot Sequence (§2), confirm which applies to *this* project from
  its own `README.md`/`docs/` rather than assuming.
- **Centralized Cloud Identity & Infrastructure Ownership** (added
  v5.22.2): cloud login and any modification to live cloud
  infrastructure or IAM route through whichever owner declares that
  domain in its own `ADAPTERS.md`, not ad hoc from whichever project
  happens to need it. Concretely:
  - **No automation authenticates as a human.** Any script, CI job, or
    agent-invoked tool that calls a cloud provider MUST use a service
    account / workload identity provisioned for that specific purpose
    — never a developer's own `gcloud`/`aws` login (see
    `METHODOLOGY.md#found-2026-08-28-human-account-cloud-lockout`).
  - **The owner of that domain provisions every service account /
    workload identity binding** used by other projects for cloud calls,
    the same way it owns IaC and deployment targets (Multi-Platform
    Target Discipline, above). A project needing new cloud access
    requests it there rather than creating its own credential.
  - **Any other repo/session that finds itself about to run a cloud
    provider's own CLI/console to change live infrastructure, IAM, or
    credentials stops and hands that to that domain's declared owner**
    instead — this is the same "bigger blast radius than approved,
    stop and ask" boundary this section already draws for individual
    actions, applied to which repo owns the action at all.
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
- **TLS is non-negotiable for every deployment**: no service, endpoint,
  or environment — `dev`, `staging`, `production`, preview, or an
  internal-only sidecar — is deployed without TLS; a cleartext listener
  is a defect, never a deferrable "internal/temporary" shortcut.
  Enforcement (CI gate, TLS-defaulting IaC) and remediation of existing
  deployments belong to whichever owner declares the deployment domain;
  this contract states the rule.
- **Deployment Authorization Triggers**: `dev`/`staging` are
  auto-authorized on 100% test-suite pass; `production` explicitly
  requires the project's designated approver's sign-off (`ADAPTERS.md` /
  an opted-in governance pack).

- If a blocker would require a broader scope, a higher-risk action, or a
  bigger blast radius than what was actually approved, **stop and ask.**
  Never silently substitute something riskier to route around an
  obstacle, even if it would technically work.
- If this project has real compliance obligations (SOC2, GDPR, HIPAA,
  or similar), see an opted-in compliance pack (e.g.
  `packs/compliance-baseline`) for a starting engineering-process
  checklist — not built into core, since requirements vary by
  jurisdiction and industry and must be verified with real
  legal/compliance counsel, never inferred generically from this file.
- **Adopting Hyer into an existing project is additive, not
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
- **Never run `git init` inside a directory without first checking
  whether it's already a linked worktree** (see
  `METHODOLOGY.md#found-2026-08-20-git-init-worktree-corruption`).
  Check first: `cat .git` — a one-line `gitdir: ...` pointer means it's
  a worktree link; a directory means it's already a real repo. If
  extracting a worktree's content into a genuinely standalone repo is
  the actual goal, use `git worktree remove` first, or a
  history-preserving extraction (`git subtree split`, `git
  filter-repo`) — never `git init`, which discards history instead of
  migrating it.
