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
    get\ item*) echo '{"id":"a","name":"a","folderId":null}' ;;
    edit\ item*) exit "${SEC_TEST_BW_EDIT_RC:-0}" ;;
    encode) cat ;;
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
if grep -q "^\[ERROR\] set not supported for tenant" <<<"$OUT1"; then pass "tagged refusal names the unsupported tenant"; else fail "no tagged 'not supported' in: $OUT1"; fi

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
if grep -q "^\[ERROR\] apply not implemented for backend" <<<"$OUT2"; then pass "tagged refusal explains the unsupported backend"; else fail "no tagged 'not implemented' in: $OUT2"; fi

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
if grep -q "keepme" "$TX4" && grep -q "^\[ERROR\] unresolved migration transaction" <<<"$OUT4"; then pass "existing TX untouched, tagged undo hint"; else fail "TX clobbered or no tagged undo hint: $OUT4"; fi

echo "[5] migrate --apply fails loudly on an empty-valued item (no fake success)"
H5="$WORK/h5"
mkdir -p "$H5/.cache/bitwarden"
set +e
OUT5="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H5" "SEC_TEST_BW_NOTES=" "$REPO_ROOT/bin/sec-migrator" --from bitwarden --to infisical --apply 2>&1)"
RC5=$?
set -e
if [[ $RC5 -eq 1 ]]; then pass "empty-val item aborts apply with exit 1"; else fail "empty-val apply exited $RC5, expected 1"; fi
if grep -q "^\[ERROR\] Migration failed while transferring" <<<"$OUT5"; then pass "prints tagged migration ERROR notice"; else fail "no tagged migration ERROR notice: $OUT5"; fi
if [[ -f "$H5/.cache/bitwarden/migration_transaction.json" ]]; then pass "transaction log written on failure"; else fail "no transaction log on failure"; fi

echo "[6] housekeep revert: a failed bw edit is surfaced, snapshot kept, no fake success"
SNAP6="$WORK/h6/.cache/bitwarden/snapshot_latest.json"
mkdir -p "$(dirname "$SNAP6")"
cat >"$SNAP6" <<'EOF'
{"backend":"bw","actions":[{"id":"a","originalName":"a","currentFolder":"root","currentFolderId":null}]}
EOF
set +e
OUT6="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$WORK/h6" "SEC_TEST_BW_EDIT_RC=1" "$REPO_ROOT/bin/sec-organizer" revert 2>&1)"
RC6=$?
set -e
if [[ $RC6 -eq 1 ]]; then pass "revert with a failing edit exits 1"; else fail "revert exited $RC6, expected 1: $OUT6"; fi
if [[ -f "$SNAP6" ]]; then pass "snapshot kept after failed revert"; else fail "snapshot DELETED after failed revert"; fi
if grep -q "Revert Successfully Completed" <<<"$OUT6"; then fail "reported success for a failed revert"; else pass "no success banner on failed revert"; fi
if grep -q "^\[ERROR\] revert failed" <<<"$OUT6"; then pass "tagged revert-failure notice names the item"; else fail "no tagged revert-failure notice: $OUT6"; fi

echo "[7] housekeep revert: successful edits clear the snapshot and report success"
SNAP7="$WORK/h7/.cache/bitwarden/snapshot_latest.json"
mkdir -p "$(dirname "$SNAP7")"
cat >"$SNAP7" <<'EOF'
{"backend":"bw","actions":[{"id":"a","originalName":"a","currentFolder":"root","currentFolderId":null}]}
EOF
set +e
OUT7="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$WORK/h7" "SEC_TEST_BW_EDIT_RC=0" "$REPO_ROOT/bin/sec-organizer" revert 2>&1)"
RC7=$?
set -e
if [[ $RC7 -eq 0 ]]; then pass "revert with working edits exits 0"; else fail "revert exited $RC7, expected 0: $OUT7"; fi
if [[ ! -f "$SNAP7" ]]; then pass "snapshot cleared after successful revert"; else fail "snapshot still present after successful revert"; fi
if grep -q "^\[ OK \] Secret Housekeeping Revert Successfully Completed" <<<"$OUT7"; then pass "tagged success banner on real success"; else fail "no tagged success banner: $OUT7"; fi

echo "[8] migrate --undo on a corrupt transaction log fails loudly (no silent no-op)"
TX8="$WORK/h8/.cache/bitwarden/migration_transaction.json"
mkdir -p "$(dirname "$TX8")"
printf '{"dstBackend":"op","createdItems":[' >"$TX8"
set +e
OUT8="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$WORK/h8" "$REPO_ROOT/bin/sec-migrator" --undo 2>&1)"
RC8=$?
set -e
if [[ $RC8 -eq 1 ]]; then pass "corrupt TX --undo exits 1"; else fail "corrupt TX --undo exited $RC8, expected 1: $OUT8"; fi
if grep -q "^\[ERROR\] corrupt or unreadable migration transaction log" <<<"$OUT8"; then pass "tagged corrupt-TX notice"; else fail "no tagged corrupt-TX notice: $OUT8"; fi
if [[ -f "$TX8" ]]; then pass "corrupt TX file kept for diagnosis"; else fail "corrupt TX file deleted"; fi

echo "[9] migrate --undo on a well-formed empty TX reports zero items and exits 0"
TX9="$WORK/h9/.cache/bitwarden/migration_transaction.json"
mkdir -p "$(dirname "$TX9")"
printf '{"dstBackend":"op","createdItems":[]}' >"$TX9"
set +e
OUT9="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$WORK/h9" "$REPO_ROOT/bin/sec-migrator" --undo 2>&1)"
RC9=$?
set -e
if [[ $RC9 -eq 0 ]]; then pass "empty TX --undo exits 0"; else fail "empty TX --undo exited $RC9, expected 0: $OUT9"; fi
if grep -q "zero created items" <<<"$OUT9"; then pass "reports zero created items"; else fail "no zero-items notice: $OUT9"; fi

echo
if [[ $FAILS -eq 0 ]]; then
    echo "ALL TESTS PASSED"
    exit 0
fi
echo "$FAILS test(s) failed"
exit 1
