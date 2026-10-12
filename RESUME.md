# Resume point — sec-cli

Written 2026-10-12 after closing #89. Working tree clean, `main` pushed at
`ec4ac1b`.

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

## Just shipped (#89, the last of the census-drift class)

`sentinel.sh coverage` section 12 now fails closed on ADAPTERS.md's
"Skills registry" census vs. the live `skills/` tree and `skills/REGISTRY.md`.
Section 12 is the twelfth and final section; `tests/test_sentinel.sh` case
[16] covers it with five isolated work copies.

The **#46/#48/#49/#84-#89 census-drift class is now closed end to end**:
profile.md's ecosystem + `[ TAG ]` censuses (#84), ADAPTERS.md's
`current suites:` snapshot (#85) and per-suite counts (#87), the audit
profile's pack taxonomy (#86), docs/ARCHITECTURE.md's producer census (#88),
and ADAPTERS.md's skills/registry census (#89).

## Verified baseline (re-run before trusting anything)

```
for s in install sync_guard write_honesty sentinel dispatch; do bash tests/test_$s.sh; done   # all ALL TESTS PASSED
.venv/bin/python -m pytest -q                                                               # 29 passed
./skills/architecture-360-audit/sentinel.sh coverage                                        # exit 0
./skills/architecture-360-audit/sentinel.sh citations                                        # exit 0
```

Suites: dispatch 79 sections / 237 assertions, install 9 / 30, sentinel 16 / 68,
sync_guard 16 / 44, write_honesty 13 / 49. 108 tracked files, 40 manifest rows,
12 personas, HISTORY.md 7734 bytes against the 8192-byte budget.

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

## If resuming the drift sweep

The census class is closed. Remaining numeric-drift risk is prose that has no
guard yet — worth a `sentinel.sh coverage` section each, filed as a real issue
first (AGENTS.md §4). Everything else open needs a human: #67 needs an explicit
scope approval, #51 lives in the hub repo.