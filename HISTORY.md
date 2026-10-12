# History — sec-cli

## Current state

This file is the narrative intent record, kept short on purpose: the full
record is archived per period under `history/` (append-only, nothing
deleted, every file searchable). A new session reads this summary by
default, not the whole history.

**2026-10-12**: issue #71 closed the flag-misparse class — `sec get`,
`set`/`create` and `unlock`/`rotate`/`keep` now reject an unknown
`--flag`/`-f*` at the operand position with a tagged `[ERROR]` + exit 2
before any backend call (same contract #73 shipped for `sec.ps1`;
keys/passwords must not begin with `-`). Issue #64 (local pre-commit
enforcement vanishes when `uv` is absent) verified as a duplicate of
#51's hub-side payload — the gate lives in the hub script, unfixable
in-repo per the frozen-fork-risk rejection — and closed as duplicate.
Issue #74 then closed the last gap in the same sweep class: `get`/
`set`/`create` no longer silently drop trailing operands (tagged
`[ERROR]` + exit 2 before any backend call; `run` stays variadic).
Issue #75 closed the last soft spot in the sweep class: `sec get --scope`
rejects a flag-like folder name (`--*`/`-[a-zA-Z]*`, tagged `[ERROR]` +
exit 2 before any backend call; sec.ps1 already did this, bin/sec was the
laggard). Issue #76 then closed the same trailing-operand gap in the arms
the #74/#75 sweep had skipped: `sec housekeep`/`organize` and `sec
unlock`/`rotate`/`keep`/`setup-keychain` no longer silently drop extra
operands (tagged `[ERROR]` + exit 2 before any organizer/keeper/backend
call; `rotate`/`keep` reject any positional, `unlock`/`setup-keychain`
still take one optional password; `run` stays variadic). Tests: dispatch
suite 68 -> 72 sections ([2e], [2f], [2g], [2h]); profile.md + ADAPTERS
counts updated. All five bash suites pass (install 9 / sync_guard 16 /
write_honesty 13 / sentinel 10 / dispatch 72), pytest mirror 29 passed,
sentinel citations + coverage green. Issue #77 then fixed the last
audit-flagged silent abort (scratchpad C25): a valid-session
`bw-session-keeper` `rotate`/`keep` whose vault refresh failed died under
`set -e` with no message — it now exits 1 with a tagged `[ERROR]`;
write_honesty 11 -> 13 sections (the keeper's first behavioral coverage:
rotate sync-failure [11], non-TTY unlock/setup-keychain honesty [12]).
Issue #78 then closed the last completion-surface parity gap: `sec
completion fish` omitted the tenant-prefix words
(bitwarden/bw/1pass/op/bws/vault/infisical/keychain) that zsh/bash/ps1 all
offer; the fish block now lists them and dispatch guard [22q] asserts the
parity across all four surfaces (dispatch 72 -> 73 sections;
profile.md + ADAPTERS counts updated; the ADAPTERS "Last updated" stamp
and stale suite snapshot were truth-up'd in the same pass).
Issue #79 closed the sibling gap in the same class: `sec completion fish`
offered no housekeep subcommands after the `organize` alias (bash/zsh/ps1
did); guard [22r] pins it (dispatch 73 -> 74 sections). Issue #80 was
opened and held for a human decision — the housekeep arm accepts
`undo`/`restore` aliases but the help text and all four completions
advertise only `plan/apply/revert`.
Open items: #67 (360 audit — needs
human scope approval), #51 (hub-side, tracked upstream), #80 (housekeep
undo/restore advertise-vs-accept — held for a human decision). Full narrative:
`history/2026-10-12.md`.

**2026-10-11**: issue #47 executed the narrative rotation policy declared
in `ADAPTERS.md` (AGENTS.md §5) — the single 103 KB `HISTORY.md` was
split losslessly into per-date archives under `history/`, this summary
was reduced to a few sentences, and `sentinel.sh coverage` gained a guard
so the file cannot silently re-bloat. The day then swept
dispatcher/completion/argv/doc-honesty residuals (#40–#66): completion
alias parity and ps1 honest-scoping (#56/#57), the top-level flag surface
on fish/ps1 (#60), the `sec.conf` parser honoring commented-out/partial
keys (#55), the runtime-dependency sentence naming `jq`'s real reach
(#54), the sync-controller provenance text (#53), the session keeper's
keep-alive/setup paths no longer re-exposing the master password on argv
(#52), and the argv sweep that moved the secret value off
`jq`/`bw`/`op`/`vault`/`infisical` child argv (#58/#59 — only `bws
secret create` retains argv, a vendor limit). It also covered the
sync-controller GitLab write path with a create-on-404 upsert (#61),
pinned the GCP create-if-absent branch (#62), removed dead pre-commit
surface (#63), corrected the 360-audit skill's own stale
`SEC_TEST_DISPATCH`/pre-commit claims (#65), hardened `sentinel.sh
citations` to content-validate bare prose anchors (#66), and fixed a
baseline-red reproducibility defect — a local `.venv/` was not
gitignored, so the sentinel control copies swept it into the tracked set
and failed the coverage denominator (#68; `.venv/`/`venv/` are now
ignored). A fresh full 360 audit (#67) is queued for the next interactive
session because the audit skill's Step-1 gate requires an explicit human
scope approval. All five bash suites pass (install 9 / sync_guard 16 /
write_honesty 11 / sentinel 10 / dispatch 70) and the pytest mirror (29
tests) passes. The GitHub tracker holds #51 (hub-side) and the queued
#67. Each issue's full narrative lives in `history/2026-10-11.md` /
`history/2026-10-12.md`. Next: advance the highest-value unfinished
in-repo work.

## Archive

- [2026-10-12](history/2026-10-12.md)
- [2026-10-11](history/2026-10-11.md)
- [2026-10-10](history/2026-10-10.md)
- [2026-10-09](history/2026-10-09.md)
- [2026-10-08](history/2026-10-08.md)
- [2026-08-27](history/2026-08-27.md)
- [2026-08-12](history/2026-08-12.md)
