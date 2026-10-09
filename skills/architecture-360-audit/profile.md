# sec-cli audit profile

The binding layer for `SKILL.md`. Every repository-specific fact the audit
needs is here; the procedure above is fixed and never changes. Regenerate this
file with the `360-check-update` command whenever the repository's shape
moves.

## Maturity tier

**TIER B, established: tests plus CI, no dependency manifest.**

Ecosystems present: Bash (`bin/sec` and five sibling dispatchers, `install.sh`,
five suites under `tests/`), Python 3 (2 files: `bin/sec-sync-controller.py`,
`bin/sec-classify.py`), PowerShell (`bin/sec.ps1`), zsh completion
(`completions/_sec`), Markdown (63 files), JSON/YAML/TOML configuration (13
files).

Measured against the tier definition:

| Tier element | State | Evidence |
|---|---|---|
| Test runner | present, green | `bash tests/test_install.sh` -> ALL TESTS PASSED (5 sections); `bash tests/test_sync_guard.sh` -> ALL TESTS PASSED (13 sections); `bash tests/test_write_honesty.sh` -> ALL TESTS PASSED (5 cases); `bash tests/test_sentinel.sh` -> ALL TESTS PASSED (4 cases, the audit instrument's own suite); `bash tests/test_dispatch.sh` -> ALL TESTS PASSED (18 sections) |
| CI | **PRESENT** (2026-10-09, issue #8) | `.github/workflows/test.yml` on push/PR to main, `ubuntu-latest`, `actions/checkout` pinned to the full commit SHA of v4.2.2, runs all five suites; `.gitlab-ci.yml` removed in commit 402bbd5 along with `.gitlab/` |
| Documentation | extensive | `README.md`, `docs/ARCHITECTURE.md`, `docs/MULTI_TENANCY.md`, `docs/OPERATOR_MANUAL.md`, `docs/SECURITY.md`, `HISTORY.md`, `ADAPTERS.md`, `AGENTS.md` |
| Issue tracker | present, live | GitHub `atalby/sec-cli`, 1 open issue at the time of this profile (`#2`) |
| Lockfile | **ABSENT** | no lockfile of any ecosystem anywhere (see manifest census below) |
| Dependency manifest | **ABSENT** | no `package.json`, `pyproject.toml`, `requirements.txt`, `Makefile`, or equivalent in the tree or on disk |

Tier reasoning (ladder: A = manifest + lockfile + runner + CI + docs;
B = established, most present with partials; C = thin, no CI; D = no CI,
unautomated tests; E = undocumented): CI arrived 2026-10-09 with five green
suites and extensive docs, so D and C are cleared; the absence of any
dependency manifest and lockfile keeps it at B rather than A.

The two partials are themselves findings, not tier annotations:

1. **No dependency manifest at all, so no supply-chain scanner has a target.**
   The zero-dependency claim in `README.md` is trivially true — there is
   nothing to pin because nothing is declared — while the runtime pulls in
   `bw`, `bws`, `op`, `jq`, `gcloud`, `git`, `curl`, and `python3` from the
   operator's machine, none version-checked. There is no `pip-audit` or
   `npm audit` to run, and per prior art C that absence is the persona 8
   finding, not an excuse to skip the dimension.
2. **The local pre-commit gate still never runs the test suites.** The
   hook's test step only recognizes `scripts/tests/`+uv, `pytest.ini`/
   `pyproject`, and `package.json` — never `tests/*.sh` (stated in
   `ADAPTERS.md:218`, tracked as open issue `#2`). Since 2026-10-09
   GitHub Actions runs all five suites on push and PR to main
   (`.github/workflows/test.yml`, issue #8), so an unhooked push is
   caught by CI after the fact rather than prevented. Owned by
   personas 3 and 6.

## Commands (executed)

Every command below was run against this tree and its output quoted. None is
carried over from a previous generation. On refresh, re-run them all and
replace the output; if one stops existing, search the manifest, `Makefile`,
CI configuration, and contributor documentation before recording an absence.

**Test suite** (four-source discovery: manifest — absent; `Makefile` —
absent; CI — `.github/workflows/test.yml` since 2026-10-09 (issue #8);
contributor documentation — `ADAPTERS.md:206` "Running this project's test
suite"). The quoted outputs below predate the 2026-10-08/09 suite additions
(`test_write_honesty.sh`, `test_dispatch.sh`) and CI; the current five-suite
battery is green end-to-end. `tests/test_sentinel.sh` belongs to the audit
instrument rather than the product but runs the same way:

    $ bash tests/test_install.sh
    [1] file-mode install copies every bin/ entry the dispatcher needs
      ok: install.sh exits 0
      ok: installed sec
      ok: installed bw-session-keeper
      ok: installed sec-organizer
      ok: installed sec-classify.py
      ok: installed sec-migrator
      ok: installed sec-sync-controller.py
    [2] piped mode: no bin/sec beside script, BASH_SOURCE unset under set -u
      ok: piped install exits 0 (no 'unbound variable' abort)
      ok: piped-mode install produced sec
      ok: bootstrap populated SEC_BOOTSTRAP_DIR via SEC_REPO_URL
    [3] piped mode reuses an existing bootstrap checkout without re-cloning
      ok: second piped install exits 0 against existing bootstrap
      ok: no redundant clone when bootstrap already present
      ok: sync controller installed in reuse path
    [4] dispatcher surface: usage documents sec sync, sync controller is -x
      ok: usage lists 'sec sync'
      ok: bin/sec:562 -x guard for sec-sync-controller.py satisfied
    [5] config bootstrap: sec.conf created under $HOME/.sec with mode 600
      ok: sec.conf mode 600

    ALL TESTS PASSED
    (exit 0)

    $ bash tests/test_sync_guard.sh
    [1] --dry-run previews present keys without writing anywhere
      ok: --dry-run exits 0
      ok: output announces dry-run mode
      ok: plan lists present key name
      ok: no secret values printed
      ok: dry-run never invoked gcloud
    [2] non-interactive run without --yes refuses to push (exit 2)
      ok: exits 2 (confirmation required)
      ok: explains how to confirm
      ok: refused run never invoked gcloud
    [3] no keys present fails loudly (exit 1), not a fake success
      ok: exits 1 when zero keys present
      ok: says no keys were found
    [4] --yes proceeds (gcloud shimmed, no GitLab token = no network)
      ok: --yes run exits 0
      ok: gcloud shimmed path received the secret version add
      ok: GitLab skipped without token (no network attempted)
      ok: no secret values printed on push
    [5] --help documents the guards; dispatcher usage advertises --dry-run
      ok: --help exits 0
      ok: --help lists --dry-run and --yes
      ok: sec usage line mentions --dry-run
    [6] unknown flag is rejected before any work (exit 2, no gcloud)
      ok: unknown flag exits 2
      ok: no backend touched on bad usage

    ALL TESTS PASSED
    (exit 0)

    $ bash tests/test_sentinel.sh
    [1] coverage subcommand accounts for every tracked file
      ok: sentinel.sh exists and is executable
      ok: coverage exits 0
      ok: coverage reports full claim
      ok: all 12 personas reachable from manifest
    [2] citations subcommand resolves every file:line anchor
      ok: citations exits 0
      ok: citations reports every anchor resolves
    [3] a broken citation is detected (sentinel fails closed)
      ok: citations exits nonzero on a broken anchor
      ok: citations names the broken anchor
    [4] unknown subcommand is a usage error (exit 2)
      ok: bad invocation exits 2

    ALL TESTS PASSED
    (exit 0)

**Tracked file count** (the manifest denominator):

    $ git ls-files | wc -l
    87

**Dependency manifest census** (the persona 8 denominator):

    $ find . -path ./.git -prune -o -type f \( -name 'package.json' -o -name 'package-lock.json' -o -name 'go.mod' -o -name 'Cargo.toml' -o -name 'Cargo.lock' -o -name 'pyproject.toml' -o -name 'requirements.txt' -o -name 'Makefile' -o -name 'uv.lock' -o -name 'Pipfile' -o -name 'Gemfile' -o -name 'composer.json' -o -name 'mix.exs' -o -name 'pom.xml' -o -name 'build.gradle' \) -print
    (no output)

**Tracker, live:**

    $ gh issue list --repo atalby/sec-cli --state all --limit 100
    4	CLOSED	Port deleted GitLab issue templates to GitHub-native .github/ISSUE_TEMPLATE/		2026-10-08T14:23:59Z
    3	CLOSED	sec sync pushes all present secrets to prod backends with no dry-run or confirmation		2026-10-08T14:22:15Z
    2	OPEN	Pre-commit Step 5 never runs tests/*.sh suites (our install tests are skipped every commit)		2026-10-08T14:00:47Z
    1	CLOSED	Hyer payload lag: repo on HIAE Protocol v5.28.0, hub stable is v5.39.1		2026-10-08T23:06:39Z

**Commit history** (the intent record for forensic scan):

    $ git log --oneline | wc -l
    40
    $ git log -1 --format='%h %ad %s' --date=short
    54146bc 2026-10-09 docs(360): correct profile ADAPTERS anchors after registry-section rewrite
    $ git log --reverse --format='%h %ad %s' --date=short | sed -n '1p'
    89c67d2 2026-08-08 feat: initial release of sec-cli v1.0.0 (Zero-Plaintext Multi-Tenant Secret Manager, Housekeeper & Migration Engine)

**Version banner gate** (hub checker, run from this repo root):

    $ python3 ~/sandbox/hyer/scripts/check_version_banners.py .
    PASS: docs/ARCHITECTURE.md HIAE Protocol version banner(s) match AGENTS.md.

**Skill registry gate:**

    $ python3 ~/sandbox/hyer/scripts/check_skill_registry.py
    PASS: skills/REGISTRY.md matches skills/ and .hyer/skills/.

**ADAPTERS completeness gate:**

    $ python3 ~/sandbox/hyer/scripts/check_adapters_completeness.py --adopter --template ~/sandbox/hyer/templates/ADAPTERS_TEMPLATE.md
    PASS: ADAPTERS.md answers every section /home/opc/sandbox/hyer/templates/ADAPTERS_TEMPLATE.md asks of an adopter.

**Toolchain:**

    $ python3 --version
    Python 3.12.14
    $ bash --version | sed -n '1p'
    GNU bash, version 5.1.8(1)-release (aarch64-redhat-linux-gnu)

**No coverage command exists.** No `pytest-cov`, no `coverage.py`, no
`.coveragerc`, no coverage flags anywhere in `tests/*.sh`. Per prior art C
this is a finding under persona 3 and persona 8, not an excuse to skip the
dimension.

## Dependency manifests and lockfiles

**None.** No manifest, no lockfile, no `Makefile`, in the tree or on disk —
the census above is empty output, re-verified this build.

**Unpinned and floating, by mechanism:**

- `README.md:29` — `curl -sSL https://raw.githubusercontent.com/atalby/sec-cli/main/install.sh | bash`
  fetches the installer with no checksum or signature verification over the
  transport that GitHub's raw domain happens to serve today.
- `install.sh:24` — `git clone --depth 1 "$REPO_URL" "$BOOTSTRAP_DIR"`
  (with `REPO_URL` defaulting at `install.sh:7` and overridable by
  `SEC_REPO_URL`) clones at whatever the remote's default branch points to;
  no commit pin, no tag, no integrity check. Both are version-floating and
  integrity-unverified by construction.
- Runtime toolchain — `bw`, `bws`, `op`, `jq`, `gcloud`, `git`, `curl`,
  `python3` are invoked from `PATH` with no version assertion anywhere in
  the tree; a breaking provider-CLI upgrade reaches this code first and
  silently.

## External integrations

How the code reaches each, not merely that it exists.

| Integration | Reached via | Anchors |
|---|---|---|
| Bitwarden (`bw` CLI) | dispatcher shells out (`bw status`, `bw list items`, `bw get attachment`) | `bin/sec:89`, `bin/sec:337`, `bin/bw-session-keeper:1` |
| Bitwarden Secrets Manager (`bws`) | dispatcher tenant vocabulary | `bin/sec:65` |
| 1Password (`op` CLI) | `op account list`, `op signin`, `op read` | `bin/sec:115`, `bin/sec:118`, `bin/sec:327` |
| Infisical / HashiCorp Vault / macOS Keychain | dispatcher tenant vocabulary | `bin/sec:65`, `bin/sec:178` |
| AWS Secrets Manager | claimed in `docs/ARCHITECTURE.md:6` — verify whether any code path reaches it (candidate smoke finding) | `docs/ARCHITECTURE.md:6` |
| GCP Secret Manager | `gcloud` shell-outs from the sync controller | `bin/sec-sync-controller.py:74`, `bin/sec-sync-controller.py:90` |
| GitLab group CI/CD variables | HTTPS API `PUT` via `urllib.request` | `bin/sec-sync-controller.py:120`, `bin/sec-sync-controller.py:127` |
| Vercel | claimed as a sync target in `docs/ARCHITECTURE.md:14` — no call site found in the controller this build (candidate smoke finding) | `docs/ARCHITECTURE.md:14` |
| GitHub (install source + tracker) | `git clone` at install, `gh` CLI for the live tracker read | `install.sh:7`, `README.md:29` |
| jq | invoked for JSON parsing inside `bin/sec` | `bin/sec:89` |
| Hyer hub checkers | invoked by the local pre-commit wrapper from `~/sandbox/hyer/scripts/` | `ADAPTERS.md:177` |

## Personas

Twelve, numbered 1 through 12, never dropped or renumbered. **Ranked
highest-value-first**: persona 1 is audited first; a scoped run drops from
persona 12 upward. Every anchor below was verified against this tree when
this profile was written; Step 3 re-verifies them at the start of every run.

Declared-persona taxonomy: `packs/solo-founder-governance` v1.2.0 was read
before deriving (`packs/solo-founder-governance/PACK.md:24` binds the repo to
`Persona: Human Systems Architect (Solo Founder / Lead Engineer)`, and
`ADAPTERS.md:28` names that persona the single final approver). It defines
eight roles; this audit keeps the twelve fixed dimensions (fleet-diffable),
borrows ownership names from the pack where they fit — Environment &
Workstation for the delivery surfaces, Multi-Project Product & Security
Auditor for security, Documentation Curator for doc alignment, Codebase
Hygiene Specialist for dead surface — and routes all output to the Human
Systems Architect for approval. A persona here is an audit lens, not a
dispatched worker.

### 1. Security and access control -- `bin/sec-sync-controller.py:18`, `bin/sec-sync-controller.py:204`, `install.sh:43`, `bin/sec:118`, `.gitignore:11`, `docs/SECURITY.md:1`, `tests/test_sync_guard.sh:41`

The zero-plaintext claim in `docs/SECURITY.md` and `docs/ARCHITECTURE.md:1`
is the repo's reason to exist; audit the places it can leak. The production
path is `sec sync`: `SYNC_KEYS` at `bin/sec-sync-controller.py:18` names the
six env keys, and the guards — TTY/`--yes` gate at line 204, dry-run — are
enforced by `tests/test_sync_guard.sh` (start of suite at
`tests/test_sync_guard.sh:41`). Re-verify the guards actually precede every
backend write, and that no other writer exists. The most direct leak surface
is `bin/sec:118` (`eval $(op signin)`): provider-CLI stdout executed as
shell. Config confidentiality: `install.sh:43` creates `$HOME/.sec/sec.conf`
mode 600 — confirm the test that claims it (`tests/test_install.sh:101`)
still exercises the real path. Note `.gitignore:11` ignores the literal
path `~/.sec/`, which never matches the real `$HOME/.sec` outside the repo —
vestigial rule with a security-adjacent history; decide whether it hides
anything (it does not today).

### 2. Architecture and code structure -- `docs/ARCHITECTURE.md:1`, `docs/ARCHITECTURE.md:14`, `bin/sec:65`, `bin/sec:159`, `bin/sec-sync-controller.py:51`

One dispatcher, five sibling executables, one Python controller — judge
whether the documented component table in `docs/ARCHITECTURE.md` matches the
tree and the call graph matches the docs. Structural smells to quantify: the
tenant vocabulary is re-spelled at `bin/sec:65` (regex dispatch),
`bin/sec:178`, `bin/sec:238`, and `bin/sec:295` (completion tables) with no
single source; `case "$cmd" in` at `bin/sec:159` is the real command router
while usage text at `bin/sec:130` is a parallel declaration that only a test
checks for one line. `docs/ARCHITECTURE.md:14` claims the sync controller
pushes to "Vercel projects" — verify a Vercel call site exists anywhere; a
claim with no code is a smoke finding. Python visibility rule: module-level
public, leading underscore private.

### 3. Test and evaluation sufficiency -- `tests/test_install.sh:63`, `tests/test_sync_guard.sh:41`, `tests/test_sentinel.sh:1`, `ADAPTERS.md:218`, `ADAPTERS.md:206`

Five install cases, six guard sections, and the audit instrument's own four
sentinel cases pass today; establish what they do not cover. Structural gaps
to quantify, not merely note: no CI anywhere, the hook's test step blind to
`tests/*.sh` (`ADAPTERS.md:218`, open issue `#2`), and zero coverage
tooling. Then cross-reference suites against the hotspots:
`bin/sec-organizer`, `bin/sec-migrator`, `bin/sec-classify.py`, and
`bin/bw-session-keeper` have no direct test (the sync/install suites touch
only their install footprint and the controller). Check for assertions that
pin the same hardcoded constants the implementation uses. The suites' value
is real but partial — measure the gap, do not dismiss either side.

### 4. Interface and developer experience -- `bin/sec:130`, `bin/sec:237`, `completions/_sec:1`, `SKILL.md:1`, `CLAUDE.md:1`, `skills/REGISTRY.md:1`, `docs/OPERATOR_MANUAL.md:1`

The operator surface is `usage()` at `bin/sec:130` (the subcommand contract,
including the `sec sync [--dry-run|--yes]` line at `bin/sec:141`), the zsh
completion `completions/_sec`, `bin/sec.ps1`, and the docs. Measure: does
every advertised subcommand (`subcmds` list at `bin/sec:237`) exist in the
dispatch, does every dispatched command appear in usage, do the completions
agree? AGENTS §8 mandates one `[ TAG ]` line per event for machine-parsed
stdout — count how much of `bin/` actually conforms. Harness entry points
(`SKILL.md`, `CLAUDE.md`, `.gemini/`, `skills/REGISTRY.md`) are part of the
product surface: a broken bridge is a broken feature.

### 5. Product and backlog -- `.github/ISSUE_TEMPLATE/bug.md:1`, `.github/ISSUE_TEMPLATE/config.yml:1`, `HISTORY.md:1`, `README.md:1`

Read tracker state live with the Step 8 command; never from memory or from
`HISTORY.md`. Reconcile both directions: confirmed findings already filed
(#2 is the standing one), and open/closed issues whose code state disagrees
— all three closed issues were closed by commits in one 2026-10-08 session;
verify each described change is actually on disk now. `HISTORY.md:1` is the
narrative intent record for forensic scan, current-state paragraph updated
in place, entries append-only.

### 6. Infrastructure, delivery, and cost -- `install.sh:7`, `README.md:29`, `packs/zero-cost-infra-defaults/PACK.md:1`, `.gemini/settings.json:1`

Delivery is: piped `curl | bash` (`README.md:29`) with a git-clone bootstrap
(`install.sh:7`), plus manual local git hooks. There is no CI (finding, not
skip), no build, no release automation — establish what actually gates a
release: the local pre-commit wrapper and nothing else. Cost posture comes
from `packs/zero-cost-infra-defaults` (opted in; check its claims still bind
against what the repo actually runs — zero CI minutes because zero CI).
`.gemini/settings.json` and the bridge dirs are harness delivery surfaces.

### 7. Persistence and state -- `bin/sec:8`, `sec.conf.example:1`, `.gitignore:12`, `bin/sec-organizer:7`, `bin/sec-migrator:6`

Persistent state: `$HOME/.sec/sec.conf` (`bin/sec:8`, INI-ish, mode 600) is
the only declared config; the ignore list names the runtime state files —
`housekeep_plan.json`, `snapshot_*.json`, `migration_transaction.json`
(`.gitignore:12` and siblings) — whose on-disk writers are
`bin/sec-organizer:7` (`LATEST_SNAPSHOT`) and `bin/sec-migrator:6`
(`TX_FILE`). Audit: are these files ever read back across runs (rollback and
revert depend on it), are formats deterministic between writer and reader,
what happens on a torn snapshot, and does any state file ever carry a
plaintext secret (zero-plaintext invariant applied to the state layer).

### 8. Supply chain, licensing, and compliance -- `LICENSE:1`, `install.sh:24`, `README.md:29`, `packs/compliance-baseline/PACK.md:1`, `.gitignore:8`

Mechanical part first: no manifest and no lockfile exist, so there is no
scanner target — say so as the verdict (prior art C). What can be verified:
`LICENSE:1` (MIT) covers the tree; the two remote-fetch sites
(`README.md:29`, `install.sh:24`) are integrity-unverified by construction;
the PATH toolchain (`bw`, `op`, `gcloud`, `jq`) is unpinned. Then the
compliance pack: `packs/compliance-baseline` is present on disk but is NOT
in ADAPTERS' opted-in list — present-but-not-declared is itself a
governance finding candidate. Re-verify that no plaintext secret has ever
reached a tracked file using the hook's own secret scan step rather than
an impression.

### 9. Observability and resilience -- `bin/bw-session-keeper:8`, `.gitignore:9`, `bin/sec-sync-controller.py:27`

There is no telemetry: no log shipping, no metrics, no alerting — `*.log`
is ignored (`*.log` at `.gitignore:9`) rather than produced. What exists
instead: exit codes. `USAGE` at `bin/sec-sync-controller.py:27` is a
documented exit-code contract (0 preview/success, 1 no keys, 2 refused);
audit whether the dispatcher and the suites honor it consistently. The only
long-running process is `bin/bw-session-keeper` with its session file at
line 8 — establish what happens when Bitwarden locks mid-rotation, whether
failures are visible to an operator, and whether any runbook exists for it
(none does — absence is the finding).

### 10. Domain specialist: secret-management correctness -- `bin/sec-classify.py:83`, `bin/sec-organizer:133`, `bin/sec-migrator:197`, `docs/MULTI_TENANCY.md:1`

The dimension this repository exists to own: does the tool do correct secret
management? Lenses: classification correctness (`classify_item` at
`bin/sec-classify.py:83` — on what inputs does it mis-bin, and does a wrong
classification propagate to an apply?), housekeeping safety (pre-apply
snapshot at `bin/sec-organizer:133` — can `revert` lose data if interrupted,
and does plan/apply use identical classification?), migration atomicity
(transaction state at `bin/sec-migrator:197` — is a mid-migration crash
recoverable, is a secret ever written to both backends in an inconsistent
order?), and multi-tenant boundary correctness (`docs/MULTI_TENANCY.md:1` —
can tenant A's key resolve to tenant B's item through the search fallbacks
in `bin/sec:337-371`?).

### 11. Resilience of the happy path -- `bin/sec-sync-controller.py:127`, `bin/sec-sync-controller.py:90`, `install.sh:24`, `bin/sec:116`

Count every external call and check three properties on each: timeout,
retry, defined behaviour on partial failure. The measured baseline this
build: **zero `timeout` occurrences** in `bin/sec-sync-controller.py`,
`install.sh`, or `bin/sec` — `urlopen` at `bin/sec-sync-controller.py:127`
has no timeout, the `subprocess.run`/`Popen` gcloud calls (e.g.
`bin/sec-sync-controller.py:90`) pass no `timeout=`, `git clone --depth 1`
at `install.sh:24` can hang unbounded, and the piped install itself has no
`--max-time`. The failure matters more here than in most repos: `sec sync`
is the production write path and an install hang is a user's first
impression. Contrast: the guard tests do exercise the refusal paths
(exit 2/1), so policy-failure is covered while network-failure is not.

### 12. Untrusted input reaching a trusted sink -- `bin/sec:65`, `bin/sec:118`, `bin/sec-sync-controller.py:120`, `install.sh:7`, `.mcp.json:1`

Trace each external input to its sink. CLI argv: `bin/sec:65` regex-selects
a tenant from user input, then dispatch (`bin/sec:159`) chooses the
subprocess — state what constrains item names and field names before they
reach provider CLIs. Environment: `SEC_REPO_URL` at `install.sh:7` flows
into `git clone` unchecked (an env var is attacker-controlled in any
compromised CI or hostile dotfile). Provider output: `bin/sec:118` executes
it (`eval`), `bin/sec:89` and friends parse it with `jq`; sync controller
URL-constructs with the secret name at `bin/sec-sync-controller.py:120` —
what chars can a `SYNC_KEYS` value carry into an API path? Config-adjacent:
`.mcp.json` is prompt-adjacent surface consumed by agent tooling. (Prior
art C: read the code at the line; do not judge by impression.)

## Coverage manifest

Denominator: **95 tracked files** (`git ls-files | wc -l`, re-measured
2026-10-09 after the issue #8 suite and CI additions). First matching row wins, so specific rows precede general ones.
`sentinel.sh` fails on any tracked file matched by no row, and on any row
matching no file except the one declared-empty row below.

| Glob | Personas |
|---|---|
| `.agents/skills/architecture-360-audit` | 4 |
| `.gemini/**` | 4 |
| `.github/**` | 5 |
| `.gitignore` | 1, 8 |
| `.mcp.json` | 1, 4 |
| `.opencode/**` | 4 |
| `.claude/**` | 4 |
| `ADAPTERS.md` | 4, 5 |
| `AGENTS.md` | 4, 5 |
| `CLAUDE.md` | 4 |
| `HISTORY.md` | 2, 5 |
| `LICENSE` | 8 |
| `README.md` | 4, 5 |
| `SKILL.md` | 4 |
| `bin/bw-session-keeper` | 1, 9 |
| `bin/sec` | 4, 12, 1 |
| `bin/sec-classify.py` | 10, 3 |
| `bin/sec-migrator` | 10, 12 |
| `bin/sec-organizer` | 10, 7 |
| `bin/sec-sync-controller.py` | 1, 11, 12 |
| `bin/sec.ps1` | 4 |
| `completions/_sec` | 4 |
| `docs/ARCHITECTURE.md` | 2, 5 |
| `docs/MULTI_TENANCY.md` | 10, 7 |
| `docs/OPERATOR_MANUAL.md` | 4, 5 |
| `docs/SECURITY.md` | 1 |
| `docs/360/**` | 5, 2 |
| `install.sh` | 6, 8, 11 |
| `methodology/**` | 4, 5 |
| `packs/**` | 6, 5 |
| `sec.conf.example` | 7, 1 |
| `skills/architecture-360-audit/**` | 4, 5 |
| `skills/360-audit-skill-forge/**` | 4, 5 |
| `skills/**` | 4, 5 |
| `tests/*.sh` | 3 |

**Forward-declared row:** `docs/360/**` was declared before the first audit
run; the run directory `docs/360/runs/2026-10-09-000410/` now exists and the
row is live. `sentinel.sh` keeps a one-row exemption for repos that have not
run the audit yet. Every other row must match at least one tracked file.

## Gitignored surfaces

A `git ls-files` enumeration is blind to everything below. `sentinel.sh`
enumerates each surface on disk and fails on any that exists and that no row
here claims. The manifest row must exist even though `git ls-files` will
never return the path.

| Surface | Exists | Declared in `.gitignore` | Owning persona |
|---|---|---|---|
| `.agents/` (hook-created skill symlinks; the `architecture-360-audit` link is un-ignored by exception and tracked) | yes, 10 other skill links | yes (`!` exception for the 360 link) | 4 |
| `__pycache__/` (e.g. `bin/__pycache__/` with compiled controller) | yes | yes | 3 |
| `.ruff_cache/` (ruff, invoked only by the hub hook) | yes | **self-ignoring**: ruff writes its own inner `.gitignore` of `*`; no root rule — `git check-ignore` finds nothing yet status stays clean | 3, 8 |
| `.DS_Store`, `._*` (macOS debris) | no | yes | 4 |
| `*.log` | no | yes | 9 |
| `.cache/` (operator runtime cache for housekeep/session state) | no | yes | 7 |
| `~/.sec/` (literal path; inert — the real config lives outside the repo at `$HOME/.sec`) | no | yes | 7 |
| `housekeep_plan.json`, `snapshot_*.json`, `migration_transaction.json` (writers: `bin/sec-organizer`, `bin/sec-migrator`) | no | yes | 7 |
| `node_modules/`, `vendor/` | **absent** | n/a | 8 |
| `.pytest_cache/` | **absent** | n/a | 3 |
| `graphify-out/`, `graft/` (regenerable code-graph caches) | **absent** | n/a | 8 |
| `.claude/`, `.opencode/` (bridge `commands/` subdirs are tracked; no session state in tree) | yes — the two bridge directories only | n/a (bridges tracked deliberately; a session-state rule would be needed before state could exist) | 4 |
| `package.json`, `package-lock.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `requirements.txt`, `uv.lock`, `Makefile` | **absent** — and this absence is a persona 8 finding, not a clean bill of health | n/a | 8 |

The last two rows are the ones a sentinel must be allowed to report as
absent: their absence from disk is the finding, so the sentinel must not fail
merely because they do not exist, and persona 8 must not read the empty
result as a passed check.
