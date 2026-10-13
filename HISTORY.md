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
`rotate`/`keep` reject positionals, `unlock`/`setup-keychain` take one
optional password), `sec get --scope` rejects a flag-like folder
name, `sec housekeep`/`organize` no longer drops extra operands, and a
`bw-session-keeper` `rotate`/`keep` whose vault refresh failed died under
`set -e` — now exit 1 + tagged `[ERROR]`. Issue #64 (pre-commit
vanishing when `uv` is absent) verified as a duplicate of #51's payload
and closed. Issue
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
`completions/_sec` regenerated). Issues #84-#91 closed
the census-drift class: profile.md's ecosystem + per-file censuses (#84),
ADAPTERS.md's `current suites:` snapshot (#85), the audit profile's stale
pack taxonomy (#86), ADAPTERS.md's per-suite `(N sections|cases)` counts
(#87), ARCHITECTURE.md's producer census (#88), the skills/registry census
(#89), and two *drifted* prose counts — "five sibling dispatchers" (live
7) and "four helper scripts" (live 7) (#90); section 13 asserts every
tracked `bin/` helper is referenced by `tests/test_dispatch.sh`. #91 guarded
the three bash-suite-count claims, re-derived from `tests/*.sh`
(section 14; sentinel 17 -> 18 cases).
Issue #93 repaired README.md's `sec housekeep` sample output, which the
shipped classifier could never produce — now pinned by dispatch section
[16-honesty], taxonomy unchanged. Issues #94-#98 guarded the remaining
structural claims: MULTI_TENANCY.md's alias count vs bin/sec's tenant regex,
profile.md's CI checkout pin, OPERATOR_MANUAL.md's principle count, SKILL.md's
suite/step/persona/scope/severity counts, and profile.md §3's four suite
count-words plus the pytest-mirror count (section 17; CI's `Run bash suites`
step has no pytest, so case [22] had to mirror the guard's `_pytest_available`
precondition). Issues #99/#100 closed the last silent-drop arms —
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
EXTRA` dropped the operand and proceeded to the rollback path; the undo
branch now rejects trailing operands with a tagged `[ERROR]` + exit 2 before
any transaction-log access (dispatch 85 -> 86 sections).
Issue #111 covered the sync controller's untested surface: the GCP
write path (describe / create-on-missing / add-version / timeout / failure),
the `parse_args` usage-error contract, and `main()`'s exit codes (pytest
29 -> 41; mirrors bumped at ADAPTERS.md:305, audit SKILL.md:451; control
[3] re-pinned).
Issue #112 covered `infer_suggested_name`'s env/project tag branch (generic
name + notes with `env: tag` -> `name (tag)`, needs_rename) — the username
path was tested, the regex path was not (pytest 41 -> 43; mirrors bumped;
control [3] re-pinned).
Open items: #67 (360 audit —
needs human scope approval), #51 (hub-side, tracked upstream), #92 (hub-side:
packs persona-count + AGENTS.md core-trait count unguarded). Full narrative:
`history/2026-10-12.md`.

**2026-10-13**: the guard-hardening lane kept closing (audit
regressions plus their guards). #119 re-pinned stale
bare `line N` references in the audit profile and #121 made `citations` fail on
one; #122 guarded README.md's front-page backend universe. #123 closed F041:
the per-tenant `cli = <backend>` key was written into every fresh `sec.conf`
and documented in three surfaces while no code read it, so the five lines came
out of the heredoc and both samples, and `coverage` gained a sub-check that
fails when a sample key is not a `get_cfg_val` read in `bin/sec` (anchored on
the call shape, so a quoted-but-unread key still fails); the control literals
it broke are now regex-shaped. #124 guarded RESUME.md's own HISTORY.md size
claim, scoped to its Verified-baseline section so narrative mentions stay
legal; #125 closed F041's second half (the `[global] auto_rotate` key, written
and read by no code) and widened #123's check from two config surfaces to all
four. #127 guarded bin/sec's hardcoded `Configured Tenants:` help line against
the live dispatcher alias regex; #129 guarded ADAPTERS.md's Opted-in Policy
Packs census (all five pack versions + the 9-persona taxonomy total) against
the live PACK.md files (sentinel 35 -> 36 cases). #130-#132 then guarded
profile.md's own code-prose counts (SYNC_KEYS' six env keys, the sync
controller's 4 timeout sites, install.sh/bin/sec's zero-timeout claim) against
the live files (sentinel 36 -> 37 cases / 362 -> 378 assertions). Tracker
holds #51, #67, #92, #120, #126. Full narrative: `history/2026-10-13.md`.

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
hardened `sentinel.sh citations` (#66), and fixed a baseline-red defect — a
local `.venv/` was not gitignored, so sentinel control copies swept it into
the tracked set and failed the coverage denominator (#68; `.venv/`/`venv/`
now ignored). All five bash suites pass; the pytest mirror (53
tests) passes. Full narrative:
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

