# Policy Packs

`AGENTS.md` core deliberately takes no position on vendor stacks,
governance identities, compliance regimes, or team-coordination
mechanics — it stays project-agnostic so it can be copied verbatim
into any project (see `AGENTS.md` §0). A **pack** is where a specific
project records its own concrete, opted-in answer to one of those
questions.

## How a project opts in

A project lists the packs it uses under its own `ADAPTERS.md`'s
"Opted-in Policy Packs" section, pinned to a specific version:

```markdown
## Opted-in Policy Packs

- `packs/solo-founder-governance (v1.2.0)`
```

No `ADAPTERS.md`, or no such section, means zero packs apply — nothing
here is a default. See `templates/ADAPTERS_TEMPLATE.md` for the
generic convention.

## Versioning

Each pack carries its own `Pack version:` line in its `PACK.md`, bumped
independently of `AGENTS.md`'s own HIAE Protocol version. A pack change
is a deliberate, reviewed edit — not a silent one — since a project has
pinned a specific version in its own `ADAPTERS.md`; bumping a pack's
content without also updating every adopting project's pin is exactly
the kind of drift `check_hub_own_pack_declaration` (a function in
`scripts/check_methodology_sync.py`) and that script's pack-diff check
exist to catch.

## The packs in this repo

| Pack | What it is |
|---|---|
| [`solo-founder-governance`](solo-founder-governance/PACK.md) | The 9-persona vertical taxonomy for a solo-founder (or single-final-approver) org, and the binding for `AGENTS.md`'s generic "designated approver" placeholder. Includes each persona's system prompt. |
| [`zero-cost-infra-defaults`](zero-cost-infra-defaults/PACK.md) | A concrete free-tier vendor stack (Cloud Run/Vercel/Cloudflare/SQLite) for a project that wants to guarantee near-zero spend when idle, plus the concrete secrets-tooling choices (`infisical`/`bws` locally, OIDC + a native cloud secret manager in production) for `AGENTS.md` §6's generic two-tier pattern. |
| [`ip-and-data-governance`](ip-and-data-governance/PACK.md) | One specific org's IP-ownership clause and a zero-data-leakage mandate (no exfiltrating proprietary code/skills to third-party training pipelines or untrusted endpoints). The ownership clause is a legal fact about one org — rewrite it before adopting anything else in this pack. |
| [`compliance-baseline`](compliance-baseline/PACK.md) | A starting engineering-process checklist (audit logging, data retention/PII minimization, a breach-escalation stub) for a Product-tier repo pursuing SOC2/GDPR/HIPAA-style obligations. Explicitly not legal or compliance advice, and adopting it does not make a project compliant with anything — it scopes to what engineering process can mechanically own before handing off to real counsel/an auditor. |
| [`human-team-coordination`](human-team-coordination/PACK.md) | Mechanics for how multiple *humans* on a team coordinate with each other and the agent sessions they direct — pairing, on-call/escalation, blameless postmortems, and resolving conflicts between concurrent sessions on overlapping code. Distinct from the code-level merge-review gate, which is `AGENTS.md` core. |

## Which ones this hub (`hyer`) itself has opted into

Per this repo's own `ADAPTERS.md`: `solo-founder-governance`,
`zero-cost-infra-defaults`, and `ip-and-data-governance`.
`compliance-baseline` and `human-team-coordination` live here for other
adopting projects to opt into — `hyer` itself is Platform-tier with a
single accountable founder, so neither currently applies to it.
