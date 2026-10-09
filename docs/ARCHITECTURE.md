# Architecture Specification — `sec-cli`

**HIAE Protocol Version**: v5.39.1

## 1. Overview
`sec-cli` is a high-leverage, zero-dependency control plane CLI that unifies secret management across Bitwarden (`bw`), Bitwarden Secrets Manager (`bws`), 1Password (`op`), Infisical, HashiCorp Vault, and AWS Secrets Manager.

## 2. Core Components & CLI Executables
- `bin/sec`: Main dispatcher script parsing subcommands (`get`, `inject`, `rotate`, `audit`).
- `bin/bw-session-keeper`: Daemon process maintaining encrypted Bitwarden unlock sessions.
- `bin/sec-classify.py`: Intelligent secret classifier categorizing environment variables.
- `bin/sec-migrator`: Automated migration engine moving secrets between backends.
- `bin/sec-organizer`: Housekeeping engine (`sec housekeep plan`/`apply`/`revert`) — classify, move, disambiguating-rename, snapshot.
- `bin/sec-sync-controller.py`: Central Secret Sync Controller (`sec sync`) — Bitwarden/bws source of truth pushed to GCP Secret Manager, GitLab group CI/CD variables, Vercel projects. Guarded against accidental prod pushes (issue #3): `--dry-run` previews key names and target endpoints with zero backend calls; a real push requires an interactive `y/N` on a TTY or an explicit `--yes` (non-interactive without it: exit 2, nothing written); zero keys present: exit 1; unknown flags: exit 2 before any work; secret values are never printed. Writes report success only when the backend accepted them — failure notices carry the backend's own stderr, every backend call has a timeout (default 60s, `SEC_SYNC_TIMEOUT` overrides), and any failed write exits 3 (contract: 0 success / 1 no keys / 2 confirmation / 3 backend write failure).
- `bin/sec.ps1`: Native Windows PowerShell wrapper for the same subcommand surface.
- `completions/_sec`: shell completion for `sec`.

## 3. Zero-Plaintext Security Architecture
- **In-Memory Injection**: Secrets are injected directly into child process environments without touching disk.
- **Zero-Storage Principle**: Plaintext secrets are never stored in temporary files or shell histories.
- **Confluence Space**: `SECCLI` | **Jira Project Key**: `SEC`
