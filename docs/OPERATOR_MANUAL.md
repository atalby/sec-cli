# `sec-cli` Operator Manual & Flags Reference

Welcome to the **`sec-cli` Operator Manual**. This document provides detailed technical documentation for all commands, flags, multi-tenant configurations, and troubleshooting procedures.

---

## 📐 Architecture & Principles

`sec-cli` is designed around four core principles:

1. **Zero-Plaintext Enforcement**: Secrets are stored exclusively in secure OS Keychains or encrypted vault providers. Process execution (`sec run -- <cmd>`) injects credentials into RAM without leaving `.env` files on disk.
2. **Multi-Tenant Routing**: Supports configuring multiple vault backends simultaneously (`~/.sec/sec.conf`) with simple tenant prefix command routing (`sec 1pass get KEY` vs `sec bitwarden get KEY`).
3. **Machine Learning Housekeeping**: Embedded zero-dependency ML classification engine ([`bin/sec-classify.py`](../bin/sec-classify.py)) analyzes title tokens, URIs, and field formats to propose folder organization structures and disambiguate generic titles (`Gmail (anass.personal@gmail.com)`).
4. **Transaction Safety & Revertability**: Every apply operation generates a timestamped, mode `0600` metadata-only pre-apply backup snapshot (`~/.cache/bitwarden/snapshot_latest.json`) and supports single-command rollbacks (`sec housekeep revert` / `sec migrate --undo`).

---

## 🛠️ Complete CLI Flag & Option Reference

### Command Syntax

```bash
sec [<tenant_prefix>] <subcommand> [flags] [arguments]
```

### Global Flags

| Flag | Long Flag | Description |
| :--- | :--- | :--- |
| `-h` | `--help` | Displays the comprehensive help menu and configured tenant list. |
| `-v` | `--version` | Displays `sec-cli` version information (`sec-cli v1.0.0`). |

---

### Subcommand Reference

#### 1. `sec [<tenant>] get <key>`
Retrieves a secret value from the active or specified tenant vault.

- **Examples**:
  ```bash
  sec get MY_API_KEY
  sec 1pass get STRIPE_SECRET
  sec get "github-app/password"
  sec get "github-app/notes"
  sec get "op://private/my-app/password"
  ```

#### 2. `sec [<tenant>] set <key> [<value>]`
Stores or creates a new secret entry in the active or specified tenant vault.

- **Options**:
  - If `<value>` is omitted, `sec` prompts interactively on terminal `stdin` with echo disabled (`read -rsp` / `-AsSecureString`).
- **Examples**:
  ```bash
  sec set MY_API_KEY                  # Interactive prompt
  sec 1pass set STRIPE_WEBHOOK "val"  # Direct inline value
  ```

#### 3. `sec [<tenant>] run -- <command_and_args>`
Executes `<command_and_args>` as a child process with injected environment variables in process memory.

- **Examples**:
  ```bash
  sec run -- terraform plan
  sec 1pass run -- aws s3 ls
  ```

#### 4. `sec housekeep {plan|apply|revert}`
Executes the ML classification and disambiguating renamer engine across your vault.

- **Sub-actions**:
  - `sec housekeep plan`: Scans vault, calculates ML confidence scores (%), and displays proposed moves/renames.
  - `sec housekeep apply`: Creates missing target folders, renames/moves items, and saves pre-apply snapshot.
  - `sec housekeep revert`: Reverts items back to their pre-housekeeping names and folder IDs.

#### 5. `sec migrate --from <src> --to <dst> [--plan|--apply|--undo]`
Executes zero-plaintext vault-to-vault migration in ephemeral memory.

- **Sub-actions**:
  - `--from <src>`: Source vault provider (`bitwarden`/`bw`, `bws`, `1password`/`op`, `infisical`, `vault`).
  - `--to <dst>`: Target vault provider.
  - `--plan` / `--dry-run`: Previews migration without modifying target vault.
  - `--apply`: Executes in-memory secret creation in target vault.
  - `--undo`: Reverts created items from target vault using transaction state log.

#### 6. Session Management Commands
- `sec unlock`: Interactively unlocks Bitwarden vault and caches session key.
- `sec rotate`: Triggers background keep-alive refresh / rotation via `bw-session-keeper`.
- `sec setup-keychain`: Stores master password in OS Keychain for zero-touch auto-rotation.
