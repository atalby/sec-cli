#!/usr/bin/env bash
set -euo pipefail

HYER_HOME="${HYER_HOME:-$HOME/sandbox/hyer}"
SERVER="$HYER_HOME/hyer-mcp/dist/stdio-server.js"

if [[ ! -f "$SERVER" ]]; then
    echo "[ERROR] hyer MCP server not found at $SERVER — set HYER_HOME to your hyer checkout." >&2
    exit 1
fi

if ! command -v node >/dev/null 2>&1; then
    echo "[ERROR] node not found on PATH; required to run the hyer MCP server." >&2
    exit 1
fi

if ! command -v sec >/dev/null 2>&1; then
    echo "[ERROR] sec not found on PATH; required to fetch hyer-gitlab-pat." >&2
    exit 1
fi

if ! GITLAB_TOKEN="$(sec get hyer-gitlab-pat)"; then
    echo "[ERROR] could not read hyer-gitlab-pat via 'sec get' (vault locked?)." >&2
    exit 1
fi
export GITLAB_TOKEN

exec node "$SERVER"
