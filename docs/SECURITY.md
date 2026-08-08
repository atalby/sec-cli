# `sec-cli` Security Model & Audit Report

`sec-cli` is designed around strict Zero-Trust and Zero-Plaintext security principles. This document outlines the threat model, security guarantees, file permissions, and audit considerations.

---

## 🛡️ Security Guarantees & Threat Matrix

| Threat Vector | Potential Vulnerability | How `sec-cli` Mitigates It |
| :--- | :--- | :--- |
| **Disk Storage Leak** | Unencrypted secrets in `.env` files or Git commits. | **Zero-Plaintext**: Secrets are never written to disk. Injected directly into memory via `sec run --`. |
| **Shell History Leak** | Secrets visible in `~/.zsh_history` or `~/.bash_history`. | **Silent Stdin Prompts**: `sec set KEY` uses terminal echo-off prompts (`read -rsp` / `-AsSecureString`). |
| **Process Table Snooping** | Secrets visible in `ps aux` command-line arguments. | **In-Memory Injection**: Credentials passed via process environment variables (`ENV`). |
| **Snapshot Exposure** | Unauthorized users reading backup plan files (`~/.cache/bitwarden/`). | **Metadata-Only Snapshots**: Backup snapshots store **only item UUIDs, original titles, and folder IDs**. Passwords and secret values are **not** present in snapshot files. |
| **Session Key Hijacking** | Unauthorized local users accessing active session keys. | **Strict OS File Permissions**: `~/.cache/bitwarden/session` uses mode `0600` (read/write exclusively by owner user ID). |
| **Master Password Storage** | Plaintext password leaks. | **OS Keychain Integration**: Master passwords stored in macOS Keychain (`security`) or Linux Secret Service (`secret-tool`). |

---

## 🔒 File Permissions Architecture

- `~/.sec/`: Directory mode `0700` (`chmod 700`)
- `~/.sec/sec.conf`: Configuration file mode `0600` (`chmod 600`)
- `~/.cache/bitwarden/`: Directory mode `0700` (`chmod 700`)
- `~/.cache/bitwarden/session`: Session key mode `0600` (`chmod 600`)
- `~/.cache/bitwarden/snapshot_*.json`: Pre-apply backup snapshot mode `0600` (`chmod 600`)
- `~/.cache/bitwarden/migration_transaction.json`: Migration transaction log mode `0600` (`chmod 600`)

---

## 🔍 Auditability

`sec-cli` is built with **zero external compiled binaries or third-party tracking dependencies**:
- Executables are human-readable POSIX Bash (`bin/sec`, `bin/bw-session-keeper`, `bin/sec-organizer`, `bin/sec-migrator`), Python 3 (`bin/sec-classify.py`), and PowerShell (`bin/sec.ps1`).
- Every line of code can be audited line-by-line in under 5 minutes.
