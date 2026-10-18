#!/usr/bin/env bash
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${SEC_TEST_WORK_ROOT:-$(mktemp -d)}"
trap 'rm -rf "$WORK"' EXIT

FAILS=0
pass() { echo "  ok: $1"; }
fail() { echo "  FAIL: $1"; FAILS=$((FAILS + 1)); }

FAKEBIN="$WORK/fakebin"
mkdir -p "$FAKEBIN"

cat >"$FAKEBIN/bw" <<'EOF'
#!/usr/bin/env bash
if [ -n "${SEC_TEST_BW_LOG:-}" ]; then echo "bw $*" >>"$SEC_TEST_BW_LOG"; fi
BW_ITEM_JSON="${SEC_TEST_BW_ITEM_JSON:-{\"id\":\"a\",\"name\":\"a\",\"folderId\":null}}"
case "$*" in
    "sync --nostatus") exit 0 ;;
    "sync") exit "${SEC_TEST_BW_SYNC_RC:-0}" ;;
    "list items")
        if [ "${SEC_TEST_BW_LIST_RC:-0}" -ne 0 ]; then echo "bw list items: vault is locked" >&2; exit "${SEC_TEST_BW_LIST_RC}"; fi
        if [ "${SEC_TEST_BW_LIST_EMPTY:-0}" -ne 0 ]; then echo '[]'; exit 0; fi
        echo '[{"name":"k","notes":"'"${SEC_TEST_BW_NOTES-v}"'"}]' ;;
    "list folders") echo "${SEC_TEST_BW_FOLDERS:-[]}" ;;
    get\ item*) echo "$BW_ITEM_JSON" ;;
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

cat >"$FAKEBIN/bws" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "project" ] && [ "${2:-}" = "list" ]; then
    if [ -n "${SEC_TEST_BWS_PROJ_GARBAGE:-}" ]; then echo "NOT-JSON-AT-ALL"; exit 0; fi
    if [ "${SEC_TEST_BWS_PROJ_RC:-0}" -ne 0 ]; then echo "bws boom" >&2; exit 1; fi
    echo '[{"id":"p1","name":"default"}]'
    exit 0
fi
if [ "${1:-}" = "secret" ] && [ "${2:-}" = "list" ]; then
    if [ "${SEC_TEST_BWS_LIST_RC:-0}" -ne 0 ]; then echo "bws secret list: boom" >&2; exit "${SEC_TEST_BWS_LIST_RC}"; fi
    echo '[{"id":"s1","key":"k1"}]'
    exit 0
fi
if [ "${1:-}" = "secret" ] && [ "${2:-}" = "create" ]; then
    if [ -n "${SEC_TEST_BWS_CREATE_GARBAGE:-}" ]; then echo "NOT-JSON-AT-ALL"; exit 0; fi
    echo '{"id":"s1","name":"created"}'
    exit 0
fi
exit 0
EOF
chmod +x "$FAKEBIN/bws"

cat >"$FAKEBIN/secret-tool" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$FAKEBIN/secret-tool"

OPCANARY="$WORK/op-canary.log"
cat >"$FAKEBIN/op" <<'EOF'
#!/usr/bin/env bash
echo "op $*" >>"${SEC_TEST_OP_CANARY:?SEC_TEST_OP_CANARY unset}"
if [ "${1:-}" = "item" ] && [ "${2:-}" = "get" ]; then
    if [ -n "${SEC_TEST_OP_ITEM_GET_JSON:-}" ]; then echo "${SEC_TEST_OP_ITEM_GET_JSON}"; fi
    exit "${SEC_TEST_OP_ITEM_GET_RC:-0}"
fi
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

echo "[3b] F048: op apply skips an action whose item changed since the plan (staleness guard)"
H3c="$WORK/h3c"
mkdir -p "$H3c/.cache/bitwarden"
PLAN3c="$H3c/.cache/bitwarden/housekeep_plan.json"
cat >"$PLAN3c" <<'EOF'
{"backend":"op","timestamp":"t","actions":[{"id":"x","originalName":"old-name","newName":"new-name","targetFolder":"general","currentFolder":null,"currentFolderId":null,"confidence":50}]}
EOF
rm -f "$OPCANARY"
set +e
OUT3c="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H3c" "SEC_TEST_OP_CANARY=$OPCANARY" "SEC_TEST_OP_RC=0" 'SEC_TEST_OP_ITEM_GET_JSON={"id":"x","title":"renamed-since-plan"}' "$REPO_ROOT/bin/sec-organizer" apply 2>&1)"
RC3c=$?
set -e
if [[ $RC3c -ne 0 ]]; then pass "all-stale op apply exits non-zero (no false success)"; else fail "all-stale op apply exited 0"; fi
if grep -q "Successfully Applied" <<<"$OUT3c"; then fail "reported success while skipping every action"; else pass "no success banner when every action skipped"; fi
if grep -q "^\[WARN\] Skipping" <<<"$OUT3c"; then pass "tagged [WARN] skip explains the staleness"; else fail "no tagged staleness warning: $OUT3c"; fi
if [[ -f "$PLAN3c" ]]; then pass "plan kept when nothing was applied"; else fail "plan DELETED despite zero applied"; fi
if grep -qE -- '--tags( |$)' "$OPCANARY" 2>/dev/null; then fail "op item edit invoked for a stale action"; else pass "no write attempted for the stale action"; fi

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

echo "[10] F048: bw apply skips an action whose item was renamed since the plan"
H10="$WORK/h10"
mkdir -p "$H10/.cache/bitwarden"
PLAN10="$H10/.cache/bitwarden/housekeep_plan.json"
cat >"$PLAN10" <<'EOF'
{"backend":"bw","timestamp":"t","actions":[{"id":"a","originalName":"old","newName":"new","targetFolder":"general","currentFolder":"root","currentFolderId":null,"confidence":50}]}
EOF
BWLOG10="$WORK/bw10.log"; : >"$BWLOG10"
set +e
OUT10="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H10" "SEC_TEST_BW_LOG=$BWLOG10" 'SEC_TEST_BW_ITEM_JSON={"id":"a","name":"renamed-since-plan","folderId":null}' "$REPO_ROOT/bin/sec-organizer" apply 2>&1)"
RC10=$?
set -e
if [[ $RC10 -ne 0 ]]; then pass "all-stale bw apply exits non-zero"; else fail "all-stale bw apply exited 0: $OUT10"; fi
if grep -q "Successfully Applied" <<<"$OUT10"; then fail "bw reported success while skipping everything"; else pass "bw no success banner when all skipped"; fi
if grep -q "^\[WARN\] Skipping" <<<"$OUT10"; then pass "bw tagged [WARN] skip explains staleness"; else fail "bw no skip message: $OUT10"; fi
if grep -q "edit item" "$BWLOG10"; then fail "bw edit item invoked for a stale action"; else pass "bw no write attempted for the stale action"; fi
if [[ -f "$PLAN10" ]]; then pass "bw plan kept when nothing applied"; else fail "bw plan DELETED despite zero applied"; fi

echo "[11] bw-session-keeper rotate: a failed vault sync is surfaced, a successful one confirmed"
H11="$WORK/h11"
mkdir -p "$H11/.cache/bitwarden"
printf 'fakesession' >"$H11/.cache/bitwarden/session"
set +e
OUT11="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H11" "SEC_TEST_BW_SYNC_RC=1" "$REPO_ROOT/bin/bw-session-keeper" rotate 2>&1)"
RC11=$?
set -e
if [[ $RC11 -eq 1 ]]; then pass "failed refresh exits 1 (no silent success)"; else fail "failed refresh exited $RC11, expected 1: $OUT11"; fi
if grep -q "^\[ OK \] Vault synced successfully." <<<"$OUT11"; then fail "reported 'Vault synced successfully' after a failed sync"; else pass "no false success banner on a failed sync"; fi
if grep -q "^\[ERROR\] Session is valid but the vault sync failed" <<<"$OUT11"; then pass "tagged [ERROR] explains the failed refresh"; else fail "no tagged sync-failure notice: $OUT11"; fi

H11b="$WORK/h11b"
mkdir -p "$H11b/.cache/bitwarden"
printf 'fakesession' >"$H11b/.cache/bitwarden/session"
set +e
OUT11b="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H11b" "SEC_TEST_BW_SYNC_RC=0" "$REPO_ROOT/bin/bw-session-keeper" rotate 2>&1)"
RC11b=$?
set -e
if [[ $RC11b -eq 0 ]]; then pass "successful refresh exits 0"; else fail "successful refresh exited $RC11b: $OUT11b"; fi
if grep -q "^\[ OK \] Vault synced successfully." <<<"$OUT11b"; then pass "tagged success banner on real success"; else fail "no success banner on a working refresh: $OUT11b"; fi

echo "[12] bw-session-keeper non-TTY unlock/setup-keychain with no stored password fail loudly (#22)"
H12="$WORK/h12"
mkdir -p "$H12"
set +e
OUT12a="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H12" "$REPO_ROOT/bin/bw-session-keeper" unlock </dev/null 2>&1)"
RC12a=$?
OUT12b="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H12" "$REPO_ROOT/bin/bw-session-keeper" setup-keychain </dev/null 2>&1)"
RC12b=$?
set -e
if [[ $RC12a -eq 1 ]]; then pass "non-TTY unlock with no stored password exits 1"; else fail "non-TTY unlock exited $RC12a, expected 1: $OUT12a"; fi
if grep -q "^\[ERROR\] Master password not available" <<<"$OUT12a"; then pass "unlock prints a tagged [ERROR]"; else fail "no tagged unlock error: $OUT12a"; fi
if [[ $RC12b -eq 1 ]]; then pass "non-TTY setup-keychain with no arg exits 1"; else fail "non-TTY setup-keychain exited $RC12b, expected 1: $OUT12b"; fi
if grep -q "^\[ERROR\] Master password not provided" <<<"$OUT12b"; then pass "setup-keychain prints a tagged [ERROR]"; else fail "no tagged setup error: $OUT12b"; fi

echo "[13] housekeep apply on a corrupt plan fails loudly (tagged, exit 1, plan kept) (#115)"
H13="$WORK/h13"
mkdir -p "$H13/.cache/bitwarden"
PLAN13="$H13/.cache/bitwarden/housekeep_plan.json"
printf '{"backend":"bw","actions":[' >"$PLAN13"
set +e
OUT13="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H13" "$REPO_ROOT/bin/sec-organizer" apply 2>&1)"
RC13=$?
set -e
if [[ $RC13 -eq 1 ]]; then pass "corrupt plan apply exits 1"; else fail "corrupt plan apply exited $RC13, expected 1: $OUT13"; fi
if grep -q "^\[ERROR\] corrupt or unreadable housekeeping plan" <<<"$OUT13"; then pass "tagged corrupt-plan notice"; else fail "no tagged corrupt-plan notice: $OUT13"; fi
if grep -q "Successfully Applied" <<<"$OUT13"; then fail "reported success for a corrupt plan"; else pass "no success banner on a corrupt plan"; fi
if [[ -f "$PLAN13" ]]; then pass "corrupt plan file kept for diagnosis"; else fail "corrupt plan file deleted"; fi

echo "[14] housekeep revert on a corrupt snapshot fails loudly (tagged, exit 1, snapshot kept) (#115)"
SNAP14="$WORK/h14/.cache/bitwarden/snapshot_latest.json"
mkdir -p "$(dirname "$SNAP14")"
printf '{"backend":"bw","actions":[' >"$SNAP14"
set +e
OUT14="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$WORK/h14" "$REPO_ROOT/bin/sec-organizer" revert 2>&1)"
RC14=$?
set -e
if [[ $RC14 -eq 1 ]]; then pass "corrupt snapshot revert exits 1"; else fail "corrupt snapshot revert exited $RC14, expected 1: $OUT14"; fi
if grep -q "^\[ERROR\] corrupt or unreadable housekeeping snapshot" <<<"$OUT14"; then pass "tagged corrupt-snapshot notice"; else fail "no tagged corrupt-snapshot notice: $OUT14"; fi
if grep -q "Revert Successfully Completed" <<<"$OUT14"; then fail "reported success for a corrupt snapshot"; else pass "no success banner on a corrupt snapshot"; fi
if [[ -f "$SNAP14" ]]; then pass "corrupt snapshot file kept for diagnosis"; else fail "corrupt snapshot file deleted"; fi

echo "[15] migrate --to bws: a failed/unreadable project listing fails loudly, never silent or raw (#167)"
H15="$WORK/h15"
mkdir -p "$H15/.cache/bitwarden"
set +e
OUT15a="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H15" "SEC_TEST_BWS_PROJ_RC=1" "$REPO_ROOT/bin/sec-migrator" --from bitwarden --to bws --apply 2>&1)"
RC15a=$?
set -e
if [[ $RC15a -eq 1 ]]; then pass "failed project list exits 1 (not silent)"; else fail "failed project list exited $RC15a, expected 1: $OUT15a"; fi
if grep -q "^\[ERROR\] 'bws project list' failed" <<<"$OUT15a"; then pass "tagged project-list failure notice"; else fail "no tagged project-list failure notice: $OUT15a"; fi
if grep -q "^\[ERROR\] Migration failed while transferring" <<<"$OUT15a"; then pass "trap_error notice runs on project-list failure"; else fail "trap_error never ran: $OUT15a"; fi
if [[ -f "$H15/.cache/bitwarden/migration_transaction.json" ]]; then pass "transaction log saved on project-list failure"; else fail "no transaction log on project-list failure"; fi

H15b="$WORK/h15b"
mkdir -p "$H15b/.cache/bitwarden"
set +e
OUT15b="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H15b" "SEC_TEST_BWS_PROJ_GARBAGE=1" "$REPO_ROOT/bin/sec-migrator" --from bitwarden --to bws --apply 2>&1)"
RC15b=$?
set -e
if [[ $RC15b -eq 1 ]]; then pass "garbage project listing exits 1 (not raw jq 4)"; else fail "garbage project listing exited $RC15b, expected 1: $OUT15b"; fi
if grep -q "^\[ERROR\] 'bws project list' returned an unreadable listing" <<<"$OUT15b"; then pass "tagged unreadable-listing notice"; else fail "no tagged unreadable-listing notice: $OUT15b"; fi
if grep -q "parse error" <<<"$OUT15b"; then fail "raw jq parse error leaked: $OUT15b"; else pass "no raw jq parse error on garbage listing"; fi

H15c="$WORK/h15c"
mkdir -p "$H15c/.cache/bitwarden"
set +e
OUT15c="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H15c" "SEC_TEST_BWS_CREATE_GARBAGE=1" "$REPO_ROOT/bin/sec-migrator" --from bitwarden --to bws --apply 2>&1)"
RC15c=$?
set -e
if [[ $RC15c -eq 1 ]]; then pass "garbage create response exits 1 (not raw jq 4)"; else fail "garbage create response exited $RC15c, expected 1: $OUT15c"; fi
if grep -q "^\[ERROR\] Migration failed while transferring" <<<"$OUT15c"; then pass "trap_error notice runs on garbage create response"; else fail "trap_error never ran: $OUT15c"; fi
if grep -q "parse error" <<<"$OUT15c"; then fail "raw jq parse error leaked: $OUT15c"; else pass "no raw jq parse error on garbage create response"; fi

H15d="$WORK/h15d"
mkdir -p "$H15d/.cache/bitwarden"
set +e
OUT15d="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H15d" "$REPO_ROOT/bin/sec-migrator" --from bitwarden --to bws --apply 2>&1)"
RC15d=$?
set -e
if [[ $RC15d -eq 0 ]]; then pass "working bws backends exit 0"; else fail "working bws migrate exited $RC15d: $OUT15d"; fi
if grep -q "^\[ OK \] Vault Migration Successfully Completed (1 items migrated)" <<<"$OUT15d"; then pass "tagged success banner on real bws success"; else fail "no success banner on working bws migrate: $OUT15d"; fi

echo "[16] migrate fails closed on a failing SOURCE listing, never 'Zero items found' (issue #170)"
H16="$WORK/h16"
mkdir -p "$H16/.cache/bitwarden"
set +e
OUT16a="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H16" "SEC_TEST_BW_LIST_RC=1" "$REPO_ROOT/bin/sec-migrator" --from bitwarden --to infisical --plan 2>&1)"
RC16a=$?
set -e
if [[ $RC16a -eq 1 ]]; then pass "failing bw source listing exits 1"; else fail "failing bw source listing exited $RC16a, expected 1: $OUT16a"; fi
if grep -q "^\[ERROR\] corrupt or unreadable listing from source backend 'bitwarden'" <<<"$OUT16a"; then pass "tagged unreadable-listing notice on bw failure"; else fail "no tagged unreadable-listing notice: $OUT16a"; fi
if grep -q "Zero items found" <<<"$OUT16a"; then fail "failing bw source still reported 'Zero items found' (false success): $OUT16a"; else pass "no false zero-items success on bw failure"; fi
if grep -q "vault is locked" <<<"$OUT16a"; then fail "raw backend diagnostic leaked: $OUT16a"; else pass "no raw backend diagnostic leaked"; fi

H16b="$WORK/h16b"
mkdir -p "$H16b/.cache/bitwarden"
set +e
OUT16b="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H16b" "SEC_TEST_OP_CANARY=$WORK/op16b.log" "SEC_TEST_OP_RC=1" "$REPO_ROOT/bin/sec-migrator" --from op --to infisical --plan 2>&1)"
RC16b=$?
set -e
if [[ $RC16b -eq 1 ]]; then pass "failing op source listing exits 1"; else fail "failing op source listing exited $RC16b, expected 1: $OUT16b"; fi
if grep -q "^\[ERROR\] corrupt or unreadable listing from source backend 'op'" <<<"$OUT16b"; then pass "tagged unreadable-listing notice on op failure"; else fail "no tagged unreadable-listing notice: $OUT16b"; fi
if grep -q "Zero items found" <<<"$OUT16b"; then fail "failing op source still reported 'Zero items found' (false success): $OUT16b"; else pass "no false zero-items success on op failure"; fi

H16c="$WORK/h16c"
mkdir -p "$H16c/.cache/bitwarden"
set +e
OUT16c="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H16c" "SEC_TEST_BWS_LIST_RC=1" "$REPO_ROOT/bin/sec-migrator" --from bws --to infisical --plan 2>&1)"
RC16c=$?
set -e
if [[ $RC16c -eq 1 ]]; then pass "failing bws source listing exits 1"; else fail "failing bws source listing exited $RC16c, expected 1: $OUT16c"; fi
if grep -q "^\[ERROR\] corrupt or unreadable listing from source backend 'bws'" <<<"$OUT16c"; then pass "tagged unreadable-listing notice on bws failure"; else fail "no tagged unreadable-listing notice: $OUT16c"; fi
if grep -q "Zero items found" <<<"$OUT16c"; then fail "failing bws source still reported 'Zero items found' (false success): $OUT16c"; else pass "no false zero-items success on bws failure"; fi
if grep -q "bws secret list: boom" <<<"$OUT16c"; then fail "raw bws diagnostic leaked: $OUT16c"; else pass "no raw bws diagnostic leaked"; fi

H16d="$WORK/h16d"
mkdir -p "$H16d/.cache/bitwarden"
set +e
OUT16d="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H16d" "SEC_TEST_BW_LIST_EMPTY=1" "$REPO_ROOT/bin/sec-migrator" --from bitwarden --to infisical --plan 2>&1)"
RC16d=$?
set -e
if [[ $RC16d -eq 0 ]]; then pass "genuinely empty source listing still exits 0"; else fail "genuinely empty source listing exited $RC16d, expected 0: $OUT16d"; fi
if grep -q "^\[INFO\] Zero items found in source backend 'bitwarden'" <<<"$OUT16d"; then pass "valid empty listing reports zero items (guard does not over-reject)"; else fail "valid empty listing did not report zero items: $OUT16d"; fi

echo
if [[ $FAILS -eq 0 ]]; then
    echo "ALL TESTS PASSED"
    exit 0
fi
echo "$FAILS test(s) failed"
exit 1
