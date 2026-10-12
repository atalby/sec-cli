# Resume point — sec-cli

Written 2026-10-12 after closing #90. Working tree clean, `main` pushed at
`c4e49e8`.

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

## Just shipped (#90 — the census-drift class is now fully closed)

A sweep of agent-facing markdown for numeric claims that no sentinel section
enforces found two still-unguarded ones, both drifted and both **wrong at
birth**, not merely stale:

- `profile.md:12` claimed `bin/sec` and "five sibling dispatchers"; live is 7.
  This was a same-file self-contradiction — `profile.md:669` already said
  "7 of the 8 tracked `bin/` entries", and section 8 guards that line.
- `ADAPTERS.md:265` claimed "the four helper scripts against stubs"; live is 7
  (five executed, `sec-migrator` via the `sec migrate` arm, and
  `sec-sync-controller.py` statically only).

The unenforced invariant underneath both: **every tracked `bin/` helper is
referenced by the dispatch suite at all**. Helper coverage had grown 2 -> 7
with no number and no guard moving. Sentinel section 13 now asserts all three
things (every helper referenced; ADAPTERS.md's word-form count matches;
profile.md's word-form count matches). Test case [17] covers each.

**Class status: #46/#48/#49/#84-#90 all carry a guard. Nothing in this class is
open.** Any remaining numeric-drift risk is prose with no guard yet — worth a
`sentinel.sh coverage` section each, filed as a real issue first (AGENTS.md §4).

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

Suites: dispatch 79 sections / 237 assertions, install 9 / 30, sentinel 17 / 75,
sync_guard 16 / 44, write_honesty 13 / 49. 108 tracked files, 40 manifest rows,
12 personas, 7 tracked `bin/` sibling helpers, HISTORY.md 8135 bytes against
the 8192-byte budget.

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

## Next autonomous work

None outstanding in-repo. #67 needs an explicit human scope approval; #51 lives
in the hub repo. The productive pattern, if continuing, is the drift sweep:
grep agent-facing markdown for structural counts, measure each against the live
tree, file an issue, then add a sentinel section plus a test case per claim.