#!/usr/bin/env bash
# install.sh: One-Line Zero-Dependency Installer for sec-cli
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
CONFIG_DIR="$HOME/.sec"
REPO_URL="${SEC_REPO_URL:-https://github.com/atalby/sec-cli.git}"
BOOTSTRAP_DIR="${SEC_BOOTSTRAP_DIR:-$HOME/.sec-cli}"

echo "=== 🔒 Installing sec-cli (Multi-Tenant Zero-Plaintext Secret Manager) ==="

mkdir -p "$INSTALL_DIR" "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR=""
fi

if [[ -z "$SCRIPT_DIR" || ! -f "$SCRIPT_DIR/bin/sec" ]]; then
    if [[ ! -f "$BOOTSTRAP_DIR/bin/sec" ]]; then
        if ! command -v git >/dev/null 2>&1; then
            echo "=== ERROR: git is required for a piped install (clones $REPO_URL) but was not found on PATH. Install git, or run the tracked install.sh from a checkout. ==="
            exit 1
        fi
        echo "=== 📥 Bootstrapping: cloning $REPO_URL to $BOOTSTRAP_DIR ==="
        git clone --depth 1 "$REPO_URL" "$BOOTSTRAP_DIR"
    fi
    SCRIPT_DIR="$BOOTSTRAP_DIR"
fi

cp "$SCRIPT_DIR/bin/sec" "$INSTALL_DIR/sec"
cp "$SCRIPT_DIR/bin/bw-session-keeper" "$INSTALL_DIR/bw-session-keeper"
cp "$SCRIPT_DIR/bin/sec-organizer" "$INSTALL_DIR/sec-organizer"
cp "$SCRIPT_DIR/bin/sec-classify.py" "$INSTALL_DIR/sec-classify.py"
cp "$SCRIPT_DIR/bin/sec-migrator" "$INSTALL_DIR/sec-migrator"
cp "$SCRIPT_DIR/bin/sec-sync-controller.py" "$INSTALL_DIR/sec-sync-controller.py"
if [[ -f "$SCRIPT_DIR/bin/sec.ps1" ]]; then
    cp "$SCRIPT_DIR/bin/sec.ps1" "$INSTALL_DIR/sec.ps1"
fi
if [[ -f "$SCRIPT_DIR/LICENSE" ]]; then
    cp "$SCRIPT_DIR/LICENSE" "$INSTALL_DIR/sec-cli-LICENSE"
fi

chmod +x "$INSTALL_DIR/sec" "$INSTALL_DIR/bw-session-keeper" "$INSTALL_DIR/sec-organizer" "$INSTALL_DIR/sec-classify.py" "$INSTALL_DIR/sec-migrator" "$INSTALL_DIR/sec-sync-controller.py"

if [[ ! -f "$CONFIG_DIR/sec.conf" ]]; then
    cp "$SCRIPT_DIR/sec.conf.example" "$CONFIG_DIR/sec.conf"
    chmod 600 "$CONFIG_DIR/sec.conf"
fi

for _dep in jq python3; do
    if ! command -v "$_dep" >/dev/null 2>&1; then
        echo "=== WARNING: '$_dep' not found on PATH — some sec-cli commands need it (jq: housekeep; python3: sync and classification) and will fail at runtime until it is installed. ==="
    fi
done

echo "=== ✨ sec-cli installed successfully to $INSTALL_DIR/sec ==="
echo ""
echo "Ensure '$INSTALL_DIR' is in your \$PATH:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""
echo "Try running:"
echo "  sec --help"
