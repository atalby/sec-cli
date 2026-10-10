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
echo "bw $*" >>"${SEC_TEST_BW_LOG:?SEC_TEST_BW_LOG unset}"
ITEMS='[{"id":"item-1","name":"MY_API_KEY","notes":null,"login":{"password":"pw-MY_API_KEY","username":"me@example.com","uris":[]},"fields":[],"folderId":""},{"id":"item-2","name":"github-app","notes":null,"login":{"password":"gh-pw","username":"gh-user","uris":[]},"fields":[{"type":0,"name":"token","value":"cf-token"}],"folderId":""}]'
case "${1:-}" in
    status)
        echo '{"status":"unlocked"}'
        ;;
    sync)
        exit 0
        ;;
    list)
        case "${2:-}" in
            items)
                if [ "${3:-}" = "--search" ]; then
                    jq -c --arg q "${4:-}" '[.[] | select(.name | contains($q))]' <<<"$ITEMS"
                else
                    echo "$ITEMS"
                fi
                ;;
            folders)
                echo '[]'
                ;;
        esac
        ;;
    get)
        case "${2:-}" in
            template) echo '{"id":"","name":"","type":1,"login":{},"notes":""}' ;;
            item) echo '{"id":"item-1","name":"MY_API_KEY","login":{"password":"pw-MY_API_KEY","username":"me@example.com"},"notes":null,"fields":[]}' ;;
        esac
        ;;
    encode)
        cat
        ;;
    create)
        echo '{"id":"created-1"}'
        ;;
    unlock)
        if [ -n "${BW_UNLOCK_PASS:-}" ]; then
            echo "bw-env-present" >>"${SEC_TEST_BW_LOG:?SEC_TEST_BW_LOG unset}"
        fi
        echo "session-tok-123"
        ;;
    *)
        exit 0
        ;;
esac
exit 0
EOF
chmod +x "$FAKEBIN/bw"

cat >"$FAKEBIN/op" <<'EOF'
#!/usr/bin/env bash
echo "op $*" >>"${SEC_TEST_OP_LOG:?SEC_TEST_OP_LOG unset}"
case "${1:-}" in
    read)
        case "${2:-}" in
            op://private/MY_API_KEY/password) echo "op-pw-MY_API_KEY" ;;
            *) exit 1 ;;
        esac
        ;;
    item)
        case "${2:-}" in
            list) echo '[{"id":"op-1","title":"OP Item","tags":[]}]' ;;
            create) echo '{"id":"op-created"}' ;;
        esac
        ;;
    run)
        shift
        [ "${1:-}" = "--" ] && shift
        exec "$@"
        ;;
esac
exit 0
EOF
chmod +x "$FAKEBIN/op"

cat >"$FAKEBIN/bws" <<'EOF'
#!/usr/bin/env bash
echo "bws $*" >>"${SEC_TEST_BWS_LOG:?SEC_TEST_BWS_LOG unset}"
case "${1:-} ${2:-}" in
    "secret list")
        exit "${BWS_LIST_RC:-1}"
        ;;
    "secret get")
        echo "bws-pw-${3:-}"
        ;;
    "project list")
        echo '[{"id":"proj-1","name":"p"}]'
        ;;
    "secret create")
        echo '{"id":"bws-created"}'
        ;;
esac
exit 0
EOF
chmod +x "$FAKEBIN/bws"

cat >"$FAKEBIN/vault" <<'EOF'
#!/usr/bin/env bash
echo "vault $*" >>"${SEC_TEST_VAULT_LOG:?SEC_TEST_VAULT_LOG unset}"
case "${1:-} ${2:-}" in
    "kv get") echo "vault-val" ;;
esac
exit 0
EOF
chmod +x "$FAKEBIN/vault"

cat >"$FAKEBIN/infisical" <<'EOF'
#!/usr/bin/env bash
echo "infisical $*" >>"${SEC_TEST_INF_LOG:?SEC_TEST_INF_LOG unset}"
if [ "${1:-}" = "secrets" ] && [ "${2:-}" = "get" ]; then
    echo "inf-pw-${3:-}"
fi
exit 0
EOF
chmod +x "$FAKEBIN/infisical"

new_home() {
    local h="$1"
    mkdir -p "$h/.sec"
    printf '[global]\ndefault_backend = bitwarden\nauto_rotate = false\n' >"$h/.sec/sec.conf"
    echo "$h"
}

run_sec() {
    local h="$1"
    shift
    env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$h" \
        "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
        "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
        "$REPO_ROOT/bin/sec" "$@" </dev/null
}

H="$(new_home "$WORK/h1")"
BWLOG="$WORK/bw.log"
OPLOG="$WORK/op.log"
BWSLOG="$WORK/bws.log"
VAULTLOG="$WORK/vault.log"
INFLOG="$WORK/inf.log"
: >"$BWLOG"; : >"$OPLOG"; : >"$BWSLOG"; : >"$VAULTLOG"; : >"$INFLOG"

echo "[1] version/help/no-args surface"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H" "$REPO_ROOT/bin/sec" -v 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "sec-cli" <<<"$OUT"; then pass "sec -v exits 0 with version"; else fail "sec -v rc=$RC out=$OUT"; fi
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H" "$REPO_ROOT/bin/sec" --help 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "Usage:" <<<"$OUT"; then pass "--help exits 0 with Usage"; else fail "--help rc=$RC"; fi
if grep -q "env injection only for bws/op/infisical" <<<"$OUT"; then pass "help states per-tenant injection truth (F001)"; else fail "help still promises universal injection: $OUT"; fi
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H" "$REPO_ROOT/bin/sec" 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "Usage:" <<<"$OUT"; then pass "no-args exits 0 with Usage"; else fail "no-args rc=$RC"; fi

echo "[2] unknown command falls through to usage (current behavior: exit 0)"
set +e
OUT="$(run_sec "$H" frobnicate 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "Usage:" <<<"$OUT"; then pass "unknown cmd prints usage, exit 0"; else fail "unknown cmd rc=$RC out=$OUT"; fi

echo "[3] bw get: plain key returns login.password"
set +e
OUT="$(run_sec "$H" get MY_API_KEY 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && [[ "$OUT" == "pw-MY_API_KEY" ]]; then pass "bw get MY_API_KEY -> pw-MY_API_KEY"; else fail "bw get rc=$RC out=$OUT"; fi

echo "[4] bw get: item/field subpath"
set +e
OUT="$(run_sec "$H" get github-app/password 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && [[ "$OUT" == "gh-pw" ]]; then pass "bw get github-app/password -> gh-pw"; else fail "subpath get rc=$RC out=$OUT"; fi

echo "[5] bw get: miss exits 1 with tenant error"
set +e
OUT="$(run_sec "$H" get NO_SUCH_KEY 2>&1)"
RC=$?
set -e
if [[ $RC -eq 1 ]]; then pass "miss exits 1"; else fail "miss rc=$RC"; fi
if grep -q "^\[ERROR\] Secret .* not found in tenant" <<<"$OUT"; then pass "miss emits tagged [ERROR]"; else fail "no tagged not-found in: $OUT"; fi

echo "[6] prefix tenant: bws get"
set +e
OUT="$(run_sec "$H" bws get MY_KEY 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && [[ "$OUT" == "bws-pw-MY_KEY" ]]; then pass "bws get -> bws-pw-MY_KEY"; else fail "bws get rc=$RC out=$OUT"; fi

echo "[7] prefix tenant: op get"
set +e
OUT="$(run_sec "$H" op get MY_API_KEY 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && [[ "$OUT" == "op-pw-MY_API_KEY" ]]; then pass "op get -> op-pw-MY_API_KEY"; else fail "op get rc=$RC out=$OUT"; fi

echo "[8] prefix tenant: vault get splits item/field and calls vault kv get (F037 fix)"
: >"$VAULTLOG"
set +e
OUT="$(run_sec "$H" vault get anything 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && [[ "$OUT" == "vault-val" ]]; then pass "bare vault get returns stub value"; else fail "bare vault get rc=$RC out=$OUT"; fi
if grep -q "kv get -field=value secret/data/anything" "$VAULTLOG"; then pass "bare key hits secret/data/anything with field=value"; else fail "unexpected vault call: $(tr '\n' ';' <"$VAULTLOG")"; fi
set +e
OUT="$(run_sec "$H" vault get myapp/production/DATABASE_URL 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && [[ "$OUT" == "vault-val" ]]; then pass "item/field vault get returns stub value"; else fail "item/field vault get rc=$RC out=$OUT"; fi
if grep -q "kv get -field=DATABASE_URL secret/data/myapp/production" "$VAULTLOG"; then pass "subpath hits secret/data/myapp/production with field=DATABASE_URL"; else fail "unexpected vault subpath call: $(tr '\n' ';' <"$VAULTLOG")"; fi

echo "[9] prefix tenant: infisical get"
set +e
OUT="$(run_sec "$H" infisical get MY_KEY 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && [[ "$OUT" == "inf-pw-MY_KEY" ]]; then pass "infisical get -> inf-pw-MY_KEY"; else fail "infisical get rc=$RC out=$OUT"; fi

echo "[10] bw set create path"
: >"$BWLOG"
set +e
OUT="$(run_sec "$H" bw set NEW_KEY newval 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]]; then pass "bw set exits 0"; else fail "bw set rc=$RC out=$OUT"; fi
if grep -q "^\[ OK \] Secret .* saved to Bitwarden Vault" <<<"$OUT"; then pass "reports [ OK ] saved-to-Bitwarden"; else fail "no tagged saved-to-Bitwarden in: $OUT"; fi
if grep -q "create item" "$BWLOG"; then pass "bw create item executed"; else fail "no 'create item' in bw log: $(tr '\n' ';' <"$BWLOG")"; fi

echo "[11] op set create path"
set +e
OUT="$(run_sec "$H" op set NEW_OP_KEY newopval 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]]; then pass "op set exits 0"; else fail "op set rc=$RC out=$OUT"; fi
if grep -q "saved to 1Password" <<<"$OUT"; then pass "reports saved-to-1Password"; else fail "no saved-to-1Password in: $OUT"; fi

echo "[12] run dispatch: default exec + op delegation"
set +e
OUT="$(run_sec "$H" run -- echo run-ok 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "run-ok" <<<"$OUT"; then pass "sec run -- echo run-ok"; else fail "default run rc=$RC out=$OUT"; fi
set +e
OUT="$(run_sec "$H" op run -- echo op-run-ok 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "op-run-ok" <<<"$OUT"; then pass "sec op run -- echo op-run-ok"; else fail "op run rc=$RC out=$OUT"; fi

echo "[13] sync dispatch reaches the controller (dry-run)"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H" "GEMINI_API_KEY=fake" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/sec" sync --dry-run 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 0 ]]; then pass "sec sync --dry-run exits 0"; else fail "sync --dry-run rc=$RC out=$OUT"; fi
if grep -q "^\[INFO\] SEC CENTRAL SECRET SYNC CONTROLLER — DRY RUN" <<<"$OUT"; then pass "prints tagged DRY RUN banner"; else fail "no tagged DRY RUN banner in: $OUT"; fi
if grep -q "^\[ OK \] DRY RUN COMPLETE" <<<"$OUT"; then pass "prints tagged DRY RUN COMPLETE"; else fail "no tagged DRY RUN COMPLETE in: $OUT"; fi
if grep -q "gcloud" "$BWLOG" 2>/dev/null; then fail "dry-run touched gcloud"; else pass "no backend write during dry-run"; fi

echo "[14] housekeep plan executes the organizer"
H2="$(new_home "$WORK/h2")"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/sec" housekeep plan 2>&1 </dev/null)"
RC=$?
set -e
PLAN="$H2/.cache/bitwarden/housekeep_plan.json"
if [[ $RC -eq 0 ]]; then pass "housekeep plan exits 0"; else fail "housekeep plan rc=$RC out=$OUT"; fi
if [[ -f "$PLAN" ]]; then pass "plan file written"; else fail "no plan file at $PLAN"; fi
if [[ "$(stat -c '%a' "$H2/.cache/bitwarden")" == "700" ]]; then pass "cache dir created 0700"; else fail "cache dir mode is $(stat -c '%a' "$H2/.cache/bitwarden"), expected 700"; fi
if [[ -f "$PLAN" && "$(stat -c '%a' "$PLAN")" == "600" ]]; then pass "plan file written 0600"; else fail "plan file mode is $(stat -c '%a' "$PLAN" 2>/dev/null || echo missing), expected 600"; fi
if jq -e '.actions | length >= 1' "$PLAN" >/dev/null 2>&1; then pass "plan has >=1 action"; else fail "plan actions missing/empty: $(cat "$PLAN" 2>/dev/null)"; fi
if grep -q "^\[INFO\] Plan Summary" <<<"$OUT"; then pass "prints tagged Plan Summary"; else fail "no tagged Plan Summary in: $OUT"; fi
if grep -q "^\[ OK \] Plan saved to" <<<"$OUT"; then pass "prints tagged Plan saved"; else fail "no tagged Plan saved in: $OUT"; fi

echo "[15] migrate plan executes the migrator"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/sec" migrate --from bitwarden --to 1pass --plan 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 0 ]]; then pass "migrate plan exits 0"; else fail "migrate plan rc=$RC out=$OUT"; fi
if grep -q "Discovered 2" <<<"$OUT"; then pass "discovers 2 fixture items"; else fail "no 'Discovered 2' in: $OUT"; fi
if grep -q "^\[ OK \] Migration Plan Summary: Ready to migrate 2" <<<"$OUT"; then pass "tagged ready-to-migrate counts 2"; else fail "no tagged 'Ready to migrate 2' in: $OUT"; fi
if grep -q "^\[INFO\] Discovered 2" <<<"$OUT"; then pass "tagged Discovered counts 2"; else fail "no tagged 'Discovered 2' in: $OUT"; fi

echo "[16] sec-classify.py direct smoke"
set +e
OUT="$(printf '%s' '{"name":"aws-access-key","login":{"username":"a@example.com"},"notes":"","fields":[]}' \
    | python3 "$REPO_ROOT/bin/sec-classify.py" 2>&1)"
RC=$?
set -e
CAT="$(jq -r '.category' <<<"$OUT" 2>/dev/null || echo parse-fail)"
if [[ $RC -eq 0 && "$CAT" == "cloud/aws" ]]; then pass "aws fixture classifies cloud/aws"; else fail "classify rc=$RC category=$CAT out=$OUT"; fi

echo "[17] keeper helper: rotate without session/master-pass, status output (invoked directly — F045)"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/bw-session-keeper" rotate 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 1 ]]; then pass "keeper rotate without secrets exits 1"; else fail "keeper rotate rc=$RC out=$OUT"; fi
if grep -q "No stored master password" <<<"$OUT"; then pass "rotate names the missing master password"; else fail "no master-pass message in: $OUT"; fi
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/bw-session-keeper" status 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "\[Vault Status\]" <<<"$OUT"; then pass "keeper status exits 0 with Vault Status banner"; else fail "keeper status rc=$RC out=$OUT"; fi
if grep -q "EXPIRED or MISSING" <<<"$OUT"; then pass "status reports session EXPIRED or MISSING"; else fail "no EXPIRED or MISSING in: $OUT"; fi

echo "[18] default_backend from sec.conf routes unprefixed get"
H3="$(new_home "$WORK/h3")"
printf '[global]\ndefault_backend = bws\nauto_rotate = false\n' >"$H3/.sec/sec.conf"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H3" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/sec" get ANY_KEY 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && [[ "$OUT" == "bws-pw-ANY_KEY" ]]; then pass "default_backend=bws routes get to bws"; else fail "default backend rc=$RC out=$OUT"; fi

MINBIN="$WORK/minbin"
mkdir -p "$MINBIN"
for _b in bash cat chmod mkdir uname tr grep jq; do
    ln -s "$(command -v "$_b")" "$MINBIN/$_b"
done
cp "$FAKEBIN/bw" "$MINBIN/bw"

run_keeper() {
    local h="$1"
    shift
    env -i "PATH=$MINBIN" "HOME=$h" \
        "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
        "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
        "$@" </dev/null
}

echo "[19] F002: setup-keychain refuses plaintext file store without opt-in"
H4="$(new_home "$WORK/h4")"
set +e
OUT="$(run_keeper "$H4" "$REPO_ROOT/bin/bw-session-keeper" setup-keychain test-master-pass 2>&1)"
RC=$?
set -e
if [[ $RC -eq 1 ]]; then pass "plaintext store refused with exit 1"; else fail "setup-keychain rc=$RC out=$OUT"; fi
if grep -qi "refusing" <<<"$OUT"; then pass "refusal message printed"; else fail "no refusal message in: $OUT"; fi
if [[ ! -f "$H4/.cache/bitwarden/master_pass" ]]; then pass "master_pass file not created"; else fail "master_pass file written despite refusal"; fi

echo "[20] F002: opt-in SEC_ALLOW_PLAINTEXT_MASTER_PASS=1 allows the mode-0600 file"
H5="$(new_home "$WORK/h5")"
set +e
OUT="$(env -i "PATH=$MINBIN" "HOME=$H5" "SEC_ALLOW_PLAINTEXT_MASTER_PASS=1" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/bw-session-keeper" setup-keychain test-master-pass 2>&1 </dev/null)"
RC=$?
set -e
MP="$H5/.cache/bitwarden/master_pass"
if [[ $RC -eq 0 ]] && [[ -f "$MP" ]] && [[ "$(cat "$MP")" == "test-master-pass" ]]; then pass "opt-in stores master_pass with the given value"; else fail "opt-in store rc=$RC file=$(cat "$MP" 2>/dev/null || echo missing) out=$OUT"; fi
if [[ -f "$MP" ]] && [[ "$(stat -c '%a' "$MP" 2>/dev/null || stat -f '%Lp' "$MP")" == "600" ]]; then pass "master_pass mode 600"; else fail "master_pass mode not 600"; fi

echo "[21] F002: rotate refuses a legacy plaintext file without opt-in"
H6="$(new_home "$WORK/h6")"
mkdir -p "$H6/.cache/bitwarden"
printf 'legacy-pass' >"$H6/.cache/bitwarden/master_pass"
chmod 600 "$H6/.cache/bitwarden/master_pass"
set +e
OUT="$(run_keeper "$H6" "$REPO_ROOT/bin/bw-session-keeper" rotate 2>&1)"
RC=$?
set -e
if [[ $RC -eq 1 ]]; then pass "rotate with unopted plaintext file exits 1"; else fail "rotate rc=$RC out=$OUT"; fi
if grep -qi "refusing to read" <<<"$OUT"; then pass "read refusal printed"; else fail "no read-refusal in: $OUT"; fi

echo "[22] F002: opt-in lets rotate consume a legacy plaintext file"
H7="$(new_home "$WORK/h7")"
mkdir -p "$H7/.cache/bitwarden"
printf 'legacy-pass' >"$H7/.cache/bitwarden/master_pass"
chmod 600 "$H7/.cache/bitwarden/master_pass"
set +e
OUT="$(env -i "PATH=$MINBIN" "HOME=$H7" "SEC_ALLOW_PLAINTEXT_MASTER_PASS=1" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/bw-session-keeper" rotate 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "Vault unlocked successfully" <<<"$OUT"; then pass "opt-in rotate unlocks via stored pass"; else fail "opt-in rotate rc=$RC out=$OUT"; fi

echo "[22b] F003: keeper unlock never puts the password on bw's argv"
H8="$(new_home "$WORK/h8")"
set +e
OUT="$(run_keeper "$H8" "$REPO_ROOT/bin/bw-session-keeper" unlock test-master-pass 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "Vault unlocked successfully" <<<"$OUT"; then pass "keeper unlock with password exits 0 and saves session"; else fail "keeper unlock rc=$RC out=$OUT"; fi
if grep 'bw unlock' "$BWLOG" | grep -q 'test-master-pass'; then fail "master password exposed on bw argv: $(grep 'bw unlock' "$BWLOG")"; else pass "master password absent from bw argv"; fi
if grep -q 'bw-env-present' "$BWLOG"; then pass "master password delivered to bw via env (BW_UNLOCK_PASS)"; else fail "password not passed via BW_UNLOCK_PASS env: $(grep 'bw unlock' "$BWLOG")"; fi

echo "[23] no producer still emits legacy [sec*] event prefixes (F048 retrofit)"
LEGACY=0
for f in bin/sec bin/sec-organizer bin/sec-migrator bin/bw-session-keeper; do
    if grep -n 'echo "\[sec' "$REPO_ROOT/$f" | grep -v 'usage\|Usage\|\[sec-organizer\] #' >/dev/null 2>&1; then
        grep -n 'echo "\[sec' "$REPO_ROOT/$f" || true
        LEGACY=1
    fi
done
if grep -n 'print(f"\s*\[sec' "$REPO_ROOT/bin/sec-sync-controller.py" >/dev/null 2>&1; then LEGACY=1; fi
if [[ $LEGACY -eq 0 ]]; then pass "no legacy [sec*] event prefixes in producers"; else fail "legacy [sec*] prefixes remain in a producer"; fi

echo "[23b] F026: sec.ps1 captures trailing args and execs without re-parse (static contract)"
if grep -qi 'invoke-expression' "$REPO_ROOT/bin/sec.ps1"; then fail "sec.ps1 still re-parses tokenized argv as source (Invoke-Expression, F026)"; else pass "no Invoke-Expression re-parse in sec.ps1"; fi
if grep -q 'ValueFromRemainingArguments' "$REPO_ROOT/bin/sec.ps1"; then pass "trailing args captured via ValueFromRemainingArguments"; else fail "sec.ps1 does not capture args past the first three positionals (F026 scope)"; fi
if grep -q '\$args' "$REPO_ROOT/bin/sec.ps1"; then fail "sec.ps1 still references \$args (empty under its param block, F026)"; else pass "no \$args references left in sec.ps1"; fi

if command -v pwsh >/dev/null 2>&1; then
    echo "[23c] F026: sec.ps1 run execs the command with tokens intact (pwsh functional)"
    HPS="$(new_home "$WORK/hps")"
    FBPS="$WORK/fb_ps"
    mkdir -p "$FBPS"
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$@" >"${SEC_TEST_PS_LOG:?}"\n' >"$FBPS/mytool"
    chmod +x "$FBPS/mytool"
    PSLOG="$WORK/ps_tokens.log"
    PWSH_BIN="$(command -v pwsh)"
    set +e
    env -i "PATH=$FBPS:/usr/bin:/bin" "HOME=$HPS" "SEC_TEST_PS_LOG=$PSLOG" \
        "$PWSH_BIN" -NoProfile -File "$REPO_ROOT/bin/sec.ps1" run mytool alpha "beta two" >/dev/null 2>&1
    PRC=$?
    set -e
    if [[ $PRC -eq 0 ]] && [[ -f "$PSLOG" ]]; then pass "sec.ps1 run executed the target command"; else fail "sec.ps1 run did not execute target (rc=$PRC)"; fi
    if [[ -f "$PSLOG" ]] && [[ "$(sed -n '1p' "$PSLOG")" == "alpha" ]] && [[ "$(sed -n '2p' "$PSLOG")" == "beta two" ]]; then pass "tokens passed through intact, no re-parse or loss"; else fail "token stream mangled: $(cat "$PSLOG" 2>/dev/null || echo '<no log>')"; fi
    rm -rf "$HPS" "$FBPS" "$PSLOG"
else
    echo "[INFO] pwsh not present on this host; sec.ps1 functional run test (section [23c]) runs in CI"
fi

echo "[24] F039: hyer MCP wiring is env-resolved, PAT via env only, no sh -c"
HMW="$WORK/hmw"
mkdir -p "$HMW/hyer-mcp/dist"
printf '#!/usr/bin/env bash\nexit 0\n' >"$HMW/hyer-mcp/dist/stdio-server.js"
FB24="$WORK/fb24"
mkdir -p "$FB24"
printf '#!/usr/bin/env bash\nprintf "node-argv: %%s\\n" "$*" >"${SEC_TEST_NODE_LOG:?}"\nprintf "node-env-token: %%s\\n" "${GITLAB_TOKEN:-<unset>}" >>"${SEC_TEST_NODE_LOG:?}"\n' >"$FB24/node"
printf '#!/usr/bin/env bash\necho "glpat-test-fake-token"\n' >"$FB24/sec"
chmod +x "$FB24/node" "$FB24/sec"
NLOG="$WORK/node24.log"
set +e
OUT24="$(env -i "PATH=$FB24:/usr/bin:/bin" "HOME=$HMW" "HYER_HOME=$HMW" "SEC_TEST_NODE_LOG=$NLOG" "$REPO_ROOT/bin/hyer-mcp.sh" 2>&1)"
RC24=$?
set -e
if [[ $RC24 -eq 0 && -f "$NLOG" ]]; then pass "wrapper execs the server with HYER_HOME resolved (rc=0)"; else fail "wrapper rc=$RC24 out=$OUT24"; fi
if grep -q "node-argv: .*${HMW}/hyer-mcp/dist/stdio-server.js" "$NLOG" 2>/dev/null; then pass "node invoked with the resolved server path"; else fail "server path missing from node argv: $(cat "$NLOG" 2>/dev/null)"; fi
if grep -q "node-env-token: glpat-test-fake-token" "$NLOG" 2>/dev/null; then pass "PAT delivered to node via environment"; else fail "GITLAB_TOKEN not in node env: $(cat "$NLOG" 2>/dev/null)"; fi
if grep -q "node-argv: .*glpat" "$NLOG" 2>/dev/null; then fail "PAT on node argv (process-table leak)"; else pass "PAT never on argv"; fi
if [[ -z "$OUT24" ]]; then pass "wrapper stdout clean for MCP stdio"; else fail "wrapper polluted stdout: $OUT24"; fi
set +e
ERR24="$(env -i "PATH=$FB24:/usr/bin:/bin" "HOME=$HMW" "HYER_HOME=$WORK/nonexistent24" "SEC_TEST_NODE_LOG=$NLOG" "$REPO_ROOT/bin/hyer-mcp.sh" 2>&1)"
RC24B=$?
set -e
if [[ $RC24B -ne 0 ]] && grep -q '^\[ERROR\]' <<<"$ERR24" && grep -q "HYER_HOME" <<<"$ERR24"; then
    pass "missing checkout: tagged [ERROR] naming HYER_HOME, non-zero exit"
else
    fail "missing-checkout diagnostic wrong (rc=$RC24B): $ERR24"
fi
if [[ -f "$REPO_ROOT/.mcp.json.example" ]] && ! grep -q '/home/opc' "$REPO_ROOT/.mcp.json.example" && ! grep -q '"command": "sh"' "$REPO_ROOT/.mcp.json.example"; then
    pass "tracked .mcp.json.example has no host path and no sh -c"
else
    fail ".mcp.json.example missing or still carries /home/opc or sh -c"
fi
if grep -q 'hyer-mcp.sh' "$REPO_ROOT/.mcp.json.example" 2>/dev/null; then pass "example wires bin/hyer-mcp.sh"; else fail "example does not reference bin/hyer-mcp.sh"; fi
if grep -qE '^\.mcp\.json$' "$REPO_ROOT/.gitignore"; then pass ".mcp.json gitignored (host-local)"; else fail ".mcp.json not in .gitignore"; fi
if git -C "$REPO_ROOT" ls-files --error-unmatch .mcp.json >/dev/null 2>&1; then fail ".mcp.json still tracked (host-local config must not be committed)"; else pass ".mcp.json untracked"; fi
if grep -q '/home/opc' "$REPO_ROOT/bin/hyer-mcp.sh" 2>/dev/null; then fail "wrapper hardcodes /home/opc"; else pass "wrapper has no hardcoded host path"; fi

echo
if [[ $FAILS -eq 0 ]]; then
    echo "ALL TESTS PASSED"
    exit 0
fi
echo "$FAILS test(s) failed"
exit 1
