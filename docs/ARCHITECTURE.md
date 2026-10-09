# Architecture Specification — `sec-cli`

**HIAE Protocol Version**: v5.39.1

## 1. Overview
`sec-cli` is a high-leverage CLI control plane that unifies secret management across Bitwarden (`bw`), Bitwarden Secrets Manager (`bws`), 1Password (`op`), Infisical, and HashiCorp Vault; `sec sync` pushes shell-exported keys to GCP Secret Manager and GitLab group variables. Runtime dependencies beyond coreutils: `jq` (housekeep) and `python3` (sync/classify).

## 2. Core Components & CLI Executables
- `bin/sec`: Main dispatcher script (get, set, run, sync, housekeep, migrate, unlock, rotate, setup-keychain, completion + aliases create/organize/keep/help/version). `set` writes are honest (issue #7): only bitwarden/bw, 1pass/op, and bws can be stored — any other tenant, or a failed store, exits 1 with an error naming the tenant instead of a silent success.
- `bin/bw-session-keeper`: One-shot session helper (status/env/unlock/rotate/keep/setup); sessions stored in a 0600 plaintext file, no daemon.
- `bin/sec-classify.py`: Intelligent secret classifier categorizing environment variables.
- `bin/sec-migrator`: Automated migration engine moving secrets between backends. Apply is transactional and honest (issue #7): the transaction log is flushed after every created item (and on INT/TERM), an unresolved prior transaction refuses to be clobbered (exit 1, undo hinted), and an item that cannot be written aborts with exit 1 instead of counting as migrated.
- `bin/sec-organizer`: Housekeeping engine (`sec housekeep plan`/`apply`/`revert`) — classify, move, disambiguating-rename, snapshot. Apply/revert refuse backends they cannot drive (issue #7): only bw and op are implemented; an unsupported backend keeps the plan/snapshot and exits 1, 1Password edits use the correct `--tags` flag and failures abort (keeping the plan/snapshot) instead of printing success.
- `bin/sec-sync-controller.py`: Central Secret Sync Controller (`sec sync`) — pushes values exported in the calling shell (`SYNC_KEYS` read from the environment; the vault is not read) to GCP Secret Manager and GitLab group CI/CD variables. Guarded against accidental prod pushes (issue #3): `--dry-run` previews key names and target endpoints with zero backend calls; a real push requires an interactive `y/N` on a TTY or an explicit `--yes` (non-interactive without it: exit 2, nothing written); zero keys present: exit 1; unknown flags: exit 2 before any work; secret values are never printed. Writes report success only when the backend accepted them — failure notices carry the backend's own stderr, every backend call has a timeout (default 60s, `SEC_SYNC_TIMEOUT` overrides), and any failed write exits 3 (contract: 0 success / 1 no keys / 2 confirmation / 3 backend write failure).
- `bin/sec.ps1`: Native Windows PowerShell wrapper for the same subcommand surface.
- `completions/_sec`: shell completion for `sec`.
- `install.sh`: one-liner installer (bootstrap clone into `~/.sec-cli`, copy of `bin/*` to `~/.local/bin`, `sec.conf` created mode 600).
- `tests/`: four zero-dependency bash suites (`test_install.sh`, `test_sync_guard.sh`, `test_write_honesty.sh`, `test_sentinel.sh`) run manually — the pre-commit Step 5 does not recognize `tests/*.sh` (issue #2).

## 3. Zero-Plaintext Security Architecture
- **In-Memory Injection**: Secrets are injected directly into child process environments without touching disk.
- **Zero-Storage Principle**: Plaintext secrets are never stored in temporary files or shell histories.
- **Confluence Space**: `SECCLI` | **Jira Project Key**: `SEC`
