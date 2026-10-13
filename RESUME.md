# Resume point - sec-cli

Session 2026-10-13 (4th run): shipped **#127** and **#128** in commit `c34c896`,
pushed to `main` (`a903ca5..c34c896`). #127: `bin/sec --help`'s `Configured
Tenants:` line was a hardcoded literal nothing derived from the dispatcher alias
regex; sentinel section 21 now compares the help line's cited alias set against
the live regex (both directions), test case [34] (2 probes + control, 10
assertions, 33->34 cases / 338->348). #128 (found while finishing #127): the
#124 size guard's section regex was unanchored, so a mid-line `## Verified
baseline` mention in the #124 narrative shadowed the real section header;
fixed with `(?m)^## Verified baseline`, test case [35] plants the shadowing
mention (4 assertions, 34->35 cases / 348->352). Also fixed the same
control-literal class #123 fixed: cases [28]/[29] hardcoded the live tracked
count (108); the planted mention is now derived from the live line and
assertions are regex-shaped. Tree clean on `main`, CI green.

Session 2026-10-13 (3rd run): shipped **#125** -- F041's second half. Deleted the
dead `[global] auto_rotate = true` from the heredoc and both doc samples, and
widened the #123 config-surface guard from two surfaces to all four (which
surfaced that `sec.conf.example` had already drifted and that
`docs/MULTI_TENANCY.md` was never guarded at all). Filed **#126** (the
`get_cfg_val` parser silently ignores a key with no `=`). No work in flight:
clean tree on `main`, CI green.

Session 2026-10-13 (2nd run): resumed an UNCOMMITTED tree that already held
most of #123 (dead `cli` config keys + a sentinel sub-check) and finished it --
the previous run left `sentinel.sh citations` red (39 shifted `bin/sec:N`
anchors), control case [22] broken on two hand-bumped literals, and
RESUME.md's mirrors unbumped. Shipped #123 (commit `ae9ba7a`) plus a
follow-up defect found while finishing it: two control assertions hardcoded
the live suite/pytest counts, so every legitimate count bump broke them; both
are now regex-shaped. Then shipped #124 (`8e528a2`), guarding RESUME.md's own
HISTORY.md size claim. Filed **#125** as the next item. No work in flight:
clean tree on `main`, CI green.

Session 2026-10-13: shipped #119 (commit `9864fb0`), filed #120 (one-off
flaky `test_dispatch.sh` failure in the pre-commit Step 5 run; not reproduced
in ~16 attempts), and opened #121 (bare line-reference guard). #121 and #122
then shipped in `4515b56` / `71df727`.

Written 2026-10-12 after closing #118 (commit `aa0eb12`), #117 (commit
`3f0e69b`), #116 (commit `fddb57b`), #115 (commit `2549973`), #114 (commit
`5e295c1`), #113 (commit `d4890c3`) and #112 (commit `d9fb2d3`), all pushed.
This lane shipped a long run of guard/fix/perf units (#97..#123), all CI-green.

The open item **#120** below has no in-repo remedy yet; every other open item
is hub-side or human-gated. If the lane is run again, the highest-value
candidates are a fresh sweep for the next unguarded current-state claim (as
#116, #117 and #123 were) or another sentinel-robustness class (as #118 was),
then the fresh 360 audit (#67, after human scope approval).

## Next autonomous work

Start with a fresh sweep for the next unguarded current-state claim (the class
#116, #117, #123, #124 and #125 were all instances of), then another
sentinel-robustness class (as #118 was), then the fresh 360 audit (#67, after
human scope approval).
Cheapest concrete next candidates, in order:
- Re-measure every numeric claim in `ADAPTERS.md`, `docs/ARCHITECTURE.md` and
  `docs/OPERATOR_MANUAL.md` against the live tree and file one issue per
  unguarded claim. #123, #124 and #125 were all found this way; the audit
  profile's own line-number anchors are guarded by `citations`, but its prose
  counts are not.
- **#126** (filed this run) - `get_cfg_val`'s awk parser silently skips a line
  with no `=`, so a `default_backend bitwarden` typo is ignored with no signal
  and falls back to the built-in default. The intended behavior (reject the
  file vs emit a tagged `[WARN]`) is a design decision that changes CLI output,
  so it needs a human call, not an autonomous edit. Filed rather than fixed
  because #123 and #125 both touched this parser and never considered its
  failure modes, and a silent ignore in a credential-adjacent parser is the
  highest-severity class left in this repo.
The rest are gated and not autonomously actionable:
- **#120** (one-off flaky `test_dispatch.sh` failure in pre-commit Step 5) -
  tracked; not reproducible in ~16 runs; a recurrence needs the hub-side hook
  to dump the `  FAIL:` lines. No in-repo fix yet.
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

- `git status` clean on `main`; `origin/main` == local `main`.
- Tracker: **GitHub** (`gh --repo atalby/sec-cli`), not glab. Remote is
  `git@github.com:atalby/sec-cli.git`; `glab` errors "None of the git remotes
  configured for this repository point to a known GitLab host" (re-confirmed
  2026-10-13 against a live `glab auth status`, which IS authenticated --
  for gitlab.com, which this repo is not on).
- Open issues: **#126** (autonomous but needs a human call - `get_cfg_val`'s
  awk parser silently skips a key with no `=`; reject-vs-warn is a design
  decision); **#120** (one-off flaky dispatch failure); **#67** (fresh 360
  audit - human scope gate); **#92** (hub-side unguarded counts); **#51**
  (hub-side handoff, tracked upstream).

## Shipped this session (all committed, pushed, CI green, issue closed)

- #128 `fix(sentinel)` (folded into `c34c896` per the #123 precedent) - the #124
  size guard extracted RESUME.md's Verified-baseline section with an unanchored
  regex, so the first literal `## Verified baseline` in the file -- a mid-line
  mention in the #124 narrative -- shadowed the real section header and the
  guard read the #116 entry's then-stale size line. It passed until now only
  because the two occurrences agreed. Fix: `(?m)^## Verified baseline`, the
  convention the persona/step counts already use. Case [35] plants a mid-line
  mention plus a stale 9999/8192 claim inside the shadowed span; coverage must
  still exit 0 (control copy too). Also fixed the same control-literal class
  #123 fixed: cases [28]/[29] hardcoded the live tracked-file count (108) in
  assertions and the planted 'correct' mention; the mention is now derived from
  the live line and the assertions are regex-shaped. Sentinel 34 -> 35 cases /
  348 -> 352 assertions; `_NUM_WORDS` gains `thirty-five`.

- #127 `fix(audit)` -> `c34c896` - `bin/sec --help`'s `Configured Tenants:` line
  was a hardcoded literal nothing derived from the dispatcher alias table.
  Sentinel section 21 now compares the help line's cited alias set against the
  live dispatcher alias regex (help-only and routable-only both fail, naming
  the drift). Case [34]: probe 1 adds `dashvault` to the regex only, probe 2
  adds `phantomtenant` to the help line only, control unmodified exits 0. 10 new
  assertions, 33 -> 34 cases / 338 -> 348. Mirrors bumped at profile.md:22 +
  section 3, ADAPTERS.md:56 + :264, RESUME.md baseline + this section.

- #125 `fix(config)` -> `fix(sentinel)` - F041's second half. The heredoc wrote
  `[global] auto_rotate = true` into every fresh `sec.conf`, but the only read
  of `auto_rotate` is `get_cfg_val "$tenant" "auto_rotate" "true"` -- the
  per-TENANT block, never `[global]`. Audit F041 had named it ("`[global]
  auto_rotate` is equally unread"); #123 closed the `cli` half and left this
  open. Empirically confirmed dead before deleting: with the line removed,
  `bin/sec --help` and bare `bin/sec` against a fresh `$HOME` both exit 0 with
  an identical banner and the same default tenant. Line came out of the heredoc,
  the README sample and the MULTI_TENANCY sample.
  The same sweep found two surfaces nobody guarded: `docs/MULTI_TENANCY.md`'s
  sample omitted the heredoc's leading comment line, and `sec.conf.example` was
  missing `[global] auto_rotate` entirely -- so it already disagreed with what
  `bin/sec` writes. Rather than add a normalization special case, the
  MULTI_TENANCY sample gained the comment line, which makes all four surfaces
  byte-identical with no exception to encode. `coverage`'s section 18 widened
  from two surfaces (heredoc vs README) to a four-way identity check, plus a
  guard that a surface carrying two ```ini fences is rejected as ambiguous
  rather than silently resolved to the first.
  Proved the widening was needed, not decorative: seeded a temp repo at `e71e74a`,
  drifted `docs/MULTI_TENANCY.md` and `sec.conf.example` with README untouched,
  and the PRE-#125 sentinel exited 0. Four new probes (one per new guard branch)
  + 1 control; 8 new assertions, 322 -> 338. Deleting one line at the top of
  `bin/sec` shifted all 39 `bin/sec:N` anchors >= 20 by -1 (gotcha 3);
  `citations` exited 0 after the re-pin. `HISTORY.md` needed a compaction pass
  to fit #124 and #125 under its 8192-byte budget, which immediately tripped
  the #124 guard (RESUME.md's own figure went stale in the same edit) -- the
  guard firing on its own author.

- #124 `fix(sentinel)` -> `8e528a2` - RESUME.md's `## Verified baseline` states
  HISTORY.md's live size but nothing checked it (the sentinel guards
  HISTORY.md's own budget, never the figure RESUME.md quotes); #123's
  compaction invalidated the claim in the commit that shipped it. Section 17
  re-derives it, SCOPED to the `## Verified baseline` section: RESUME.md also
  carries size mentions in `## Next autonomous work` (quoting the stale figure
  as the work item) and `## Shipped this session` (true at the time), and a
  document-wide `findall` would flag narrative as drift -- gotcha 1. Case [33]
  probe 2 plants a size claim in the shipped-this-session section and asserts
  `coverage` still exits 0, so the scope is proven. Same class: case [22]'s
  profile.md probe hardcoded `own thirty-two sentinel cases` (breaks on every
  added case) -> now `own [\w-]+ sentinel cases` substituting a word that is
  never the live count; `[\w-]` matters because `\w` misses the hyphen in
  "thirty-three" (caught empirically: the `\w`-only version matched nothing
  and the control degraded to "coverage accepted a drifted count"). Mirrors
  32 -> 33 cases / 314 -> 322 assertions; `_NUM_WORDS` gains `thirty-three`.

- #123 `fix(config)` -> `ae9ba7a` - the per-tenant `cli = <backend>` key was
  written into every fresh `~/.sec/sec.conf` and documented in three surfaces
  while no code read it (audit finding F041: "user setting cli = ... gets a
  silently ignored setting"); `bin/sec` is the only `sec.conf` owner and
  resolves the tenant binary from a hardcoded alias table. The five lines came
  out of the `bin/sec` heredoc, the README sample and `docs/MULTI_TENANCY.md`
  (of the three documented surfaces, only README and MULTI_TENANCY were
  guarded; `sec.conf.example` had already drifted and #125 fixed it).
  `coverage` gained a sub-check failing
  when a sample key is not the second argument of a `get_cfg_val` call in
  `bin/sec` -- anchored on the CALL SHAPE, not the bare quoted literal, so
  case [32] probe 3 (`_key_probe="cli"`) proves a quoted-but-never-read key
  still fails. Removing 5 lines at the top of `bin/sec` shifted all 39
  `bin/sec:N` anchors >= 23 by -5 (incl. `448-463` -> `443-458`); mirrors 31 ->
  32 cases / 300 -> 314 assertions; `_NUM_WORDS` gains `thirty-two`.
  Follow-up defect found while finishing: control case [22] hardcoded the live
  count twice (`own thirty-one` and `live suite has 31`) and case [27]
  hardcoded `pytest mirror (53` + required exactly ONE occurrence, so every
  legitimate count bump broke them. All three assertions are now
  regex-shaped / count-agnostic, matching the #118 `findall` convention.
- #119 `fix(docs)` -> `9864fb0` - `skills/architecture-360-audit/profile.md`
  (the audit line-map) carried STALE bare line references: sync-controller
  TTY gate `line 248` -> `line 270`; section-7 header `.gitignore:12` ->
  `.gitignore:14`; "runtime state files .gitignore:12 + lines 13-14" ->
  `:14-16`; section-11 "(lines 83, 99, 119)" -> `(84, 100, 120)`, "urlopen at
  line 170" -> `line 159`, "defined at line 17" -> `line 18`, re-dated to
  2026-10-13. Bare refs are NOT scanned by the sentinel's colon-anchor check
  (documented blind spot). #120 filed for the one-off flaky hook failure.
- #118 `fix(sentinel)` -> `aa0eb12` - section 17's count guards used `re.search`
  (first match); a doc that quoted the claim earlier (as the #117 resume note
  did) shadowed the real current-state line, so real drift went unseen. The
  three bare-count guards now `re.findall` and require *every* occurrence to
  match live (`dict.fromkeys` de-dups). Case [29] proves it (earlier correct
  mention + drifted real line -> `coverage` fails naming the drift; two-agreeing
  control exits 0). Sentinel 28 -> 29 cases / 278 -> 284 assertions; mirrors
  `profile.md:22`/`:641`, `ADAPTERS.md:56`/`:262`, `RESUME.md:157`/`:158`;
  `_NUM_WORDS` gains `twenty-nine`; control [22] literals re-pinned.
- #117 `fix(docs)` -> `3f0e69b` - `RESUME.md`'s `## Current state` line (160)
  declaring 108 tracked files / 12 personas / 5 bash suites was the last
  unguarded structural claim; corrupting it left `coverage` exiting 0. Extended sentinel
  section 17 with a `(\d+) tracked files, (\d+) personas, (\d+) bash suites`
  guard against `len(tracked)`, `_live_personas`, `_live_suite_count`. Case
  [28] proves it. Sentinel 27 -> 28 cases / 272 -> 278 assertions; mirrors
  `profile.md:22`/`:641`, `ADAPTERS.md:56`/`:262`, `RESUME.md:157`/`:158`;
  `_NUM_WORDS` gains `twenty-eight`; control [22] literals re-pinned.
- #116 `fix(docs)` -> `fddb57b` - `HISTORY.md`'s `## Current state` claimed a
  pytest mirror of 29 tests (live 53) and a stale open-issue set; that count was
  guarded in `ADAPTERS.md` + audit `SKILL.md` (#97) and `RESUME.md` (#109) but
  not in `HISTORY.md`. Fixed the value and extended sentinel section 17 to
  guard `HISTORY.md` too. Case [27] proves it (corrupt 53 -> 52 -> `coverage`
  exits nonzero naming the drift; control exits 0). Sentinel 26 -> 27 cases /
  266 -> 272 assertions; mirrors `profile.md:22`/`:641`, `ADAPTERS.md:56`/`:262`,
  `RESUME.md:141`; `_NUM_WORDS` gains `twenty-seven`; control [22] literals
  re-pinned. `HISTORY.md` now 8062/8192 bytes.
- #115 `fix(sec-organizer)` -> `2549973` - `sec-organizer apply`/`revert` did not
  guard a corrupt plan/snapshot and died on a raw `jq` parse (exit 4, no tagged
  line). Now a tagged `[ERROR]` + exit 1, file kept. `tests/test_write_honesty.sh`
  [13]/[14], suite 13 -> 15 sections. Mirrors: `profile.md` §3 count + `[ TAG ]`
  census (`sec-organizer` 37 -> 41), citation anchors re-pinned
  (`LATEST_SNAPSHOT` 290->296, `snapshot_file` 195->201); `docs/ARCHITECTURE.md`
  records the pre-use validation.
- #114 `fix(docs)` -> `5e295c1` - `docs/OPERATOR_MANUAL.md:31` documented
  `-v`/`--version` as `` `sec-cli v1.0.0` `` (the `--help` banner string), but
  the live command prints `` sec-cli version 1.0.0 ``. Corrected the row and
  added sentinel section 20 that runs `bin/sec version` and fails on drift;
  `test_sentinel.sh` case [26] proves the guard (control copy passes). Sentinel
  25 -> 26 cases / 260 -> 266 assertions; mirrors bumped at `profile.md:22`,
  `profile.md:641`, `ADAPTERS.md:56`, `ADAPTERS.md:262`, `RESUME.md:131-132`;
  sentinel control [17] literals re-pinned (`twenty-six`, `live suite has 26`).
- #113 `test(sync)` -> `d4890c3` - 10 new pytest cases covering the untested
  user-facing error contract of the two Python entrypoints: sync controller
  GCP add-version timeout / missing-binary / stderr-detail, `main()` help (0),
  usage-error (2), gitlab-failure (3), interactive abort (2) / confirm (0),
  and a real CLI `--help` subprocess; classify invalid-JSON fallback (exit 0,
  no crash). pytest mirror 43 -> 53; mirrors bumped at `ADAPTERS.md:305`,
  `skills/architecture-360-audit/SKILL.md:451`, `profile.md:427` transcript,
  `RESUME.md:117`. Sentinel control [3] drift regexes re-pinned 43 -> 53.
- #112 `test(classify)` -> `d9fb2d3` - 2 new pytest cases covering
  `infer_suggested_name`'s env/project tag branch (generic name + notes with
  `env: tag` -> `name (tag)`, needs_rename). pytest mirror 41 -> 43; mirrors
  bumped at `ADAPTERS.md:305`, `skills/architecture-360-audit/SKILL.md:451`,
  `profile.md:427` transcript, `RESUME.md:104`. Sentinel control [3] drift
  regexes re-pinned 41 -> 43.
- #111 `test(sync)` -> `84c3ee6` - 12 new pytest cases covering the sync
  controller's untested surface: GCP write path (describe / create-on-missing /
  add-version / timeout / failure), `parse_args` usage-error contract, and
  `main()` exit codes 0/1/2/3. pytest mirror 29 -> 41; mirrors bumped at
  `ADAPTERS.md:305`, `skills/architecture-360-audit/SKILL.md:451`,
  `profile.md:427` transcript, `RESUME.md:104`. Sentinel control [3]'s
  hardcoded drift count re-pinned 29 -> 41.
- #110 `fix(migrate)` -> `8ba4a49` - `sec migrate undo|revert|--undo` short-circuited
  the migrator's arg parse (bin/sec-migrator:37), so `sec migrate undo EXTRA`
  silently dropped the operand and proceeded to the rollback path. The undo
  branch now rejects trailing operands with a tagged `[ERROR]` + exit 2 before
  any transaction-log access. Dispatch section [2d3] pins it (undo EXTRA /
  --undo EXTRA / revert EXTRA all refused pre-TX-check). Mirrors 85 -> 86 at
  `profile.md:22`, `ADAPTERS.md:55`, `ADAPTERS.md:264`, `RESUME.md:103`.
- #109 `test(sentinel)` -> `eaf4c0a` - sentinel section 17 now guards RESUME.md's
  suite-count line + `Sentinel = N cases / M assertions` total against the live
  suites (they were hand-bumped, unguarded). Case [25] proves it. Mirrors
  24 -> 25 cases / 250 -> 260 assertions.
- #108 `fix(migrate)` -> `9750ef5` (resume `3df3b0a`) - sec migrate's source
  set (bitwarden/bw, 1password/op, bws) vs destination set (+infisical +vault)
  now agree across all four completions, `sec-migrator` usage and
  OPERATOR_MANUAL; `completions/_sec` regenerated. Sentinel section 19 +
  case [24] pin the 10 surfaces; dispatch `[22u]` updated off the old union
  guard. Mirrors 23 -> 24 at `profile.md:22`/`:641`, `ADAPTERS.md:56`/`:262`,
  `RESUME.md:87`; suite now 24 cases / 250 assertions.
- #107 `fix(readme)` -> `1d61880` (resume `e1dffcc`) - README front page
  pinned to the live CLI: quoted `sec --help` + sec.conf sample byte-identical
  to `bin/sec`, migrate bullet lists all 5 destination backends, session
  rotation claim corrected. Sentinel section 18 + case [23] guard it. Mirrors
  22 -> 23.
- #106 `fix(test)` -> `e309d3e` - single `WORK_ROOT="$(mktemp -d)"` +
  one `trap 'rm -rf "$WORK_ROOT"' EXIT`; every `WORK_*="$(mktemp -d)"` across
  all 22 sections creates under the root. Previously the trap cleaned only 18 of
  53 names, leaking ~35 `/tmp` dirs per run. Measured leak delta after fix: 0.
- #105 `perf(test)` -> `794751d` - root cause of the ~97s sentinel suite: each
  of 18 `cp -a "$REPO_ROOT/." "$W/"` sites (expanding to ~55 work dirs) copied
  `.git` (15M) + `.venv` (29M) + worktree (~4GB/run, IO-bound). Fix: build one
  tar of `git ls-files` (1.2M) once, `seed()` extracts per work dir. Sentinel
  suite 97s -> ~40s; pytest mirror ~95-160s -> ~85s (still 29 passed).
- #103 `test(dispatch)` -> `c5c909d` - guard that all four completion surfaces
  (zsh/bash/fish/ps1) list every dispatcher subcommand; derives the canonical
  token set from `bin/sec` arms and asserts each surface's own parsed list
  contains all 15, pinning each parse to exactly 15 (dispatch 84 -> 85). Mirrors
  bumped at `profile.md:22`, `ADAPTERS.md:55`, `ADAPTERS.md:264`.
- #104 `fix(test)` -> `1647604` - root cause of a pre-commit
  `subprocess.TimeoutExpired` in the pytest mirror: `scripts/tests/test_install.py`
  hardcoded `timeout=120`, below sentinel's real ~97s (->165s under contention).
  Added `_SUITE_TIMEOUT = int(os.environ.get("SEC_TEST_SUITE_TIMEOUT", "300"))`.

### Prior session (same lane, already shipped)

- #97 `test(sentinel)` -> `e588f0c` - guarded profile.md §3 count-words + the
  pytest-mirror "29 passed" (sentinel section 17 + case [22]).
- #98 `fix(ci)` -> `2344f6c` - mirrored section 17's `_pytest_available`
  precondition in case [22] (the `Run bash suites` CI step has no pytest, so CI
  went red unwitnessed).
- #99 `fix(sec)` -> `201531a` - `sec completion <shell> <extra>` rejected a
  trailing operand; four shifted profile.md `bin/sec:` anchors re-pinned
  (dispatch 80 -> 81).
- #100 `fix(sec)` -> `d743c93` - `sec help`/`sec version` rejected a trailing
  operand (were: exit 0, silent drop); folded into existing lines, no anchor
  shift (dispatch 81 -> 82).
- #101 `test(dispatch)` -> `0813bf4` - `sec --help` prints a usage line for every
  canonical subcommand and every non-flag dispatch arm (dispatch 82 -> 83).
- #102 `test(dispatch)` -> `a9cff4b` - the canonical tenant set is identical in
  the dispatcher, `sec --help`, and all four completions (dispatch 83 -> 84).

## Verified baseline (re-run before trusting anything)

```
for s in install sync_guard write_honesty sentinel dispatch; do bash tests/test_$s.sh; done   # all ALL TESTS PASSED
.venv/bin/python -m pytest -q                                                               # 53 passed
./skills/architecture-360-audit/sentinel.sh coverage                                        # exit 0
./skills/architecture-360-audit/sentinel.sh citations                                       # exit 0
```

Live suite section counts (sentinel `coverage` re-derives these; keep the three
mirrors in sync): dispatch 86, install 9, sentinel 35, sync_guard 16,
write_honesty 15. Sentinel = 35 cases / 352 assertions. HISTORY.md is at
8136/8192 bytes - the next narrative addition must compact an older clause first.
109 tracked files, 12 personas, 5 bash suites. No unmerged branches (only main).
No real TODO/FIXME debt in tracked files. Sentinel suite wall time ~40s after
#105; full-suite + pytest-mirror check is cheap enough to run on every touch.

## Gotchas worth not rediscovering

1. **Suite-count mirrors (dispatch):** three sites, bumped by hand whenever a
   dispatch section is added/removed - `profile.md:22`, `ADAPTERS.md:55`
   (`current suites: dispatch N,`), `ADAPTERS.md:264` (`` `bash tests/test_dispatch.sh`
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
   "Step 23 (doc path refs)" advisory (issue #179) that does not block. The mirror
   now uses `SEC_TEST_SUITE_TIMEOUT` (default 300s) - see #104/#105.
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
