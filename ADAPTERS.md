# Adapters — sec-cli

Concrete tool bindings for this project or workstation. `AGENTS.md`
stays generic on purpose (§0's own boundary: it owns *how things get
done*, never *which specific tool*) — this file supplies the
opinionated specifics an agent session should use instead of guessing
or defaulting to whatever it's seen most often in training data.

This file was created during the 2026-08-22 sync of `AGENTS.md` to
methodology `stable` (v5.1.0). The prior `AGENTS.md` (HIAE Protocol
v4.1.0) carried project-specific policy text directly in the file; the
current upstream `AGENTS.md` deliberately removed all of that in favor
of this file. Everything below was migrated out of that old file
verbatim (or via opting into the matching reusable pack) so no policy
content was lost in the sync.

---

## Opted-in Policy Packs

Which of the central methodology repo's optional policy packs
(`packs/<name>/`) this project has deliberately opted into.
`AGENTS.md` §2 checks this section at boot.

- packs/zero-cost-infra-defaults (v1.0.0)
- packs/solo-founder-governance (v1.0.0)
- packs/ip-and-data-governance (v1.0.0)

The old `AGENTS.md`'s "Cost Circuit-Breakers & Spend Safety" $0
idle-scaling / free-tier-primacy bullets, its "Consolidated 2-Tool
Zero-Cost Secret Architecture" (Tier 1 local CLI injection, Tier 2
OIDC/native cloud secret manager/SOPS+KMS), its full 6-persona
Vertical Intra-Agent Persona Taxonomy (§1.1), and its "Human Systems
Architect" sign-off requirement for production deployments/UI
promotions are all now carried by these three packs rather than
restated here — see each pack's own `PACK.md` for the full text.

## Secrets

- **Tool**: `infisical run --` or `bws run --` (Infisical CLI or
  Bitwarden Secrets Manager CLI) — per the opted-in
  `packs/zero-cost-infra-defaults` pack's Tier 1 binding.
- **Retrieval pattern**: `infisical run -- <cmd>` or `bws run -- <cmd>`.
- **Tier 2 (CI/CD, production)**: OIDC Workload Identity Federation for
  CI; a native cloud secret manager with envelope encryption + IAM RBAC
  for production workloads; SOPS + KMS envelope-encrypted manifests for
  IaC/GitOps bootstrap. Per `packs/zero-cost-infra-defaults`.

## Cloud provider

- **Provider**: not specified as a single backend cloud provider in the
  migrated `AGENTS.md` — only a UI-hosting binding was named (below).
    Confirm this against the project's own `README.md`/`docs/` per
  `AGENTS.md` §6 rather than assuming.
- **UI / static hosting**: Vercel — migrated verbatim from the old
  `AGENTS.md` §6 "Multi-Platform Target Discipline": "static/serverless
  UIs typically deploy to a platform like Vercel; containerized/stateful
  services typically deploy to a cloud provider via IaC, managed
  centrally in a dedicated infra repo."

## Cost / Budget Circuit-Breaker Thresholds (bespoke — legacy binding)

The old `AGENTS.md` v4.1.0 included a specific numeric budget threshold
in its §1.0 Cost Circuit-Breakers section that upstream `AGENTS.md`
removed in v4.7.0 (see the central repo's `CHANGELOG.md`: the number
"only ever made sense for whichever specific project has real variable
infra-cost shape... and was never wired to anything that could actually
stop a session from exceeding it"). This doesn't map cleanly onto any
of the three existing packs, so it's preserved here verbatim rather
than being force-fit or dropped:

- **Budget Threshold**: No agent session or automated swarm may incur
  >$50/day in external cloud infrastructure spend or >1,000,000
  tokens/session without explicit Human Systems Architect authorization.
- **Breach Protocol**: Upon hitting any budget or rate threshold,
  execution must pause immediately and escalate to the Human Systems
  Architect.

Note per current `AGENTS.md` §1: this is not wired to any real
enforcement mechanism. Treat it as a documented convention, not an
enforced gate, until real infra-layer enforcement exists.

## Skill Synthesis & Memory Persistence (bespoke — legacy tool binding)

The old `AGENTS.md` v4.1.0 §10 named concrete Gemini-CLI-specific paths
and memory-tool names for its Agent Self-Learning architecture; current
upstream `AGENTS.md` §10 deliberately generalized this to "whichever
skill/procedure format and location this tool and project use" and
"whichever centralized, persisted knowledge-graph or memory store is
already configured for the project," pointing here. Migrated verbatim:

- **Skill package location**: `.gemini/skills/<skill-name>/SKILL.md`
  (or globally at `~/.gemini/config/skills/<skill-name>/SKILL.md`).
  Each skill MUST contain YAML metadata (`name`, `description`), a
  step-by-step SOP, edge-case warnings, and optional automated
  verification scripts.
- **Memory / knowledge-graph store**: the canonical Knowledge Graph /
  Memory MCP server (`claude-mem` / `memory` / `graphify`).

Verify these bindings are still accurate for whichever agent tool is
actually driving a given session in this repo (Claude Code, Gemini CLI,
etc.) rather than assuming — this section is a migrated fact from the
old file, not a re-verified current one.
