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
`do_unlock` helper, with regression guards [22j]/[22k]. Then #53 re-truth'd
the sync controller's own docstring and runtime banner, which still
advertised a "Single Source of Truth: Bitwarden Vault" even though
`sec sync` reads values only from the invoking environment (docs already
said so since #9); a sync_guard guard [15] now fails if the false claim
returns. Then #54 corrected the README/ARCHITECTURE/install.sh
runtime-dependency sentence, which understated `jq` as housekeep-only
although `bin/sec` needs it for auth/get/set too; a sentinel-suite guard
[10] fails if that understatement returns. Then #55 fixed a sec.conf
parser bug: `get_cfg_val` matched the key as an unanchored regex on the
first `=`-field and never skipped comments, so a commented-out key such
as `# auto_rotate = false` still took effect (a plain default-backend
lookup could also collide with a longer key name); the parser now skips
comments/blanks and requires an exact key-name match, with dispatch
guards [18b]/[18c]. Then #56 completed the completion surfaces: the
zsh/bash/fish/ps1 generators listed only the ten canonical commands and
omitted the `create`/`organize`/`keep` aliases the dispatcher arms
accept and ARCHITECTURE.md documents; all four now offer the aliases
(with the checked-in `completions/_sec` regenerated from `sec completion
zsh`), and dispatch guard [22l] fails if any surface drops them. Then #57
fixed a completion-honesty residual on the PowerShell side: `bin/sec.ps1`
implements only get/set/run/housekeep/migrate (a core subset since #44),
yet the ps1 completer registered `sec.ps1` under the full `$subcommands`
array, so tab-completion advertised `sync`/`create`/`organize`/`keep`/…
that the wrapper rejects with `[ERROR]`; the completer now offers
`sec.ps1` only its implemented set (via a `GetCommandName() -ieq
'sec.ps1'` branch) while `sec`/`sec.exe` keep the full list, and dispatch
guard [22l] checks the ps1 scoping. Then #58 removed the secret-on-argv
path on the default backend: `sec set` handed the value to `jq` as
`--arg val`, putting it on jq's command line (visible in `ps`) even when
supplied via the prompts that exist to keep it out of argv/history, and
then passed the encoded blob (embedding the value) as a positional arg to
`bw create/edit item`; the value now reaches jq via `env.SECVAL` and the
blob reaches bw on stdin, with dispatch guard 22m pinning it. Then #59
gave the migrator's bw target the same treatment (jq via `env.SECVAL`,
blob to `bw create item` on stdin, dispatch guard 22n). Then #59 finished
the remainder after confirming each backend's stdin/file contract against
the vendor docs: the `1pass` set path sends an item JSON template to
`op item create -` on stdin, the migrator's op arm does the same, and its
vault arm pipes the value to `vault kv put ... value=-`; infisical has no
stdin channel, so its arm stages the value in a transient mode-0600 file
(`KEY=@path`, unlinked immediately). Only `bws secret create` still takes
the value as a positional argv — a vendor limitation with no stdin/file/env
alternative (open upstream bitwarden/sdk-sm #1568, CWE-214) — now documented
as such in `docs/SECURITY.md`; dispatch guard 22o pins all four paths off
argv and the infisical file delivery. Then #60 closed a completion-parity
residual: the fish and ps1 surfaces omitted the top-level `--help`/`-h`/
`--version`/`-v` flags that bash and zsh already offered and `bin/sec`
accepts — fish now offers all four, ps1 offers them for `sec`/`sec.exe` but
only `--help`/`-h` for `sec.ps1` (which rejects `--version`/`-v`), with
dispatch guard 22p. Then #61 closed the sync controller's GitLab write
path: it was exercised only in `--dry-run` and issued `PUT` alone, so a
group variable that did not yet exist could never be created (the GCP arm
already creates-if-absent); a new pytest mirror
`scripts/tests/test_sync_controller.py` mocks `urllib.request.urlopen` to
cover update/404-create/error/token-skip, and the controller now does a
defensive create-on-404 upsert. All five bash suites pass (install 9 / sync_guard 15 /
write_honesty 11 / sentinel 10 / dispatch 64), the pytest mirror (29 tests) passes, and
the GitHub tracker holds only the hub-side handoff #51 (in-repo issues
exhausted). Next: advance the highest-value unfinished in-repo work.

## Archive

- [2026-10-11](history/2026-10-11.md)
- [2026-10-10](history/2026-10-10.md)
- [2026-10-09](history/2026-10-09.md)
- [2026-10-08](history/2026-10-08.md)
- [2026-08-27](history/2026-08-27.md)
- [2026-08-12](history/2026-08-12.md)
