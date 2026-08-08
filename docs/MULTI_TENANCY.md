# `sec-cli` Multi-Tenancy Guide

`sec-cli` supports seamless multi-tenancy, allowing you to manage personal, work, client, and multi-cloud secret vaults concurrently.

---

## ⚙️ Configuration Setup (`~/.sec/sec.conf`)

The configuration file lives at `~/.sec/sec.conf` (mode `0600`).

### Example Configuration

```ini
[global]
default_backend = bitwarden
auto_rotate = true

[bitwarden]
cli = bw
auto_rotate = true

[1pass]
cli = op
auto_rotate = false

[bws]
cli = bws
auto_rotate = true

[vault]
cli = vault
auto_rotate = false

[infisical]
cli = infisical
auto_rotate = false
```

---

## 🔀 Tenant Prefix Command Routing

You can target any tenant directly by prefixing its section name before the subcommand:

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

For each tenant section in `~/.sec/sec.conf`:

- `auto_rotate = true`: When vault status is locked or expired, `sec` attempts background key refresh using stored macOS Keychain or Linux Secret Service entries.
- `auto_rotate = false`: When vault status is locked, `sec` prompts interactively for manual authentication (`bw unlock`, `op signin`, `vault login`).
