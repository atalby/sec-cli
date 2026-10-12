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
did); guard [22r] pins it (dispatch 73 -> 74 sections). Issue #80 then
resolved the last member of that class consistently: the housekeep arm
accepts `undo`/`restore` as aliases of `revert` (sec-organizer has mapped
them since v1.0.0), but all four completions advertised only
`plan/apply/revert`; the aliases are now offered in the housekeep completion
on every surface — matching how the create/organize/keep aliases are
advertised — with guard [22s] pinning the parity and the checked-in
`completions/_sec` golden regenerated (dispatch 74 -> 75 sections). The
`sec housekeep --help` / error text stays canonical (plan/apply/revert),
consistent with the top-level help, which also lists no aliases.
Issue #81 then repaired the ps1 completion's runtime: it read
`$commandAst.ArgumentElements`, a property that does not exist on
`System.Management.Automation.Language.CommandAst` (only `CommandElements`
does, "never null"), so `$elements` was null, the `Count -le 1` branch
always won, and the ps1 subcommand completions were dead code at runtime.
It now reads `CommandElements`; guard [22t] pins that plus the
`powershell` shell word on all four surfaces (bin/sec always accepted
`sec completion powershell` but never completed it), and guard [22u]
pins the migrate backend values (bitwarden 1password bws vault infisical)
on bash/fish/ps1 to match zsh (dispatch 75 -> 77 sections; the
`completions/_sec` golden was regenerated for the zsh shells list).
Issue #82 then completed the bare `help`/`version` subcommands the
dispatcher accepts (`bin/sec` `-h|--help|help)`, `-v|--version|version)`)
on all four surfaces; guard [22v] pins the parity (dispatch 77 -> 78
sections; the `completions/_sec` golden was regenerated for the added
zsh subcommands). The top-level `usage()` stays canonical.
Issue #83 then completed the `get --scope` and `set/create --type` flags
the dispatcher accepts (bin/sec get arm and set|create `--type`
login/note/card/identity) on all four surfaces; guard [22w] pins the
parity (dispatch 78 -> 79 sections; the `completions/_sec` golden was
regenerated for the added zsh `_arguments` arms). Issue #84 then fixed and
guarded the recurring census drift: profile.md's ecosystem counts
(Markdown 64 -> 71, Python 2 -> 6) and its `[ TAG ]`-emission per-file
census (sec-organizer 36 -> 37, sec-sync-controller.py 29 -> 30,
sec-migrator 23 -> 24, bw-session-keeper 16 -> 17, sec.ps1 6 -> 11) were
re-measured, and `sentinel.sh coverage` gained a section-8 guard
(`test_sentinel.sh` case [11] proves it RED/GREEN) so both blocks fail
closed against the live tree — the same drift mode #46/#48/#49 addressed,
now closed for the census counts too.
Issue #85 then guarded ADAPTERS.md's `current suites:` snapshot (fixed
twice: #79/#84) via `sentinel.sh` section 9 and `test_sentinel.sh` [12].
Issue #86 then fixed the audit profile's stale pack taxonomy (cited
solo-founder-governance v1.2.0/'eight roles' after #1 re-synced it to
v1.4.0/9 personas) and guarded it (sentinel section 10 + test [13]).
Open items: #67 (360 audit — needs
human scope approval), #51 (hub-side, tracked upstream). Full narrative:
`history/2026-10-12.md`.

**2026-10-11**: issue #47 executed the narrative rotation policy declared
in `ADAPTERS.md` (AGENTS.md §5) — the single 103 KB `HISTORY.md` was
split losslessly into per-date archives under `history/`, this summary
was reduced to a few sentences, and `sentinel.sh coverage` gained a guard
so the file cannot silently re-bloat. The day then swept
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
ignored). A fresh full 360 audit (#67) is queued for the next interactive
session because the audit skill's Step-1 gate requires an explicit human
scope approval. All five bash suites pass; the pytest mirror (29
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
