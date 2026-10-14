# History — sec-cli

## Current state

This file is the narrative intent record, kept short on purpose: the full
record is archived per period under `history/` (append-only, nothing
deleted, every file searchable). A new session reads this summary by
default, not the whole history.

**2026-10-12**: the flag-misparse / operand-honesty sweep closed
wholesale (#71-#80): `sec get`, `set`/`create` and `unlock`/`rotate`/
`keep` reject an unknown `--flag`/`-f*` at the operand position with a
tagged `[ERROR]` + exit 2 before any backend call (same contract #73
shipped for `sec.ps1`), the
same arms reject trailing/dropped operands (`run` stays variadic;
`rotate`/`keep` reject positionals, `unlock`/`setup-keychain` take one
optional password), `sec get --scope` rejects a flag-like folder
name, `sec housekeep`/`organize` no longer drops extra operands, and a
`bw-session-keeper` `rotate`/`keep` whose vault refresh failed died under
`set -e` — now exit 1 + tagged `[ERROR]`. Issue #64 (pre-commit
vanishing when `uv` is absent) verified as a duplicate of #51's payload
and closed. Issue
#78-#80 closed the completion-parity class: fish omitted the tenant-prefix
words; no housekeep subcommands followed the `organize` alias; all four surfaces
advertised only `plan/apply/revert` (now `undo`/`restore`, matching
`sec-organizer`); guard [22s] pins it (dispatch 74 -> 75).
Issue #81 fixed the ps1 completion runtime (`$commandAst.ArgumentElements`
-> `CommandElements`, so ps1 subcommand completion had been dead code) and
pinned the `powershell` shell word plus the migrate backend values; #82
added the bare `help`/`version` subcommands; #83 added `get --scope` /
`set|create --type`; guards [22t]-[22w] pin them (dispatch 75 -> 79;
`completions/_sec` regenerated). Issues #84-#91 closed
the census-drift class (#84-#90; details in `history/2026-10-12.md`); section 13
asserts every tracked `bin/` helper is referenced by `tests/test_dispatch.sh`. #91 guarded
the three bash-suite-count claims, re-derived from `tests/*.sh`
(section 14; sentinel 17 -> 18 cases).
Issue #93 repaired README.md's `sec housekeep` sample output, which the
shipped classifier could never produce — now pinned by dispatch section
[16-honesty], taxonomy unchanged. Issues #94-#98 guarded the remaining
structural claims: MULTI_TENANCY.md's alias count vs bin/sec's tenant regex,
profile.md's CI checkout pin, OPERATOR_MANUAL.md's principle count, SKILL.md's
suite/step/persona/scope/severity counts, and profile.md §3's four suite
count-words plus the pytest-mirror count (section 17). Issues #99/#100 closed the last silent-drop arms —
`sec completion <shell> <extra>`, `sec help <x>` and `sec version <x>` all
exited 0 while dropping the operand; each now rejects it with a tagged
`[ERROR]` + exit 2 (dispatch 80 -> 82 sections).
Issues #101-#103 tied the completion surfaces to the dispatcher: `sec --help`
prints a line for every subcommand and non-flag arm, the tenant set is identical
across dispatcher/usage/completions, and each surface offers every subcommand
token (#103 parses each surface's own list and asserts all 15) (dispatch 83 ->
85 sections).
Issue #110 closed the last silent-drop arm in the migrator: `sec migrate
undo|revert|--undo` short-circuited the argument parse, so `sec migrate undo
EXTRA` dropped the operand; the undo
branch now rejects trailing operands with a tagged `[ERROR]` + exit 2 before
any transaction-log access (dispatch 85 -> 86 sections).
Issue #111 covered the sync controller's untested surface: the GCP
write path (describe / create-on-missing / add-version / timeout / failure),
the `parse_args` usage-error contract, and `main()`'s exit codes (pytest
29 -> 41; mirrors bumped at ADAPTERS.md:305, skills/architecture-360-audit/SKILL.md:451; control
[3] re-pinned).
Issue #112 covered `infer_suggested_name`'s env/project tag branch (generic
name + notes with `env: tag` -> `name (tag)`, needs_rename) — the username
path was tested, the regex path was not (pytest 41 -> 43; mirrors bumped;
control [3] re-pinned).
Open items: #67 (360 audit —
needs human scope approval), #51 (hub-side, tracked upstream), #92 (hub-side:
packs persona-count + AGENTS.md core-trait count unguarded). Full narrative:
`history/2026-10-12.md`.

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

- [2026-10-13](history/2026-10-13.md)
- [2026-10-12](history/2026-10-12.md)
- [2026-10-11](history/2026-10-11.md)
- [2026-10-10](history/2026-10-10.md)
- [2026-10-09](history/2026-10-09.md)
- [2026-10-08](history/2026-10-08.md)
- [2026-08-27](history/2026-08-27.md)
- [2026-08-12](history/2026-08-12.md)

