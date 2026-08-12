# History — sec-cli

## Current state
**2026-08-12**: `sec-cli` zero-plaintext multi-tenant secret manager active across all 16 fleet repositories. Integrates Bitwarden (`bw`), Bitwarden Secrets Manager (`bws`), 1Password (`op`), Infisical, and HashiCorp Vault.

---

### 2026-08-12 — Central Secret Sync Controller (`sec sync`)
- Implemented `sec sync` subcommand (`bin/sec-sync-controller.py`) in `sec-cli`.
- Automatically syncs Bitwarden canonical vault keys to GCP Secret Manager (`sublime-flux-504502-k3`) and GitLab Group CI/CD variables (`at-tech-io`).
- Eliminates secret drift and configuration fragmentation across multi-cloud environments.
