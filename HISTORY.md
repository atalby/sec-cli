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

**2026-10-15**: three more passes of the unguarded-current-state-claim sweep, each
closed by a sentinel section deriving the live value from code. (1) docs/ARCHITECTURE.md's
`install.sh` bullet had no guard (the `bin/*` wording was imprecise, `bin/hyer-mcp.sh`
is never installed) -- section 37, case [61], five probes + control red first. Its
commit cites a then-nonexistent issue #160 -- a dead reference.
(2) docs/MULTI_TENANCY.md's `auto_rotate` rule claimed two branches "for each
tenant section"; live bin/sec reads the key once and consults it only in the
`bitwarden|bw)` arm, `op` and `vault` prompt unconditionally, `bws`/`infisical`/
`keychain` have no auth arm, and the prompt is a fallback reached under
`auto_rotate = true` too -- not a false-branch. Per-backend table + section 38,
case [62]. (3) docs/SECURITY.md's master-password row and Disk Storage Leak census
were unguarded, and their claims are currently TRUE -- highest blast radius in the
class, since a silent regression writes a Bitwarden master password to disk in
cleartext. `SEC_ALLOW_PLAINTEXT_MASTER_PASS` gates both paths (store refused
unless `=1`, read only if `=1`), the file is `~/.cache/bitwarden/master_pass`
at mode 0600, and bin/sec-migrator stages the infisical import in a `mktemp` file
chmod'd to the documented mode and `rm -f`'d in BOTH branches (the doc understated
one). Section 39, case [63]. Sentinel 60 -> 63 cases / 736 -> 792 assertions.
Tracker holds #51, #67, #92.
separately, test_dispatch.sh case `[11] op set` failed once in four full runs and
would not reproduce. Filed as #162 with the evidence table rather than
attributed to load; chasing it found a real defect, not a flake: all seven
`sec set` fall-through points in bin/sec discarded stderr and collapsed into one
`[ERROR] failed to store secret ... in tenant '<t>'`, naming the tenant but never
the step. It now names the stage. Stderr stays discarded on purpose -- `bws secret
create` carries the value in argv, so a child's stderr could echo it. Case [11d],
red-first 274/5 then green 279/0, three default-off stub knobs. Diff review then
caught a flaw in the fix itself: the update path ANDed the payload check with the
pipeline, so an empty payload was misreported as a `bw edit`
refusal -- the exact misdiagnosis the change removes -- now split.
Dispatch 92 -> 93 sections. The PowerShell sibling's matching fall-through was
filed separately as #163 rather than widening this fix, and it was worse than
filed: with no tenant dispatch the ps1 probes PATH in order, so an unusable bws
fell through to bw, really wrote the secret to the Bitwarden Vault, printed raw
untagged PowerShell errors, and exited 0 -- a failed write reported as success.
Its bws arm is now terminal and names the same stage bin/sec does. Fall-through is
safe for reads, unsafe for writes. Guarded by dispatch [23f]: three static parity
assertions plus three pwsh functional ones, 6/6 red first, the red run logging
the bw stub's `get template item` as proof the substitution happened. Dispatch
93 -> 94; bin/sec.ps1 tagged-line census 11 -> 12. The functional half runs in CI
(ubuntu-latest ships pwsh, from the run log) and here against a portable arm64
pwsh extract.
Fifth, the bitwarden attachment-read path had a dead guard (#164): line 535 piped
`bw_list_items`'s literal `ERR` sentinel straight into jq, so its ERR test could
never fire and a failed lookup leaked a raw `parse error` + exit 4 -- now
capture-then-guard, as its three siblings did. Case [4d], dispatch 94 -> 95.
Sixth, that hole lived in three `sec-organizer` write paths (#165): a dead-guard
`bw get item` read (silent half-revert), the unvalidated `folders_json` mask
(garbage-RC0 -> raw jq exit 4), and unguarded apply/revert pipelines (raw
`TOKEN-abc123` as exit 66, `bw encode` as 141). Cases [14e-h], dispatch 95 -> 99.
Seventh, #166-#169 closed the class's remaining reads: four silent-death backend
reads in bin/sec + keeper (#166, [14i-m]); the sec-migrator `bws project list`
twin + three create-response jqs (#167, write-honesty [15]); the README migrate
bullet that read destination-only backends as sources (#168, sentinel 19b); and
#169's sec-organizer `bw list folders` mask, whose `|| echo "[]"` made the
`require_json_array` guard unreachable -- a false plan and a false apply success
([14n]/[14o], dispatch 105 -> 107). Eighth, #170 closed the last twin:
sec-migrator's `fetch_source_items` masked a failing bw/op/bws source listing as
`[]`, and its jq count guard missed it (jq on `[]` exits 0 with `0`), so a broken
source printed `[INFO] Zero items found` + exit 0; `|| true` alone was
insufficient (jq on an empty payload also exits 0 with no output), so an explicit
empty/whitespace guard now rejects the read before the count. Write-honesty [16],
16 -> 17; migrator tagged census 29 -> 30. Ninth, #171 corrected README's Smart
Session bullet (false "any locked tenant") and made section 38 guard it, [62].
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

