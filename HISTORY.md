# History — sec-cli

## Current state

This file is the narrative intent record, kept short on purpose: the full
record is archived per period under `history/` (append-only, nothing
deleted, every file searchable). A new session reads this summary by
default, not the whole history.

**2026-10-14**: the unguarded-current-state-claim sweep ran #144-#159, one
project-owned doc claim per issue, each closed by a sentinel section that derives
the live value from the code and requires the doc to match: HIAE banner (#144),
SECURITY.md path->mode pairs (#145), the two docs quoting the config mode
(#146), the section-9 suite extractor (#147), RESUME.md's count mirrors (#148),
natural-language mode prose (#149), runtime deps + SEC_* vars (#150), `sec run`
injection backends (#151), classifier categories (#152), the completion surface
(#153), the bin/sec.ps1 surface (#154), SECURITY.md's executable census (#155),
`sec sync` exit codes (#156, extended to SKILL.md in #157), SECURITY.md's argv
mitigations (#158) and snapshot-contents field set (#159, which had gone stale).
Sentinel 49 -> 60 cases / 532 -> 736 assertions. Tracker holds #51, #67, #92.
Full narrative: `history/2026-10-14.md`.

**2026-10-15**: two more passes of the same sweep. First, docs/ARCHITECTURE.md's
`install.sh` bullet (bootstrap clone dir, install destination, `bin/` helper set --
the `bin/*` wording was imprecise, `bin/hyer-mcp.sh` is never installed -- the
piped-mode empty-dir fallback, the LICENSE copy name, the missing-git diagnosis)
had no guard; sentinel section 37 checks each against install.sh (case [61], five
probes + control proven red first). Its commit cites "issue #160" but no such
issue was ever filed -- the tracker sat at 159 until this run filed its own
finding, which took #160, so that citation is a dead reference.
Second, docs/MULTI_TENANCY.md's `auto_rotate` contract claimed a two-branch
true/false rule "for each tenant section"; live bin/sec reads the key once and
consults it only in the `bitwarden|bw)` arm, `op` and `vault` prompt
unconditionally, `bws`/`infisical`/`keychain` have no auth arm at all, and the
prompt is a fallback reached under `auto_rotate = true` too -- not a false-branch.
The doc became a per-backend table; sentinel section 38 derives the
consulted/prompting/no-arm sets from `ensure_tenant_auth` (case [62], three
probes + control proven red first). Sentinel 60 -> 62 cases / 736 -> 776
assertions. Tracker holds #51, #67, #92.
Full narrative: `history/2026-10-15.md`.

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

