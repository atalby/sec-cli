---
name: sec-cli
description: >-
  Zero-Plaintext Multi-Tenant Secret Manager, Intelligent Housekeeper, and Vault Migration Engine.
  Use when retrieving API keys, storing credentials, executing commands with injected secrets, or reorganizing vaults.
---

# `sec-cli`: Zero-Plaintext Multi-Tenant Secret Manager & Housekeeper Skill

This skill enforces zero-plaintext secret handling across developers and AI agents using `sec-cli`.

---

## 🔒 Core Directives

1. **Zero-Plaintext Storage**: NEVER write raw API keys, passwords, database URLs, or private tokens into committed files (`.env`, `config.json`, or `.yml`).
2. **In-Memory Injection**: Use runtime CLI launchers (`sec run -- <cmd>` or `sec 1pass run -- <cmd>`) to inject credentials directly into process memory at execution time.
3. **Multi-Tenant Routing**: Specify the tenant name before the command if using non-default vaults (e.g. `sec 1pass get KEY` or `sec bitwarden get KEY`).

---

## 🛠️ CLI Command Reference

### 1. Secret Retrieval & Injection
```bash
sec get <key>                    # Retrieve secret value from default vault
sec 1pass get <key>             # Retrieve secret value from 1Password
sec get "item_name/password"    # Retrieve specific field from a named item
sec run -- terraform plan       # Run command with secrets injected into memory
```

### 2. Secret Storage
```bash
sec set MY_API_KEY              # Prompts securely on terminal stdin (no history leak)
sec set MY_API_KEY "secret_val" # Store inline secret value
```

### 3. Intelligent Housekeeping & Rollback
```bash
sec housekeep plan              # Generate ML classification plan for vault organization
sec housekeep apply             # Create folders & reorganize items with pre-apply backup
sec housekeep revert            # Instantly undo/rollback last housekeeping operation
```

### 4. Zero-Plaintext Vault Migration
```bash
sec migrate --from bitwarden --to 1password --plan
sec migrate --from bitwarden --to 1password --apply
sec migrate --undo
```
