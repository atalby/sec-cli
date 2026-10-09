#!/usr/bin/env bash
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

FAILS=0
pass() { echo "  ok: $1"; }
fail() { echo "  FAIL: $1"; FAILS=$((FAILS + 1)); }

FAKEBIN="$WORK/fakebin"
mkdir -p "$FAKEBIN"

cat >"$FAKEBIN/bw" <<'EOF'
#!/usr/bin/env bash
case "$*" in
    "sync --nostatus") exit 0 ;;
    "list items") echo '[{"name":"k","notes":"'"${SEC_TEST_BW_NOTES-v}"'"}]' ;;
    *) exit 0 ;;
esac
EOF
chmod +x "$FAKEBIN/bw"

cat >"$FAKEBIN/infisical" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$FAKEBIN/infisical"

OPCANARY="$WORK/op-canary.log"
cat >"$FAKEBIN/op" <<'EOF'
#!/usr/bin/env bash
echo "op $*" >>"${SEC_TEST_OP_CANARY:?SEC_TEST_OP_CANARY unset}"
exit "${SEC_TEST_OP_RC:-0}"
EOF
chmod +x "$FAKEBIN/op"

echo "[1] sec set for an unsupported tenant fails loudly (exit 1, not silent 0)"
H1="$WORK/h1"
mkdir -p "$H1"
set +e
OUT1="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H1" "$REPO_ROOT/bin/sec" keychain set K V 2>&1 </dev/null)"
RC1=$?
set -e
if [[ $RC1 -eq 1 ]]; then pass "unsupported tenant set exits 1"; else fail "unsupported tenant set exited $RC1, expected 1"; fi
if grep -qi "not supported" <<<"$OUT1"; then pass "names the unsupported tenant"; else fail "no 'not supported' explanation: $OUT1"; fi

echo "[2] housekeep apply refuses an unsupported backend, keeps the plan"
H2="$WORK/h2"
mkdir -p "$H2/.cache/bitwarden"
PLAN2="$H2/.cache/bitwarden/housekeep_plan.json"
cat >"$PLAN2" <<'EOF'
{"backend":"bws","timestamp":"t","actions":[{"id":"x","originalName":"a","newName":"b","targetFolder":"general","currentFolder":"root","currentFolderId":null,"confidence":50}]}
EOF
set +e
OUT2="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2" "$REPO_ROOT/bin/sec-organizer" apply 2>&1)"
RC2=$?
set -e
if [[ $RC2 -eq 1 ]]; then pass "bws apply exits 1"; else fail "bws apply exited $RC2, expected 1"; fi
if [[ -f "$PLAN2" ]]; then pass "plan file kept on refusal"; else fail "plan file DELETED on refusal"; fi
if grep -q "Successfully Applied" <<<"$OUT2"; then fail "reported success for a no-op apply"; else pass "no success banner on refusal"; fi
if grep -qi "not implemented" <<<"$OUT2"; then pass "explains the unsupported backend"; else fail "no 'not implemented' explanation: $OUT2"; fi

echo "[3] housekeep apply (op) honours --tags and fails hard on backend error"
H3="$WORK/h3"
mkdir -p "$H3/.cache/bitwarden"
PLAN3="$H3/.cache/bitwarden/housekeep_plan.json"
cat >"$PLAN3" <<'EOF'
{"backend":"op","timestamp":"t","actions":[{"id":"x","originalName":"a","newName":"b","targetFolder":"general","currentFolder":null,"currentFolderId":null,"confidence":50}]}
EOF
rm -f "$OPCANARY"
set +e
OUT3="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H3" "SEC_TEST_OP_CANARY=$OPCANARY" "SEC_TEST_OP_RC=1" "$REPO_ROOT/bin/sec-organizer" apply 2>&1)"
RC3=$?
set -e
if [[ $RC3 -ne 0 ]]; then pass "op apply surfaces backend failure (exit $RC3)"; else fail "op apply exited 0 despite failing backend"; fi
if [[ -f "$PLAN3" ]]; then pass "plan kept after failed op apply"; else fail "plan DELETED after failed op apply"; fi
if ls "$H3/.cache/bitwarden"/snapshot_*.json >/dev/null 2>&1; then pass "snapshot kept after failed op apply"; else fail "snapshot missing after failed op apply"; fi
if grep -q "Successfully Applied" <<<"$OUT3"; then fail "reported success for a failed apply"; else pass "no success banner on failure"; fi

H3b="$WORK/h3b"
mkdir -p "$H3b/.cache/bitwarden"
cat >"$H3b/.cache/bitwarden/housekeep_plan.json" <<'EOF'
{"backend":"op","timestamp":"t","actions":[{"id":"x","originalName":"a","newName":"b","targetFolder":"general","currentFolder":null,"currentFolderId":null,"confidence":50}]}
EOF
rm -f "$OPCANARY"
set +e
OUT3b="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H3b" "SEC_TEST_OP_CANARY=$OPCANARY" "SEC_TEST_OP_RC=0" "$REPO_ROOT/bin/sec-organizer" apply 2>&1)"
RC3b=$?
set -e
if [[ $RC3b -eq 0 ]]; then pass "op apply succeeds against a working backend"; else fail "op apply exited $RC3b despite working backend: $OUT3b"; fi
if grep -qE -- '--tags( |$)' "$OPCANARY" 2>/dev/null; then pass "op invoked with --tags"; else fail "op never saw --tags (canary: $(tr '\n' ';' <"$OPCANARY" 2>/dev/null))"; fi
if grep -qE -- '--tag( |$)' "$OPCANARY" 2>/dev/null; then fail "op still invoked with the bogus --tag flag"; else pass "no bogus --tag flag"; fi

echo "[4] migrate --apply refuses to clobber an unresolved transaction"
H4="$WORK/h4"
mkdir -p "$H4/.cache/bitwarden"
TX4="$H4/.cache/bitwarden/migration_transaction.json"
cat >"$TX4" <<'EOF'
{"srcBackend":"bw","dstBackend":"infisical","timestamp":"old","createdItems":[{"id":"keepme","name":"keepme"}]}
EOF
set +e
OUT4="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H4" "$REPO_ROOT/bin/sec-migrator" --from bitwarden --to infisical --apply 2>&1)"
RC4=$?
set -e
if [[ $RC4 -eq 1 ]]; then pass "apply with unresolved TX exits 1"; else fail "apply with unresolved TX exited $RC4, expected 1"; fi
if grep -q "keepme" "$TX4" && grep -q "unresolved\|undo" <<<"$OUT4"; then pass "existing TX untouched and undo hinted"; else fail "TX clobbered or no undo hint: $OUT4"; fi

echo "[5] migrate --apply fails loudly on an empty-valued item (no fake success)"
H5="$WORK/h5"
mkdir -p "$H5/.cache/bitwarden"
set +e
OUT5="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H5" "SEC_TEST_BW_NOTES=" "$REPO_ROOT/bin/sec-migrator" --from bitwarden --to infisical --apply 2>&1)"
RC5=$?
set -e
if [[ $RC5 -eq 1 ]]; then pass "empty-val item aborts apply with exit 1"; else fail "empty-val apply exited $RC5, expected 1"; fi
if grep -q "ERROR" <<<"$OUT5"; then pass "prints the migration ERROR notice"; else fail "no ERROR notice: $OUT5"; fi
if [[ -f "$H5/.cache/bitwarden/migration_transaction.json" ]]; then pass "transaction log written on failure"; else fail "no transaction log on failure"; fi

echo
if [[ $FAILS -eq 0 ]]; then
    echo "ALL TESTS PASSED"
    exit 0
fi
echo "$FAILS test(s) failed"
exit 1
