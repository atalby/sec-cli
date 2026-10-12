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
shipped for `sec.ps1`; keys/passwords must not begin with `-`), the
same arms reject trailing/dropped operands (`run` stays variadic;
`rotate`/`keep` reject any positional, `unlock`/`setup-keychain` still
take one optional password), `sec get --scope` rejects a flag-like folder
name, `sec housekeep`/`organize` no longer drops extra operands, and a
`bw-session-keeper` `rotate`/`keep` whose vault refresh failed died under
`set -e` with no message — now exit 1 + tagged `[ERROR]`. Issue #64
(local pre-commit enforcement vanishing when `uv` is absent) was verified
as a duplicate of #51's hub-side payload and closed as duplicate. Issue
#78-#80 closed the completion-parity class: fish omitted the tenant-prefix
words the other surfaces offer; no housekeep subcommands followed the
`organize` alias; and all four surfaces advertised only `plan/apply/revert`
(now `undo`/`restore` too, matching `sec-organizer`); guard [22s] pins it
(dispatch 74 -> 75; `completions/_sec` regenerated).
Issue #81 fixed the ps1 completion runtime (`$commandAst.ArgumentElements`
-> `CommandElements`, so ps1 subcommand completion had been dead code) and
pinned the `powershell` shell word plus the migrate backend values; #82
added the bare `help`/`version` subcommands; #83 added `get --scope` /
`set|create --type`; guards [22t]-[22w] pin them (dispatch 75 -> 79;
`completions/_sec` regenerated each time). The top-level `usage()` stays
canonical. Issues #84-#91 closed
the census-drift class: profile.md's ecosystem + per-file censuses (#84),
ADAPTERS.md's `current suites:` snapshot (#85), the audit profile's stale
pack taxonomy (#86), ADAPTERS.md's per-suite `(N sections|cases)` counts
(#87), ARCHITECTURE.md's producer census (#88), the skills/registry census
(#89), and two *drifted* prose counts — "five sibling dispatchers" (live
7) and "four helper scripts" (live 7) (#90); section 13 also asserts every
tracked `bin/` helper is referenced by `tests/test_dispatch.sh`. #91 guarded
the three bash-suite-count claims, re-derived from tracked `tests/*.sh`
(section 14; sentinel 17 -> 18 cases).
Issue #93 then repaired README.md's `sec housekeep` sample output, which
the shipped classifier could never produce (`[token:gmail]` is not a real
token, and confidence is `max/(max+2)*100`, so 94/89 were unreachable):
the Gmail fixture classifies `cloud/gcp` / 50 / `[token:google]` and
PROD_DB `database` / 81 / `[regex:postgres://, token:db, token:postgres]` —
now pinned by dispatch section [16-honesty] (dispatch 79 -> 80 sections);
the classifier taxonomy was left unchanged (Gmail is a Google property).
Issue #94 then guarded three correct-but-unguarded structural claims:
MULTI_TENANCY.md's "eight fixed aliases" vs bin/sec's tenant regex,
profile.md's CI checkout pin (v4.2.2), and OPERATOR_MANUAL.md's "four core
principles" (section 15; sentinel 18 -> 19 cases).
Issue #95 then guarded SKILL.md's own suite-count prose, whose "the two
`tests/*.sh` suites" had silently understated the live five; the count is now
derived and checked in both places SKILL.md states it (section 14 extended;
sentinel 19 -> 20 cases).
Issue #96 then guarded SKILL.md's remaining structural counts — its step
count (11) and persona count (12, cross-checked against profile.md's
"Twelve, numbered 1 through 12"), the two Step-1 scopes, and the
three-value severity set (section 16; sentinel 20 -> 21 cases).
Issue #97 then bound the last unguarded count claims: profile.md §3's four
suite count-words and the pytest mirror's "29 passed" (ADAPTERS.md:305,
SKILL.md:451), all re-derived from the live suites (section 17; sentinel
21 -> 22 cases). CI then went red: the `Run bash suites` step has no pytest,
so section 17's pytest-mirror check skips and case [22]'s two pytest
corruptions went unwitnessed; the case now mirrors the guard's own
`_pytest_available` precondition (#98).
Issue #99 then closed the last silent-drop arm in the same #74/#76 class:
`sec completion <shell> <extra>` had printed a completion script and exited
0, dropping the extra operand; the arm now rejects a trailing argument with
a tagged `[ERROR]` + exit 2 before emitting anything, and the four shifted
profile.md `bin/sec:` anchors were re-pinned (dispatch 80 -> 81 sections).
Issue #100 then guarded the two argument-less arms: `sec help <x>` and
`sec version <x>` had exited 0, silently dropping the operand; both now
reject it with a tagged `[ERROR]` + exit 2 before printing (dispatch 81 -> 82
sections).
Issues #101-#103 tied the completion surfaces to the dispatcher: `sec --help`
prints a line for every subcommand and non-flag arm, the tenant set is identical
across the dispatcher, usage and all four completions, and each surface offers
every subcommand token (#103 parses each surface's own list and asserts all 15)
(dispatch 83 -> 85 sections).
Issue #110 closed the last silent-drop arm in the migrator: `sec migrate
undo|revert|--undo` short-circuited the argument parse, so `sec migrate undo
EXTRA` dropped the operand and proceeded to the rollback path; the undo
branch now rejects trailing operands with a tagged `[ERROR]` + exit 2 before
any transaction-log access (dispatch 85 -> 86 sections).
Issue #111 then covered the sync controller's untested surface: the GCP
write path (describe / create-on-missing / add-version / timeout / failure),
the `parse_args` usage-error contract, and `main()`'s exit codes (pytest
29 -> 41; mirrors bumped at ADAPTERS.md:305, audit SKILL.md:451; sentinel
control [3] re-pinned).
Open items: #67 (360 audit —
needs human scope approval), #51 (hub-side, tracked upstream), #92 (hub-side:
packs persona-count + AGENTS.md core-trait count unguarded). Full narrative:
`history/2026-10-12.md`.

**2026-10-11**: issue #47 executed the narrative rotation policy declared
in `ADAPTERS.md` (AGENTS.md §5) — the single 103 KB `HISTORY.md` was
split losslessly into per-date archives under `history/`, and
`sentinel.sh coverage` gained a guard so the file cannot silently re-bloat. The day then swept
dispatcher/completion/argv/doc-honesty residuals (#40–#66): completion
alias parity + ps1 honest-scoping (#56/#57), the top-level fish/ps1 flag
surface (#60), the `sec.conf` parser honoring commented-out keys (#55),
`jq`'s real dependency reach (#54), the sync-controller provenance text
(#53), the keeper's keep-alive/setup no longer re-exposing the master
password on argv (#52), and the argv sweep moving the secret off
`jq`/`bw`/`op`/`vault`/`infisical` child argv (#58/#59 — only `bws
secret create` retains argv, a vendor limit). It also covered the GitLab sync
write path with a create-on-404 upsert (#61), pinned the GCP
create-if-absent branch (#62), removed dead pre-commit surface (#63),
corrected the 360-audit skill's stale `SEC_TEST_DISPATCH` claims (#65),
hardened `sentinel.sh citations` (#66), and fixed a baseline-red defect — a local `.venv/` was not
gitignored, so the sentinel control copies swept it into the tracked set
and failed the coverage denominator (#68; `.venv/`/`venv/` are now
ignored). A fresh full 360 audit (#67) stays queued (its Step-1 gate needs
human scope approval). All five bash suites pass; the pytest mirror (29
tests) passes. The tracker holds #51 (hub-side) and #67. Full narrative:
`history/2026-10-11.md` / `history/2026-10-12.md`.

## Archive

- [2026-10-12](history/2026-10-12.md)
- [2026-10-11](history/2026-10-11.md)
- [2026-10-10](history/2026-10-10.md)
- [2026-10-09](history/2026-10-09.md)
- [2026-10-08](history/2026-10-08.md)
- [2026-08-27](history/2026-08-27.md)
- [2026-08-12](history/2026-08-12.md)
