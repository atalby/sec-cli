#!/usr/bin/env bash
# install.sh: One-Line Zero-Dependency Installer for sec-cli
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
CONFIG_DIR="$HOME/.sec"

echo "=== 🔒 Installing sec-cli (Multi-Tenant Zero-Plaintext Secret Manager) ==="

mkdir -p "$INSTALL_DIR" "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cp "$SCRIPT_DIR/bin/sec" "$INSTALL_DIR/sec"
cp "$SCRIPT_DIR/bin/bw-session-keeper" "$INSTALL_DIR/bw-session-keeper"
cp "$SCRIPT_DIR/bin/sec-organizer" "$INSTALL_DIR/sec-organizer"
cp "$SCRIPT_DIR/bin/sec-classify.py" "$INSTALL_DIR/sec-classify.py"
cp "$SCRIPT_DIR/bin/sec-migrator" "$INSTALL_DIR/sec-migrator"
if [[ -f "$SCRIPT_DIR/bin/sec.ps1" ]]; then
    cp "$SCRIPT_DIR/bin/sec.ps1" "$INSTALL_DIR/sec.ps1"
fi

chmod +x "$INSTALL_DIR/sec" "$INSTALL_DIR/bw-session-keeper" "$INSTALL_DIR/sec-organizer" "$INSTALL_DIR/sec-classify.py" "$INSTALL_DIR/sec-migrator"

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
