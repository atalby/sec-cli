# 🔒 `sec-cli`

> **Zero-Plaintext Multi-Tenant Secret Manager, Intelligent Housekeeper, Disambiguating Renamer & Vault Migration Engine.**

`sec-cli` is a lightweight, high-leverage, zero-dependency CLI control plane that unifies secret management across **Bitwarden Secrets Manager (`bws`)**, **Bitwarden Vault (`bw`)**, **1Password (`op`)**, **Infisical**, **HashiCorp Vault**, **AWS Secrets Manager**, **GCP Secret Manager**, **Unix Pass**, and **OS Keychains**.

---

## ✨ Key Features

- 🛡️ **Zero-Plaintext Security**: Eliminates `.env` files and hardcoded API keys. Credentials are injected directly into process memory (`sec run -- <cmd>`) or prompt stdin without appearing in terminal command-line history.
- 🏢 **Multi-Tenant Configuration (`~/.sec/sec.conf`)**: Configure default vaults and override target tenants per command (`sec 1pass get KEY` vs `sec bitwarden get KEY`).
- 🔄 **Smart Session Auto-Rotation**: Keeps Bitwarden/1Password sessions alive in background RAM using OS Keychains (`security` / `secret-tool`), with fallback to interactive prompts when locked.
- 🧹 **Intelligent Housekeeping (`sec housekeep plan` / `apply`)**:
  - Uses an embedded zero-dependency **Naive Bayes ML Classifier** ([`bin/sec-classify.py`](bin/sec-classify.py)) to categorize secrets into clean folder structures (`cloud/aws`, `database`, `integrations`, `infrastructure/ssh`).
  - Displays **ML Confidence Scores (%)** and **Matched Signal Triggers**.
  - **Intelligent Disambiguating Renamer**: Differentiates generic titles (e.g. 4 entries named `Gmail`) into distinct, readable names (e.g. `Gmail (anass.personal@gmail.com)`).
  - **Pre-Apply Backup Snapshots & Instant Rollback (`sec housekeep revert`)**: Saves mode `0600` metadata-only snapshots before every move/rename.
- 🚀 **Zero-Plaintext Vault Migration (`sec migrate`)**: Streams secrets directly between vault providers in memory (`Bitwarden` $\iff$ `1Password` $\iff$ `Vault`) with error trapping and single-command rollback (`sec migrate --undo`).
- 🌍 **100% Cross-Platform**: Native execution on **macOS**, **Linux**, **Windows WSL 2**, and **Windows Native PowerShell** (`sec.ps1`).

---

## 📦 Quick Installation

### One-Line Curl Installer

```bash
curl -sSL https://raw.githubusercontent.com/at-tech-io/sec-cli/main/install.sh | bash
```

### Manual Clone

```bash
git clone https://github.com/at-tech-io/sec-cli.git ~/.sec-cli
./~/.sec-cli/install.sh
```

Ensure `$HOME/.local/bin` is in your shell `$PATH`:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## ⚙️ Multi-Tenant Configuration (`~/.sec/sec.conf`)

`sec-cli` automatically initializes `~/.sec/sec.conf` (mode `0600`) upon first run:

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
```

---

## 💻 Complete Command Reference & Flags

### Main CLI Entrypoint: `sec`

```text
sec-cli v1.0.0 — Multi-Tenant Zero-Plaintext Secret Manager & Housekeeper

Usage:
  sec [<tenant>] get <key>                 Retrieve secret value from tenant or default vault
  sec [<tenant>] get <item>/<field>        Retrieve specific field from named vault item (e.g. 'github/password')
  sec [<tenant>] set <key> [<val>]         Store / create new secret in tenant vault (prompts if <val> omitted)
  sec [<tenant>] run -- <cmd>              Execute command with tenant secrets injected into process memory
  sec sync                                 Central Secret Sync Engine: Sync Bitwarden secrets to GCP & GitLab
  sec housekeep {plan|apply|revert}        Intelligent ML categorization, plan/apply, & instant rollback engine
  sec migrate --from <src> --to <dst>     Zero-plaintext vault-to-vault migration engine
  sec unlock                               Unlock Bitwarden vault and save session
  sec rotate                               Keep-alive / rotate Bitwarden session key
  sec setup-keychain                       Store master password in Keychain for auto-rotation
  sec completion {zsh|bash|fish|ps1}        Generate shell autocompletion scripts

Flags:
  -h, --help     Display this help menu
  -v, --version  Display version
```

---

### ⌨️ Shell Autocompletion Setup

```bash
# Zsh (macOS / Linux / WSL):
source <(sec completion zsh)

# Bash (Linux / Git Bash):
source <(sec completion bash)

# Fish Shell:
sec completion fish | source

# PowerShell (Windows Native):
sec completion ps1 | Invoke-Expression
```

---

### 1. Secret Retrieval & Injection

```bash
# Retrieve using default tenant from ~/.sec/sec.conf (e.g. Bitwarden):
sec get MY_API_KEY

# Retrieve specific field from a named item:
sec get "github-app/password"
sec get "github-app/notes"

# Target explicit tenant prefix:
sec 1pass get STRIPE_SECRET
sec vault get myapp/production/DATABASE_URL

# Execute process with in-memory environment injection:
sec run -- terraform plan
sec 1pass run -- aws s3 ls
```

---

### 2. Secret Creation (`sec set`)

```bash
# Interactive prompt (terminal echo disabled - no shell history leak):
sec set MY_API_KEY

# Direct inline value:
sec 1pass set STRIPE_WEBHOOK "whsec_123"
```

---

### 3. Intelligent Housekeeping (`sec housekeep`)

```bash
# Generate ML categorization & disambiguation plan:
sec housekeep plan

# Output:
#   [MOVE & RENAME] "Gmail" -> Folder: "integrations", New Name: "Gmail (anass.personal@gmail.com)" (Confidence: 94%, Match: [token:gmail])
#   [MOVE]          "PROD_POSTGRES_DB" -> Folder: "database" (Confidence: 89%, Match: [regex:postgres://])

# Execute changes with pre-apply backup snapshot:
sec housekeep apply

# Rollback last housekeeping operation:
sec housekeep revert
```

---

### 4. Zero-Plaintext Vault Migration (`sec migrate`)

```bash
# Preview migration plan:
sec migrate --from bitwarden --to 1password --plan

# Execute migration:
sec migrate --from bitwarden --to 1password --apply

# Rollback partially created items if an error occurs:
sec migrate --undo
```

---

## 🌐 Multi-OS Support Matrix

| OS Environment | POSIX Script ([`bin/sec`](bin/sec)) | PowerShell Wrapper ([`bin/sec.ps1`](bin/sec.ps1)) | ML Classifier ([`bin/sec-classify.py`](bin/sec-classify.py)) |
| :--- | :--- | :--- | :--- |
| **macOS** | ✅ Native | N/A | ✅ Native (Python 3) |
| **Linux** (Ubuntu, Fedora, Arch) | ✅ Native | N/A | ✅ Native (Python 3) |
| **Windows WSL 2** | ✅ Native | N/A | ✅ Native (Python 3) |
| **Windows Native** | ✅ Git Bash | ✅ Native PowerShell | ✅ Native (Python 3) |

---

## 📄 License

MIT License — see [`LICENSE`](LICENSE) for details.
