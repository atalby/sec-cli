# History — sec-cli

## Current state

This file is the narrative intent record, kept short on purpose: the full
record is archived per period under `history/` (append-only, nothing
deleted, every file searchable). A new session reads this summary by
default, not the whole history.

**2026-10-14**: #144 closed the unguarded-current-state sweep's next instance:
docs/ARCHITECTURE.md's HIAE version banner had no in-repo guard (only the
hand-run hub `check_version_banners.py`, quoted in profile.md), so a
fleet-sync AGENTS.md bump would leave it stale with CI green; sentinel
section 23 now compares the banner vs AGENTS.md (case [43], proven red
first). #145 then swept the same class one file over:
docs/SECURITY.md's "File Permissions Architecture" states six path->mode
pairs with no guard, so a dropped `chmod` would leave the security doc lying
with CI green; sentinel section 25 resolves each doc path from its source
variable and checks the mode against both its own inline chmod and the live
chmod, both directions. #145 also closed section 24's untested debt (case [44])
and covered section 25 (case [45]). Sentinel 45 -> 47 cases
/ 468 -> 504 assertions. #146 swept the same class into the two docs that quote
the config-file mode outside SECURITY.md: README.md and docs/MULTI_TENANCY.md
both state `~/.sec/sec.conf` (mode `0600`) with no guard, so sentinel section 26
resolves the live `bin/sec` chmod on `$CONFIG_FILE` and fails if either doc's
stated mode drifts, names a different path, or drops the claim (case [46]).
Sentinel 47 -> 48 cases / 504 -> 524 assertions. #147 then line-anchored section
9's `current suites:` extractor (an earlier inline mention shadowed the real
ADAPTERS.md snapshot; case [47], red first). #148 scoped RESUME.md's two own
count mirrors ('suite counts ... mirrors in sync' and 'Sentinel = N cases / M
assertions') to `## Verified baseline`'s body so an earlier echo cannot shadow
the real claim (case [48], proven red first). #149 guarded the last prose
natural-language mode claims (README.md + OPERATOR_MANUAL.md + ARCHITECTURE.md
vs their live chmod/umask; section 27, case [49], proven red first). Sentinel
49 -> 51 cases / 532 -> 568 assertions. #150 guarded the runtime-dependency sentence +
documented SEC_* var names (README.md + ARCHITECTURE.md vs install.sh's
`for _dep` loop + bin/; section 28, case [50], proven red first). #151 guarded
the `sec run` injection-backend prose (README.md + ARCHITECTURE.md vs bin/sec's
`run)` arm; section 29, case [51], proven red first). #152 guarded the
classifier-category names (README.md + ARCHITECTURE.md vs bin/sec-classify.py's
CATEGORY_WEIGHTS keys + the `general` fallback; section 30, case [52], proven
red first). #153 guarded the completion surface (OPERATOR_MANUAL.md vs bin/sec's
completion dispatch + completions/_sec; section 31, case [53]). #154 guarded
ARCHITECTURE.md's bin/sec.ps1 native-subset + bash-only full-surface claim vs the
live dispatch (section 32, case [54]; both proven red first). #155 guarded
docs/SECURITY.md's executables enumeration vs the live tracked bin/ tree grouped
by shebang (section 33, case [57], proven red first). #156 guarded `sec sync`'s
exit-code contract (OPERATOR_MANUAL.md + ARCHITECTURE.md vs
bin/sec-sync-controller.py's returned codes + meaning anchors; section 34,
case [58], proven red first); #157 extended that guard to the contract's third
enumeration, SKILL.md's stale `exit codes 0/1/2` (now 0/1/2/3). Sentinel 49 -> 58
cases / 532 -> 712 assertions.
Tracker holds #51, #67, #92.
Full narrative: `history/2026-10-14.md`.

**2026-10-12**: the flag-misparse / operand-honesty sweep (#71-#80) rejected
unknown flags and dropped operands with tagged `[ERROR]` + exit 2; completion
parity and runtime fixed (#78-#83); the census-drift class closed (#84-#91,
sentinel 17 -> 18 cases); README's housekeep sample repaired (#93); structural
claims guarded (#94-#98); the last silent-drop arms closed (#99/#100,
#110-#112); completion surfaces tied to the dispatcher (#101-#103); the sync
controller's write path and the naming branch covered (pytest 29 -> 43);
#64 closed as a duplicate of #51's payload. Detail: `history/2026-10-12.md`.

**2026-10-13**: the guard-hardening lane closed more guard classes plus one
real product bug. #119-#136 swept and guarded stale current-state claims:
audit profile line anchors, README's backend universe, RESUME's own size
claim, two F041 dead config keys, bin/sec's tenant help line, ADAPTERS.md's
pack/persona census, profile.md's code-prose counts and tracked-file
transcript, sentinel section 7's shadowable first-match, and the
360-audit-skill-forge spec (42 cases / 434 assertions). #137 was the lane's
first product bug: `bin/sec` ran `set -u` and expanded the possibly-empty
`SCOPE_ARGS` bare, a fatal `unbound variable` on bash < 4.4, so `sec get` died
on stock macOS while Linux CI stayed green; four sites fixed plus a source
scanner (case [32]). #120's half closed the observability
gap behind its un-diagnosable flake: the pytest mirror reported a failing
suite as only its last 2000 chars; it now names every `  FAIL:` line with its
section (53 -> 58 tests). The sweep also derived every remaining live
count and numeral word in `tests/test_sentinel.sh` (a `_NUM_WORDS`-keyed check
ignores a digit, so only a word swap fails); its first pass
missed six (dump every corruption heredoc, not grep prefixes). #138 found the class one layer out: `citations` walked only the
audit skill's two docs, leaving RESUME.md's and HISTORY.md's 58 anchors
unverified, and two bare line-451 citations of the audit `SKILL.md`
silently resolved to the 50-line root `SKILL.md`. Both are qualified; repo docs now get an anchor pass (path,
EOF, range) with a drift control. #139: profile.md's bin
decomposition names a controller count with no drift control, so it could rot
silently. #140 closed the same first-match class at the audit slot: the migrate
and alias guards took the first regex hit, so a duplicate above the canonical
one fed them a set they then agreed with; both now select the canonical
block/gate line and flag duplicates (case [39], 452 assertions); #141 anchored
the migrator source guard too (case [40]). #126 closed a real parser
silent-drop: `bin/sec`'s `get_cfg_val` skipped any `sec.conf` line with no `=`,
so a typo like `default_backend bitwarden` was ignored with no signal; it now
emits a tagged `[WARN]` naming the line (in-place, no line shift; dispatch
[18d]). #142 closed the F015-class residual: `sec-migrator` masked `jq`
parse failures in two reads (a malformed source listing reported "Zero
items found" + exit 0; a corrupt apply-mode transaction log was ignored),
both now tagged `[ERROR]` + exit 1 (dispatch 88 -> 90). #143 swept the F015
class one file over: `sec-organizer`'s plan read normalized a bw/op/bws
listing failure to `[]`, so a broken backend produced a false "0 secrets"
plan + exit 0; a `require_json_array` guard now rejects an empty or non-array
listing with a tagged `[ERROR]` + exit 1 (dispatch 90 -> 92). Tracker holds #51,
#67, #92.
Full narrative: `history/2026-10-13.md`.

**2026-10-11**: issue #47 executed the narrative rotation policy declared
in `ADAPTERS.md` (AGENTS.md §5) — the single 103 KB `HISTORY.md` was
split losslessly into per-date archives under `history/`, and
`sentinel.sh coverage` gained a guard so the file cannot silently re-bloat. The day then swept
dispatcher/completion/argv/doc-honesty residuals (#40–#66; detail in
`history/2026-10-11.md`), notably moving secrets off child argv (#58/#59) and a baseline-red
ungitignored local `.venv/` (#68; now ignored). All five bash suites and the
pytest mirror (58 tests) pass. Full narrative:
`history/2026-10-11.md` / `history/2026-10-12.md`.

## Archive

- [2026-10-14](history/2026-10-14.md)
- [2026-10-13](history/2026-10-13.md)
- [2026-10-12](history/2026-10-12.md)
- [2026-10-11](history/2026-10-11.md)
- [2026-10-10](history/2026-10-10.md)
- [2026-10-09](history/2026-10-09.md)
- [2026-10-08](history/2026-10-08.md)
- [2026-08-27](history/2026-08-27.md)
- [2026-08-12](history/2026-08-12.md)

