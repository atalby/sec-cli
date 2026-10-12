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
#78 closed the last completion-surface parity gap: `sec completion fish`
omitted the tenant-prefix words (bitwarden/bw/1pass/op/bws/vault/
infisical/keychain) the other three surfaces offer; #79 closed the sibling
gap (no housekeep subcommands after the `organize` alias); #80 resolved
the class by accepting `undo`/`restore` as aliases of `revert` (which
sec-organizer has mapped since v1.0.0), but all four completions
advertised only
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
regenerated for the added zsh `_arguments` arms). Issues #84-#90 closed
the census-drift class wholesale, one guard per claim: profile.md's
ecosystem and `[ TAG ]` per-file censuses (#84), ADAPTERS.md's
`current suites:` snapshot (#85), the audit profile's stale pack taxonomy,
corrected (#86), ADAPTERS.md's per-suite `(N sections|cases)` counts (#87),
docs/ARCHITECTURE.md's producer census, 'six' -> seven with `sec.ps1`
omitted (#88), ADAPTERS.md's skills/registry census — 23 skill dirs / 35
registry rows / 12 hub-internal, already correct but unguarded (#89) — and
the class's last two *drifted* prose counts: profile.md's "five sibling
dispatchers" (live 7, contradicting its own line 669) and ADAPTERS.md's
"four helper scripts" (live 7, one static-only), both wrong at birth;
section 13 now also asserts every tracked `bin/` helper is referenced by
`tests/test_dispatch.sh`. Issue #91 then guarded the three bash-suite-count
prose claims — all correct but unguarded — re-deriving the count from
tracked `tests/*.sh` and checking profile.md's tests/ census, its CI row,
and ARCHITECTURE.md's count plus its cited suite-name list (section 14;
sentinel 17 -> 18 cases).
Issue #93 then repaired README.md's `sec housekeep` sample output, which
the shipped classifier could never produce (`[token:gmail]` is not a real
token, and confidence is `max/(max+2)*100`, so 94/89 were unreachable):
the Gmail fixture classifies `cloud/gcp` / 50 / `[token:google]` and
PROD_DB `database` / 81 / `[regex:postgres://, token:db, token:postgres]` —
now pinned by dispatch section [16-honesty] (dispatch 79 -> 80 sections);
the classifier taxonomy was left unchanged (Gmail is a Google property).
Issue #94 then guarded the last three correct-but-unguarded structural
prose claims: docs/MULTI_TENANCY.md's "eight fixed aliases" list vs
bin/sec's tenant regex, profile.md's CI row ("full commit SHA of v4.2.2")
vs the pinned `actions/checkout`, and OPERATOR_MANUAL.md's "four core
principles" count vs its numbered list (section 15; sentinel 18 -> 19
cases).
Open items: #67 (360 audit —
needs human scope approval), #51 (hub-side, tracked upstream), #92 (hub-side:
packs persona-count + AGENTS.md core-trait count unguarded). Full narrative:
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
