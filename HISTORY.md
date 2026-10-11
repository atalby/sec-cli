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
so the file cannot silently re-bloat. Immediately before, #46 closed the
last audit-instrument gap (the coverage denominator is now validated
against `git ls-files`), #45 fixed the F048 residual (`sec-organizer`
classifies `op`/`bws` from full item detail; `apply` re-checks
staleness), and #40–#44 closed the dispatcher/completion/ps1 honesty
residuals. All five bash suites pass (install 9 / sync_guard 14 /
write_honesty 11 / sentinel 8 / dispatch 47), the pytest mirror passes,
and the GitHub tracker holds only hub-side items (#2, #13 — both handed
upstream). Next: advance the highest-value unfinished work.

## Archive

- [2026-10-11](history/2026-10-11.md)
- [2026-10-10](history/2026-10-10.md)
- [2026-10-09](history/2026-10-09.md)
- [2026-10-08](history/2026-10-08.md)
- [2026-08-27](history/2026-08-27.md)
- [2026-08-12](history/2026-08-12.md)
