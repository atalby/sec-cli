# Resume Point

## Completed Work
- Issue #34 closed (commit f939795, pushed): phase-2 content lint in sentinel.sh citations. Anchors fail when the cited line no longer holds the claim's symbol (token spans filtered through a stopword list, word-boundary match, table rows borrow same-line spans, prose borrows within 45 chars). Caught and re-pointed 12 real staleness/phantoms incl. the `op account list` phantom. Test [5] injection (stale vs control) proves both directions.
- Issue #35 closed (commit a0d0816, pushed): phase-3 claim-existence lint. A backticked span is a symbol only when identifier-shaped AND carrying `_` or camelCase — admits UPPER_SNAKE constants (SYNC_KEYS, REPO_URL, TX_FILE, SEC_SYNC_TIMEOUT, USAGE ...) and excludes prose spans (`git clone`, exit codes, pack names) by construction; every symbol claim must appear in some tracked file OUTSIDE the audit's own docs. Two self-defeats found by TDD and fixed: (1) profile.md/SKILL.md must not be their own haystack; (2) the test payload is assembled at runtime from $(printf ...) fragments so tests/test_sentinel.sh is not the phantom's hiding place. Test [6] injection (phantom named + real SEC_SYNC_TIMEOUT control passing) proves both directions; census 19 real spans, zero missing. Suite is now 6 cases.
- Remaining blind spot, stated in SKILL.md Step 3 and the #35 comment: a space-separated prose phantom (`op account list` class) is not identifier-shaped, so phase 3 passes it — still only caught by reading code.
- Docs same unit: SKILL.md rule 5 + Step 3 describe both phases and the prose-phantom blind spot; profile.md Personas intro, persona 3 "five sentinel cases" -> "six", ecosystem Test-runner row 5 -> 6 cases, sentinel suite quote +[6]; HISTORY.md newest-first entries for #34 and #35.
- Final verification: sentinel coverage + citations green (99 files/38 rows/6 gitignored/12 personas); all five bash suites ALL TESTS PASSED; pytest mirror 9 passed, 1 skipped (10 passed with SEC_TEST_DISPATCH=1); pre-commit gate green; push run green; tree clean.

## Next High-Value Work
No unblocked in-repo item remains in the tracker: #2/#13 are hub-side (work_items 291/292), #32's full 360 re-derivation is operator-gated per the 360 skill Step 1. Highest-value unfinished work that IS reachable here, in order:
1. The prose-phantom catch (#35's stated remainder): extend phase 3 to check multi-word quoted claims against the tree, or declare prose spans exempt in profile.md with an explicit exceptions list. Design must avoid false positives on legit phrase claims.
2. #32's operator go-ahead: ask the operator for the 360 audit (full re-derivation, what is MISSING per persona, not just claim verification) — then run the architecture-360-audit skill end to end.
3. When the hub lands: re-point the hook to run tests/*.sh (work_items 291) and check packs/ byte-identity after the payload resize (work_items 292).

## Resume Instructions
Resume with `gh issue list --repo atalby/sec-cli --state open` and this file. #2/#13 stay comment-only until the hub lands; #32 needs explicit operator go-ahead before any 360 audit. Tests: the four fast suites via pytest mirror (`python3 -m pytest scripts/tests/ -q`), all five directly, plus `bash skills/architecture-360-audit/sentinel.sh citations` after any profile.md edit.
