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

**2026-10-15**: three unguarded-current-state-claim passes, each closed by a
sentinel section deriving the live value from code: docs/ARCHITECTURE.md's
`install.sh` bullet ([61]); docs/MULTI_TENANCY.md's `auto_rotate` rule, live only
in bin/sec's `bitwarden|bw)` arm ([62]); docs/SECURITY.md's master-password row +
Disk Storage Leak census, gated by `SEC_ALLOW_PLAINTEXT_MASTER_PASS` ([63], highest
blast radius in the class). Sentinel 60 -> 63 cases / 736 -> 792 assertions. Then a
read-path honesty sweep (#162-#170) closing silent deaths: seven `sec set`
fall-throughs; a PowerShell `bws` arm falling through to Vault with exit 0; a
literal `ERR` into jq; three `sec-organizer` write holes; the sec-migrator
`bws project list` twin; `fetch_source_items` masking a failing source as `[]`.
Dispatch 92 -> 107 cases, write-honesty 16 -> 17, migrator census 29 -> 30. Then
five guard-widening units (#171-#178), each also reading a doc restating a guarded
claim ([62]/[18]/[64]/[31]/[51]/[54]). Assertions 736 -> 852. Full narrative:
`history/2026-10-15.md`.

**2026-10-16**: #181 closed the citation class and the Archive-index hole it
exposed. CLAUDE.md's claim that Claude Code "does not yet auto-discover
`AGENTS.md`" was false (Claude Code reads `AGENTS.md` natively; the built-in
`agents-md` mod even skips it when a `CLAUDE.md` exists), and its pointer to
`docs/wiki` named a path this repo has never had -- two empty `git log --all`
probes, zero sentinel coverage, in a file every Claude Code session loads.
Section 41 + case [65] now require every slash-qualified backticked citation in
README.md, CLAUDE.md, `docs/*.md`, and the 360-audit SKILL.md to resolve on disk,
skipping only tokens the payload itself cites (hub-relative), and declare what
they do not cover: ADAPTERS.md and profile.md, whose slash-qualified citations
are mostly hub-side or deliberately narrative. The same issue found section 6
accepting any `history/<file>.md` substring as a link, which is why
`history/2026-10-15.md` shipped with no `## Archive` row; it now requires the
`- [date](history/file.md)` form. Sentinel 64 -> 65 cases.
Full narrative: `history/2026-10-16.md`.

**2026-10-17**: #182 dropped the phantom backends (Vercel, AWS Secrets Manager,
`pass`) from ADAPTERS.md/profile.md/SKILL.md (section 42). #183 truth-upped the
repo-root `SKILL.md` (a v1.0.0 artifact no sentinel section read) and extended
section 29 to read it. #184 closed the harness-bridge class: the six command bridges
(`.opencode`/`.claude`/`.gemini`, audit + refresh each) are product surface, yet no
sentinel section read any bridge file, so a dropped no-paraphrase sentence, a
retargeted `.agents` symlink, or a stale-section refresh bridge all passed. Section
43 discovers the bridges from `git ls-files`, asserts the pointer contract, and
closed two live drifts (a missing `agent: build`; two bridges not naming the `skill`
tool). Sentinel 67 cases / 902 assertions. Narrative: `history/2026-10-17.md`.

**2026-10-18**: reverted the 62nd run's unsanctioned, uncommitted RESUME.md
compaction (it had dropped the Verified-baseline section, turning `sentinel.sh
coverage` red), then closed the two items that exposed: #186 raised the pytest
mirror's per-suite timeout default 300s -> 900s in `scripts/tests/test_install.py`
(a loaded `test_sentinel.sh` run takes ~263s), and #185 rotated RESUME.md's
narrative - the 63rd/61st/60th/59th-run session entries and the prior "Shipped this
session" list - verbatim into `history/2026-10-18.md`, trimming RESUME.md to
current state with no line lost (script-asserted). Narrative:
`history/2026-10-18.md`.

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

- [2026-10-18](history/2026-10-18.md)
- [2026-10-17](history/2026-10-17.md)
- [2026-10-16](history/2026-10-16.md)
- [2026-10-15](history/2026-10-15.md)
- [2026-10-14](history/2026-10-14.md)
- [2026-10-13](history/2026-10-13.md)
- [2026-10-12](history/2026-10-12.md)
- [2026-10-11](history/2026-10-11.md)
- [2026-10-10](history/2026-10-10.md)
- [2026-10-09](history/2026-10-09.md)
- [2026-10-08](history/2026-10-08.md)
- [2026-08-27](history/2026-08-27.md)
- [2026-08-12](history/2026-08-12.md)

