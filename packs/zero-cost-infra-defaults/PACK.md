# Pack: zero-cost-infra-defaults

Pack version: v1.0.0

## What this is

A concrete cost/vendor stack for a project that genuinely wants to
guarantee near-zero spend when idle, on a specific set of free-tier
cloud services. `AGENTS.md` core states only the *principle* (prefer
free tiers where they genuinely meet the need); this pack is one
real-world instantiation of that principle, not a universal default.

A team with latency SLAs that need warm instances, a different cloud
vendor, or a cost model that isn't "scale to zero at all costs" should
not adopt this pack as-is.

## Cost Circuit-Breakers & Spend Safety

- **Inviolable Zero-Cost ($0) Idle Auto-Scaling Policy**: All
  infrastructure manifests (Cloud Run, Cloudflare Workers, Vercel
  Serverless, AWS Lambda/Fargate) MUST configure scale-to-zero
  auto-scaling (`min_instances = 0`) to guarantee $0 spend when idle.
- **Free-Tier Tiering Primacy**:
  - Compute: GCP Cloud Run (`min_instances = 0`, max=10, 2M free
    reqs/mo) or Vercel Serverless Hobby tier ($0).
  - Edge Routing & DNS: Cloudflare Free Tier / Workers (100k free
    reqs/day).
  - Storage & DB: SQLite / Cloudflare R2 / GCP GCS Free Tier
    (5 GB/mo).
  - Paid Add-ons: Opt-in only (`enable_redis = false`, zero compute
    allocation when unutilized).

the Session Scoping and Breach Protocol guidance in `methodology/tiers.md` applies
regardless of whether this pack is adopted — they're tool-agnostic
process, not vendor choice, and stay in core rather than being
duplicated here.

## Secrets tooling (concrete tier-1/tier-2 tools)

`AGENTS.md` §6 states the generic two-tier secrets pattern (local
injection tool, no `.env` files; native cloud workload identity in
production). This pack's concrete tool choices for that pattern:

- **Tier 1 — Local Developer Workstations**: `infisical run --` or
  `bws run --` (Infisical or Bitwarden Secrets Manager CLI).
- **Tier 2 — CI/CD, Cloud Production & GitOps**:
  - **CI/CD Pipelines**: Free OIDC Workload Identity Federation for
    keyless CI authentication.
  - **Production Workloads**: A native cloud secret manager with
    envelope encryption and IAM RBAC.
  - **IaC & GitOps Bootstrap**: Envelope-encrypted secret manifests
    (SOPS + KMS) for git-diff auditability.
