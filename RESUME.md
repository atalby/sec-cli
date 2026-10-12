# Resume point - sec-cli

Written 2026-10-12 after closing #108 (commit `9750ef5`, resume `3df3b0a`)
and #107 (commit `1d61880`, resume `e1dffcc`), both pushed. Working tree clean
on `main`; `origin/main` == local `main`. This lane shipped a long run of
guard/fix/perf units (#97..#108), all CI-green.

There is now **no open issue with an autonomous in-repo remedy**. The remaining
open items are hub-side or human-gated (see below). If the lane is run again,
the highest-value candidates are the fresh 360 audit (#67, after human scope
approval) and re-running the verified baseline to catch any drift.

## Next autonomous work

None until a human un-sticks one of the gated items:
- **#67** (fresh 360 audit) - its Step-1 gate needs explicit human scope approval.
- **#92** (hub-side: two unguarded counts in hub-owned files) - gotcha 6; no
  in-repo remedy.
- **#51** (hub-side handoff items tracked upstream) - unfixable in-repo.

Resume commands:
`cd /home/opc/sandbox/sec-cli && gh --repo atalby/sec-cli issue view 67`

If picking un-tracked work instead, the cheapest high-value items are: re-run the
verified baseline below to confirm no drift, and the sentinel suite is now ~40s
(was ~97s) so full-suite runs are cheap enough to do on every check.

## Where things stand

- `git status` clean on `main`; `origin/main` == local `main`.
- Tracker: **GitHub** (`gh --repo atalby/sec-cli`), not glab. Remote is
  `git@github.com:atalby/sec-cli.git`; `glab` errors "None of the git remotes
  configured for this repository point to a known GitLab host".
- Open issues: **#67** (fresh 360 audit - human scope gate); **#92** (hub-side
  unguarded counts); **#51** (hub-side handoff, tracked upstream). None are
  autonomously actionable in-repo.

## Shipped this session (all committed, pushed, CI green, issue closed)

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
.venv/bin/python -m pytest -q                                                               # 29 passed
./skills/architecture-360-audit/sentinel.sh coverage                                        # exit 0
./skills/architecture-360-audit/sentinel.sh citations                                       # exit 0
```

Live suite section counts (sentinel `coverage` re-derives these; keep the three
mirrors in sync): dispatch 85, install 9, sentinel 25, sync_guard 16,
write_honesty 13. Sentinel = 25 cases / 260 assertions. HISTORY.md is at
8038/8192 bytes - the next narrative addition must compact an older clause first.
108 tracked files, 12 personas, 5 bash suites. No unmerged branches (only main).
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
