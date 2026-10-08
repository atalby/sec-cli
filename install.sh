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

# When piped (`curl ... | bash`) BASH_SOURCE is unset and `set -u` would
# abort on ${BASH_SOURCE[0]}; default to "." so the check below decides.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" && pwd)"

if [[ ! -f "$SCRIPT_DIR/bin/sec" ]]; then
    # Piped install: no repo files alongside this script. Clone once and
    # re-source from the checkout instead of failing on `cp`.
    if [[ ! -f "$BOOTSTRAP_DIR/bin/sec" ]]; then
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

chmod +x "$INSTALL_DIR/sec" "$INSTALL_DIR/bw-session-keeper" "$INSTALL_DIR/sec-organizer" "$INSTALL_DIR/sec-classify.py" "$INSTALL_DIR/sec-migrator" "$INSTALL_DIR/sec-sync-controller.py"

if [[ ! -f "$CONFIG_DIR/sec.conf" ]]; then
    cp "$SCRIPT_DIR/sec.conf.example" "$CONFIG_DIR/sec.conf"
    chmod 600 "$CONFIG_DIR/sec.conf"
fi

echo "=== ✨ sec-cli installed successfully to $INSTALL_DIR/sec ==="
echo ""
echo "Ensure '$INSTALL_DIR' is in your \$PATH:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""
echo "Try running:"
echo "  sec --help"
