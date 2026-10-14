# `sec-cli` Security Model & Audit Report

`sec-cli` is designed around strict Zero-Trust and Zero-Plaintext security principles. This document outlines the threat model, security guarantees, file permissions, and audit considerations.

---

## 🛡️ Security Guarantees & Threat Matrix

| Threat Vector | Potential Vulnerability | How `sec-cli` Mitigates It |
| :--- | :--- | :--- |
| **Disk Storage Leak** | Unencrypted secrets in `.env` files or Git commits. | **Zero-Plaintext**: Vendor run-wrappers (`bws`/`op`/`infisical`) inject secrets into process memory via `sec run --`; under `bitwarden` (the default) `sec run` is a plain exec with no injection (audit F001). Documented on-disk exceptions, all mode 0600: the session-key file; the master-pass file, written/read only with `SEC_ALLOW_PLAINTEXT_MASTER_PASS=1` (issue #10); and the transient `infisical` staging file, created 0600 and unlinked immediately after `secrets set` (issue #59). |
| **Shell History Leak** | Secrets visible in `~/.zsh_history` or `~/.bash_history`. | **Silent Stdin Prompts**: `sec set KEY` uses terminal echo-off prompts (`read -rsp` / `-AsSecureString`). |
| **Process Table Snooping** | Secrets visible in `ps aux` command-line arguments. | **In-Memory Injection**: Credentials passed via process environment variables (`ENV`) or stdin, never in argv — including the master password at `bw unlock`, handed over via `bw unlock --passwordenv` (never argv, issue #16; the session-keeper keep-alive/`setup-keychain` self-exec that re-exposed it as `"$0" unlock <pw>` was closed in issue #52). `sec set` and `sec migrate` deliver a secret value to `op` (item JSON template on stdin, `op item create -`) and to `vault` (`value=-` on stdin) with no argv exposure (issue #59). **Two documented exceptions remain**: `bws secret create` accepts the value only as a positional argv argument and offers no stdin/file/env channel (vendor limitation, bitwarden/sdk-sm issue #1568, CWE-214); `infisical secrets set` likewise has no stdin channel, so the value is passed as a transient mode-0600 temp file (`KEY=@path`, unlinked immediately after) instead of argv. |
| **Snapshot Exposure** | Unauthorized users reading backup plan files (`~/.cache/bitwarden/`). | **Metadata-Only Snapshots**: Backup snapshots store metadata fields only (`id`, `originalName`, `newName`, `currentFolder`, `currentFolderId`, `targetFolder`, `confidence`, `backend`, `timestamp`, `actions`). Passwords and secret values are **not** present in snapshot files. |
| **Session Key Hijacking** | Unauthorized local users accessing active session keys. | **Strict OS File Permissions**: `~/.cache/bitwarden/session` uses mode `0600` (read/write exclusively by owner user ID). |
| **Master Password Storage** | Plaintext password leaks. | **OS Keychain Integration**: macOS Keychain (`security`) or Linux Secret Service (`secret-tool`); when neither binary exists the keeper **refuses** to store or read a plaintext file unless `SEC_ALLOW_PLAINTEXT_MASTER_PASS=1` is set (explicit opt-in for headless hosts that cannot run libsecret; the fallback file is mode-0600 at `~/.cache/bitwarden/master_pass`). |

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
- Executables are human-readable POSIX Bash (`bin/sec`, `bin/bw-session-keeper`, `bin/sec-organizer`, `bin/sec-migrator`, `bin/hyer-mcp.sh`), Python 3 (`bin/sec-classify.py`, `bin/sec-sync-controller.py`), and PowerShell (`bin/sec.ps1`).
- Every line of code can be audited line-by-line in under 5 minutes.
