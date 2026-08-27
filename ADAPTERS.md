# Adapters — sec-cli

Concrete tool bindings for this project or workstation. `AGENTS.md`
stays generic on purpose (§0's own boundary: it owns *how things get
done*, never *which specific tool*) — this file supplies the
opinionated specifics an agent session should use instead of guessing
or defaulting to whatever it's seen most often in training data.

Reconciled 2026-08-27 against the current
`templates/ADAPTERS_TEMPLATE.md` during the Hyer fleet sync (the same
pass already applied to `iac-infrastructure`, `talby-law-firm`,
`axiom-mesh`, `llm-fallback-manager`, `documesh`, `at-tech-website`,
and `whatsapp-messenger` — this file carried the same unverified
migrated legacy text as those repos' pre-sync copies: a `bws`/
`infisical` secrets binding, a removed `$50/day` budget block, and
`.gemini/skills/` paths).

---

## Opted-in Policy Packs

Which of the central methodology repo's optional policy packs
(`packs/<name>/`) this project has deliberately opted into.
`AGENTS.md` §2 checks this section at boot.

- `packs/zero-cost-infra-defaults (v1.0.0)`
- `packs/solo-founder-governance (v1.2.0)` — bumped from v1.0.0 in this
  sync (v1.1.0 added Codebase Hygiene Specialist, v1.2.0 added OSS
  Ecosystem Scout — 8-persona taxonomy total).
- `packs/ip-and-data-governance (v1.0.0)`

Dropped in this sync: a bespoke "$50/day, >1,000,000 tokens/session"
Cost Circuit-Breaker threshold, migrated verbatim from the pre-v5.1.0
`AGENTS.md`. Current `AGENTS.md` §1 removed that number upstream in
v4.7.0 specifically because it was never wired to anything that could
actually enforce it — restating it here contradicted the current
file's own text.

## Secrets

This repo IS `sec-cli` — the secrets tool itself, not a consumer of a
different one. Its own `AGENTS.md`-adjacent policy is therefore: this
repo's own multi-backend design (`bw`/`bws`/`op`/Infisical/Vault/AWS
Secrets Manager/GCP Secret Manager/`pass`/OS keychains, per
`README.md`) IS the secrets tool for every *other* repo on this
workstation, invoked as plain `sec`. For work *inside* this repo
itself (dev/test), the same `at-tech-io` fleet convention applies:

- **Tool**: `sec` (this repo's own built CLI, or `~/sandbox/dev-infra-fleet`'s
  wrapper if that's how it's invoked on this workstation), backed by
  Bitwarden (default tenant).
- **Retrieval pattern**: `sec run -- <command>` injects secrets into
  process memory; `sec get <key>` for a single value.

## Git host

- **Host**: **GitHub** (github.com) — not GitLab, unlike the rest of
  the `at-tech-io` fleet. `git@github.com:atalby/sec-cli.git`.
- **CLI**: `gh`, confirmed authenticated (`atalby`).
- **Note**: this repo also carries a `.gitlab-ci.yml` despite having no
  GitLab remote — pre-existing, not investigated or touched in this
  sync (out of scope; flag if it turns out to be dead weight).

## Issue tracker

- **Tracker**: GitHub Issues
- **Project**: `atalby/sec-cli`

## Hyer version sync

Per `AGENTS.md` §2 step 1 — use this instead of manually reading or
cloning `engineering-methodology`.

- **Tool**: `hyer` MCP server, wired in `.mcp.json`
  (`hyer-mcp/dist/stdio-server.js` from the hub checkout at
  `~/sandbox/engineering-methodology`, `GITLAB_TOKEN` injected via
  `sec get engineering-methodology-gitlab-pat` — the hub itself lives
  on GitLab even though this repo doesn't).
- **Check current/latest version**: `sync_status` with this repo's
  current `AGENTS.md` version as `current_version`.
- **Fetch latest content**: `get_methodology` with `version: "stable"`.
- **Known fragility**: `.mcp.json`'s path tracks the hub checkout's
  disk, not a git ref — the hub renamed `mcp-server/` → `hyer-mcp/` and
  server name `methodology-local` → `hyer` (now in `stable` as of
  v5.21.1). This repo's `.mcp.json` uses the current on-disk path from
  the start.
- **Note on `stable` moving fast**: this repo's sync landed at
  `stable` = `cf7804c` (v5.21.2) — the hub shipped v5.21.0 → v5.21.1 →
  v5.21.2 within roughly an hour of this same fleet-sync task starting.
  Per the hub's own `moving-stable-tag` skill: a manual copy is a
  point-in-time snapshot regardless of which ref fetched it; this is
  the resolved commit at copy time, not an expectation of staying
  perpetually current without a future re-sync.

## Skills registry

- **Registry file**: `skills/REGISTRY.md`
- **Contents**: the 9 adopter-distributable skills, copied from the
  hub's `stable` tag in this sync (this repo had no `skills/` before).

## Local pre-commit hook

- **Install/verify command**: from the hub repo,
  `scripts/install-hooks.sh ~/sandbox/sec-cli` — installs a thin
  wrapper that execs the hub's current `scripts/pre-commit-hiae.sh` by
  absolute path.
- **Last verified not-a-frozen-fork**: 2026-08-27 (installed for the
  first time in this sync). Note: the hub's own `scripts/pre-commit-hiae.sh`
  had a real bug fixed the same day (v5.21.2, issue #39) — steps 2/3/5/6
  silently no-op'd for any adopter using this exact wrapper pattern,
  due to those steps resolving their hub-internal `.py` scripts against
  the *committing repo's* cwd instead of the script's own directory.
  Since the wrapper always execs the hub's current script by absolute
  path, this repo picked up the fix automatically with zero action
  needed here.

## Known hub-side bug affecting this repo's pre-commit gate

`scripts/check_version_banners.py` (hub-side, invoked as step 3 of the
shared `pre-commit-hiae.sh`) hardcodes checking `docs/ARCHITECTURE.md`
and `WIKI.md` with no existence guard — written and only ever exercised
against `engineering-methodology`'s own repo, which has both. The
v5.21.2 fix (issue #39) made steps 2/3/5/6 actually run for adopters
using the `install-hooks.sh` wrapper pattern for the first time — which
means this hardcoded, unguarded two-file check now unconditionally
applies fleet-wide, not just to the hub. This repo has
`docs/ARCHITECTURE.md` (banner added, above) but no `WIKI.md` at all —
a real gap in the wiring, not something to paper over by fabricating an
empty `WIKI.md` just to satisfy the check. Reported upstream 2026-08-27
via `fleet-agent-swarm` to the `methodology` session.

## Running this project's test suite

- **Command**: none found — no `pytest.ini`/`pyproject.toml`/`Cargo.toml`/
  `go.mod`/`package.json` at repo root. This is a "zero-dependency"
  shell-script CLI (`install.sh`) per its own `README.md`; verify
  against current source before assuming there's truly no test harness
  anywhere in the repo.

## Cloud provider

Not applicable — `sec-cli` is a local CLI tool, not a deployed service.
