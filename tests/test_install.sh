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

echo "[6] piped install never trusts a foreign cwd's bin/sec (F038 supply-chain)"
OUT6="$WORK/install6"
BOOT6="$WORK/bootstrap6"
EVIL="$WORK/evil"
mkdir -p "$EVIL/bin"
printf '#!/bin/sh\necho FOREIGN-TRUSTED-MARKER\n' >"$EVIL/bin/sec"
chmod +x "$EVIL/bin/sec"
if (cd "$EVIL" && cat "$REPO_ROOT/install.sh" | HOME="$WORK/home1" INSTALL_DIR="$OUT6" \
    SEC_BOOTSTRAP_DIR="$BOOT6" SEC_REPO_URL="$REPO_ROOT" bash) >"$WORK/out6.log" 2>&1; then
    pass "piped install from foreign cwd exits 0"
else
    fail "piped install from foreign cwd exited non-zero"
    cat "$WORK/out6.log"
fi
if grep -q "FOREIGN-TRUSTED-MARKER" "$OUT6/sec" 2>/dev/null; then
    fail "installer copied the foreign cwd's bin/sec"
else
    pass "foreign cwd bin/sec ignored"
fi
if grep -q "Bootstrapping" "$WORK/out6.log"; then
    pass "piped mode bootstrapped from SEC_REPO_URL instead of cwd"
else
    fail "no bootstrap occurred from a foreign cwd"
fi

echo "[7] LICENSE is installed alongside the binaries (F051)"
if [[ -f "$OUT1/sec-cli-LICENSE" ]] && diff -q "$REPO_ROOT/LICENSE" "$OUT1/sec-cli-LICENSE" >/dev/null 2>&1; then
    pass "LICENSE copied to install dir, byte-identical"
else
    fail "LICENSE not installed (expected $OUT1/sec-cli-LICENSE)"
fi

echo "[8] file-mode install warns about missing runtime dependencies (F053)"
MINBIN8="$WORK/minbin8"
mkdir -p "$MINBIN8"
for _b in bash mkdir chmod dirname cp; do
    ln -s "$(command -v "$_b")" "$MINBIN8/$_b"
done
OUT8="$WORK/install8"
if env -i "PATH=$MINBIN8" "HOME=$WORK/home1" "INSTALL_DIR=$OUT8" \
    "$REPO_ROOT/install.sh" >"$WORK/out8.log" 2>&1; then
    pass "install still succeeds with jq/python3 absent"
else
    fail "install failed when jq/python3 absent"
    cat "$WORK/out8.log"
fi
if grep -q "jq" "$WORK/out8.log" && grep -q "python3" "$WORK/out8.log" && grep -qi "warning" "$WORK/out8.log"; then
    pass "warnings name both missing runtime deps"
else
    fail "no missing-dependency warnings in: $(cat "$WORK/out8.log")"
fi

echo "[9] piped install fails with a clear diagnostic when git is absent (F053)"
BOOT9="$WORK/bootstrap9"
MINBIN9="$WORK/minbin9"
mkdir -p "$MINBIN9"
for _b in bash mkdir chmod dirname cp; do
    ln -s "$(command -v "$_b")" "$MINBIN9/$_b"
done
set +e
(cd "$WORK" && cat "$REPO_ROOT/install.sh" | env -i "PATH=$MINBIN9" "HOME=$WORK/home1" \
    "INSTALL_DIR=$WORK/install9" "SEC_BOOTSTRAP_DIR=$BOOT9" "SEC_REPO_URL=$REPO_ROOT" bash) \
    >"$WORK/out9.log" 2>&1
RC9=$?
set -e
if [[ $RC9 -ne 0 ]]; then pass "piped install without git exits non-zero"; else fail "piped install without git exited 0"; fi
if grep -q "git is required" "$WORK/out9.log"; then
    pass "clear git-missing diagnostic"
else
    fail "raw failure instead of diagnostic: $(cat "$WORK/out9.log")"
fi

echo ""
if [[ $FAILS -eq 0 ]]; then
    echo "ALL TESTS PASSED"
    exit 0
fi
echo "$FAILS TEST(S) FAILED"
exit 1
