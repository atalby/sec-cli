# Resume point - sec-cli

## Session 2026-10-18 (63rd, 64th, 65th, 66th, 67th, 68th, 69th runs) -- 63rd: reverted the 62nd run's unsanctioned compaction; shipped #186; rotated this file's narrative history to history/ (issue #185). 64th (commit da794d8): shipped the #187 version-surface guards, count mirrors 67 -> 68; #187 closed after baseline re-verify. 65th: shipped #188 (parent-owned work root for the pytest mirror; fixes the mktemp leak under SIGKILL; 58 -> 65 collected tests), baseline re-verified green. 66th: shipped #189 (a sentinel section 44 deriving the `sec set` supported-tenant set from bin/sec's live store arms and requiring docs/ARCHITECTURE.md + docs/OPERATOR_MANUAL.md to name exactly it; OPERATOR_MANUAL's Complete CLI reference gained the missing restriction; sentinel cases 68 -> 69, assertions 916 -> 928); also cleared the stale #187 entry from this file's open-issue list. 67th: shipped #190 (sentinel section 45 deriving `sec housekeep` apply/revert's supported-backend set from bin/sec-organizer's two arms, requiring the two arms to agree with each other and with docs/ARCHITECTURE.md + docs/OPERATOR_MANUAL.md; both surfaces gained the missing restriction; sentinel cases 69 -> 70, assertions 928 -> 940). 68th: shipped #191 (the `sec get --scope` bw path masked a failing `bw list folders` read as a valid empty array via `|| echo '[]'`, hollowing the adjacent corrupt-listing guard so a locked vault or expired session was misreported as `scope folder not found`; the read is now `|| true` with an explicit empty/non-array payload guard before the scope resolves, and a class guard covers bin/sec, bin/sec-organizer and bin/sec-migrator; dispatch sections [14p]/[14q], dispatch 107 -> 109; the last surviving mask of the #169/#170 class and the only `|| echo '[]'` left in bin/). 69th: shipped #192 (op/vault fakes now drain stdin, eliminating the EPIPE/SIGPIPE race; dispatch 109 -> 110; section [11e]).

This run did three things, in order.

1. Reverted the 62nd run's unsanctioned, uncommitted RESUME.md compaction: it had
   dropped the Verified-baseline section and the structural-count line, so
   `sentinel.sh coverage` was RC=1 and the pytest mirror's sentinel case timed
   out. The bloat it was reacting to is now addressed properly in step 3; the
   root cause of the bloat was filed as #185.
2. Shipped #186: raised the pytest mirror's `SEC_TEST_SUITE_TIMEOUT` default from
   300s to 900s in `scripts/tests/test_install.py` (a heavily loaded
   `test_sentinel.sh` run takes ~263s, leaving only ~14% headroom at 300s).
3. Shipped #185 (this rotation): the 61st, 60th and 59th-run session entries and
   the prior "Shipped this session" list were moved VERBATIM into
   `history/2026-10-18.md`, leaving only current state here. Nothing was dropped
   or reworded - the moved lines are byte-identical, and the script asserted
   that every non-blank line of the pre-rotation file still appears in this file
   or in `history/2026-10-18.md`.

RESUME-POINT INVARIANTS (do not break - sentinel section 17 plus test_sentinel
cases [25], [28], [33] and [35] enforce these): this file MUST keep, between the
shipped-this-session heading and the single Verified-baseline heading, a
suite-counts "mirrors in sync" line, a Sentinel cases/assertions line, an
`N/8192 bytes` HISTORY.md size, and one tracked-files/personas/bash-suites line -
all matching the live tree.

Baseline re-verified green this run (run serially, no self-contention): the five
`tests/test_*.sh` suites ALL TESTS PASSED; `.venv/bin/python -m pytest -q` 65
passed; `sentinel.sh coverage` RC=0; `sentinel.sh citations` RC=0.

NEXT MOVE (resume point): #192 shipped and closed this run (the op/vault fakes in
tests/test_dispatch.sh now drain stdin, mirroring the bw idiom, eliminating
the EPIPE/SIGPIPE race that fabricated a 'stage: op item create' failure under
load; new section [11e] locks the class with a >64 KiB payload; dispatch 109 ->
110). Baseline re-verified green: all five bash suites ALL TESTS PASSED,
pytest 65 passed, sentinel coverage + citations exit 0. Open issues remaining
are gated/hub-side: #67 (fresh 360 audit, needs human scope approval), #92
(hub-owned unguarded counts), #51 (hub-side handoff). Tracker is GitHub
`atalby/sec-cli` (`gh`); the standing order names GitLab, but no `sec-cli`
project exists under `at-tech-io` and the remote is
`git@github.com:atalby/sec-cli.git`.

## Next autonomous work

The 5th-run sweep of ADAPTERS.md / docs/ARCHITECTURE.md / docs/OPERATOR_MANUAL.md
is complete (found and shipped #129), the 6th-run sweep of profile.md's
code-prose counts shipped #130-#132, the 7th-run sweep of profile.md's
remaining prose counts shipped #133, the 8th-run sentinel-robustness pass
shipped #134 (the executed-commands transcript twin of the tracked-file
denominator, 99 -> 109, now derived in section 5), the 9th run shipped #135
(section 7's per-suite count guard was the last `find`+`re.search` first-match;
now same-line-bound + `findall` all-must-match like section 9), and the 10th
run shipped #136 (the sentinel read every current-state file except the
360-audit-skill-forge generator spec; section 16 now cross-checks the forge's
declared shape against the live SKILL.md). profile.md's numeric claims and the
audit-skill family's cross-file shape claims are now exhaustively guarded. The
26th run shipped #146: the `~/.sec/sec.conf` mode `0600` natural-language copies
in README.md and docs/MULTI_TENANCY.md were the next unguarded current-state
claims; sentinel section 26 now ties both to the live `bin/sec` chmod on
`$CONFIG_FILE`. The 27th run shipped #147: section 9's `current suites:`
extractor was the last non-anchored first-match count-grab of the #118/#136
shape, so an earlier inline mention could shadow the real ADAPTERS.md snapshot;
the pattern is now line-anchored. The 28th run shipped #148: a full audit of the
45 remaining single-`re.search` extractors found every one matching exactly once
today, but RESUME.md's two own count mirrors (mirrors-in-sync line and the
`Sentinel = N cases / M assertions` total) were still searched over the whole
append-heavy file, so an earlier narrative echo could shadow the real claim; both
are now scoped to the `## Verified baseline` section body. The 29th run shipped
#149: the last five natural-language mode claims (README.md + OPERATOR_MANUAL.md
snapshot mode/path; ARCHITECTURE.md session, umask, cache-dir, plan, and sec.conf
modes) were the remaining unguarded current-state claims, so sentinel section 27
now binds each to its live chmod/umask. The 30th run shipped #150: the
runtime-dependency sentence (README.md + ARCHITECTURE.md) and the documented
`SEC_*` env vars were the last unguarded doc-name claims, so sentinel section 28
binds the dep set to install.sh's `for _dep` loop and each documented `SEC_*`
var to a live bin/ reader. The 31st run shipped #151: the `sec run`
env-injection backend prose (README.md + ARCHITECTURE.md) was the next
unguarded doc-name claim, so sentinel section 29 binds every prose site to the
live bin/sec `run)` arm's case patterns. The 32nd run shipped #152: the
classifier-category names (README.md + ARCHITECTURE.md) were the next unguarded
doc-name claim, so sentinel section 30 binds them to bin/sec-classify.py's
`CATEGORY_WEIGHTS` keys + the `general` fallback. The 33rd run shipped #153: the
completion surface (OPERATOR_MANUAL.md) was the next unguarded doc-name claim,
so sentinel section 31 binds its shell set + alias + `completions/_sec` to the
live bin/sec completion dispatch. The 34th run shipped #154: docs/ARCHITECTURE.md
bin/sec.ps1's native subset + bash-only full surface was the next unguarded
doc-name claim, so sentinel section 32 binds it to the live ps1 switch arms +
bin/sec dispatch. The 35th run shipped #155 (SECURITY.md's executables
enumeration, section 33), the 36th #156 and the 37th #157 (the `sec sync`
exit-code contract, section 34, extended to SKILL.md), the 38th #158
(SECURITY.md's argv/stdin mitigation tokens, section 35), and the 39th #159
(SECURITY.md's snapshot-contents claim vs bin/sec-organizer's live ten-field
schema, section 36). Next candidates, in
order: any remaining single-`re.search` count-grabs of that shape (below), then
the fresh 360 audit (#67, after human scope approval).
Cheapest concrete next candidates, in order:
- The **pytest-count mirror family is now self-maintaining** (case [22]'s
  controls derive the live collection count, the pattern case [27] already
  used), and the wider lesson it taught -- convert every hand-pinned
  English-numeral drift control in `tests/test_sentinel.sh` to the derived
  `num_word` form -- was swept to completion in commits 9a4938e/f129881
  (the `twelve personas` / `Nine install sections` / `twelve bound audit
  dimensions` sites and the `live suite has 9` expectation literal this
  section used to name are all derived now; verified gone this run). No
  hand-pinned numeral remains.
- (swept this run) A sentinel-robustness class: the guards added ad hoc
  (#123-#136) each attach to a specific section. #136 closed the last "a file it
  does not read" (the forge). The 28th run (#148) swept the remaining single
  `re.search(...)` extractors: a full audit (45 sites) confirms every one matches
  exactly once today, and the two RESUME.md mirrors whose file could realistically
  grow a shadowing echo are now scoped to their section. No non-anchored
  first-match count-grab on a shadow-prone doc remains; the rest are on
  low-drift code/doc surfaces where a second same-shape mention is implausible.
- **#126** (filed 3rd run, CLOSED in the 18th run) - `get_cfg_val`'s awk
  parser silently skipped a line with no `=`; the design call was taken the
  cheapest-reasonable-path way: a tagged `[WARN]` naming the line, parse
  result and exit code unchanged (dispatch [18d]). No in-repo action left.
The rest are gated and not autonomously actionable:
- **#67** (fresh 360 audit) - its Step-1 gate needs explicit human scope approval.
- **#92** (hub-side: two unguarded counts in hub-owned files) - gotcha 6; no
  in-repo remedy.
- **#51** (hub-side handoff items tracked upstream) - unfixable in-repo.

Resume command:
`cd /home/opc/sandbox/sec-cli && ./skills/architecture-360-audit/sentinel.sh coverage`

If picking un-tracked work instead, the cheapest high-value items are: re-run the
verified baseline below to confirm no drift, and the sentinel suite is now ~40s
(was ~97s) so full-suite runs are cheap enough to do on every check.

## Where things stand

- `main` is the only branch; the #185 rotation commit and the tracked-file
  mirror bumps that followed it were verified pushed (`origin/main` == local
  `main`) at the end of the 64th run.
- Tracker: **GitHub** (`gh --repo atalby/sec-cli`), not glab. Remote is
  `git@github.com:atalby/sec-cli.git`; `glab` errors "None of the git remotes
  configured for this repository point to a known GitLab host" (re-confirmed
  2026-10-13 against a live `glab auth status`, which IS authenticated --
  for gitlab.com, which this repo is not on).
- Open issues: **#67** (fresh 360 audit - human scope gate); **#92**
  (hub-side unguarded counts); **#51** (hub-side handoff, tracked upstream);
  **#192** (test_dispatch.sh's op/vault fakes not draining stdin -- shipped and
  closed in the 69th run); **#191** (the `sec get --scope` bw folder-listing
  mask -- shipped and closed in the 68th run); **#190** (`sec housekeep`
  apply/revert supported-backend contract unguarded
  and missing from the OPERATOR_MANUAL's Complete CLI reference -- shipped and
  closed in the 67th run); **#189** (`sec set` supported-tenant contract
  guarded on one surface only -- shipped and closed in the 66th run).
  **#188** closed in the 65th run (parent-owned pytest
  work root); **#187** closed in the 64th run (version-surface guards);
  **#185** closed in the 64th run (RESUME.md rotation);
  **#126** closed in the 18th run (warn design call, dispatch [18d]); #120
  closed earlier (repo-side observability half shipped, hook fix stayed
  hub-side). Re-verified live via `gh issue list` this run.
- Operator standing order says the tracker is GitLab/`glab`; re-verified this
  run that it is not -- `git remote -v` is `git@github.com:atalby/sec-cli.git`
  and `glab issue list` fails with "None of the git remotes configured for this
  repository point to a known GitLab host" while `glab auth status` shows a
  live gitlab.com login. This repo is GitHub-tracked, so `gh` is used.

## Shipped this session (all committed, pushed, CI green, issue closed)

Narrative rotated 2026-10-18 (63rd run, #185): the full per-issue shipped list
and the prior-session entries now live verbatim in `history/2026-10-18.md`. This
heading is retained because sentinel's own test cases [33] and [35] use it as
their probe anchor above the Verified-baseline section.

## Verified baseline (re-run before trusting anything)

```
for s in install sync_guard write_honesty sentinel dispatch; do bash tests/test_$s.sh; done   # all ALL TESTS PASSED
.venv/bin/python -m pytest -q                                                               # 65 passed
./skills/architecture-360-audit/sentinel.sh coverage                                        # exit 0
./skills/architecture-360-audit/sentinel.sh citations                                       # exit 0
```

Live suite section counts (sentinel `coverage` re-derives these; keep the three
mirrors in sync): dispatch 110, install 9, sentinel 70, sync_guard 16,
write_honesty 17. Sentinel = 70 cases / 940 assertions. HISTORY.md is at
6956/8192 bytes - headroom of 1236 bytes before its budget (the full narratives
live in `history/2026-10-15.md` through `history/2026-10-18.md`).
120 tracked files, 12 personas, 5 bash suites. No unmerged branches (only main).
No real TODO/FIXME debt in tracked files. Sentinel suite wall time ~150s (each
guard case re-runs full coverage a few times); the pytest mirror adds ~3.5 min.
Run both when a sentinel section changes.

## Gotchas worth not rediscovering

1. **Suite-count mirrors (dispatch):** three sites, bumped by hand whenever a
   dispatch section is added/removed - `profile.md:22`, `ADAPTERS.md:55`
   (`current suites: dispatch N,`), `ADAPTERS.md:265` (`` `bash tests/test_dispatch.sh`
   (N sections, ``). Sentinel `coverage` checks all three; `HISTORY.md` and
   `history/*.md` hits are historical narrative, leave them.
2. **Bump mirrors BEFORE capturing RED** (gotcha from #90/#91): a new test case
   changes the count and the control copies read those mirrors; stale mirrors make
   the control fail for the wrong reason.
3. **A fix above line 222 in `bin/sec` shifts every later `bin/sec:N` anchor** in
   `profile.md` (sentinel `citations` scans SKILL.md + profile.md only). Prefer a
   net-zero edit (replace an existing line, e.g. fold a guard into an existing
   line with `A && B; C`) so no re-pin is needed - that is how #100 avoided it.
   Otherwise re-run `sentinel.sh citations` and re-pin each N>=222 by +k.
4. **pre-commit HIAE runs the pytest suite and rejects ADDED comments/docstrings**,
   checks plain-text + TDD + granularity. It cannot see commit ordering inside one
   commit, so stage a test file with any impl change. Advisory WARNING when staged
   changes span 2 categories is recurring and benign; it also emits a
   "Step 23 (doc path refs)" advisory (issue #179) that does not block. As of
   the 60th run it reports 7 dangling backticked path refs: the 2 project-owned
   ones (`history/2026-10-11.md:58`, `profile.md:818`) name
   `scripts/pre-commit-test-suites.sh`, deliberately removed by issue #63, so
   they are benign narrative; the other 5 are hub-owned
   (`methodology/adoption.md:9`, `packs/solo-founder-governance/PACK.md:170` +
   `:215`, `skills/adopt-persona/SKILL.md:33`, `skills/adr-capture/SKILL.md:139`)
   -> hub-side, not an adopter fix. The mirror now uses
   `SEC_TEST_SUITE_TIMEOUT` (default 900s, raised from 300 by #186 after a
   loaded sentinel run took 263s) - see #104/#105.
5. **`gh issue close --comment` with a long heredoc can hang.** Write the body to
   a file: `gh issue close N --comment "$(cat f)"` (worked this session) or
   comment then close separately; verify state after.
6. **A guard needs one project-owned side.** A claim with both sides hub-owned
   (`packs/README.md` vs `PACK.md`, `AGENTS.md` vs its own §1.2) belongs upstream
   (that is #92) - not an adopter guard. Confirm ownership: `git log --oneline --
   <file>` returning only `chore(adopt): re-sync` means hub-owned.
7. **HISTORY.md is force-loaded** (sentinel section 6 guards the 8192-byte
   budget). Adding narrative means compacting an older clause in the same edit;
   full text goes in `history/<date>.md` (append-only).
8. **zsh does not word-split unquoted vars or support `read -ra`** (bash-only):
   use `bash -c` for multi-token probes.
9. **CI:** `.github/workflows/test.yml` - step "Run bash suites" runs
   test_install, test_sync_guard, test_write_honesty, test_sentinel, test_dispatch
   (NO pytest); step "Run pytest mirror" creates a venv and runs
   `python -m pytest scripts/tests/ -q`. A sentinel check that needs pytest must
   degrade gracefully (see #98). Runners are iac-infrastructure's domain - never
   create/edit runners.
10. **`sentinel.sh citations` scans only SKILL.md and profile.md** (not
    ARCHITECTURE.md); piping it to `tail` masks the real exit code - check `$?`.
11. **NEVER copy the tree with a bare `$REPO_ROOT`.** A prior profiling probe ran
    `cp -a "$REPO_ROOT/." "$W/"` with `REPO_ROOT` unset -> copied `/` and filled
    the disk. Always set and verify `REPO_ROOT` first; use the repo's own test
    helpers rather than ad-hoc copies.

## Ownership boundaries

`AGENTS.md`, `methodology/` and `packs/` are hub-synced - do not hand-edit.
`ADAPTERS.md`, `profile.md`, `RESUME.md`, `docs/`, `tests/`, `bin/sec`,
`HISTORY.md`, `history/` and `scripts/` are project-owned and safe to edit.
