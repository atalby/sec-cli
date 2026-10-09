#!/usr/bin/env bash
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SENTINEL="$REPO_ROOT/skills/architecture-360-audit/sentinel.sh"

pass=0
fail=0
ok() { echo "  ok: $1"; pass=$((pass + 1)); }
no() { echo "  fail: $1"; fail=$((fail + 1)); }

echo "[1] coverage subcommand accounts for every tracked file"
if [[ -x "$SENTINEL" ]]; then
    ok "sentinel.sh exists and is executable"
else
    no "sentinel.sh missing or not executable"
fi
OUT="$("$SENTINEL" coverage --list 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "coverage exits 0"
else
    no "coverage exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -q "\[ OK \] coverage: all .* tracked files claimed" <<<"$OUT"; then
    ok "coverage reports full claim"
else
    no "coverage output missing claim summary"
fi
if grep -q "personas: all 12 reachable" <<<"$OUT"; then
    ok "all 12 personas reachable from manifest"
else
    no "persona reachability line missing"
fi

echo "[2] citations subcommand resolves every file:line anchor"
OUT="$("$SENTINEL" citations 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "citations exits 0"
else
    no "citations exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -q "\[ OK \] citations: every file:line anchor" <<<"$OUT"; then
    ok "citations reports every anchor resolves"
else
    no "citations success line missing"
fi

echo "[3] a broken citation is detected (sentinel fails closed)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/skills/architecture-360-audit"
cp "$REPO_ROOT/skills/architecture-360-audit/profile.md" "$WORK/skills/architecture-360-audit/profile.md"
cp "$REPO_ROOT/skills/architecture-360-audit/SKILL.md" "$WORK/skills/architecture-360-audit/SKILL.md"
cp "$SENTINEL" "$WORK/skills/architecture-360-audit/sentinel.sh"
chmod +x "$WORK/skills/architecture-360-audit/sentinel.sh"
printf '\nGhost citation: `definitely-missing-file.py:4242`\n' >>"$WORK/skills/architecture-360-audit/profile.md"
OUT="$(cd "$WORK" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" citations 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "citations exits nonzero on a broken anchor"
else
    no "citations accepted a broken anchor"
fi
if grep -q "definitely-missing-file.py:4242" <<<"$OUT"; then
    ok "citations names the broken anchor"
else
    no "citations did not name the broken anchor"
fi

echo "[4] unknown subcommand is a usage error (exit 2)"
"$SENTINEL" bogus >/dev/null 2>&1
RC=$?
if [[ $RC -eq 2 ]]; then
    ok "bad invocation exits 2"
else
    no "bad invocation exited $RC, expected 2"
fi

echo
if [[ $fail -eq 0 ]]; then
    echo "ALL TESTS PASSED"
    exit 0
fi
echo "$fail test(s) failed"
exit 1
