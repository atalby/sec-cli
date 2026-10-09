#!/usr/bin/env bash
# tests/test_install.sh — zero-dependency regression tests for install.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

FAILS=0
pass() { echo "  ok: $1"; }
fail() { echo "  FAIL: $1"; FAILS=$((FAILS + 1)); }

expect_file() {
    if [[ -x "$1" ]]; then pass "$2"; else fail "$2 (missing or not executable: $1)"; fi
}

echo "[1] file-mode install copies every bin/ entry the dispatcher needs"
OUT1="$WORK/install1"
mkdir -p "$WORK/home1"
if HOME="$WORK/home1" INSTALL_DIR="$OUT1" "$REPO_ROOT/install.sh" >"$WORK/out1.log" 2>&1; then
    pass "install.sh exits 0"
else
    fail "install.sh exited non-zero"
    cat "$WORK/out1.log"
fi
for f in sec bw-session-keeper sec-organizer sec-classify.py sec-migrator sec-sync-controller.py sec.ps1; do
    expect_file "$OUT1/$f" "installed $f"
done

echo "[2] piped mode: no bin/sec beside script, BASH_SOURCE unset under set -u"
OUT2="$WORK/install2"
BOOT2="$WORK/bootstrap2"
if (cd "$WORK" && cat "$REPO_ROOT/install.sh" | HOME="$WORK/home1" INSTALL_DIR="$OUT2" \
    SEC_BOOTSTRAP_DIR="$BOOT2" SEC_REPO_URL="$REPO_ROOT" bash) >"$WORK/out2.log" 2>&1; then
    pass "piped install exits 0 (no 'unbound variable' abort)"
else
    fail "piped install exited non-zero"
    cat "$WORK/out2.log"
fi
expect_file "$OUT2/sec" "piped-mode install produced sec"
if [[ -f "$BOOT2/bin/sec" ]]; then
    pass "bootstrap populated SEC_BOOTSTRAP_DIR via SEC_REPO_URL"
else
    fail "bootstrap did not populate SEC_BOOTSTRAP_DIR ($BOOT2)"
fi

echo "[3] piped mode reuses an existing bootstrap checkout without re-cloning"
OUT3="$WORK/install3"
if (cd "$WORK" && cat "$REPO_ROOT/install.sh" | HOME="$WORK/home1" INSTALL_DIR="$OUT3" \
    SEC_BOOTSTRAP_DIR="$BOOT2" SEC_REPO_URL="$REPO_ROOT" bash) >"$WORK/out3.log" 2>&1; then
    pass "second piped install exits 0 against existing bootstrap"
else
    fail "second piped install exited non-zero"
    cat "$WORK/out3.log"
fi
if grep -q "Bootstrapping" "$WORK/out3.log"; then
    fail "re-cloned even though bootstrap checkout already existed"
else
    pass "no redundant clone when bootstrap already present"
fi
expect_file "$OUT3/sec-sync-controller.py" "sync controller installed in reuse path"

echo "[4] dispatcher surface: usage, completion surfaces, sync controller is -x"
HELP="$("$OUT1/sec" --help 2>&1 || true)"
if grep -q "sec sync" <<<"$HELP"; then
    pass "usage lists 'sec sync'"
else
    fail "usage does not list 'sec sync'"
fi
if grep -q "completion {zsh|bash|fish|ps1}" <<<"$HELP"; then
    pass "usage lists fish among completion shells"
else
    fail "usage does not list fish among completion shells"
fi
if "$OUT1/sec" completion zsh | grep -q "'sync:"; then
    pass "zsh completion offers sec sync"
else
    fail "zsh completion does not offer sec sync"
fi
if "$OUT1/sec" completion bash | grep -qw "sync"; then
    pass "bash completion offers sec sync"
else
    fail "bash completion does not offer sec sync"
fi
if "$OUT1/sec" completion fish | grep -q "'sync'"; then
    pass "fish completion offers sec sync"
else
    fail "fish completion does not offer sec sync"
fi
if diff -q <("$OUT1/sec" completion zsh) "$REPO_ROOT/completions/_sec" >/dev/null; then
    pass "tracked completions/_sec matches 'sec completion zsh' output"
else
    fail "completions/_sec has drifted from 'sec completion zsh' output"
fi
if [[ -x "$OUT1/sec-sync-controller.py" ]]; then
    pass "bin/sec:562 -x guard for sec-sync-controller.py satisfied"
else
    fail "sec-sync-controller.py not executable; 'sec sync' would fall through silently"
fi

echo "[5] config bootstrap: sec.conf created under \$HOME/.sec with mode 600"
if [[ -f "$WORK/home1/.sec/sec.conf" ]]; then
    MODE="$(stat -c '%a' "$WORK/home1/.sec/sec.conf" 2>/dev/null || stat -f '%Lp' "$WORK/home1/.sec/sec.conf")"
    if [[ "$MODE" == "600" ]]; then pass "sec.conf mode 600"; else fail "sec.conf mode is $MODE, expected 600"; fi
else
    fail "sec.conf not created in \$HOME/.sec"
fi

echo ""
if [[ $FAILS -eq 0 ]]; then
    echo "ALL TESTS PASSED"
    exit 0
fi
echo "$FAILS TEST(S) FAILED"
exit 1
