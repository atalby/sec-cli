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

## Repo ownership

Per `AGENTS.md` §1.0's Cross-Repo Ownership & Ask-Don't-Read Mandate
(added v5.28.0). Any session outside this repo should check this field
before reading or editing anything here — and ask rather than reach in
directly. This applies with extra weight here: `sec-cli` is the fleet's
own secrets tool, not just another repo.

- **Owner**: Persona: Human Systems Architect (Solo Founder / Lead
  Engineer) — this repo's opted-in `packs/solo-founder-governance`
  names a single final approver, and no other opted-in pack or doc here
  names a different owner.
- **Last updated**: 2026-10-12 (issues #78/#79: the fish completion surface
  now offers the tenant-prefix words and routes the organize alias to the
  housekeep subcommands, dispatch guards 22q/22r; issue #81: the ps1 completion now reads the real CommandAst.CommandElements (ArgumentElements does not exist, so the subcommand arms were dead) and all four surfaces complete the powershell shell word + migrate backend values, guards 22t/22u; issue #82: the bare help/version subcommands the dispatcher accepts are now completed on all four surfaces, guard 22v; issue #83: the `get --scope` and `set/create --type` flags the dispatcher accepts are now completed on all four surfaces, guard 22w; issue #65: corrected the stale `SEC_TEST_DISPATCH` opt-in and pre-commit "blind to `tests/*.sh`" claims across ADAPTERS.md, the 360-audit skill, and CI; issue #47: the 103 KB `HISTORY.md` narrative was
  split losslessly into per-date `history/` archives and guarded against re-bloat;
  issue #46: sentinel now guards the profile.md
  coverage denominator against the live tracked-file count; issue #44: sec.ps1 doc parity + non-zero exit on unimplemented
  commands; issue #48: `sec migrate` tagged usage/help exit-code parity; issue #49:
  re-measured the profile.md tagged-output census; dispatch 48, write-honesty 11, sentinel 9; issue #54:
  README/ARCHITECTURE/install.sh no longer understate jq as a housekeep-only
  dependency (it drives auth/get/set too), guarded by sentinel case [10];
  issues #55–#60: the sec.conf parser now skips comments/blanks and matches
  the key name exactly, all four completion surfaces offer the
  create/organize/keep aliases (ps1 scoped to what `sec.ps1` implements),
  the secret value moved off child argv on the bitwarden path (jq via
  `env.SECVAL`, blob on stdin), then the migrator's bw target, then the
  op/vault/infisical storers (stdin/`value=-`/transient 0600 `@file`; only
  `bws secret create` retains an argv value — vendor limitation, upstream
  bitwarden/sdk-sm #1568), and the fish/ps1 completions now offer
  --help/-h/--version/-v; issue #61: the sync controller's GitLab write
  path is now covered by a pytest mirror (`scripts/tests/test_sync_controller.py`)
  and does a defensive create-on-404 upsert (the GCP arm already created
  if absent); issue #62: the GCP create-if-absent branch itself is now
  pinned by sync_guard section [16] (the shim reads `SEC_TEST_GCLOUD_DESCRIBE_RC`);
  current suites: dispatch 79, write-honesty 13,
  sentinel 17, sync-guard 16, install 9; earlier 2026-10-10, later
  same day: issues #30–#35 —
  sec.ps1 `set` honesty fix + dispatch assertions, pytest mirror executes
  the four fast bash suites with dispatch opt-in behind `SEC_TEST_DISPATCH=1`,
  GitHub Actions runs the mirror in a venv (issue #2 half), Vercel phantom
  dropped from the sync controller, sentinel citations gained an anchor-content
  lint and an identifier-claim-existence lint; earlier the same day: audit
  follow-up issues #16–#28 —
  keeper/organizer/migrator/install/MCP/classify honesty guards, suite
  counts re-measured; prior 2026-10-09: 360 audit run 2026-10-09-000410
  and its report §8 doc truth-up applied, then issue #8: fifth test suite
  + GitHub Actions CI; earlier 2026-10-08 truth-up pass: dead GitLab CI
  removed, test suites documented, pre-commit re-verified, template gaps
  filled; mandate arrived 2026-09-07 with hub v5.28.0).

## Opted-in Policy Packs

Which of the central methodology repo's optional policy packs
(`packs/<name>/`) this project has deliberately opted into.
`AGENTS.md` §2 checks this section at boot.

- `packs/zero-cost-infra-defaults (v1.0.0)`
- `packs/solo-founder-governance (v1.4.0)` — re-synced to stable@736000d
  (v1.3.0 added InfraAgent's explicit Traits field, v1.4.0 added the
  UI/UX Design Reviewer — 9-persona taxonomy total; local was v1.2.0,
  8-persona, when issue #5 was filed).
- `packs/ip-and-data-governance (v1.0.0)`
- `packs/compliance-baseline (v1.0.0)` — byte-identical hub payload
  (declared 2026-10-10, audit F052: present on disk since the v5.39.1
  full-payload adoption but never listed here).
- `packs/human-team-coordination (v1.0.0)` — byte-identical hub payload
  (declared 2026-10-10, audit F052, same provenance).

Dropped in this sync: a bespoke "$50/day, >1,000,000 tokens/session"
Cost Circuit-Breaker threshold, migrated verbatim from the pre-v5.1.0
`AGENTS.md`. Current `AGENTS.md` §1 removed that number upstream in
v4.7.0 specifically because it was never wired to anything that could
actually enforce it — restating it here contradicted the current
file's own text.

## Local tooling discovery

- **Discovery command**: `sec --help` (same as `sec` with no args) —
  the dispatcher's own usage screen lists every subcommand
  (get/set/run/housekeep/migrate/sync/unlock/rotate/setup-keychain/
  completion), the config file location, and the configured tenants.
- **When to run it**: at session start before any secrets-touching
  task, instead of guessing subcommand names from README memory.

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
- **Note**: the legacy `.gitlab-ci.yml` and `.gitlab/` (issue/MR
  templates) were removed 2026-10-08 — no GitLab remote exists here,
  every pipeline step was an `|| true` no-op against a Python project
  layout this repo doesn't have (no requirements.txt/pyproject), and
  GitHub's native `.github/` conventions are what `gh` actually uses.
  (Confirmed dead first: their only in-repo reference was this
  file's own earlier "flag if dead weight" note.) The template
  content itself was ported to `.github/ISSUE_TEMPLATE/` the same
  day (issue #4), so nothing was lost.

## Issue tracker

- **Tracker**: GitHub Issues
- **Project**: `atalby/sec-cli`

## Persisted memory / knowledge-graph store

- **Tool**: `HISTORY.md` (this repo's durable narrative per AGENTS.md
  §5) as the in-repo store, plus host-level knowledge-graph MCP
  servers (graft, codebase-memory) that index this checkout — no
  in-repo graph output directory exists.
- **Where it lives**: in-repo at `HISTORY.md` (short current-state
  summary) and `history/<date>.md` (full per-period narrative); graph
  data lives in each MCP server's own storage outside the checkout.
- **Pruning policy**: `HISTORY.md` follows AGENTS.md §5's
  rotation/archival rule once it starts dominating session-load cost.
  Executed 2026-10-11 (issue #47): the single 103 KB file was split
  losslessly into per-date archives under `history/`, `HISTORY.md`
  reduced to a summary + links, and `sentinel.sh coverage` now fails
  if a dated entry, an over-budget summary, or an orphaned archive
  reappears. The graphs are still small, no pruning needed yet.

## Methodology version sync (Hyer)

Per `AGENTS.md` §2 step 1 — use this instead of manually reading or
cloning Hyer directly.

- **Hub location**: filesystem-local checkout `~/sandbox/hyer`, remote
  `git@gitlab.com:at-tech-io/infrastructure/hyer.git` (the hub lives
  on GitLab even though this repo doesn't).
- **Tool**: `hyer` MCP server, launched by `bin/hyer-mcp.sh`
  (resolves `$HYER_HOME`, default `~/sandbox/hyer`, runs
  `hyer-mcp/dist/stdio-server.js` from that checkout; `GITLAB_TOKEN`
  fetched via `sec get hyer-gitlab-pat` and exported to node's
  environment — never argv). MCP client config is host-local: copy the
  tracked `.mcp.json.example` to `.mcp.json` (gitignored) and set the
  two paths.
- **Check current/latest version**: `sync_status` with this repo's
  current `AGENTS.md` version as `current_version`.
- **Fetch latest content**: `get_methodology` with `version: "stable"`.
- **Known fragility**: (a) the hub checkout location still tracks disk,
  not a git ref — but since issue #20 (2026-10-10) that path lives only
  in the host-local, gitignored `.mcp.json` (template:
  `.mcp.json.example`), resolved at server start via `HYER_HOME`, so
  the tracked tree carries no absolute host path, no `sh -c` exec
  string, and the PAT is delivered via environment only (until
  2026-10-08 the tracked file had pointed at a never-valid
  `/Users/anass/...` path; corrected to `/home/opc/sandbox/hyer` then,
  re-hardened out of the tree under #20). (b) 2026-10-08: the
  server responded `fetch is not defined` to every method
  (`locate_hub`, `list_payload`, `get_methodology`) — a deterministic
  server-side bug, retried once and still failing, so the MCP read path
  is unusable until fixed. Adopters should fall back only to the
  contract's sanctioned clone byte path (`git show <peeled-sha>:<path>`
  in a clone that already exists), never to an unauthenticated request
  or a guessed project id.
- **Current payload state**: adopted HIAE Protocol **v5.39.1** on
  2026-10-08 via `/adopt-hyer`. Provenance: immutable tag `stable`
  peeled to commit `736000ddcbc9d5e0d4f373e242ba1ed5e6bdb1a8` (verify
  with `git ls-remote git@gitlab.com:at-tech-io/infrastructure/hyer.git
  'refs/tags/stable^{}'` — the SHA beside the tag is a check value, not
  the provenance claim; the tag is). All 39 payload files (AGENTS.md,
  methodology/**, skills/**) placed via the already-present-clone byte
  path (`git show <sha>:<path>` in `~/sandbox/hyer`, which predates the
  adoption) and proven byte-for-byte: `git hash-object <dest>` equals
  the blob id in commit `736000d` for every file, including the merged
  `skills/REGISTRY.md`. The `hyer` MCP server was unusable during this
  adoption (`fetch is not defined` from every method — server-side bug,
  see Known fragility); the contract's sanctioned clone path was used
  instead, with no hub-address reconstruction and no token fallback.
  Per the hub's own `moving-stable-tag` skill: a manual copy is a
  point-in-time snapshot regardless of which ref fetched it, not an
  expectation of staying perpetually current without a future re-sync.

## Skills registry

- **Registry file**: `skills/REGISTRY.md`
- **Contents**: 23 skill dirs under `skills/` — 22 adopter-distributable
  from the 2026-10-08 v5.39.1 adoption plus 1 project-specific
  (`architecture-360-audit`, built in-repo that same day) — plus 12
  `.hyer/skills/` hub-internal rows: 35 skill rows, one per skill dir.
  History: first populated in the
  2026-08-27 fleet sync (10 skills, no `skills/` before that);
  hub-internal rows repointed `.claude/skills/` → `.hyer/skills/` on
  2026-10-08 (commit 06f129a); full merge to the v5.39.1 incoming
  registry the same day (zero adopter-owned rows to preserve — every
  local skill is hub payload).

## Local pre-commit hook

- **Install/verify command**: from the hub repo,
  `scripts/install-hooks.sh --apply ~/sandbox/sec-cli` — installs a thin
  wrapper that execs the hub's current `scripts/pre-commit-hiae.sh` by
  absolute path.
- **Last verified not-a-frozen-fork**: 2026-10-08. At that session's
  boot the hook was found to *be* a frozen fork — a full byte-copy of
  the hub script with none of the hub's `.py` helpers beside it, so
  steps 3/5/6 silently no-op'd while still printing their banners
  (exactly what AGENTS.md's boot sequence forbids). Reinstalled with
  the command above; the forked copy was kept at
  `.git/hooks/pre-commit.hyer-backup-20261008134704`. The live gate
  then ran its full ~22 steps green end-to-end, commit-msg hook
  included. The earlier v5.21.2 issue #39 wrapper bug (fixed upstream)
  stays fixed automatically, since the wrapper always execs the hub's
  current script.

## Known hub-side bug affecting this repo's pre-commit gate (resolved)

None currently. The previously documented one — hub-side
`scripts/check_version_banners.py` hard-checking `docs/ARCHITECTURE.md`
and `WIKI.md` with no existence guard, which would fail any adopter
without a `WIKI.md` (this repo has none) — was fixed upstream: the
checker now tolerates a missing `WIKI.md` (version extraction returns
None for an absent file) and gates the wiki inline-current check on
being run inside the hub itself. Verified 2026-10-08 by reading the hub
source and running `python3 ~/sandbox/hyer/scripts/check_version_banners.py .`
from this repo root: PASS with no `WIKI.md` present. Originally
reported upstream 2026-08-27 via `fleet-agent-swarm`; resolved before
this pass, and this section was rewritten in place (not appended to)
per AGENTS.md §5's replace-don't-append rule.

## Running this project's test suite

- **Command**: `bash tests/test_install.sh` (9 sections, install path),
  `bash tests/test_sync_guard.sh` (16 sections, sync guard canaries),
  `bash tests/test_write_honesty.sh` (13 sections, silent-no-op write
  paths, revert/undo honesty, keeper sync-failure + non-TTY honesty), `bash tests/test_sentinel.sh` (17 cases,
  the 360 audit instrument's coverage/citations sentinel) and
  `bash tests/test_dispatch.sh` (79 sections, every `sec` dispatch arm
  plus the seven sibling `bin/` helpers the suite references —
  `sec-sync-controller.py` statically, its functional coverage living in
  the sync-guard and install suites) — all zero-dependency
  bash. Run all five before committing; added 2026-10-08/09 in e5c51d7,
  8c6dcbd, b326a14, c613d2c and eaab363; section counts refreshed
  2026-10-10 (audit F052, re-counted after #19, #22–#26 and the
  #27/#29/#30 assertions; last re-counted again after #33 added the
  advertised-target guard [14] to the sync_guard suite), then
  2026-10-11 after #52 added the F003-residual keeper argv guards
  (suite cases 22j and 22k), then #53 added the sync-provenance guard
  [15], then #54 added the runtime-dependency-truth guard [10] to the
  sentinel suite, then #55 tightened the sec.conf parser (`get_cfg_val`
  now skips comments/blanks and matches the key name exactly) with
  dispatch guards 18b/18c, then #56 added the completion-alias guard
  (suite case 22l; all four completion surfaces must offer
  create/organize/keep), then #58 moved the sec.conf value delivery off
  child argv (`sec set` now feeds jq via `env.SECVAL` and pipes the
  encoded blob to `bw create/edit item` via stdin instead of positional
  args) with dispatch guard 22m, then #59 kept the migrator's bw target off
  jq/bw argv too (dispatch guard 22n), and finished the rest of #59: the
  `1pass` set path and migrator's op arm now send an item JSON template to
  `op item create -` on stdin, the vault arm pipes the value to
  `vault kv put ... value=-`, and infisical stages the value in a transient
  mode-0600 file (`KEY=@path`) since it has no stdin channel — only
  `bws secret create` still takes the value on argv (vendor limitation, no
  stdin/file/env; upstream bitwarden/sdk-sm #1568), documented in
  docs/SECURITY.md, with dispatch guard 22o, then #60 added the
  completion-flag guard 22p (fish/ps1 now offer --help/-h/--version/-v,
  with sec.ps1 scoped to --help/-h), then #78 added the completion-tenant
  guard 22q (all four surfaces must offer the tenant-prefix words
  bitwarden/bw/1pass/op/bws/vault/infisical/keychain; the fish surface
  had omitted them), then #79 guarded the organize-alias case 22r (fish had omitted both).
  A sixth, zero-dependency pytest suite lives at `scripts/tests/`
  (`python3 -m pytest scripts/tests/ -q`, added in 00b1a65 under issue
  #2); since #31 it also **executes** all five bash suites
  (`test_install`, `test_sync_guard`, `test_write_honesty`,
  `test_sentinel`, `test_dispatch` — a regression in any of them fails
  pytest, verified by injection). The heavy `tests/test_dispatch.sh`
  (~14s, stub backends) runs in that mirror unconditionally: commit
  0284d39 removed the former `SEC_TEST_DISPATCH=1` opt-in (issue #65),
  so plain `python3 -m pytest scripts/tests/ -q` is now 29 passed.
- **Note**: the shared pre-commit's Step 5 does **not** glob `tests/*.sh`
  itself — it recognizes `scripts/tests/`+uv, `pytest.ini`/
  `pyproject.toml`, or `package.json` — which is why the `scripts/tests/`
  pytest mirror exists (issue #2, closed). With `uv` on PATH it therefore
  *does* run all five suites at commit time through that mirror (verified
  on the #63 commit's gate: 29 passed); with `uv` absent Step 5 warns
  that no suite applies and enforces nothing (issue #64). Since 2026-10-09
  GitHub Actions runs the five bash suites plus the pytest mirror on push
  and PR to main (`.github/workflows/test.yml`, issue #8; checkout pinned
  by full commit SHA).

## Cloud provider

_Not applicable: `sec-cli` is a local CLI tool, not a deployed service;
it has no cloud provider footprint and no IaC of its own._

## Docs mirror (if this ecosystem has one)

_Not applicable: AGENTS.md §5's cross-project documentation mirror has
not been adopted for this ecosystem; README, docs/, and HISTORY.md
stay in-repo only._

## Cross-session communication (if multiple agent sessions coordinate)

_Not applicable: this repo is worked by a single agent session at a
time and no cross-session coordination channel is configured or
needed for it._

## Proactive next-action timeout (`methodology/proactive-next-action.md`)

- **Tool**: opencode (this repo's agent tool).
- **Mechanism**: none configured — no auto-proceed timer; the session
  self-drives at task boundaries under standing orders (finish an
  item, immediately take the next) instead of a timed hook. This is
  the explicit "no equivalent mechanism" answer, not an unfilled gap.
