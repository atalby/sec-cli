# History — sec-cli

## Current state

This file is the narrative intent record, kept short on purpose: the full
record is archived per period under `history/` (append-only, nothing deleted,
every file searchable). A new session reads this summary by default.

**2026-10-14**: the unguarded-current-state-claim sweep ran #144-#159 -- one
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
commit cites "issue #160" but no such issue existed: the tracker sat at 159 until
this run's own finding took #160, so that citation is a dead reference.
(2) docs/MULTI_TENANCY.md's `auto_rotate` rule claimed two branches "for each
tenant section"; live bin/sec reads the key once and consults it only in the
`bitwarden|bw)` arm, `op` and `vault` prompt unconditionally, `bws`/`infisical`/
`keychain` have no auth arm, and the prompt is a fallback reached under
`auto_rotate = true` too -- not a false-branch. Per-backend table + section 38,
case [62]. (3) docs/SECURITY.md's master-password row and Disk Storage Leak census
were unguarded, and their claims are currently TRUE -- highest blast radius in the
class, since a silent regression writes a Bitwarden master password to disk in
cleartext. `SEC_ALLOW_PLAINTEXT_MASTER_PASS` gates both paths (store refused
unless `=1`, read only if `=1`), the file is `~/.cache/bitwarden/master_pass` at
mode 0600, and bin/sec-migrator stages the infisical import in a `mktemp` file
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
pipeline, so a short-circuited empty payload was misreported as a `bw edit`
refusal -- the exact misdiagnosis the change removes -- now split.
Dispatch 92 -> 93 sections. The PowerShell sibling's matching fall-through was
filed separately as #163 rather than widening this fix, and it was worse than
filed: the ps1 has no tenant dispatch, it probes PATH in order, so an unusable bws
fell through to bw, really wrote the secret to the Bitwarden Vault, printed raw
untagged PowerShell errors, and exited 0 -- a failed write reported as success.
Its bws arm is now terminal and names the same stage bin/sec does. Fall-through is
safe for reads, unsafe for writes. Guarded by dispatch [23f]: three static parity
assertions plus three pwsh functional ones, 6/6 red first, the red run logging
the bw stub's `get template item` as proof the substitution happened. Dispatch
93 -> 94; bin/sec.ps1 tagged-line census 11 -> 12. The functional half runs in CI
because ubuntu-latest ships pwsh -- from the run log, not assumed -- and here
against a portable pwsh 7.6.7 arm64 extract, this host being aarch64.
Fifth, the bitwarden attachment-read path had a dead guard (#164): `bw_list_items`
signals failure by printing a literal `ERR` on stdout, and three of its four
consumers capture it before testing; line 535 piped it straight into jq, so the
`[[ "$item_id" == "ERR" ]]` test could never fire and `set -e`/`pipefail` leaked
jq's exit status -- a failed lookup printed a raw untagged `parse error` and
exited 4, a code bin/sec never returns, from the same `bw list items` failure that
exits 1 everywhere else. Now capture-then-guard, as its siblings did. Case [4d],
six assertions, red-first 294/3 -> 297/0, one default-off knob.
Dispatch 94 -> 95 sections.
Full narrative: `history/2026-10-15.md`.

**2026-10-12**: the flag-misparse / operand-honesty sweep (#71-#80) rejected
unknown flags and dropped operands with tagged `[ERROR]` + exit 2; completion
parity and runtime fixed (#78-#83); census-drift class closed (#84-#91, sentinel
17 -> 18 cases); README's housekeep sample repaired (#93); structural claims
guarded (#94-#98); last silent-drop arms closed (#99/#100, #110-#112); completion
surfaces tied to the dispatcher (#101-#103); the sync controller's write path and
naming branch covered (pytest 29 -> 43); #64 closed as a duplicate of #51's.
Detail: `history/2026-10-12.md`.

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
#138-#141 anchored `citations` and closed the first-match class in the migrate,
alias, and migrator guards; the sweep also derived every remaining live count and
numeral word in `tests/test_sentinel.sh` (a `_NUM_WORDS` key ignores a digit, so
only a word swap fails).
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

