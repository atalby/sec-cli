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
so the file cannot silently re-bloat. Two honesty residuals followed:
#48 brought `sec migrate`'s usage/help handling onto the same tagged
exit-code contract as the `bin/sec` dispatcher (a missing `--from`/`--to`
operand, an unknown flag, or a missing pair is now a tagged `[ERROR]`
that exits 2 instead of leaking a raw `set -u` unbound-variable error,
while `--help`/`-h` print usage and exit 0), and #49 re-measured the
persona-4 `[ TAG ]` census in `profile.md` that had drifted since
2026-10-10. Immediately before, #46 closed the last audit-instrument gap
(the coverage denominator is now validated against `git ls-files`), #45
fixed the F048 residual (`sec-organizer` classifies `op`/`bws` from full
item detail; `apply` re-checks staleness), and #40–#44 closed the
dispatcher/completion/ps1 honesty residuals. Then #52 closed a confirmed
F003 residual the #16 fix had left behind: the session keeper's keep-alive
`rotate` and `setup-keychain` paths re-exec'd the helper as
`"$0" unlock <pw>`, so a plain `sec get` on an expired session with the
default `auto_rotate=true` leaked the master password into the process
table (`/proc/<pid>/cmdline`); both paths now unlock in-process via a
`do_unlock` helper, with regression guards [22j]/[22k]. All five bash
suites pass (install 9 / sync_guard 14 / write_honesty 11 / sentinel 9 /
dispatch 57), the pytest mirror passes, and the GitHub tracker holds only
the hub-side handoff #51. Next: advance the highest-value unfinished work.

## Archive

- [2026-10-11](history/2026-10-11.md)
- [2026-10-10](history/2026-10-10.md)
- [2026-10-09](history/2026-10-09.md)
- [2026-10-08](history/2026-10-08.md)
- [2026-08-27](history/2026-08-27.md)
- [2026-08-12](history/2026-08-12.md)
