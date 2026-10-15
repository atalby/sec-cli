# History — sec-cli

## Current state

This file is the narrative intent record, kept short on purpose: the full
record is archived per period under `history/` (append-only, nothing deleted,
every file searchable). A new session reads this summary by default.

**2026-10-14**: the unguarded-current-state-claim sweep ran #144-#159 - one
project-owned doc claim per issue, each closed by a sentinel section deriving the
live value from code: the HIAE banner, SECURITY.md path->mode pairs, config-mode
docs, the suite extractor, RESUME.md's count mirrors, mode prose, runtime deps,
`sec run` injection backends, classifier categories, completion, bin/sec.ps1,
SECURITY.md's executable census, `sec sync` exit codes, SECURITY.md's argv
mitigations, and the snapshot-contents field set (that last one had gone stale).
Sentinel 49 -> 60 cases / 532 -> 736 assertions.
Narrative: `history/2026-10-14.md`.

**2026-10-15**: three passes of the unguarded-current-state-claim sweep, each closed
by a sentinel section deriving the live value from code. (1) docs/ARCHITECTURE.md's
`install.sh` bullet had no guard (the `bin/*` wording was imprecise, `bin/hyer-mcp.sh`
is never installed) -- section 37, case [61]. (2) docs/MULTI_TENANCY.md's `auto_rotate`
rule claimed two branches "for each tenant section"; live bin/sec reads the key once,
in the `bitwarden|bw)` arm only -- `op`/`vault` prompt unconditionally, `bws`/`infisical`/
`keychain` have no auth arm, and the prompt is a fallback reached under `auto_rotate = true`
too. Per-backend table + section 38, case [62]. (3) docs/SECURITY.md's master-password
row and Disk Storage Leak census were unguarded and currently TRUE -- highest blast
radius in the class: a silent regression writes a Bitwarden master password to disk in
cleartext. `SEC_ALLOW_PLAINTEXT_MASTER_PASS` gates both paths, the file is
`~/.cache/bitwarden/master_pass` at mode 0600, and bin/sec-migrator stages the infisical
import in a `mktemp` file chmod'd to that mode and `rm -f`'d in both branches. Section 39,
case [63]. Sentinel 60 -> 63 cases / 736 -> 792 assertions. Tracker: #51, #67, #92.
Then a read-path honesty sweep. test_dispatch.sh case `[11] op set` failed once in four
runs and would not reproduce; filed as #162, chasing it found a real defect: all seven
`sec set` fall-through points discarded stderr and collapsed into one `[ERROR] failed to
store secret ... in tenant '<t>'`, naming the tenant but never the step -- it now names
the stage (stderr stays discarded: `bws secret create` carries the value in argv). Case
[11d], 274/5 red -> 279/0. Dispatch 92 -> 93. #163 filed for the PowerShell sibling, which
was worse: with no tenant dispatch the ps1 probes PATH, so an unusable bws fell through to
bw, really wrote to the Vault, and exited 0. Its bws arm is now terminal. Dispatch [23f],
dispatch 93 -> 94; ps1 tagged-line census 11 -> 12. Fifth, #164: the bitwarden
attachment-read path piped `bw_list_items`'s literal `ERR` sentinel into jq, so its guard
could never fire -- now capture-then-guard; [4d], dispatch 94 -> 95. Sixth, #165 closed
three `sec-organizer` write-path holes (dead-guard reader, unvalidated `folders_json`
mask, unguarded apply/revert pipelines); [14e-h], dispatch 95 -> 99. Seventh, #166-#169
closed the class's remaining reads: four silent-death backend reads in bin/sec + keeper
([14i-m]); the sec-migrator `bws project list` twin + three create-response jqs
(write-honesty [15]); the README migrate bullet that read destination-only backends as
sources (sentinel 19b); and the `bw list folders` mask whose `|| echo "[]"` made the
guard unreachable ([14n]/[14o], dispatch 105 -> 107). Eighth, #170 closed the last twin:
sec-migrator's `fetch_source_items` masked a failing source listing as `[]`, and jq on
`[]` exits 0 with `0`, so a broken source printed `[INFO] Zero items found` + exit 0; an
explicit empty-payload guard now rejects the read before the count. Write-honesty [16],
16 -> 17; migrator tagged census 29 -> 30. Ninth, #171 corrected README's Smart Session
bullet (false "any locked tenant") and made section 38 guard it, [62]. Tenth, #172 made
section 14 also fail if the CI workflow's suite run-list stops running every live suite,
[18]. Eleventh, #173 made section 40 guard docs/ARCHITECTURE.md's bin/hyer-mcp.sh component
bullet (HYER_HOME default, secret, GITLAB_TOKEN, no `sh -c`, gitignored `.mcp.json` /
tracked `.mcp.json.example`) against the live launcher, [64]; sentinel 63 -> 64 cases.
Twelfth, #174 made section 18b also read docs/ARCHITECTURE.md's Overview sentence (the
same universe + sync-target claim as README's) so both front sentences must name the live
migrator universe and every controller target, [31]; assertions 820 -> 828.
Thirteenth, #175 made section 29 also read docs/OPERATOR_MANUAL.md, which restates the
`sec run` injection backends twice (its RAM-only list and its "only when the tenant is"
sentence) plus a `plain exec` claim, while the guard read only README + ARCHITECTURE --
[51], assertions 828 -> 836. Fourteenth, #176 made section 29 also read
docs/SECURITY.md's Disk Storage Leak row (the fourth doc restating the same
backend set), [51], assertions 836 -> 840. Fifteenth, #177 extended the
ps1-surface guard to README.md's Multi-OS matrix PowerShell cell, which restated
the bin/sec.ps1 native subset that only ARCHITECTURE.md was checked against,
[54], assertions 840 -> 844.
Full narrative: `history/2026-10-15.md`.

**2026-10-12**: the flag-misparse / operand-honesty sweep (#71-#80) rejected
unknown flags and dropped operands with tagged `[ERROR]` + exit 2; completion
parity and runtime fixed (#78-#83); census-drift class closed (#84-#91, sentinel
17 -> 18 cases); README's housekeep sample repaired (#93); structural claims
guarded (#94-#98); last silent-drop arms closed (#99/#100, #110-#112); completion
surfaces tied to the dispatcher (#101-#103); the sync controller's write path and
naming branch covered (pytest 29 -> 43); #64 closed as a duplicate of #51's.
Detail: `history/2026-10-12.md`.

**2026-10-13**: guard-hardening plus three product bugs. #119-#136 guarded stale claims (anchors, backend universe, size claim, dead config keys, tenant help, pack/persona census, code-prose counts, transcript, first-match guards, forge spec -- 42 cases / 434 assertions). #137: bare `SCOPE_ARGS` under `set -u` killed `sec get` on bash < 4.4 -- four sites + scanner [32]. #126/#142/#143 closed silent drops (`sec.conf` no-`=` line now `[WARN]`; migrator/organizer `jq` masks now `[ERROR]` + exit 1, dispatch 88 -> 92). #120: pytest mirror names every `FAIL:` line (53 -> 58 tests). #138-#141 anchored `citations`, closed first-match in migrate/alias/migrator, derived all live counts/words in `test_sentinel.sh`.
Narrative: `history/2026-10-13.md`.

**2026-10-11**: issue #47 executed the narrative rotation policy declared in
`ADAPTERS.md` (AGENTS.md §5) — the single 103 KB `HISTORY.md` was split
losslessly into per-date archives under `history/`, and `sentinel.sh coverage`
gained a guard so the file cannot silently re-bloat. The day then swept
dispatcher/completion/argv/doc-honesty residuals (#40–#66), notably moving secrets
off child argv (#58/#59) and a baseline-red ungitignored local `.venv/` (#68).
All five bash suites and the pytest mirror (58 tests) pass. Narrative:
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

