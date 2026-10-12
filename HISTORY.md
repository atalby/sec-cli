# History — sec-cli

## Current state

This file is the narrative intent record, kept short on purpose: the full
record is archived per period under `history/` (append-only, nothing
deleted, every file searchable). A new session reads this summary by
default, not the whole history.

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
write_honesty 11 / sentinel 10 / dispatch 66) and the pytest mirror (29
tests) passes. The GitHub tracker holds #51 (hub-side) and #64 (local
enforcement requires `uv`), plus the queued #67. Each issue's full
narrative lives in `history/2026-10-11.md`. Next: advance the
highest-value unfinished in-repo work.

## Archive

- [2026-10-11](history/2026-10-11.md)
- [2026-10-10](history/2026-10-10.md)
- [2026-10-09](history/2026-10-09.md)
- [2026-10-08](history/2026-10-08.md)
- [2026-08-27](history/2026-08-27.md)
- [2026-08-12](history/2026-08-12.md)
