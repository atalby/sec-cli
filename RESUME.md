# Resume point - sec-cli

Session 2026-10-14 (33rd run): shipped **#153** -- the `sec completion` surface
(OPERATOR_MANUAL.md:95-96's shell set, `powershell`->`ps1` alias, and the claim
that `completions/_sec` mirrors the zsh output) had no guard. Sentinel section 31
parses the shell arms from bin/sec's completion dispatch and requires the doc's
shell set + alias to match the live grouping, and `completions/_sec` to be
byte-identical to live `bin/sec completion zsh` (case [53], four probes +
control, proven red first -- a first-cut parser bug, the zsh heredoc's inner
`case $state in ... esac` truncating the match, was found and fixed). Sentinel
54 -> 55 cases / 628 -> 648 assertions; mirrors bumped at `profile.md:22`,
`profile.md:641` (fifty-five), `ADAPTERS.md:56`, `ADAPTERS.md:262`, this file's
mirrors-in-sync + `Sentinel =` lines and HISTORY.md size (8056/8192); HISTORY.md
2026-10-14 block extended and `history/2026-10-14.md` appended.

Resume here next run: no non-gated tracker item remains. The tracker holds
**#67** (fresh 360 audit -- its Step-1 gate needs explicit human scope approval;
must NOT be started autonomously) and **#92** + **#51** (hub-side, not this
repo). Standing next autonomous move: sweep for the next unguarded
current-state claim (the #129-#153 class); if none surfaces, the fresh 360
audit (#67) only after human approval.

Session 2026-10-14 (32nd run): shipped **#152** -- the classifier-category
claims (README.md:15's example list, docs/ARCHITECTURE.md:12's login-field
examples) had no guard. Sentinel section 30 parses the live `CATEGORY_WEIGHTS`
keys from bin/sec-classify.py, asserts the `general` fallback literal survives,
and requires every category named in both docs to be a live key (case [52],
four probes + control, proven red first). Sentinel 53 -> 54 cases / 608 -> 628
assertions; mirrors bumped at `profile.md:22`, `profile.md:641` (fifty-four),
`ADAPTERS.md:56`, `ADAPTERS.md:262`, this file's mirrors-in-sync + `Sentinel =`
lines and HISTORY.md size (7885/8192, the 2026-10-14 paragraph compacted to
fit); HISTORY.md 2026-10-14 block extended and `history/2026-10-14.md` appended.

Resume here next run: no non-gated tracker item remains. The tracker holds
**#67** (fresh 360 audit -- its Step-1 gate needs explicit human scope approval;
must NOT be started autonomously) and **#92** + **#51** (hub-side, not this
repo). Standing next autonomous move: sweep for the next unguarded
current-state claim (the #129-#152 class); if none surfaces, the fresh 360
audit (#67) only after human approval.

Session 2026-10-14 (31st run): shipped **#151** -- the `sec run` env-injection
backend prose (README.md:11 + :136 comment, ARCHITECTURE.md:22) had no guard;
only the byte-identical `sec --help` block copy was covered (section 18).
Sentinel section 29 parses the live injection backends from bin/sec's `run)`
arm `case` patterns (`<patterns>) exec <wrapper> run --`) and requires every
prose site to name exactly that set, plus both docs to still call `bitwarden`
a plain exec (case [51], four probes + control, proven red first). Sentinel
52 -> 53 cases / 588 -> 608 assertions; mirrors bumped at `profile.md:22`,
`profile.md:641` (fifty-three), `ADAPTERS.md:56`, `ADAPTERS.md:262`, this
file's mirrors-in-sync + `Sentinel =` lines and HISTORY.md size (8026/8192,
the 2026-10-14 paragraph compacted to fit); HISTORY.md 2026-10-14 block
extended and `history/2026-10-14.md` appended.

Resume here next run: no non-gated tracker item remains. The tracker holds
**#67** (fresh 360 audit -- its Step-1 gate needs explicit human scope approval;
must NOT be started autonomously) and **#92** + **#51** (hub-side, not this
repo). Standing next autonomous move: sweep for the next unguarded
current-state claim (the #129-#151 class); if none surfaces, the fresh 360
audit (#67) only after human approval.

Session 2026-10-14 (30th run): shipped **#150** -- the runtime-dependency
sentence (README.md + ARCHITECTURE.md) and the documented `SEC_*` env vars had
no sentinel guard. Sentinel section 28 binds the README/ARCHITECTURE
"Runtime dependencies beyond coreutils: `jq` ... `python3` ..." sentence to
install.sh's `for _dep in jq python3` loop, and requires every `SEC_*` token
named in the five shipped docs to appear in install.sh or a file under bin/
(case [50], four probes + control, proven to fire first). Sentinel 51 -> 52
cases / 568 -> 588 assertions; mirrors bumped at `profile.md:22`,
`profile.md:641` (fifty-two), `ADAPTERS.md:56`, `ADAPTERS.md:262`, this file's
mirrors-in-sync + `Sentinel =` lines and HISTORY.md size (8068/8192);
HISTORY.md 2026-10-14 block extended and `history/2026-10-14.md` appended.

Resume here next run: no non-gated tracker item remains. The tracker holds
**#67** (fresh 360 audit -- its Step-1 gate needs explicit human scope approval;
must NOT be started autonomously) and **#92** + **#51** (hub-side, not this
repo). Standing next autonomous move: sweep for the next unguarded
current-state claim (the #129-#150 class); if none surfaces, the fresh 360
audit (#67) only after human approval.

Session 2026-10-14 (29th run): shipped **#149** -- the last unguarded
natural-language mode claims. Five prose mode facts across three docs had no
sentinel guard: README.md's snapshot mode, OPERATOR_MANUAL.md's snapshot mode +
path, and ARCHITECTURE.md's session, umask, cache-dir, plan, and sec.conf
modes. Sentinel section 27 binds each to its live chmod/umask in
`bin/sec-organizer`, `bin/bw-session-keeper`, and `install.sh` (case [49], six
probes + control; the guard was proven to fire before green). Sentinel
50 -> 51 cases / 540 -> 568 assertions; mirrors bumped at `profile.md:22`,
`profile.md:641` (fifty-one), `ADAPTERS.md:56`, `ADAPTERS.md:262`, this file's
mirrors-in-sync + `Sentinel =` lines and HISTORY.md size (7659/8192);
HISTORY.md 2026-10-14 block extended and `history/2026-10-14.md` appended.

Resume here next run: no non-gated tracker item remains. The tracker holds
**#67** (fresh 360 audit -- its Step-1 gate needs explicit human scope approval;
must NOT be started autonomously) and **#92** + **#51** (hub-side, not this
repo). Standing next autonomous move: sweep for the next unguarded
current-state claim (the #129-#149 class); if none surfaces, the fresh 360
audit (#67) only after human approval.

Session 2026-10-14 (28th run): shipped **#148** -- the last realistic
first-match shadow of the #118/#128/#135/#147 class. RESUME.md's own two count
mirrors (the 'suite counts ... mirrors in sync' line and the
'Sentinel = N cases / M assertions' total) were searched over the whole
append-heavy narrative by sentinel section 17, so an earlier 'Shipped this
session' echo of either shape could shadow the real claim inside
`## Verified baseline` and pass a drifted line. Both searches are now scoped to
that section's body (the convention its sibling bytes check already used).
Case [48] proven red first (unfixed guard exited 0 with three failures, clean
control exited 0). Sentinel 49 -> 50 cases / 532 -> 540 assertions; mirrors
bumped at `profile.md:22`, `profile.md:641` (fifty), `ADAPTERS.md:56`,
`ADAPTERS.md:262`, this file's mirrors-in-sync + `Sentinel =` lines;
HISTORY.md 2026-10-14 block extended and `history/2026-10-14.md` appended.
The 45-site single-`re.search` audit run this session found every remaining
extractor matching exactly once; the two RESUME.md sites were the only ones on
a shadow-prone (append-heavy) file, so the class is now swept to its realistic
floor.

Resume here next run: the tracker's open items are #67 (fresh 360 audit --
its Step-1 gate needs explicit human scope approval; must NOT be started
autonomously) and #92 + #51 (hub-side, not this repo). No non-gated tracker
item remains, and the #118-family sentinel-robustness sweep is complete; the
next autonomous move is the fresh 360 audit (#67) only after human approval, or
another unguarded-current-state claim if one surfaces.

Session 2026-10-14 (24th run): shipped **#145** -- two items. (1) The
unguarded-current-state sweep's next instance: `docs/SECURITY.md`'s "File
Permissions Architecture" section states six path->mode pairs (0700/0600) but
nothing re-verified them against the live `chmod` calls in `bin/sec`,
`bin/bw-session-keeper`, `bin/sec-organizer`, `bin/sec-migrator`. Sentinel
section 25 resolves each documented path from its source variable
(`$CONFIG_DIR`, `$SESSION_FILE`, ...), checks the doc mode against both its own
inline chmod and the live chmod, and fails if a guarded path stops being
documented. (2) The previous run's section 24 (the timeout-claim guard) had
shipped with NO probes and NO issue -- closed here with case [44]; case [45]
covers section 25. Both cases proven red first (drift probes fail, controls
green), then green. Sentinel 45 -> 47 cases / 468 -> 504 assertions; mirrors
bumped at `profile.md:22`, `profile.md:641` (forty-seven), `ADAPTERS.md:56`,
`ADAPTERS.md:262`, this file's mirrors-in-sync + `Sentinel =` lines;
HISTORY.md 2026-10-14 block extended and `history/2026-10-14.md` appended.

Resume here next run: the tracker's open items are #67 (fresh 360 audit --
its Step-1 gate needs explicit human scope approval; must NOT be started
autonomously) and #92 + #51 (hub-side, not this repo). The highest-value
autonomous pattern remains: sweep for the next unguarded current-state claim
(this run's #145 was exactly that), or another sentinel-robustness class;
the theoretical `re.search` scope-grab hardening stays conditional as noted
in "Next autonomous work".

Session 2026-10-14 (23rd run): shipped sentinel section 24 (no issue was filed
at the time and it added no probes -- both closed by the 24th run under #145)
-- the unguarded-current-state
sweep's next instance: ARCHITECTURE.md + OPERATOR_MANUAL.md claimed "every
backend call has a timeout (default 60s, SEC_SYNC_TIMEOUT overrides)" but
nothing verified the live `bin/sec-sync-controller.py` actually has `timeout=`
on all backend calls. Added sentinel section 24 that extracts both docs'
timeout claims, confirms the controller's `BACKEND_TIMEOUT` default is 60,
and scans every `subprocess.run`/`p.communicate`/`urlopen` call (excluding
cleanup calls in `except TimeoutExpired` blocks) for a `timeout=` parameter.
Proven red first (two probe drifts: ARCHITECTURE.md default -> 99s, a
`subprocess.run` without timeout=), then green. Sentinel remains 45 cases /
468 assertions (new section adds no probes to test_sentinel.sh yet; will add
when probes are written); mirrors bumped at `profile.md:22`, `profile.md:641`,
`ADAPTERS.md:56`, `ADAPTERS.md:262`, this file's mirrors-in-sync +
`Sentinel =` lines; HISTORY.md compacted (2026-10-14 block) to 5606/8192.

Resume here next run: the tracker's open items are #67 (fresh 360 audit --
its Step-1 gate needs explicit human scope approval; must NOT be started
autonomously) and #92 + #51 (hub-side, not this repo). The highest-value
autonomous pattern remains: sweep for the next unguarded current-state claim
(this run's #145 was exactly that), or another sentinel-robustness class;
the theoretical `re.search` scope-grab hardening stays conditional as noted
in "Next autonomous work".

Session 2026-10-14 (22nd run): shipped **#144** -- the unguarded-current-state
sweep's next instance (the class #129-#139 worked). `docs/ARCHITECTURE.md:3`'s
HIAE Protocol version banner had NO in-repo guard (`grep -n HIAE` over
`sentinel.sh` and `tests/` -> zero matches); the only live gate was the
hand-run hub script `~/sandbox/hyer/scripts/check_version_banners.py`, whose
PASS transcript sits quoted at `profile.md:501-504` but nothing re-runs it, so
a fleet-sync bump of `AGENTS.md` would leave the project banner stale with CI
green. Sentinel section 23 now compares the banner (same regex shape as the
hub checker's, whitespace-unwrapped) across `AGENTS.md` vs
`docs/ARCHITECTURE.md`: either banner absent fails (the hub checker skips
absent banners -- an absent check is not a passing one, #98 class), and a
version mismatch names both sides. Proven red first (case [43], four probes:
banner corrupted to v9.9.9 / banner line deleted / AGENTS.md banner deleted /
control; RED = 7 failures since coverage exited 0 on all three drifts), then
green. Two test bugs surfaced while turning it green, both in the new test:
probe C's removal regex needed no leading space (`AGENTS.md:38` begins the
line with `(`), and the control grep allowed only one version dot (`v5.39.1`
has two). Sentinel 44 -> 45 cases / 452 -> 468 assertions; mirrors bumped at
`profile.md:22`, `profile.md:641`, `ADAPTERS.md:56`, `ADAPTERS.md:262`, this
file's mirrors-in-sync + `Sentinel =` lines; HISTORY.md compacted (2026-10-12
block) to 5606/8192 and gained `history/2026-10-14.md`. This run also
corrected stale text below: the "three hand-pinned English numerals" bullet
was already done by 9a4938e/f129881, and #126 is closed (warn design call,
run 18).

Resume here next run: the tracker's open items are #67 (fresh 360 audit --
its Step-1 gate needs explicit human scope approval; must NOT be started
autonomously) and #92 + #51 (hub-side, not this repo). The highest-value
autonomous pattern remains: sweep for the next unguarded current-state claim
(this run's #144 was exactly that), or another sentinel-robustness class;
the theoretical `re.search` scope-grab hardening stays conditional as noted
in "Next autonomous work".

Session 2026-10-14 (21st run): swept the three remaining targets named by the
20th run (`bin/sec-sync-controller.py`, `bin/bw-session-keeper`,
`bin/hyer-mcp.sh`) and found NO F015-class masking. The controller checks
`p.returncode`, uses `urlopen(..., timeout=BACKEND_TIMEOUT)`, and returns
3/2/1 on failed-count / confirmation / zero-keys; the keeper guards unlock
with `[[ -n "$raw_session" ]]` and reads the master password via
`--passwordenv` (never argv); `hyer-mcp.sh` is fully `[ERROR]` + exit 1
fail-closed. Also re-verified the OLD 360 audit
(`docs/360/runs/2026-10-09-000410/findings.json`, 55 findings F001-F055) is
fully remediated by the #40-#66 sweep, and fuzzed 20 edge-case CLI
invocations (no crashes, no false successes, no hangs). Conclusion: the
fail-open masking class is exhausted repo-wide and no autonomously-actionable
defect remains. No files changed this run.

Resume here next run: no non-gated work remains. Every open tracker item is
gated -- #67 (a FRESH 360 audit) needs a human scope decision (full vs
scoped) before its Step 1 may run and must NOT be started autonomously; #92
and #51 are hub-side (not this repo). If the operator wants a new unit, the
only substantive option is #67 once a human approves its scope.

Session 2026-10-14 (20th run): shipped **#143** -- the F015 fail-open sweep one
file over, into `bin/sec-organizer`'s `cmd_plan`. Its source-listing reads
normalized a backend failure to `[]` (`bw list items` / `bws secret list` /
`op item list` behind `2>/dev/null || echo "[]"`), so a broken backend made the
item loop iterate zero times and printed `[INFO] Plan Summary: 0 secrets ...`
plus `[ OK ] Plan saved` and exited 0 -- a false success in a credential
housekeeping plan. Added a `require_json_array` guard that rejects an empty
payload or a non-array listing with a tagged `[ERROR] corrupt or unreadable
listing from backend '<x>'` + exit 1; a legitimate empty vault (`[]`) still
passes. Proven red first (four new assertions: section [14c] bw path with
`SEC_TEST_BW_ITEMS` malformed, section [14d] bws path via a counter stub that
reaches the bws branch), then green (dispatch 90 -> 92). Mirrors bumped:
profile.md:22, profile.md tagged census `sec-organizer` 41 -> 42, profile.md
`bin/sec-organizer:201` -> `:215` and `:296` -> `:310` (the +14 shift),
ADAPTERS.md:55, ADAPTERS.md:264, the RESUME mirrors-in-sync line, HISTORY.md
8150/8192.

Left for the next run: the tracker's open items were #67 (fresh 360 audit,
Step-1 scope approval needed), #92 and #51 (hub-side, not this repo). The
fail-open masking class was closed in `bin/sec`, `bin/sec-migrator` and
`bin/sec-organizer`; the next sweep targeted the remaining JSON readers --
`sec-sync-controller.py`, `bw-session-keeper`, `hyer-mcp.sh` -- for a read that
masks a parse failure behind `2>/dev/null || echo 0` / `|| echo ''`. (The 21st
run above did that sweep and found them clean.)

Session 2026-10-14 (19th run): shipped **#142** -- the #126 sweep's own
F015-class residual, found one file over in `bin/sec-migrator`. Two `jq`
reads still swallowed a parse failure behind `2>/dev/null || echo 0`: the
source-listing count (a backend emitting non-JSON while exiting 0 became
`count=0`, printing `[INFO] Zero items found` and exit 0 -- a fail-open
false success in a credential migration) and the apply-mode transaction
check (a corrupt `migration_transaction.json` masked as 0, so an unresolved
transaction was ignored and then overwritten by `save_tx`). Both now use the
F015 `if ! var="$(jq ...)"` convention: tagged `[ERROR]` + exit 1. Proven red
first (both returned rc=0 with the false-success text), then green (dispatch
88 -> 90; new sections [15b] and [15c]). Mirrors bumped: profile.md:22,
profile.md tagged census `sec-migrator` 24 -> 26, profile.md
`bin/sec-migrator:147` -> `:151` (the +4 shift), ADAPTERS.md:55,
ADAPTERS.md:264, the RESUME mirrors-in-sync line, HISTORY.md 8158/8192.

Left for the next run: the tracker's open items are #67 (fresh 360 audit,
Step-1 scope approval needed), #92 and #51 (hub-side, not this repo). The
jq/fail-open masking class is now exhausted in `bin/sec` and
`bin/sec-migrator`; the natural next unit is the same sweep against the OTHER
bin scripts that read JSON (`sec-organizer.py`, `sec-sync-controller.py`,
`bw-session-keeper`, `hyer-mcp.sh`) for a read that masks a parse failure
behind `2>/dev/null || echo 0`/`|| echo ''`. (`bin/sec-migrator` line 248
still masks but is unreachable -- fix#1 exits first.)

Session 2026-10-14 (18th run): shipped **#126** -- bin/sec's `get_cfg_val`
silently dropped any `sec.conf` line with no `=`, so a typo'd key
(`default_backend bitwarden`) was ignored with no signal: the highest-severity
class left, a silent drop in a credential-adjacent parser. Took the
cheapest-reasonable-path design call (warn, not reject): the arm now prints a
tagged `[WARN] sec.conf: ignoring malformed line <NR> (no =): <text>` to stderr
and the parse result plus exit code are UNCHANGED; the awk call's `2>/dev/null`
was dropped so the warning is not swallowed (`|| echo "$default_val"` still
covers an awk failure). Zero line shift -- the edit is confined to the existing
`eq==0` line and the closing redirect, because ~60 repo-doc citations point at
`bin/sec:NNN`. Proven red first (new dispatch section [18d]: malformed config
still routes to the default AND emits the tagged WARN at line 2; a well-formed
control yields the exact default with no WARN). Live dispatch 87 -> 88; mirrors
bumped (profile.md:22, profile.md tagged census `sec` 25 -> 26, ADAPTERS.md:55,
ADAPTERS.md:264, RESUME mirrors-in-sync line), HISTORY.md compacted to 7893/8192.

Left for the next run: the tracker's open items were #67 (fresh 360 audit, Step-1
scope approval needed), #92 and #51 (hub-side, not this repo). Both the
first-match-shadow and silent-drop classes now look exhausted (this run closed
the last silent-drop arm); the productive next question is the one #67 was filed
to answer -- a fresh 360 sweep against the current tree, which needs the human's
scope approval.

Session 2026-10-13 (17th run): #141 -- the audit slot's first-match shadow, third
instance, same class as #140. The migrator SOURCE guard read
`re.search(r'fetch_source_items\(\) \{\n\s*case "\$SRC" in\n([\s\S]*?)\n\s*\*\)')`,
i.e. the first function-name match in `bin/sec-migrator`, so a second
`fetch_source_items() { case "$SRC" in` block above the real one fed
`_mig_src_set` the shadow's set. Proven red first: an untagged shadow carrying
all three arms above the real block, with the real `bws)` arm deleted, still
printed `[ OK ] migrate surfaces: source/destination backend sets agree`
(coverage exit 0). The guard now takes every `fetch_source_items()` block from
`re.finditer`, uses the first, and appends to `migrate_mismatches` when there is
more than one: `[ERROR] migrate: bin/sec-migrator carries 2 fetch_source_items()
source blocks, expected exactly 1`. Case [40] pins it with three probes (shadow +
bws dropped, bws dropped with no shadow, unmutated control).

Also closed out the sweep this run: the AST count over the now-fixed coverage
python (65 `re.search`/`re.match` sites, 21 resolved texts) reports no site whose
target file can carry more than one match. The only `n=0` sites are by design --
`_pkg_live` is a loop-local read of a pack's PACK.md, and the `_btext`
`[ TAG ]` scan is the zero-tag producer census. Live counts now: sentinel
45 cases / 468 assertions (each `ok ` branch is paired with a `no `, so a case
with 4 branches is +8).

Left for the next run: the tracker's open items were #126 (sec.conf parser
silently skips a key with no '='; needs the human design call -- reject vs
tagged WARN), #67 (fresh 360 audit, Step-1 scope approval needed), #92 and #51
(hub-side, not this repo). Beyond those, the remaining first-match class lives
outside the audit slot's python: any bin script whose allow-list is read by a
consumer elsewhere (shell completion generators, install.sh's section census)
is worth the same AST count against ITS consumer.

Session 2026-10-13 (15th run): #139 -- profile.md's bin/ decomposition states
two numbers ("N sibling executables, N Python controller") and sentinel checks
both, but only the first had a drift control, so the controller branch could
have rotted with the suite still green. Case [38] now seeds a fourth workdir and
rewrites ONLY the controller half, leaving the sibling-executable half live so
the assertion is unambiguous; `WRONG_CONTROLLERS` derives from `num_word`, and
forcing it onto the live spelling fails exactly 2 assertions. The live
assertion mirror is a static count of `ok `/`no ` lines, so two new branches
are +4: 430 -> 434. Worth reusing: after the two numeral sweeps the productive
question is no longer "which literals remain" but "which sentinel branches have
no control at all".

Session 2026-10-13 (14th run): the drift sweep's own audit was wrong in a
useful way -- it grepped for corruption replacement strings that *begin* with a
numeral word, so six controls whose literal sat later in the string survived
the first commit (9a4938e): profile.md's seven sibling dispatchers, ADAPTERS.md's
seven `bin/` helpers, MULTI_TENANCY.md's eight fixed aliases,
OPERATOR_MANUAL.md's four core principles, SKILL.md's five `tests/*.sh` scanner
suites and five-suite gate. All six now take a `WRONG_*` word from `num_word`;
forcing each onto its live word fails 12 assertions, so none is a lucky literal.
Dumping every corruption heredoc and grepping the whole replacement body is the
method to reuse. A live bug the run exposed: an expectation grepped with double
quotes around a backticked `tests/*.sh`, so bash command-substituted it before
grep saw the pattern -- patterns containing backticks must be single-quoted.

Same run, **#138**: `citations` walked only the audit skill's two docs, so
RESUME.md's and HISTORY.md's 58 anchors were unverified, and two bare
line-451 citations of the audit `SKILL.md` were silently binding to the
50-line root `SKILL.md` (24 tracked files share that basename). Both are
qualified; the repo docs now get an anchor-resolution pass (path resolves,
range inside EOF, no reversed range) driven by sentinel case [42] with a
derived injected anchor. Deliberately not extended: the bare `line N` rule and
the stale-content / phantom-claim heuristics assume audit-skill prose density
and false-positive on narrative docs. `history/*.md` stays excluded because
those archives record now-stale anchors on purpose. `_NUM_WORDS` gains
forty-two through forty-five. 41 -> 42 cases / 418 -> 430 assertions; mirrors
bumped at `ADAPTERS.md:56`/`:262`, `profile.md:22`/`:641`, this file and
`HISTORY.md`, which was rewritten to stay inside its budget.

Session 2026-10-13 (13th run): finished the drift-control sweep #120's bump
started. Every remaining hardcoded live count or numeral word in
`tests/test_sentinel.sh` now derives from the live tree, and `sentinel.sh` no
longer prints a pinned `all 12 reachable`. The rule is that a drift control
which pins the live value is a control that silently stops testing anything
the day the live value happens to equal it. Mechanism: a `num_word` helper
picks a numeral word that differs from the live one, because a digit swap does
**not** work for the `_NUM_WORDS`-keyed checks (they ignore any word outside
that map, so a digit yields coverage exit 0). Live `forty-one` and `Twelve`
spellings forced `[\w-]+` captures in the corruptions, `[A-Za-z-]+` in the
expectations, and dropped a `[\w-]` inside a `grep -E` bracket that POSIX reads
as `{\, w, -}`. Negative control: forcing the wrong word back onto the live
value turns those controls into no-ops and 10 assertions fail. No tracked-file
or suite-count mirror moved (109 files, 41 cases / 418 assertions).

Same run, second batch: the sweep's own grep was too narrow -- it matched
replacement strings that *start* with a numeral word, so six pinned sites
survived the first commit (9a4938e): profile.md's seven sibling dispatchers,
ADAPTERS.md's seven `bin/` helpers, MULTI_TENANCY.md's eight fixed aliases,
OPERATOR_MANUAL.md's four core principles, SKILL.md's five `tests/*.sh`
scanner suites and five-suite gate. All six now take a `WRONG_*` word from
`num_word` and all six expectations widened. Found by dumping every corruption
heredoc and grepping the whole replacement string, which is the method to reuse.
One live-only grep bug: the expectation for the scanner suites used double
quotes around a pattern containing backticks, so bash ran `tests/*.sh` as a
command substitution -- such greps must be single-quoted. Negative control on
the six: forcing each `WRONG_*` to the live word fails 12 assertions. No
mirror moved.

Session 2026-10-13 (12th run): shipped **#120**'s repo-side half and closed
**#137** (which the 11th run had staged but not committed). #120: the pytest
mirror reported a failing bash suite as only `result.stdout[-2000:]`, and for
the long dispatch suite that tail never carries the failure -- proven by
injection, a check name planted in `test_dispatch.sh`'s first section appeared
**0** times in the old report. `_failing_checks` in
`scripts/tests/test_install.py` now extracts every `  FAIL:` line with its
enclosing `[NN]` section header; `_suite_failure_detail` falls back to a
15-line tail when a suite dies without reporting; both suite runners are pinned
to that call shape by a source-shape guard (the extractor's own tests would
still pass if a runner regressed to raw slicing). Mirror 53 -> 58 tests.
That bump immediately broke sentinel case [22]'s drift controls, which
hardcoded `is now 53 passed` / `suites (53 passed` -- and the new reporter
named the cause in one run ("ADAPTERS.md pytest count not found to corrupt"),
the exact failure mode #120 had created. Those four literals now derive the
live collection count, the pattern case [27] already used. The hook-side half
of #120 (dumping the report) stays hub-side and out of scope.

Session 2026-10-13 (11th run): shipped **#137**, the lane's first *product*
bug rather than a doc-guard: `bin/sec` expands the possibly-empty `SCOPE_ARGS`
bare under `set -u`, fatal on bash < 4.4, so `sec get` died on stock macOS
(bash 3.2) while Linux CI stayed green. Four sites fixed with
`${SCOPE_ARGS[@]+${SCOPE_ARGS[@]}}` (net-zero, anchors unshifted) plus a static
source scanner as dispatch case [32], so the class is finally observable on
Linux. A repo-wide sweep for the rest of the class found zero other hits: no
`declare -A`/`mapfile`/`${x,,}`/`&>>`/`[[ -v ]]` in any shell surface, and no
GNU-ism (`grep -P`, `readlink -f`, `sed -r`, `sha256sum`, `xargs -r`,
`sort -V`, ...) in `bin/sec`, `install.sh`, `bin/hyer-mcp.sh`,
`bin/bw-session-keeper`, `bin/sec-migrator`, `bin/sec-organizer` or
`completions/_sec`, so #137 was its only live instance. Also finished and
shipped the previous run's **#136** (the forge shape guard, commit `201751f`),
which was sitting uncommitted in the tree.


Session 2026-10-13 (10th run): shipped **#136** -- the last sentinel-robustness
class, "a file it does not read". `sentinel.sh` reads profile.md, the live
`SKILL.md`, ADAPTERS.md, the docs, RESUME.md and HISTORY.md, but never
`skills/360-audit-skill-forge/SKILL.md`, the generator spec that declares the
live audit skill's shape ("Eleven steps, sixteen headings counting the title",
"twelve bound audit dimensions", "the twelve personas", "one of three values
only", "Offer exactly two scopes"). RED proof: corrupting ONLY that file
(forge "Eleven steps" -> "Nine steps" etc.) left `coverage` exit 0. Section 16
now reads the forge and cross-checks those constants against the live-derived
`_skill_step_count` / `_live_top_headings` / `_live_personas` / `_sev_set` /
`_live_scopes`; failures emit `[ERROR] skill forge: ...`; test case [41] (2
probes + control, 10 new assertions, 40 -> 41 cases / 408 -> 418).
`_NUM_WORDS` gains `forty-one`. HISTORY.md compacted to 8103 bytes. Tracker
holds #51, #67, #92, #120, #126.

Session 2026-10-13 (9th run): shipped **#135** -- the next sentinel-robustness
class. sentinel section 7 (per-suite section counts, the #48 drift class) derived
each suite's count with `profile_text.find(f"test_{_s}.sh")` (first mention
anywhere) then `re.search` (the next count after it), so one earlier
`tests/test_<suite>.sh` mention with no count on its own line made the guard read
a *different* suite's count -- the same #118 non-anchored-search class that #87
already fixed in the sibling section 9. Pre-fix probe: an intro line naming
`tests/test_dispatch.sh` made coverage exit 1 with "says 9 for
tests/test_dispatch.sh". Now same-line-bound + `findall` all-must-match (the
section 9 convention); test case [40] (2 probes + control, 10 new assertions,
39 -> 40 cases / 398 -> 408). `_NUM_WORDS` gains `forty`. HISTORY.md now
8148/8192 bytes. Tracker holds #51, #67, #92, #120, #126.

Session 2026-10-13 (8th run): shipped **#134** -- the resume's sentinel-robustness
class. profile.md:435 quoted `git ls-files | wc -l` as `99` in the
executed-commands transcript, a stale value contradicting the profile's own
`Denominator: **109 tracked files**`, and unguarded (section 5 only checked the
prose denominator). Set to 109; section 5 now derives both surfaces; test case
[39] (2 probes + control, 6 new assertions, 38 -> 39 cases / 392 -> 398).
`_NUM_WORDS` gains `thirty-nine`. HISTORY.md compacted to 7966 bytes. Tracker
holds #51, #67, #92, #120, #126. Tree clean on `main`.

Session 2026-10-13 (7th run): shipped **#133** -- re-swept profile.md for
unguarded prose counts (the #130-#132 pass covered only the code-derived ones)
and found three classes: seven further suite-count spellings ("five green
suites" + "five bash suites" x6) where only two spellings were guarded; the
"twelve fixed dimensions" persona count (only "Twelve, numbered 1 through 12"
was guarded); and the "five sibling executables, one Python controller" bin/
decomposition (only "seven sibling dispatchers" was guarded). Sentinel sections
13/14/16 now derive all three: 13 splits the live bin/ helpers into controllers
vs non-controller-non-MCP; 14 scans every normalized "N [green|bash] suite(s)"
spelling; 16 scans "N fixed dimensions". Test case [38] (3 probes + control,
14 new assertions, 37 -> 38 cases / 378 -> 392). Tree clean on `main`, CI green.

Session 2026-10-13 (6th run): shipped **#130**, **#131** and **#132** -- three
profile.md code-prose counts. Persona 11 cited the sync controller's
"**4 timeout sites**" and install.sh/bin/sec's "**zero** timeout occurrences",
persona 1 cited SYNC_KEYS' "six env keys"; none was derived from the code.
Sentinel section 22 now counts `timeout=` in bin/sec-sync-controller.py, scans
install.sh + bin/sec for any timeout construct, and parses the live SYNC_KEYS
list -- comparing each claim's count and (for SYNC_KEYS) the member set.
Test case [37] (3 probes + control, 16 new assertions, 36 -> 37 cases /
362 -> 378). Tree clean on `main`, CI green.

Session 2026-10-13 (5th run): shipped **#129** — the unguarded-claim sweep of
ADAPTERS.md / docs/ARCHITECTURE.md / docs/OPERATOR_MANUAL.md found one
unguarded census: ADAPTERS.md's Opted-in Policy Packs section (five
`packs/<name> (vX.Y.Z)` citations + the "9-persona taxonomy total") had no
guard deriving it from the live packs/ PACK.md files (section 10 only checked
profile.md's copy, #86). Section 10 now compares every citation against each
pack's live `Pack version:`, fails on an uncited live pack dir, and compares
the persona-taxonomy total against PACK.md's live `### N.` headings; case
[36] proves it (2 probes + control, 10 assertions, 35 -> 36 cases /
352 -> 362). Every other numeric claim in the three docs verified guarded or
historical. Tree clean on `main`, CI green.

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

Every open item is hub-side or human-gated (#120 was closed this run). If
the lane is run again, the highest-value candidates are a fresh sweep for the
next unguarded current-state claim (as #116, #117, #123, #130-#132 and #144
were) or another sentinel-robustness class (as #118 was), then the fresh 360
audit (#67, after human scope approval).
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
live bin/sec completion dispatch. Next candidates, in
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

- `git status` clean on `main`; `origin/main` == local `main` (verified after
  the #137 commit and push).
- Tracker: **GitHub** (`gh --repo atalby/sec-cli`), not glab. Remote is
  `git@github.com:atalby/sec-cli.git`; `glab` errors "None of the git remotes
  configured for this repository point to a known GitLab host" (re-confirmed
  2026-10-13 against a live `glab auth status`, which IS authenticated --
  for gitlab.com, which this repo is not on).
- Open issues: **#67** (fresh 360 audit - human scope gate); **#92**
  (hub-side unguarded counts); **#51** (hub-side handoff, tracked upstream).
  **#126** closed in the 18th run (warn design call, dispatch [18d]); #120
  closed earlier (repo-side observability half shipped, hook fix stayed
  hub-side). Re-verified live via `gh issue list` this run.
- Operator standing order says the tracker is GitLab/`glab`; re-verified this
  run that it is not -- `git remote -v` is `git@github.com:atalby/sec-cli.git`
  and `glab issue list` fails with "None of the git remotes configured for this
  repository point to a known GitLab host" while `glab auth status` shows a
  live gitlab.com login. This repo is GitHub-tracked, so `gh` is used.

## Shipped this session (all committed, pushed, CI green, issue closed)

- #153 `feat(sentinel)` - the `sec completion` surface (OPERATOR_MANUAL.md:95-96) had no guard. Sentinel section 31 parses the shell arms from bin/sec's completion dispatch and requires the doc's shell set + `powershell`->`ps1` alias to match the live grouping, and `completions/_sec` to be byte-identical to live `bin/sec completion zsh` (case [53], four probes + control). Sentinel 54 -> 55 cases / 628 -> 648 assertions.
- #152 `feat(sentinel)` - the classifier-category names (README.md:15 + docs/ARCHITECTURE.md:12) had no guard. Sentinel section 30 parses the live `CATEGORY_WEIGHTS` keys from bin/sec-classify.py and the `general` fallback, requiring every category named in both docs to be a live key (case [52], four probes + control). Sentinel 53 -> 54 cases / 608 -> 628 assertions.
- #151 `feat(sentinel)` - the `sec run` env-injection backend prose (README.md:11
  + :136, docs/ARCHITECTURE.md:22) had no guard; only the byte-identical
  `sec --help` block copy was covered. Sentinel section 29 parses the live
  injection backends from bin/sec's `run)` arm case patterns and requires each
  prose site to name exactly that set, plus both docs to still call `bitwarden`
  a plain exec (case [51], four probes + control). Sentinel 52 -> 53 cases /
  588 -> 608 assertions.
- #150 `feat(sentinel)` - the runtime-dependency sentence (README.md:5 +
  docs/ARCHITECTURE.md:6) and the documented `SEC_*` env vars were the last
  unguarded doc-name claims. Sentinel section 28 binds the dep set parsed from
  the sentence to install.sh's `for _dep in jq python3` loop, and requires every
  `SEC_*` token named in the five shipped docs to appear in install.sh or a file
  under bin/ (case [50], four probes + control). Sentinel 51 -> 52 cases /
  568 -> 588 assertions.
- #149 `feat(sentinel)` - the last five unguarded natural-language mode claims:
  README.md's snapshot mode, OPERATOR_MANUAL.md's snapshot mode + path, and
  ARCHITECTURE.md's session/umask/cache-dir/plan/sec.conf modes now bind to
  the live `bin/sec-organizer`, `bin/bw-session-keeper`, and `install.sh`
  chmod/umask calls via sentinel section 27 (case [49], six probes + control).
  Sentinel 50 -> 51 cases / 540 -> 568 assertions.
- #148 `fix(sentinel)` - RESUME.md's own two count mirrors (the 'suite counts
  ... mirrors in sync' line and the 'Sentinel = N cases / M assertions' total)
  were the remaining non-anchored first-match count-grabs of the #118/#128/
  #135/#147 shape. Both live inside `## Verified baseline`, but section 17
  searched the whole append-heavy narrative, so an earlier 'Shipped this
  session' echo of either shape could shadow the real claim and pass a drifted
  line (fail-open). Both searches are now scoped to the Verified baseline
  section body (the convention its sibling bytes check already used). Case [48]
  proven red first: unfixed guard exited 0 with three failures, clean control
  exited 0. Sentinel 49 -> 50 cases / 532 -> 540 assertions; `_NUM_WORDS`
  gained `fifty`; mirrors bumped at `profile.md:22`, `profile.md:641`,
  `ADAPTERS.md:56`, `ADAPTERS.md:262`, and the baseline `Sentinel =` line.

- #147 `fix(sentinel)` - section 9's `current suites:` extractor was the last
  non-anchored first-match count-grab of the #118/#136 shape: an earlier inline
  (non-line-start) `current suites:` mention in ADAPTERS.md could shadow the real
  snapshot and fire five false `[ERROR] adapters suite:` lines. The regex is now
  line-anchored (`(?m)^[ \t]*current suites:`). Case [47] (probe + control).
  Sentinel 48 -> 49 cases / 524 -> 532 assertions; mirrors bumped at
  `profile.md:22`, `profile.md:641` (forty-nine), `ADAPTERS.md:56`,
  `ADAPTERS.md:262`, and the baseline `Sentinel =` line.

- #146 `fix(sentinel)` - the `~/.sec/sec.conf` mode `0600` prose in README.md:48
  and docs/MULTI_TENANCY.md:9 was unguarded (only docs/SECURITY.md's differing
  wording was, via section 25). Section 26 reuses the section-25 helpers to
  resolve the live `bin/sec` chmod on `$CONFIG_FILE` and fails when either doc's
  stated mode drifts, names a different path, or drops the claim. Case [46], four
  probes + control. Sentinel 47 -> 48 cases / 504 -> 524 assertions; mirrors
  bumped at `profile.md:22`, `profile.md:641` (forty-eight), `ADAPTERS.md:56`,
  `ADAPTERS.md:262`, and the baseline `Sentinel =` line.

- #120 `fix(test)` - the repo-side observability half of the flaky-dispatch
  issue, and the reason that issue was undiagnosable. The mirror reported a
  failing suite as `result.stdout[-2000:]`; for the long dispatch suite that
  tail never contains the failure. Proof by injection: a `fail` planted in
  `test_dispatch.sh`'s first section appears **0** times in the old pytest
  report and is named by the new one. `_failing_checks` extracts every
  `  FAIL:` line with its enclosing `[NN]` header (one extractor covers all
  five suites -- they share the `fail() { echo "  FAIL: $1"; }` shape);
  `_suite_failure_detail` adds a 15-line tail and, when a suite dies without
  reporting, says so instead of showing an arbitrary window. Five new tests,
  including a source-shape guard on both runner bodies because the extractor's
  own tests would still pass if a runner regressed to raw slicing. Mirror 53
  -> 58; mirrors bumped at `ADAPTERS.md:305`, `skills/architecture-360-audit/SKILL.md:451`,
  `profile.md:427`, `RESUME.md` baseline and `HISTORY.md`. Second-order find:
  sentinel case [22]'s drift-control literals hardcoded `53` and broke on the
  bump -- named by the new reporter in one run -- so they now derive the live
  collection count (`PYTEST_COUNT`), the pattern case [27] already used.

- #137 `fix(dispatch)` - a real product bug,
  not a doc-guard. `bin/sec` runs `set -euo pipefail` and expanded the
  possibly-empty `SCOPE_ARGS` bare at bin/sec:497/520/535/542, so on stock
  macOS (`env bash` = 3.2, where an empty `[@]` expansion under `set -u` is a
  fatal `unbound variable`) plain `sec get KEY` died with rc 1. All four sites
  now use `${SCOPE_ARGS[@]+${SCOPE_ARGS[@]}}` -- net-zero edits, so no
  `bin/sec:N` anchor shifted and `sentinel.sh citations` stayed green. Because
  Linux CI cannot observe a bash-3.2 failure, dispatch case [32] scans the
  source instead: every `"${NAME[@]}"` whose `NAME=()` is assigned somewhere
  in `bin/sec` fails (a `+`-prefixed match is the guarded inner form), so the
  class is visible on Linux. RED: the first version of the scanner matched
  nothing because its name-extraction used `%%[*` (an unterminated bracket
  glob, which bash treats literally); it failed green until rewritten with a
  sed name-extraction, then failed correctly naming `SCOPE_ARGS`. Mirrors
  bumped to dispatch 87 at profile.md:22, ADAPTERS.md:55 + :264, RESUME.md
  baseline; HISTORY.md compacted 8103 -> 8179.

- #133 `fix(sentinel)` - profile.md's remaining unguarded prose counts, guarded
  by extending existing sections. (1) suite count: sections 14 now scans every
  normalized "N [green|bash] suite(s)" spelling in profile.md against the live
  `tests/*.sh` count (five; only "N suites under tests/" + "runs all N suites"
  were guarded). (2) persona count: section 16 scans "N fixed dimensions"
  against the live persona-heading count (twelve; only "Twelve, numbered 1
  through 12" was guarded). (3) bin decomposition: section 13 splits the live
  bin/ helpers into controller (`*-controller.py`) vs non-controller-non-MCP and
  checks profile.md's "N sibling executables, N Python controller" (five + one).
  Case [38]: probe 1 edits "five green" -> "six green", probe 2 "twelve fixed
  dimensions" -> "thirteen", probe 3 "five sibling executables" -> "six",
  control exits 0. 14 new assertions (7 ok/no sites), 37 -> 38 cases /
  378 -> 392; `_NUM_WORDS` gains `thirty-eight`. Mirrors bumped at profile.md:22
  + :641, ADAPTERS.md:56 + :262, RESUME.md baseline; HISTORY.md's 2026-10-13
  block gained the #133 sentence and was compacted (8178 -> 8190).

- #130/#131/#132 `fix(sentinel)` - profile.md's own code-prose counts, all
  guarded by the new sentinel section 22. Persona 11 cited the sync
  controller's "**4 timeout sites**" (nothing derived it from the `timeout=`
  occurrences) and install.sh/bin/sec's "**zero** timeout occurrences";
  persona 1 cited SYNC_KEYS' "six env keys". Section 22 counts `timeout=` in
  `bin/sec-sync-controller.py`, scans install.sh + bin/sec for any
  `timeout`/`--max-time`/`--connect-timeout`, and parses the live SYNC_KEYS
  list -- failing on both a count drift and a member-set drift. Case [37]:
  probe 1 bumps profile's "4 timeout sites" to 5, probe 2 plants `timeout 30`
  on install.sh's git clone (live 1 vs the zero claim), probe 3 drops
  `STRIPE_SECRET_KEY` from SYNC_KEYS (live 5 + names drift), control exits 0.
  16 new assertions (8 ok/no sites), 36 -> 37 cases / 362 -> 378; `_NUM_WORDS`
  gains `zero` + `thirty-seven`. Mirrors bumped at profile.md:22 + :641,
  ADAPTERS.md:56 + :262, RESUME.md baseline; HISTORY.md's 2026-10-13 block
  gained the #130-#132 sentence and was compacted to stay under budget
  (8188 -> 8178).

- #129 `fix(sentinel)` - ADAPTERS.md's Opted-in Policy Packs section cited
  all five pack versions (`zero-cost-infra-defaults`, `solo-founder-governance`,
  `ip-and-data-governance`, `compliance-baseline`, `human-team-coordination`)
  plus a "9-persona taxonomy total", and nothing derived any of it from the
  live packs/ PACK.md files (section 10/#86 checked only profile.md's copy).
  Section 10 now compares every `packs/<name> (vX.Y.Z)` citation against that
  pack's live `Pack version:`, fails when a live pack dir is uncited, and
  compares the persona-taxonomy total against PACK.md's live `### N.` persona
  headings. Case [36]: probe 1 rewrites the solo-founder citation to v9.9.9,
  probe 2 rewrites "9-persona" to "10-persona", control unmodified exits 0.
  10 new assertions, 35 -> 36 cases / 352 -> 362. Mirrors bumped at
  `profile.md:22` + section 3, `ADAPTERS.md:55` + `:262`, `RESUME.md` baseline
  + this section; `_NUM_WORDS` gains `thirty-six`. HISTORY.md needed three
  compacted clauses to fit the entry under its 8192-byte budget, which tripped
  the #124 guard on RESUME.md's own size line in the same edit (8136 -> 8188).

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
  `profile.md:22`/`:641`, `ADAPTERS.md:56`/`:262`, `RESUME.md:197`/`:198`;
  `_NUM_WORDS` gains `twenty-nine`; control [22] literals re-pinned.
- #117 `fix(docs)` -> `3f0e69b` - `RESUME.md`'s `## Current state` line (160)
  declaring 108 tracked files / 12 personas / 5 bash suites was the last
  unguarded structural claim; corrupting it left `coverage` exiting 0. Extended sentinel
  section 17 with a `(\d+) tracked files, (\d+) personas, (\d+) bash suites`
  guard against `len(tracked)`, `_live_personas`, `_live_suite_count`. Case
  [28] proves it. Sentinel 27 -> 28 cases / 272 -> 278 assertions; mirrors
  `profile.md:22`/`:641`, `ADAPTERS.md:56`/`:262`, `RESUME.md:197`/`:198`;
  `_NUM_WORDS` gains `twenty-eight`; control [22] literals re-pinned.
- #116 `fix(docs)` -> `fddb57b` - `HISTORY.md`'s `## Current state` claimed a
  pytest mirror of 29 tests (live 53) and a stale open-issue set; that count was
  guarded in `ADAPTERS.md` + audit `SKILL.md` (#97) and `RESUME.md` (#109) but
  not in `HISTORY.md`. Fixed the value and extended sentinel section 17 to
  guard `HISTORY.md` too. Case [27] proves it (corrupt 53 -> 52 -> `coverage`
  exits nonzero naming the drift; control exits 0). Sentinel 26 -> 27 cases /
  266 -> 272 assertions; mirrors `profile.md:22`/`:641`, `ADAPTERS.md:56`/`:262`,
  `RESUME.md:181`; `_NUM_WORDS` gains `twenty-seven`; control [22] literals
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
  `profile.md:641`, `ADAPTERS.md:56`, `ADAPTERS.md:262`, `RESUME.md:171-172`;
  sentinel control [17] literals re-pinned (`twenty-six`, `live suite has 26`).
- #113 `test(sync)` -> `d4890c3` - 10 new pytest cases covering the untested
  user-facing error contract of the two Python entrypoints: sync controller
  GCP add-version timeout / missing-binary / stderr-detail, `main()` help (0),
  usage-error (2), gitlab-failure (3), interactive abort (2) / confirm (0),
  and a real CLI `--help` subprocess; classify invalid-JSON fallback (exit 0,
  no crash). pytest mirror 43 -> 53; mirrors bumped at `ADAPTERS.md:305`,
  `skills/architecture-360-audit/SKILL.md:451`, `profile.md:427` transcript,
  `RESUME.md:157`. Sentinel control [3] drift regexes re-pinned 43 -> 53.
- #112 `test(classify)` -> `d9fb2d3` - 2 new pytest cases covering
  `infer_suggested_name`'s env/project tag branch (generic name + notes with
  `env: tag` -> `name (tag)`, needs_rename). pytest mirror 41 -> 43; mirrors
  bumped at `ADAPTERS.md:305`, `skills/architecture-360-audit/SKILL.md:451`,
  `profile.md:427` transcript, `RESUME.md:144`. Sentinel control [3] drift
  regexes re-pinned 41 -> 43.
- #111 `test(sync)` -> `84c3ee6` - 12 new pytest cases covering the sync
  controller's untested surface: GCP write path (describe / create-on-missing /
  add-version / timeout / failure), `parse_args` usage-error contract, and
  `main()` exit codes 0/1/2/3. pytest mirror 29 -> 41; mirrors bumped at
  `ADAPTERS.md:305`, `skills/architecture-360-audit/SKILL.md:451`,
  `profile.md:427` transcript, `RESUME.md:144`. Sentinel control [3]'s
  hardcoded drift count re-pinned 29 -> 41.
- #110 `fix(migrate)` -> `8ba4a49` - `sec migrate undo|revert|--undo` short-circuited
  the migrator's arg parse (bin/sec-migrator:50), so `sec migrate undo EXTRA`
  silently dropped the operand and proceeded to the rollback path. The undo
  branch now rejects trailing operands with a tagged `[ERROR]` + exit 2 before
  any transaction-log access. Dispatch section [2d3] pins it (undo EXTRA /
  --undo EXTRA / revert EXTRA all refused pre-TX-check). Mirrors 85 -> 86 at
  `profile.md:22`, `ADAPTERS.md:55`, `ADAPTERS.md:264`, `RESUME.md:143`.
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
  `RESUME.md:127`; suite now 24 cases / 250 assertions.
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
.venv/bin/python -m pytest -q                                                               # 58 passed
./skills/architecture-360-audit/sentinel.sh coverage                                        # exit 0
./skills/architecture-360-audit/sentinel.sh citations                                       # exit 0
```

Live suite section counts (sentinel `coverage` re-derives these; keep the three
mirrors in sync): dispatch 92, install 9, sentinel 55, sync_guard 16,
write_honesty 15. Sentinel = 55 cases / 648 assertions. HISTORY.md is at
8056/8192 bytes - the next narrative addition must still compact first if it
would cross the budget (#146/#147/#148's entries extended the 2026-10-14 paragraph
and appended to `history/2026-10-14.md`).
110 tracked files, 12 personas, 5 bash suites. No unmerged branches (only main).
No real TODO/FIXME debt in tracked files. Sentinel suite wall time ~150s (each
guard case re-runs full coverage a few times); the pytest mirror adds ~3.5 min.
Run both when a sentinel section changes.

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
