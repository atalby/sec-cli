# Resume point — sec-cli

Written 2026-10-12 after closing #91. Working tree clean, `main` pushed at
`8457377`.

## Where things stand

- `git status` clean on `main`; `origin/main` == local `main`.
- Tracker: **GitHub** (`gh --repo atalby/sec-cli`), not glab. The remote is
  `git@github.com:atalby/sec-cli.git`; `glab` is authenticated to gitlab.com
  but errors with "None of the git remotes configured for this repository
  point to a known GitLab host".
- Open issues: **#67** (fresh 360 audit — its Step-1 gate needs explicit human
  scope approval, so it is *not* autonomous) and **#51** (hub-side handoff,
  tracked upstream in the hyer hub, unfixable in-repo).
- No autonomous in-repo work item remains.

## Just shipped (#91 — the last unguarded-but-correct suite counts)

The #90 markdown sweep also surfaced three claims that were **correct but
unguarded** — the bash-suite count, stated three times, with no sentinel section
enforcing any of them (`git ls-files 'tests/*.sh' | wc -l` = 5):

- `profile.md:13` — ``five suites under `tests/` `` (the same sentence whose
  Python-file count section 8 *does* guard, making the suite count the only
  unguarded number in it)
- `profile.md:23` (CI table row) — `runs all five suites`
- `docs/ARCHITECTURE.md:19` — `five zero-dependency bash suites (...)`

Sentinel **section 14** re-derives the count from tracked `tests/*.sh` and checks
all three, **plus a fourth check the others need**: `ARCHITECTURE.md`'s cited
suite *names*, compared bidirectionally against the tracked basenames. That half
is load-bearing — a renamed suite keeps the count at 5, so a count-only guard
would never notice. Test case T4 exists only to exercise it. Test case [18]
covers all four; sentinel is now 18 cases / 84 assertions.

No prose correction was needed (unlike #84-#90, every claim was already true).

**Class status: #46/#48/#49/#84-#91 all carry a guard.** Sweep candidates still
open are `packs/README.md`'s "9-persona" count and `AGENTS.md`'s "4 core
execution traits" — both inside **hub-synced** files, so guard them from the
project side or file hub-side, never hand-edit locally.

## Ownership boundaries (checked before editing #90)

`AGENTS.md`, `methodology/` and `packs/` are **hub-synced** from the hyer hub
(`cdbd1d9`, `6ff435d`) — do not hand-edit; a re-sync overwrites. `ADAPTERS.md`,
`profile.md`, `docs/` and `tests/` are project-owned and safe to fix.

## Verified baseline (re-run before trusting anything)

```
for s in install sync_guard write_honesty sentinel dispatch; do bash tests/test_$s.sh; done   # all ALL TESTS PASSED
.venv/bin/python -m pytest -q                                                               # 29 passed
./skills/architecture-360-audit/sentinel.sh coverage                                        # exit 0
./skills/architecture-360-audit/sentinel.sh citations                                        # exit 0
```

Suites: dispatch 79 sections / 237 assertions, install 9 / 30, sentinel 18 / 84,
sync_guard 16 / 44, write_honesty 13 / 49. 108 tracked files, 40 manifest rows,
12 personas, 7 tracked `bin/` sibling helpers, 5 bash suites, 23 skill dirs /
35 registry rows, HISTORY.md 6671 bytes against the 8192-byte budget.

## Gotchas worth not rediscovering

1. **pre-commit Step 21 ignores `TDD-Red:` trailers.**
   `/home/opc/sandbox/hyer/scripts/pre-commit-hiae.sh:458` calls
   `check_tdd_evidence.py "$STAGED_ALL" --repo-root "$REPO_ROOT"` with **no**
   `--message-file`, so `message` is always `None` and the trailer is never
   parsed at pre-commit time. A commit that touches only an impl file (e.g.
   `sentinel.sh`) is blocked no matter what the trailer says. The only path is
   to stage a test file in the same commit. Do not burn three commits on this.
2. **Counting census numbers: filter to data rows.** `grep -c "\.hyer/skills/"`
   returns 14 and `grep -c '`skills/`'` returns 40 because both also match
   prose. Only `^| ` rows may be counted.
3. **Test work copies need their own `git init`.** Cases that `cp -a` the repo
   root must `rm -rf "$W/.git"` then `git init -q . && git add -A`, or the
   coverage denominator comes from the parent's index. Give every case a fresh
   `mktemp -d` — reusing one across cases inherits the earlier corruption.
4. **HISTORY.md is force-loaded by every session** (sentinel section 6 guards
   the 8192-byte budget). Adding narrative means compacting an older clause in
   the same edit; the full text goes in `history/<date>.md`.
5. **A prose fix that adds lines invalidates line-number citations.** Fixing
   `ADAPTERS.md` for #90 grew it 3 lines and made `profile.md:53`'s
   `ADAPTERS.md:305` anchor stale — `sentinel.sh citations` caught it; re-verify
   citations after any edit that changes a cited file's length.
6. **The pre-commit gate's persona advisory is inconsistently applied.** Commit
   trailers in this repo carry `Persona-Dispatch-Considered` roughly half the
   time; when the gate warns, a small `--allow-empty` follow-up recording the
   disposition is the cheap fix (see `c4e49e8`), and it keeps the main
   evidence commit unamended.
7. **Bump suite-count mirrors BEFORE capturing RED.** A new test case bumps the
   suite's case count, and every control copy reads those mirrors. If they are
   stale, the control fails for the wrong reason and RED is not isolated (hit
   both in #90 and #91).
8. **Check compaction seams before committing.** Rewriting a HISTORY.md clause
   that ends mid-sentence leaves a dangling fragment (hit in #91: `...of
   `revert`.` / `them since v1.0.0), but all four completions...`). Read the
   lines either side of every edit.
9. **`gh issue close --comment` with a long heredoc can hang** past the shell
   timeout and leave the issue OPEN. Write the body to a file, then
   `gh issue comment N --body-file <f>` followed by a separate
   `gh issue close N --reason completed`, and verify the state afterwards.

## Next autonomous work

None outstanding in-repo. #67 needs an explicit human scope approval; #51 lives
in the hub repo. The productive pattern, if continuing, is the drift sweep:
grep agent-facing markdown for structural counts, measure each against the live
tree, file an issue, then add a sentinel section plus a test case per claim.
Note that a count claim and a *name list* behind it are two guards, not one —
see the `ARCHITECTURE.md` suite-name check in section 14.