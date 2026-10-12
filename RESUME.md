# Resume point - sec-cli

Written 2026-10-12 after closing #102 (commit `a9cff4b`, pushed). Working tree
clean on `main`. This session shipped five guard/fix units (#98, #99, #100,
#101, #102); the only remaining open issue with an autonomous in-repo remedy is
**#103**.

## Next autonomous work

**#103 - guard that every completion surface offers every dispatcher subcommand.**
The four surfaces (zsh/bash/fish/ps1) currently list all 15 subcommands (verified
this session: no live drift), but nothing ties them to the dispatcher arms; a newly
added arm can be added to `bin/sec` (and to `sec --help`, now guarded by #101)
while silently missing from one or more completion scripts. Existing coverage is
partial only: #56 (bash `subcmds` alias tokens), #82 (bare `help`/`version`), #83
(`get --scope` / `set --type`). Implementation: a `tests/test_dispatch.sh` section
iterating the dispatcher's non-flag arms (parse them as section [2k] does:
`grep -oE '^    [a-z][a-z|-]*\)$' bin/sec | sed -E 's/^ +//; s/\)$//'`) and
asserting each surface's subcommand list contains every arm's primary token.
One new `echo "["` line bumps the dispatch section count - see the mirror gotcha.

Resume command:
`cd /home/opc/sandbox/sec-cli && gh --repo atalby/sec-cli issue view 103`

## Where things stand

- `git status` clean on `main`; `origin/main` == local `main`.
- Tracker: **GitHub** (`gh --repo atalby/sec-cli`), not glab. Remote is
  `git@github.com:atalby/sec-cli.git`; `glab` errors "None of the git remotes
  configured for this repository point to a known GitLab host".
- Open issues: **#103** (autonomous guard, next unit); **#67** (fresh 360 audit -
  its Step-1 gate needs explicit human scope approval, so not autonomous); **#51**
  (hub-side handoff, tracked upstream, unfixable in-repo); **#92** (hub-side: two
  unguarded counts in hub-owned files; gotcha 10).

## Shipped this session (all committed, pushed, CI green, issue closed)

- #97 `test(sentinel)` -> `e588f0c` - guarded profile.md §3 count-words + the
  pytest-mirror "29 passed" (sentinel section 17 + test case [22]).
- #98 `fix(ci)` -> `2344f6c` - mirrored section 17's `_pytest_available`
  precondition in case [22] (the `Run bash suites` CI step has no pytest, so the
  pytest-mirror corruption was unwitnessed and CI went red).
- #99 `fix(sec)` -> `201531a` - `sec completion <shell> <extra>` rejected a
  trailing operand (was: printed a script, exit 0); four shifted profile.md
  `bin/sec:` anchors re-pinned (dispatch 80 -> 81).
- #100 `fix(sec)` -> `d743c93` - `sec help`/`sec version` rejected a trailing
  operand (were: exit 0, silent drop). Folded into an existing line per arm, so
  `bin/sec` line count is unchanged and no anchor shifted (dispatch 81 -> 82).
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
mirrors in sync): dispatch 84, install 9, sentinel 22, sync_guard 16,
write_honesty 13. Sentinel = 22 cases / 116 assertions. HISTORY.md is at
8154/8192 bytes - the **next** narrative addition must compact an older clause
first (it is nearly full). 108 tracked files, 12 personas, 5 bash suites.

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
4. **pre-commit HIAE runs the pytest suite (~95-153s)** and rejects ADDED
   comments/docstrings, checks plain-text + TDD + granularity. It cannot see
   commit ordering inside one commit, so stage a test file with any impl change.
   Advisory WARNING when staged changes span 2 categories is recurring and benign.
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

## Ownership boundaries

`AGENTS.md`, `methodology/` and `packs/` are hub-synced - do not hand-edit.
`ADAPTERS.md`, `profile.md`, `RESUME.md`, `docs/`, `tests/`, `bin/sec` and
`HISTORY.md` are project-owned and safe to edit.
