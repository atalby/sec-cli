# History — sec-cli

## Current state

This file is the narrative intent record, kept short on purpose: the full
record is archived per period under `history/` (append-only, nothing
deleted, every file searchable). A new session reads this summary by
default, not the whole history.

**2026-10-14**: the unguarded-current-state-claim sweep ran #144-#159 -- one
project-owned doc claim per issue, each closed by a sentinel section that derives
the live value from code and requires the doc to match: HIAE banner, SECURITY.md
path->mode pairs, the two config-mode docs, the suite extractor, RESUME.md's count
mirrors, mode prose, runtime deps, `sec run` injection backends, classifier
categories, completion, bin/sec.ps1, SECURITY.md's executable census, `sec sync`
exit codes (+SKILL.md), SECURITY.md's argv mitigations, and the snapshot-contents
field set (that last one had gone stale). Sentinel 49 -> 60 cases / 532 -> 736
assertions. Tracker holds #51, #67, #92.
Full narrative: `history/2026-10-14.md`.

**2026-10-15**: three more passes of the same sweep. First, docs/ARCHITECTURE.md's
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
probes + control proven red first). Third, docs/SECURITY.md's master-password row
and the Disk Storage Leak census were unguarded, and their claims are currently
TRUE -- the highest blast radius in the class, since a silent regression would
write a Bitwarden master password to disk in cleartext. Live shape:
`SEC_ALLOW_PLAINTEXT_MASTER_PASS` gates both paths (store refused unless `=1`,
read only if `=1`), the file is `~/.cache/bitwarden/master_pass` at mode 0600,
and bin/sec-migrator stages the infisical import in a `mktemp` file chmod'd to
the documented mode and `rm -f`'d in BOTH branches (the doc understated one).
Sentinel section 39 derives all of it (case [63], three probes + control proven
red first). Sentinel 60 -> 63 cases / 736 -> 792 assertions.
Tracker holds #51, #67, #92.
Separately: test_dispatch.sh case `[11] op set` failed once in four full runs and
would not reproduce. Filed as #162 with the four-run evidence table rather than
attributed to load -- chasing it found a real defect instead of a flake: all seven
`sec set` fall-through points in bin/sec discarded stderr and collapsed into one
`[ERROR] failed to store secret ... in tenant '<t>'`, naming the tenant but never
the step. It now names the stage. Stderr stays discarded on purpose -- `bws secret
create` carries the value in argv, so a child's stderr could echo it; stage names
only, never child output. Test case [11d], red-first 274/5 then green 279/0, plus
three default-off stub knobs. Diff review then caught a flaw in the fix itself:
the update path ANDed the payload check with the pipeline, so a short-circuited
empty payload was misreported as a `bw edit` refusal -- the exact misdiagnosis the
change removes -- now split. Dispatch 92 -> 93 sections. Checking the PowerShell
sibling for parity found a separate silent fall-through (no `else` on the
`$projId` guard, so bws-with-no-projects blames the wrong backend) -- filed as
#163 rather than widening this fix.
Full narrative: `history/2026-10-15.md`.

**2026-10-12**: the flag-misparse / operand-honesty sweep (#71-#80) rejected
unknown flags and dropped operands with tagged `[ERROR]` + exit 2; completion
parity and runtime fixed (#78-#83); the census-drift class closed (#84-#91,
sentinel 17 -> 18 cases); README's housekeep sample repaired (#93); structural
claims guarded (#94-#98); the last silent-drop arms closed (#99/#100,
#110-#112); completion surfaces tied to the dispatcher (#101-#103); the sync
controller's write path and the naming branch covered (pytest 29 -> 43);
#64 closed as a duplicate of #51's payload. Detail: `history/2026-10-12.md`.

**2026-10-13**: the guard-hardening lane closed more guard classes plus three real
product bugs. #119-#136 swept and guarded stale current-state claims (audit profile
line anchors, README's backend universe, RESUME's own size claim, two F041 dead
config keys, bin/sec's tenant help line, ADAPTERS.md's pack/persona census,
profile.md's code-prose counts and tracked-file transcript, sentinel section 7's
shadowable first-match, the 360-audit-skill-forge spec -- 42 cases / 434
assertions). The first product bug was #137: `bin/sec` ran `set -u` and expanded
the possibly-empty `SCOPE_ARGS` bare, a fatal `unbound variable` on bash < 4.4, so
`sec get` died on stock macOS while Linux CI stayed green -- four sites fixed plus
a source scanner (case [32]). The others were silent drops in credential-adjacent
parsers: #126 (`get_cfg_val` ignored a `sec.conf` line with no `=`, now a tagged
`[WARN]` naming the line), #142 and #143 (`sec-migrator` masked `jq` parse
failures as "Zero items found" + exit 0; `sec-organizer` normalized a failed
listing to `[]` and printed a false "0 secrets" plan -- both now tagged `[ERROR]`
+ exit 1, dispatch 88 -> 92). #120 closed the observability gap behind its own
un-diagnosable flake: the pytest mirror reported a failing suite as only its last
2000 chars; it now names every `  FAIL:` line with its section (53 -> 58 tests).
#138-#141 anchored `citations` over RESUME.md/HISTORY.md and closed the
first-match class in the migrate, alias, and migrator guards. The sweep also
derived every remaining live count and numeral word in `tests/test_sentinel.sh`
(a `_NUM_WORDS`-keyed check ignores a digit, so only a word swap fails). Tracker
holds #51, #67, #92.
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

