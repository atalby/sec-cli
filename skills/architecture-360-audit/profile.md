# sec-cli audit profile

The binding layer for `SKILL.md`. Every repository-specific fact the audit
needs is here; the procedure above is fixed and never changes. Regenerate this
file with the `360-check-update` command whenever the repository's shape
moves.

## Maturity tier

**TIER B, established: tests plus CI, no project dependency manifest.**

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
| Issue tracker | present, live | GitHub `atalby/sec-cli`, 2 open issues at the time of this profile (`#2`, `#13`) |
| Lockfile | **ABSENT (project)** | no project lockfile of any ecosystem; the only lockfile on disk is the harness-managed `.opencode/package-lock.json` (2026-10-10, self-gitignored by `.opencode/.gitignore`) |
| Dependency manifest | **ABSENT (project)** | no `package.json`, `pyproject.toml`, `requirements.txt`, `Makefile`, or equivalent anywhere in the tracked tree; the only manifests on disk are `.opencode/package.json` + `.opencode/package-lock.json`, opencode's own plugin bootstrap (`@opencode-ai/plugin` 1.18.35, installed 2026-10-10) |

Tier reasoning (ladder: A = manifest + lockfile + runner + CI + docs;
B = established, most present with partials; C = thin, no CI; D = no CI,
unautomated tests; E = undocumented): CI arrived 2026-10-09 with five green
suites and extensive docs, so D and C are cleared; the absence of any
project dependency manifest and lockfile keeps it at B rather than A — the
`.opencode/` pair is harness tooling state, not a build input, so it does
not promote the tier.

The two partials are themselves findings, not tier annotations:

1. **No project dependency manifest at all, so no supply-chain scanner has
   a target.** The zero-dependency claim in `README.md` is trivially true —
   there is nothing to pin because nothing is declared — while the runtime pulls in
   `bw`, `bws`, `op`, `jq`, `gcloud`, `git`, `curl`, and `python3` from the
   operator's machine, none version-checked. There is no `pip-audit` target
   and no project `npm audit` target; the only npm manifest on disk is the
   harness's own `.opencode/package.json` (opencode plugin state, ignored by
   `.opencode/.gitignore`), which is tooling, not this project's supply
   chain. Per prior art C that absence is the persona 8 finding, not an
   excuse to skip the dimension.
2. **The local pre-commit gate still never runs the test suites.** The
   hook's test step only recognizes `scripts/tests/`+uv, `pytest.ini`/
   `pyproject`, and `package.json` — never `tests/*.sh` (stated in
   `ADAPTERS.md:233`, tracked as open issue `#2`). Since 2026-10-09
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
absent; CI — `.github/workflows/test.yml` since 2026-10-09 (issue #8), runs
the five bash suites below and nothing else; contributor documentation —
`ADAPTERS.md:221` "Running this project's test suite", which also names the
pytest mirror at `scripts/tests/`). All quotes below current as of the
2026-10-10 profile pass. `tests/test_sentinel.sh` belongs to the audit
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
      ok: installed sec.ps1
    [2] piped mode: no bin/sec beside script, BASH_SOURCE unset under set -u
      ok: piped install exits 0 (no 'unbound variable' abort)
      ok: piped-mode install produced sec
      ok: bootstrap populated SEC_BOOTSTRAP_DIR via SEC_REPO_URL
    [3] piped mode reuses an existing bootstrap checkout without re-cloning
      ok: second piped install exits 0 against existing bootstrap
      ok: no redundant clone when bootstrap already present
      ok: sync controller installed in reuse path
    [4] dispatcher surface: usage, completion surfaces, sync controller is -x
      ok: usage lists 'sec sync'
      ok: usage lists fish among completion shells
      ok: zsh completion offers sec sync
      ok: bash completion offers sec sync
      ok: fish completion offers sec sync
      ok: tracked completions/_sec matches 'sec completion zsh' output
      ok: bin/sec:562 -x guard for sec-sync-controller.py satisfied
    [5] config bootstrap: sec.conf created under $HOME/.sec with mode 600
      ok: sec.conf mode 600
    [6] piped install never trusts a foreign cwd's bin/sec (F038 supply-chain)
      ok: piped install from foreign cwd exits 0
      ok: foreign cwd bin/sec ignored
      ok: piped mode bootstrapped from SEC_REPO_URL instead of cwd
    [7] LICENSE is installed alongside the binaries (F051)
      ok: LICENSE copied to install dir, byte-identical
    [8] file-mode install warns about missing runtime dependencies (F053)
      ok: install still succeeds with jq/python3 absent
      ok: warnings name both missing runtime deps
    [9] piped install fails with a clear diagnostic when git is absent (F053)
      ok: piped install without git exits non-zero
      ok: clear git-missing diagnostic

    ALL TESTS PASSED
    (exit 0)

    $ bash tests/test_sync_guard.sh
    [1] --dry-run previews present keys without writing anywhere
      ok: --dry-run exits 0
      ok: output announces tagged dry-run mode
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
    [7] dry-run names the GCP destination from GCP_PROJECT_ID (F044)
      ok: [7] dry-run exits 0
      ok: [7] plan names the configured project
      ok: [7] still zero backend calls in dry-run
    [8] dry-run names the GitLab destination from GITLAB_GROUP_ID (F044)
      ok: [8] dry-run exits 0
      ok: [8] plan names the configured group
      ok: [8] GitLab shown as active target when token present
    [9] real --yes push sends --project=<GCP_PROJECT_ID> to gcloud (F044)
      ok: [9] push exits 0
      ok: [9] gcloud shim saw the configured project
    [10] backend write failure exits 3 with a FAILED notice, no secret leak (F044)
      ok: [10] exits 3 on backend write failure
      ok: [10] output marks the sync FAILED with [ERROR] tag
      ok: [10] no secret values printed on failure
    [11] a failing backend write must exit 3, never a fake success (issue #6)
      ok: failed write exits 3 (backend failure)
      ok: no false success line on failed write
      ok: failure notice carries the backend's own stderr
      ok: summary reports the failure
      ok: no secret values printed on failure
    [12] backend timeouts are configured (no unbounded gcloud/urlopen)
      ok: controller sets timeout= at 4 call sites (>=3)
    [13] --help documents exit 3 so the extended contract is discoverable
      ok: --help exits 0
      ok: --help documents exit 3 (backend write failure)

    ALL TESTS PASSED
    (exit 0)

    $ bash tests/test_write_honesty.sh
    [1] sec set for an unsupported tenant fails loudly (exit 1, not silent 0)
      ok: unsupported tenant set exits 1
      ok: tagged refusal names the unsupported tenant
    [2] housekeep apply refuses an unsupported backend, keeps the plan
      ok: bws apply exits 1
      ok: plan file kept on refusal
      ok: no success banner on refusal
      ok: tagged refusal explains the unsupported backend
    [3] housekeep apply (op) honours --tags and fails hard on backend error
      ok: op apply surfaces backend failure (exit 1)
      ok: plan kept after failed op apply
      ok: snapshot kept after failed op apply
      ok: no success banner on failure
      ok: op apply succeeds against a working backend
      ok: op invoked with --tags
      ok: no bogus --tag flag
    [4] migrate --apply refuses to clobber an unresolved transaction
      ok: apply with unresolved TX exits 1
      ok: existing TX untouched, tagged undo hint
    [5] migrate --apply fails loudly on an empty-valued item (no fake success)
      ok: empty-val item aborts apply with exit 1
      ok: prints tagged migration ERROR notice
      ok: transaction log written on failure
    [6] housekeep revert: a failed bw edit is surfaced, snapshot kept, no fake success
      ok: revert with a failing edit exits 1
      ok: snapshot kept after failed revert
      ok: no success banner on failed revert
      ok: tagged revert-failure notice names the item
    [7] housekeep revert: successful edits clear the snapshot and report success
      ok: revert with working edits exits 0
      ok: snapshot cleared after successful revert
      ok: tagged success banner on real success
    [8] migrate --undo on a corrupt transaction log fails loudly (no silent no-op)
      ok: corrupt TX --undo exits 1
      ok: tagged corrupt-TX notice
      ok: corrupt TX file kept for diagnosis
    [9] migrate --undo on a well-formed empty TX reports zero items and exits 0
      ok: empty TX --undo exits 0
      ok: reports zero created items

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

    $ bash tests/test_dispatch.sh
    [1] version/help/no-args surface
      ok: sec -v exits 0 with version
      ok: --help exits 0 with Usage
      ok: help states per-tenant injection truth (F001)
      ok: no-args exits 0 with Usage
    [2] unknown command falls through to usage (current behavior: exit 0)
      ok: unknown cmd prints usage, exit 0
    [3] bw get: plain key returns login.password
      ok: bw get MY_API_KEY -> pw-MY_API_KEY
    [4] bw get: item/field subpath
      ok: bw get github-app/password -> gh-pw
    [5] bw get: miss exits 1 with tenant error
      ok: miss exits 1
      ok: miss emits tagged [ERROR]
    [6] prefix tenant: bws get
      ok: bws get -> bws-pw-MY_KEY
    [7] prefix tenant: op get
      ok: op get -> op-pw-MY_API_KEY
    [8] prefix tenant: vault get splits item/field and calls vault kv get (F037 fix)
      ok: bare vault get returns stub value
      ok: bare key hits secret/data/anything with field=value
      ok: item/field vault get returns stub value
      ok: subpath hits secret/data/myapp/production with field=DATABASE_URL
    [9] prefix tenant: infisical get
      ok: infisical get -> inf-pw-MY_API_KEY
    [10] bw set create path
      ok: bw set exits 0
      ok: reports [ OK ] saved-to-Bitwarden
      ok: bw create item executed
    [11] op set create path
      ok: op set exits 0
      ok: reports saved-to-1Password
    [12] run dispatch: default exec + op delegation
      ok: sec run -- echo run-ok
      ok: sec op run -- echo op-run-ok
    [13] sync dispatch reaches the controller (dry-run)
      ok: sec sync --dry-run exits 0
      ok: prints tagged DRY RUN banner
      ok: prints tagged DRY RUN COMPLETE
      ok: no backend write during dry-run
    [14] housekeep plan executes the organizer
      ok: housekeep plan exits 0
      ok: plan file written
      ok: cache dir created 0700
      ok: plan file written 0600
      ok: plan has >=1 action
      ok: prints tagged Plan Summary
      ok: prints tagged Plan saved
    [15] migrate plan executes the migrator
      ok: migrate plan exits 0
      ok: discovers 2 fixture items
      ok: tagged ready-to-migrate counts 2
      ok: tagged Discovered counts 2
    [16] sec-classify.py direct smoke
      ok: aws fixture classifies cloud/aws
    [16b] F017: classify reads login.password (AKIA key in password field -> cloud/aws)
      ok: AKIA in login.password classifies cloud/aws
    [16c] F017: a null uri in login.uris does not drop the item to confidence-0
      ok: null uri does not drop confidence to 0 (got 66)
    [16d] F018: iam.gserviceaccount.com classifies cloud/gcp, not cloud/aws
      ok: iam.gserviceaccount.com classifies cloud/gcp
    [17] keeper helper: rotate without session/master-pass, status output (invoked directly — F045)
      ok: keeper rotate without secrets exits 1
      ok: rotate names the missing master password
      ok: keeper status exits 0 with Vault Status banner
      ok: status reports session EXPIRED or MISSING
    [18] default_backend from sec.conf routes unprefixed get
      ok: default_backend=bws routes get to bws
    [19] F002: setup-keychain refuses plaintext file store without opt-in
      ok: plaintext store refused with exit 1
      ok: refusal message printed
      ok: master_pass file not created
    [20] F002: opt-in SEC_ALLOW_PLAINTEXT_MASTER_PASS=1 allows the mode-0600 file
      ok: opt-in stores master_pass with the given value
      ok: master_pass mode 600
    [21] F002: rotate refuses a legacy plaintext file without opt-in
      ok: rotate with unopted plaintext file exits 1
      ok: read refusal printed
    [22] F002: opt-in lets rotate consume a legacy plaintext file
      ok: opt-in rotate unlocks via stored pass
    [22b] F003: keeper unlock never puts the password on bw's argv
      ok: keeper unlock with password exits 0 and saves session
      ok: master password absent from bw argv
      ok: master password delivered to bw via env (BW_UNLOCK_PASS)
    [22c] F011: non-TTY unlock with no stored password fails with a message, not silently
      ok: non-TTY unlock exits non-zero
      ok: non-TTY unlock emits a tagged [ERROR]
    [22d] F011: non-TTY setup-keychain with no password fails with a message, not silently
      ok: non-TTY setup-keychain exits non-zero
      ok: non-TTY setup-keychain emits a tagged [ERROR]
    [22e] F021: sync with no controller errors instead of exiting 0
      ok: sync without controller exits non-zero
      ok: sync without controller emits a tagged [ERROR]
    [22f] F025: failing bw list items surfaces the provider error, not not-found
      ok: provider failure exits non-zero
      ok: provider failure emits a tagged [ERROR]
      ok: provider failure is not misreported as not-found
    [23] no producer still emits legacy [sec*] event prefixes (F048 retrofit)
      ok: no legacy [sec*] event prefixes in producers
    [23b] F026: sec.ps1 captures trailing args and execs without re-parse (static contract)
      ok: no Invoke-Expression re-parse in sec.ps1
      ok: trailing args captured via ValueFromRemainingArguments
      ok: no $args references left in sec.ps1
    [INFO] pwsh not present on this host; sec.ps1 functional run test (section [23c]) runs in CI
    [24] F039: hyer MCP wiring is env-resolved, PAT via env only, no sh -c
      ok: wrapper execs the server with HYER_HOME resolved (rc=0)
      ok: node invoked with the resolved server path
      ok: PAT delivered to node via environment
      ok: PAT never on argv
      ok: wrapper stdout clean for MCP stdio
      ok: missing checkout: tagged [ERROR] naming HYER_HOME, non-zero exit
      ok: tracked .mcp.json.example has no host path and no sh -c
      ok: example wires bin/hyer-mcp.sh
      ok: .mcp.json gitignored (host-local)
      ok: .mcp.json untracked
      ok: wrapper has no hardcoded host path
    [25] F024: op guard tests session validity (op whoami), not account configuration
      ok: expired session re-authenticated, get succeeds
      ok: value returned after re-auth
      ok: signin prompted when session invalid
      ok: failed signin: non-zero exit, tagged error, not misreported as not-found
      ok: signin attempted before giving up
    [26] #27: --scope on unsupported tenants refuses honestly (exit 2, tagged)
      ok: bws --scope refused with tagged error, exit 2
      ok: infisical --scope refused with tagged error, exit 2
    [27] #27: bw --scope resolves a folder name and restricts lookup
      ok: scoped get returns the folder's item value
      ok: lookup passed --folderid f-aaa
      ok: unresolvable folder: exit 1, tagged scope-folder-not-found
    [28] #27: op --scope substitutes the vault in synthesized URIs (bash + ps1)
      ok: bash op --scope reads from the named vault
      ok: unscoped op get still defaults to the private vault
      ok: ps1 op --scope reads from the named vault
    [29] #27: bw ambiguous item name refuses instead of first-match
      ok: ambiguous name: exit 1, tagged error lists both matches
      ok: slash form still extracts the field across matches
      ok: ps1 ambiguous name refuses (was a yellow notice)
    [30] #29: ps1 op read failure exits nonzero with an error (not silent success)
      ok: ps1 failed op read: nonzero exit, not-found error
      ok: ps1 successful op read still returns the value, exit 0
    [31] #30: ps1 set fails honestly (no backend, or store write fails)
      ok: ps1 set with no backend: nonzero exit + tagged error
      ok: ps1 set with failing bw create: nonzero exit, no false success line
      ok: ps1 set with a working bw reports success, exit 0
      ok: ps1 set with failing bws create: nonzero exit, no false success line
      ok: ps1 set with a working bws reports success, exit 0

    ALL TESTS PASSED
    (exit 0)

    $ python3 -m pytest scripts/tests/ -q
    .....                                                                    [100%]
    5 passed in 0.03s

**Tracked file count** (the manifest denominator):

    $ git ls-files | wc -l
    99

**Dependency manifest census** (the persona 8 denominator):

    $ find . -path ./.git -prune -o -type f \( -name 'package.json' -o -name 'package-lock.json' -o -name 'go.mod' -o -name 'Cargo.toml' -o -name 'Cargo.lock' -o -name 'pyproject.toml' -o -name 'requirements.txt' -o -name 'Makefile' -o -name 'uv.lock' -o -name 'Pipfile' -o -name 'Gemfile' -o -name 'composer.json' -o -name 'mix.exs' -o -name 'pom.xml' -o -name 'build.gradle' \) -print | wc -l
    44

    $ find . -path ./.git -prune -o -type f \( -name 'package.json' -o -name 'package-lock.json' -o -name 'go.mod' -o -name 'Cargo.toml' -o -name 'Cargo.lock' -o -name 'pyproject.toml' -o -name 'requirements.txt' -o -name 'Makefile' -o -name 'uv.lock' -o -name 'Pipfile' -o -name 'Gemfile' -o -name 'composer.json' -o -name 'mix.exs' -o -name 'pom.xml' -o -name 'build.gradle' \) -print | grep -vc '^./\.opencode/'
    0

    44 hits, every one under `.opencode/` (2 root files plus 42 below
    `.opencode/node_modules/`), zero anywhere else in the tree. First seen
    2026-10-10, when opencode bootstrapped its plugin dependency there;
    the pre-bootstrap census was `(no output)`.

**Tracker, live:**

    $ gh issue list --repo atalby/sec-cli --state all --limit 100
    30	OPEN	sec.ps1 'set' lies: reports success it never achieved		2026-10-10T13:42:04Z
    29	CLOSED	sec.ps1 op read failure still exits 0 with empty output (same honesty class as #24)		2026-10-10T08:53:48Z
    28	CLOSED	ADAPTERS.md test-suite section counts and Last-updated date stale (audit §8 item 11 residual)		2026-10-10T07:23:04Z
    27	CLOSED	bin/sec get: no folder/tenant/org scoping; arbitrary first match and on-miss full dump (F020)		2026-10-10T08:46:22Z
    26	CLOSED	bin/sec: op session guard tests op account list, not session validity (F024)		2026-10-10T07:10:32Z
    25	CLOSED	sec-classify.py: login.password/username/totp unread; GCP service-account token lost to AWS (F017/F018)		2026-10-10T06:43:24Z
    24	CLOSED	bin/sec get: failing bw list items is reported as Secret-not-found (F025)		2026-10-10T05:59:24Z
    23	CLOSED	bin/sec: sync arm falls through to exit 0 when controller is absent (F021)		2026-10-10T05:59:15Z
    22	CLOSED	bw-session-keeper: non-TTY unlock/setup dies silently before any message (F011)		2026-10-10T05:59:05Z
    21	CLOSED	ADAPTERS packs declaration misses 2 packs on disk; test-suite section stale (F052 + §8.11 drift)		2026-10-10T03:08:14Z
    20	CLOSED	.mcp.json hardcodes a foreign absolute repo path and pipes a live GitLab PAT into sh -c with no integrity pin (F039)		2026-10-10T04:25:06Z
    19	CLOSED	install.sh supply-chain hardening: piped-mode foreign bin/sec trust, LICENSE not copied, zero dependency checks (F038/F051/F053)		2026-10-10T03:35:41Z
    18	CLOSED	sec.ps1 run re-parses tokenized argv as PowerShell source; positional scope wrong (F026)		2026-10-10T03:32:37Z
    17	CLOSED	sec-organizer: cache dir never chmod 700; plan file written 0644 until apply (F014)		2026-10-10T03:14:36Z
    16	CLOSED	bw-session-keeper unlock passes master password as argv, contradicting SECURITY.md env-mitigation claim (F003)		2026-10-10T03:24:02Z
    15	CLOSED	sec-migrator: TX-file jq failure silently treated as empty transaction (audit F015)		2026-10-10T01:20:35Z
    14	CLOSED	sec-organizer revert: failed bw/op edits are discarded, snapshot deleted, success printed (audit F013 residual)		2026-10-10T01:20:33Z
    13	OPEN	Hub-side: PACK.md secrets section cites AGENTS.md §6 as stating the two-tier pattern (audit §8 item 14)		2026-10-10T07:47:24Z
    12	CLOSED	Full [ TAG ] stdout retrofit across sec-cli (audit F048)		2026-10-09T23:59:05Z
    11	CLOSED	bin/sec vault get: unbound item_name under set -u (audit F037)		2026-10-09T23:28:09Z
    10	CLOSED	bw-session-keeper: refuse plaintext master_pass file storage (audit F002)		2026-10-09T23:21:20Z
    9	CLOSED	Docs truth-up batch: phantom backends/Vercel/SoT claims, stale README usage, OPERATOR_MANUAL missing sync (report section 8)		2026-10-09T21:04:09Z
    8	CLOSED	Test backbone: 791 lines behaviorally untested, only --help executed, destination unpinned, no CI, sentinel suite not executable (F044-F046/F054/F042)		2026-10-09T23:00:59Z
    7	CLOSED	Silent no-op and lossy write paths: set arms exit 0 without storing, bws housekeep apply skips then deletes plan, op revert wrong flag, migrator TX gaps (F019/F012/F013/F015/F016)		2026-10-09T19:54:45Z
    6	CLOSED	sec sync reports success on failed writes: returncode unchecked, unconditional check mark, exit 0 after 100% failure, no timeouts (F006-F009)		2026-10-09T19:09:10Z
    5	CLOSED	#1 follow-up: packs/ never re-synced (7/9 differ from stable) + changelog review unrecorded (F055)		2026-10-09T20:00:52Z
    4	CLOSED	Port deleted GitLab issue templates to GitHub-native .github/ISSUE_TEMPLATE/		2026-10-08T14:23:59Z
    3	CLOSED	sec sync pushes all present secrets to prod backends with no dry-run or confirmation		2026-10-08T14:22:15Z
    2	OPEN	Pre-commit Step 5 never runs tests/*.sh suites (our install tests are skipped every commit)		2026-10-10T07:47:23Z
    1	CLOSED	Hyer payload lag: repo on HIAE Protocol v5.28.0, hub stable is v5.39.1		2026-10-08T23:06:39Z

**Commit history** (the intent record for forensic scan):

    $ git log --oneline | wc -l
    80
    $ git log -1 --format='%h %ad %s' --date=short
    3592421 2026-10-10 docs: update RESUME.md with issue #2 completion and new high-value work status
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

**None as a project surface.** No manifest, no lockfile, no `Makefile`
belonging to this project in the tree or on disk — the only on-disk census
hits are opencode's own harness install under `.opencode/` (see the census
above), which is tooling state, not a build input. Re-verified in the
2026-10-10 profile pass.

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
| Hyer hub checkers | invoked by the local pre-commit wrapper from `~/sandbox/hyer/scripts/` | `ADAPTERS.md:188` |

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

### 3. Test and evaluation sufficiency -- `tests/test_install.sh:63`, `tests/test_sync_guard.sh:41`, `tests/test_sentinel.sh:1`, `ADAPTERS.md:237`, `ADAPTERS.md:221`

Nine install sections, thirteen guard sections, nine write-honesty
sections, and the audit instrument's own four sentinel cases pass today
(as does the five-assertion pytest mirror at `scripts/tests/`); establish
what they do not cover. Structural gaps to quantify, not merely note:
GitHub Actions CI exists since 2026-10-09 (issue #8,
`.github/workflows/test.yml`) but runs only the five bash suites — the
pytest mirror is not wired in; the hook's test step is blind to
`tests/*.sh` (`ADAPTERS.md:237`, open issue `#2`); and there is zero
coverage tooling. Then cross-reference suites against the hotspots:
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
(`install.sh:7`), plus manual local git hooks. GitHub Actions CI has
existed since 2026-10-09 (issue #8, `.github/workflows/test.yml`: the five
bash suites on push/PR to main) alongside the local pre-commit wrapper;
there is no build and no release automation — establish what actually
gates a release: CI plus the wrapper, nothing else. Cost posture comes
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

Mechanical part first: no project manifest and no lockfile exist, so there
is no project-level scanner target — say so as the verdict (prior art C).
What can be verified:
`LICENSE:1` (MIT) covers the tree; the two remote-fetch sites
(`README.md:29`, `install.sh:24`) are integrity-unverified by construction;
the PATH toolchain (`bw`, `op`, `gcloud`, `jq`) is unpinned. Then the
compliance pack: `packs/compliance-baseline` and
`packs/human-team-coordination` are present on disk and were declared
opted-in in ADAPTERS on 2026-10-10 (audit F052 — the declaration itself
was late), so re-verify the declaration and the on-disk bytes still agree
rather than trusting either. Re-verify that no plaintext secret has ever
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

### 12. Untrusted input reaching a trusted sink -- `bin/sec:65`, `bin/sec:118`, `bin/sec-sync-controller.py:120`, `install.sh:7`, `.mcp.json.example:1`

Trace each external input to its sink. CLI argv: `bin/sec:65` regex-selects
a tenant from user input, then dispatch (`bin/sec:159`) chooses the
subprocess — state what constrains item names and field names before they
reach provider CLIs. Environment: `SEC_REPO_URL` at `install.sh:7` flows
into `git clone` unchecked (an env var is attacker-controlled in any
compromised CI or hostile dotfile). Provider output: `bin/sec:118` executes
it (`eval`), `bin/sec:89` and friends parse it with `jq`; sync controller
URL-constructs with the secret name at `bin/sec-sync-controller.py:120` —
what chars can a `SYNC_KEYS` value carry into an API path? Config-adjacent:
`.mcp.json.example` wires the host-local (gitignored) `.mcp.json` through
`bin/hyer-mcp.sh`, so agent tooling never carries a tracked exec string —
check that the wrapper keeps the PAT env-only. (Prior
art C: read the code at the line; do not judge by impression.)

## Coverage manifest

Denominator: **99 tracked files** (`git ls-files | wc -l`, re-measured
2026-10-10 after the issue #2 pytest suite (`scripts/tests/`) and the
`RESUME.md` resume marker landed: 96 + 3). First matching row wins, so
specific rows precede general rows.
`sentinel.sh` fails on any tracked file matched by no row, and on any row
matching no file except the one declared-empty row below.

| Glob | Personas |
|---|---|
| `.agents/skills/architecture-360-audit` | 4 |
| `.gemini/**` | 4 |
| `.github/**` | 5 |
| `.gitignore` | 1, 8 |
| `.mcp.json.example` | 1, 4 |
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
| `bin/hyer-mcp.sh` | 1, 4 |
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
| `RESUME.md` | 4, 5 |
| `sec.conf.example` | 7, 1 |
| `scripts/tests/**` | 3 |
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
| `.mcp.json` (host-local MCP wiring; tracked copy removed in issue #20, `.mcp.json.example` is the tracked template) | yes | yes | 4 |
| `node_modules/`, `vendor/` | `node_modules/` **present once** — `.opencode/node_modules/` (opencode's plugin dependency tree, 42 manifests below it); `vendor/` absent | yes — `.opencode/.gitignore` line 1; no root rule needed | 8 |
| `.pytest_cache/` | **absent** | n/a | 3 |
| `graphify-out/`, `graft/` (regenerable code-graph caches) | **absent** | n/a | 8 |
| `.claude/`, `.opencode/` (bridge `commands/` subdirs are tracked) | yes — both bridge dirs; `.opencode/` additionally carries opencode's plugin install since 2026-10-10 (`package.json`, lockfile, `node_modules/`, self-written `.gitignore`) | partially — bridges tracked deliberately; the plugin install self-ignores via `.opencode/.gitignore` | 4 |
| `package.json`, `package-lock.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, `requirements.txt`, `uv.lock`, `Makefile` | **absent as a project surface** — and that absence is a persona 8 finding, not a clean bill of health | n/a | 8 |
| `.opencode/package*.json` | yes — 2 files, opencode's own plugin bootstrap (`@opencode-ai/plugin` 1.18.35), first seen 2026-10-10; harness tooling state, not a project build input | yes — `.opencode/.gitignore` (written by opencode, ignores itself too) | 4, 8 |

The `node_modules`/`vendor` and project-manifest rows are the ones a
sentinel must be allowed to report as absent: their absence from disk is
the finding, so the sentinel must not fail merely because they do not
exist, and persona 8 must not read the empty result as a passed check.
The `.opencode/package*.json` row is the mirror case: the same sentinel
fails closed until a row claims a manifest that does appear, which is how
the 2026-10-10 plugin bootstrap was caught (suite `tests/test_sentinel.sh`,
3 assertions red until this row existed).
