# `sec-cli` Multi-Tenancy Guide

`sec-cli` supports seamless multi-tenancy, allowing you to manage personal, work, client, and multi-cloud secret vaults concurrently.

---

## ⚙️ Configuration Setup (`~/.sec/sec.conf`)

The configuration file lives at `~/.sec/sec.conf` (mode `0600`).

### Example Configuration

```ini
# ~/.sec/sec.conf: Fleet Multi-Tenant Secret Manager Configuration
[global]
default_backend = bitwarden

[bitwarden]
auto_rotate = true

[1pass]
auto_rotate = false

[bws]
auto_rotate = true

[vault]
auto_rotate = false

[infisical]
auto_rotate = false
```

---

## 🔀 Tenant Prefix Command Routing

Prefix routing supports the eight fixed aliases (bitwarden/bw, 1pass/op, bws, vault, infisical, keychain); arbitrary `sec.conf` sections are not routable as prefixes. You can target any of those eight before the subcommand:

```bash
# 1. Use default tenant from ~/.sec/sec.conf (e.g. Bitwarden):
sec get API_KEY

# 2. Target 1Password explicitly:
sec 1pass get API_KEY
sec 1pass set STRIPE_WEBHOOK "whsec_123"

# 3. Target Bitwarden Secrets Manager explicitly:
sec bws get DB_URL

# 4. Target HashiCorp Vault explicitly:
sec vault get myapp/production/DATABASE_URL
```

---

## 🔐 Auto-Rotate vs. Interactive Login

`auto_rotate` (default `true`) is read per tenant section by `bin/sec`'s
`ensure_tenant_auth`, but it only *drives* behavior for the backends that have an auth
arm there. The per-backend response when the vault is locked or expired:

| Backend | `auto_rotate` consulted | Response when locked |
|---|---|---|
| `bitwarden` | yes | Background key refresh via `bin/bw-session-keeper rotate` (stored macOS Keychain / Linux Secret Service), then prompts interactively if the vault is *still* locked |
| `1pass` | no | Prompts interactively with `op signin`, whatever `auto_rotate` is set to |
| `vault` | no | Prompts interactively with `vault login`, whatever `auto_rotate` is set to |
| `bws` | no auth arm | `ensure_tenant_auth` performs no session handling |
| `infisical` | no auth arm | `ensure_tenant_auth` performs no session handling |
| `keychain` | no auth arm | `ensure_tenant_auth` performs no session handling |

The interactive prompt is a **fallback, not an `auto_rotate = false` branch**: with
`auto_rotate = true`, `bitwarden` still reaches `bw-session-keeper unlock` whenever the
rotate step leaves the vault locked.
