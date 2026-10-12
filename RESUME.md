# Resume point — sec-cli

Written 2026-10-12 after closing #96. Working tree clean on `main`; last push
will be the #96 docs commit.

## Where things stand

- `git status` clean on `main`; `origin/main` == local `main`.
- Tracker: **GitHub** (`gh --repo atalby/sec-cli`), not glab. The remote is
  `git@github.com:atalby/sec-cli.git`; `glab` is authenticated to gitlab.com
  but errors with "None of the git remotes configured for this repository
  point to a known GitLab host".
- Open issues: **#67** (fresh 360 audit — its Step-1 gate needs explicit human
  scope approval, so it is *not* autonomous), **#51** (hub-side handoff, tracked
  upstream in the hyer hub, unfixable in-repo), and **#92** (hub-side: two
  unguarded counts in hub-owned files, filed by the #90/#91 sweep).
- No autonomous in-repo work item remains.

## Just shipped (#96 — SKILL.md's own step/persona/scope/severity counts)

The post-#95 sweep closed the audit instrument's remaining structural counts:
`SKILL.md`'s step count (11 `## Step` headings), persona count (12, cross-
checked against `profile.md`'s "Twelve, numbered 1 through 12"), the two
Step-1 scopes, and the three-value severity set. All were correct but
unguarded. Added **sentinel section 16** (reuses `_NUM_WORDS`, normalizes
whitespace so the wrapped "the twelve\npersonas" matches, ignores non-numeric
words) and test case [21] (four corruptions + control). One guard bug fixed:
`_NUM_WORDS` is lowercase, so the captured "Twelve" needed `.lower()`.
Sentinel is now 21 cases / 107 assertions. RED proven against pre-#96 `HEAD`.

## Just shipped (#95 — SKILL.md's own suite-count prose was stale and unguarded)

The post-#94 sweep of agent-facing markdown for numeric claims found the audit
instrument's *own* skill file had never been guarded. `SKILL.md:279` said "the
two `tests/*.sh` suites" (written at `0d64844` when the tree had two; live is
5); `SKILL.md:451` said the gate "executes all five bash suites" (correct, but
unguarded). Corrected `two` -> `five` in place (same line, so `citations` held)
and **extended sentinel section 14** to derive the live count and check both
places SKILL.md states it. Test case [20] covers two corruptions plus a control;
sentinel is now 20 cases / 98 assertions. RED proven against the pre-fix `HEAD`
sentinel: exit 0 on a drifted SKILL.md.

## Just shipped (#94 — the last correct-but-unguarded structural prose claims)

The post-#93 sweep found three claims **correct but unguarded** in
project-owned docs (the #85/#87/#88/#91 class; ownership checked per gotcha 10):

- `docs/MULTI_TENANCY.md:43` — "the eight fixed aliases
  (bitwarden/bw, 1pass/op, bws, vault, infisical, keychain)" vs `bin/sec:79`'s
  tenant regex (8 tokens)
- `profile.md:23` (CI row) — "`actions/checkout` pinned to the full commit SHA
  of v4.2.2" vs `.github/workflows/test.yml:13`
  (`actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2`)
- `docs/OPERATOR_MANUAL.md:9` — "four core principles" vs its 4 numbered items

Sentinel **section 15** derives the live tenant tokens from `bin/sec`, parses
the workflow's pinned SHA+version comment, and counts the manual's numbered
list; it checks each claim's count word (via `_NUM_WORDS`) **and** the alias
*set* (a count-only guard would miss a renamed alias). Test case [19] covers
four corruptions plus a control; sentinel is now 19 cases / 93 assertions.

### Defect found while doing this

The profile CI-version regex first used `(\S+?)[,;.\s]`, and `.` in the
terminator class made the lazy match stop at `v4` for `v4.2.2,` — a spurious
mismatch caught by case [19] in the first GREEN run (17 failures). Fixed by
capturing the version as `(v\d+\.\d+\.\d+)`.

## Just shipped (#93 — README housekeep sample was stale vs the classifier)

`README.md:155-156`'s `sec housekeep` sample claimed output the shipped
`bin/sec-classify.py` can never produce: `[token:gmail]` is not a real token
(no category carries a gmail/mail token) and confidence is
`int(max/(max+2)*100)`, so 94/89 were unreachable. Measured reality: the
Gmail fixture categorizes `cloud/gcp` / 50 / `[token:google]` (suggested name
`Gmail (anass.personal@gmail.com)`), and PROD_DB `database` / 81 /
`[regex:postgres://, token:db, token:postgres]`. The docs were the stale side
(Gmail is a Google property, so `cloud/gcp` is defensible); the classifier
taxonomy was left unchanged. Fixed the README sample in place (line count
preserved) and added dispatch section **[16-honesty]** asserting the two
classifier outputs verbatim (dispatch 79 -> 80 sections; mirrors at
`profile.md:22`, `ADAPTERS.md:55`, `ADAPTERS.md:264` bumped first).

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

**Class status: #46/#48/#49/#84-#91 all carry a guard.** The sweep's last two
candidates — `packs/README.md`'s "9-persona" count and `AGENTS.md`'s "4 core
execution traits" — were filed hub-side as **#92** rather than guarded here. See
gotcha 10 for why.

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

Suites: dispatch 80 sections / 239 assertions, install 9 / 30, sentinel 21 / 107,
sync_guard 16 / 44, write_honesty 13 / 49. 108 tracked files, 40 manifest rows,
12 personas, 7 tracked `bin/` sibling helpers, 5 bash suites, 23 skill dirs /
35 registry rows, HISTORY.md within the 8192-byte budget (sentinel section 6
guards it).

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
10. **A guard needs one project-owned side.** Every sentinel guard so far
   compares a *project-owned* claim against a live-derived truth (section 10:
   profile.md vs PACK.md; section 11: ARCHITECTURE.md vs live `bin/`;
   section 14: profile.md + ARCHITECTURE.md vs tracked `tests/*.sh`). The
   adopter can always fix the project side. A claim with **both sides
   hub-owned** (`packs/README.md` vs `PACK.md`, or `AGENTS.md` vs its own §1.2)
   is the wrong shape for an adopter guard: the day the hub ships an internal
   inconsistency, every adopter's `sentinel.sh coverage` goes red with no local
   remedy, breaking the Definition of Done's "suite is green" gate. File those
   hub-side instead — that is what #92 is. Confirm ownership before adding a
   guard: `git log --oneline -- <file>` returning only `chore(adopt): re-sync`
   commits means hub-owned.

## Next autonomous work

None outstanding in-repo. #67 needs an explicit human scope approval; #51 and
#92 live in the hub repo. The productive pattern, if continuing, is the drift
sweep: grep agent-facing markdown for structural counts, measure each against
the live tree, file an issue, then add a sentinel section plus a test case per
claim — but check ownership first, because a claim with two hub-owned sides
belongs upstream (gotcha 10). Two refinements that paid off in #91: a count
claim and the *name list* behind it are two guards, not one (see the
`ARCHITECTURE.md` suite-name check in section 14), and a correctly-worded claim
still needs a guard — correctness is not detection.