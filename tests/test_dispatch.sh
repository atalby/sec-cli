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
printf 'bw %s\n' "${*//$'\n'/ }" >>"${SEC_TEST_BW_LOG:?SEC_TEST_BW_LOG unset}"
DEFAULT_ITEMS='[{"id":"item-1","name":"MY_API_KEY","notes":null,"login":{"password":"pw-MY_API_KEY","username":"me@example.com","uris":[]},"fields":[],"folderId":""},{"id":"item-2","name":"github-app","notes":null,"login":{"password":"gh-pw","username":"gh-user","uris":[]},"fields":[{"type":0,"name":"token","value":"cf-token"}],"folderId":""}]'
ITEMS="${SEC_TEST_BW_ITEMS:-$DEFAULT_ITEMS}"
case "${1:-}" in
    status)
        if [ -n "${SEC_TEST_BW_STATUS_RC:-}" ]; then
            echo "Error: vault is locked." >&2
            exit "${SEC_TEST_BW_STATUS_RC}"
        fi
        if [ -n "${SEC_TEST_BW_STATUS_GARBAGE:-}" ]; then
            echo 'GARBAGE{{{not-json'
            exit 0
        fi
        echo '{"status":"unlocked"}'
        ;;
    sync)
        exit 0
        ;;
    list)
        case "${2:-}" in
            items)
                if [ "${SEC_TEST_BW_LIST_RC:-0}" != "0" ]; then
                    echo "Error: vault is locked." >&2
                    exit "${SEC_TEST_BW_LIST_RC}"
                fi
                shift 2
                SEARCH_Q=""
                FOLDER_ID=""
                while [ $# -gt 0 ]; do
                    case "$1" in
                        --search) SEARCH_Q="${2:-}"; shift 2 ;;
                        --folderid) FOLDER_ID="${2:-}"; shift 2 ;;
                        *) shift ;;
                    esac
                done
                if [ -n "${SEC_TEST_BW_FAIL_SEARCH:-}" ] && [ "$SEARCH_Q" = "${SEC_TEST_BW_FAIL_SEARCH:-}" ]; then
                    echo "Error: vault is locked." >&2
                    exit 1
                fi
                if [ -n "$FOLDER_ID" ]; then
                    if [ "$FOLDER_ID" = "null" ]; then
                        items="$(jq -c '[.[] | select((.folderId // "") == "")]' <<<"$ITEMS")"
                    else
                        items="$(jq -c --arg f "$FOLDER_ID" '[.[] | select(.folderId == $f)]' <<<"$ITEMS")"
                    fi
                else
                    items="$ITEMS"
                fi
                if [ -n "$SEARCH_Q" ]; then
                    jq -c --arg q "$SEARCH_Q" '[.[] | select(.name | contains($q))]' <<<"$items"
                else
                    echo "$items"
                fi
                ;;
            folders)
                if [ "${SEC_TEST_BW_FOLDERS_RC:-0}" != "0" ]; then
                    echo "Error: vault is locked." >&2
                    exit "${SEC_TEST_BW_FOLDERS_RC}"
                fi
                if [ -n "${SEC_TEST_BW_FOLDERS:-}" ]; then
                    echo "${SEC_TEST_BW_FOLDERS}"
                else
                    echo '[{"id":"f-aaa","name":"work"},{"id":"f-bbb","name":"home"}]'
                fi
                ;;
        esac
        ;;
    get)
        case "${2:-}" in
            template)
                if [ -n "${SEC_TEST_BW_TEMPLATE_RC:-}" ]; then
                    echo "bw: raw backend diagnostic TOKEN-abc123" >&2
                    exit "${SEC_TEST_BW_TEMPLATE_RC}"
                fi
                echo '{"id":"","name":"","type":1,"login":{},"notes":""}' ;;
            item)
                if [ -n "${SEC_TEST_BW_GET_ITEM_RC:-}" ]; then
                    echo "Error: item not readable." >&2
                    exit "${SEC_TEST_BW_GET_ITEM_RC}"
                fi
                echo '{"id":"item-1","name":"MY_API_KEY","login":{"password":"pw-MY_API_KEY","username":"me@example.com"},"notes":null,"fields":[]}'
                ;;
            attachment) echo "attachment-content" ;;
        esac
        ;;
    encode)
        if [ -n "${SEC_TEST_BW_ENCODE_RC:-}" ]; then
            echo "Error: encode failed." >&2
            exit "${SEC_TEST_BW_ENCODE_RC}"
        fi
        if [ "${SEC_TEST_BW_ENCODE_EMPTY:-0}" != "0" ]; then
            exit 0
        fi
        cat
        ;;
    create)
        if [ "${SEC_TEST_BW_CREATE_RC:-0}" != "0" ]; then
            echo "Error: vault is locked." >&2
            exit "${SEC_TEST_BW_CREATE_RC}"
        fi
        if [ ! -t 0 ]; then cat >>"${SEC_TEST_BW_LOG:?SEC_TEST_BW_LOG unset}"; fi
        echo '{"id":"created-1"}'
        ;;
    edit)
        if [ ! -t 0 ]; then cat >>"${SEC_TEST_BW_LOG:?SEC_TEST_BW_LOG unset}"; fi
        echo '{"id":"item-1"}'
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
        if [ "${SEC_TEST_OP_WHOAMI_RC:-0}" != "0" ] && [ ! -f "${HOME}/.cache/op-signedin" ]; then
            exit 1
        fi
        case "${2:-}" in
            op://private/MY_API_KEY/password) echo "op-pw-MY_API_KEY" ;;
            op://*/MY_API_KEY/password)
                vault_part="${2#op://}"
                echo "op-pw-vault-${vault_part%%/*}"
                ;;
            *) exit 1 ;;
        esac
        ;;
    whoami)
        if [ -f "${HOME}/.cache/op-signedin" ]; then exit 0; fi
        exit "${SEC_TEST_OP_WHOAMI_RC:-0}"
        ;;
    signin)
        if [ "${SEC_TEST_OP_SIGNIN_RC:-0}" = "0" ]; then
            mkdir -p "${HOME}/.cache"
            touch "${HOME}/.cache/op-signedin"
            echo "export OP_SESSION_TEST=1"
        fi
        exit "${SEC_TEST_OP_SIGNIN_RC:-0}"
        ;;
    item)
        case "${2:-}" in
            list) echo '[{"id":"op-1","title":"OP Item","tags":[]}]' ;;
            create)
                if [ ! -t 0 ]; then cat >/dev/null; fi
                if [ "${SEC_TEST_OP_ITEM_CREATE_RC:-0}" != "0" ]; then
                    echo "Error: could not create item." >&2
                    exit "${SEC_TEST_OP_ITEM_CREATE_RC}"
                fi
                echo '{"id":"op-created"}' ;;
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
        if [ -n "${SEC_TEST_BWS_PROJ_RC:-}" ]; then
            echo "Error: BWS_ACCESS_TOKEN missing." >&2
            exit "${SEC_TEST_BWS_PROJ_RC}"
        fi
        if [ "${SEC_TEST_BWS_NOPROJ:-0}" != "0" ]; then
            echo '[]'
            exit 0
        fi
        echo '[{"id":"proj-1","name":"p"}]'
        ;;
    "secret create")
        if [ "${SEC_TEST_BWS_CREATE_RC:-0}" != "0" ]; then
            echo "Error: could not create secret." >&2
            exit "${SEC_TEST_BWS_CREATE_RC}"
        fi
        echo '{"id":"bws-created"}'
        ;;
    "run --")
        shift 2
        exec "$@"
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
    "kv put") if [ ! -t 0 ]; then cat >/dev/null; fi ;;
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
if [ "${1:-}" = "run" ]; then
    shift
    [ "${1:-}" = "--" ] && shift
    exec "$@"
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

echo "[2] unknown command fails loudly: exit 2 + tagged error, not a silent usage + exit 0"
set +e
OUT="$(run_sec "$H" frobnicate 2>&1)"
RC=$?
set -e
if [[ $RC -eq 2 ]] && grep -q "^\[ERROR\] unknown command" <<<"$OUT"; then pass "unknown cmd exits 2 with a tagged error"; else fail "unknown cmd rc=$RC out=$OUT"; fi

echo "[2b] missing/invalid operand fails loudly: exit 2 + tagged error, not a silent usage/success"
assert_usage_error() {
    local label="$1"; shift
    local out rc
    set +e
    out="$(run_sec "$H" "$@" 2>&1)"
    rc=$?
    set -e
    if [[ $rc -eq 2 ]] && grep -q "^\[ERROR\]" <<<"$out"; then
        pass "$label -> exit 2 + tagged error"
    else
        fail "$label rc=$rc out=$out"
    fi
}
assert_usage_error "sec get" get
assert_usage_error "sec set" set
assert_usage_error "sec create" create
assert_usage_error "sec run" run
assert_usage_error "sec get --scope" get --scope
assert_usage_error "sec run --" run --
assert_usage_error "sec completion bogus" completion bogus
assert_usage_error "sec set --type" set --type
assert_usage_error "sec set --type bogus" set --type bogus SOME_KEY someval
assert_usage_error "sec create --type bogus" create --type bogus SOME_KEY someval
assert_usage_error "sec housekeep bogus" housekeep bogus
assert_usage_error "sec organize bogus" organize bogus

echo "[2b2] housekeep/organize --help exits 0 with usage (issue #69)"
set +e
OUT="$(run_sec "$H" housekeep --help 2>&1)"; RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "housekeep {plan|apply|revert}" <<<"$OUT"; then pass "sec housekeep --help exits 0 with usage"; else fail "sec housekeep --help rc=$RC out=[$OUT]"; fi
set +e
OUT="$(run_sec "$H" organize --help 2>&1)"; RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "organize {plan|apply|revert}" <<<"$OUT"; then pass "sec organize --help exits 0 with usage"; else fail "sec organize --help rc=$RC out=[$OUT]"; fi

echo "[2b3] sec-organizer direct invalid subcommand fails loudly (tagged, exit 2) (issue #69)"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H" "$REPO_ROOT/bin/sec-organizer" frobnicate 2>&1 </dev/null)"; RC=$?
set -e
if [[ $RC -eq 2 ]] && grep -q "^\[ERROR\]" <<<"$OUT"; then pass "sec-organizer frobnicate -> exit 2 + tagged error"; else fail "sec-organizer frobnicate rc=$RC out=[$OUT]"; fi

echo "[2c] set/create with no value on a non-TTY fails with a tagged error, not a silent read-EOF death (issue #42)"
set +e
OUT="$(run_sec "$H" set NEWKEY 2>&1)"; RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q '^\[ERROR\]' <<<"$OUT"; then pass "set NEWKEY (no value, no TTY) -> exit 1 + tagged error"; else fail "set NEWKEY rc=$RC out=[$OUT]"; fi
set +e
OUT="$(run_sec "$H" create NEWNOTE 2>&1)"; RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q '^\[ERROR\]' <<<"$OUT"; then pass "create NEWNOTE (no value, no TTY) -> exit 1 + tagged error"; else fail "create NEWNOTE rc=$RC out=[$OUT]"; fi

echo "[2d] sec migrate usage/help contract: missing operand/flag -> exit 2 tagged; --help -> exit 0 (issue #48)"
assert_usage_error "sec migrate" migrate
assert_usage_error "sec migrate --from" migrate --from
assert_usage_error "sec migrate --to" migrate --to
assert_usage_error "sec migrate --bogus" migrate --bogus
set +e
OUT="$(run_sec "$H" migrate --help 2>&1)"; RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "sec migrate --from" <<<"$OUT" && grep -q -- "--plan" <<<"$OUT"; then pass "sec migrate --help prints usage (documents --plan) and exits 0"; else fail "sec migrate --help rc=$RC out=[$OUT]"; fi
set +e
OUT="$(run_sec "$H" migrate -h 2>&1)"; RC=$?
set -e
if [[ $RC -eq 0 ]]; then pass "sec migrate -h exits 0"; else fail "sec migrate -h rc=$RC out=[$OUT]"; fi

echo "[2d2] sec migrate rejects an unsupported destination up front (issue #72)"
set +e
OUT="$(run_sec "$H" migrate --from bw --to bogus --plan 2>&1)"; RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] Destination backend 'bogus' not supported" <<<"$OUT"; then pass "migrate --to bogus --plan -> exit 1 + tagged error"; else fail "migrate --to bogus --plan rc=$RC out=[$OUT]"; fi
if grep -q "Ready to migrate" <<<"$OUT"; then fail "migrate --to bogus still printed a Ready-to-migrate plan: $OUT"; else pass "migrate --to bogus printed no plan"; fi
set +e
OUT="$(run_sec "$H" migrate --from bw --to bogus --apply 2>&1)"; RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] Destination backend 'bogus' not supported" <<<"$OUT"; then pass "migrate --to bogus --apply -> exit 1 + tagged error"; else fail "migrate --to bogus --apply rc=$RC out=[$OUT]"; fi
if grep -q "Migration Successfully Completed" <<<"$OUT"; then fail "migrate --to bogus --apply still reported success: $OUT"; else pass "migrate --to bogus --apply reported no false success"; fi

echo "[2d4] sec migrate rejects destination-only backends as --from up front (issue #168)"
set +e
OUT="$(run_sec "$H" migrate --from infisical --to bw --plan 2>&1)"; RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] Source backend 'infisical' not supported" <<<"$OUT"; then pass "migrate --from infisical --plan -> exit 1 + tagged error"; else fail "migrate --from infisical --plan rc=$RC out=[$OUT]"; fi
if grep -q "Ready to migrate" <<<"$OUT"; then fail "migrate --from infisical still printed a migration plan: $OUT"; else pass "migrate --from infisical printed no plan"; fi
set +e
OUT="$(run_sec "$H" migrate --from vault --to bw --plan 2>&1)"; RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] Source backend 'vault' not supported" <<<"$OUT"; then pass "migrate --from vault --plan -> exit 1 + tagged error"; else fail "migrate --from vault --plan rc=$RC out=[$OUT]"; fi
if grep -q "Ready to migrate" <<<"$OUT"; then fail "migrate --from vault still printed a migration plan: $OUT"; else pass "migrate --from vault printed no plan"; fi

echo "[2d3] sec migrate undo/revert/--undo reject trailing operands before any rollback (issue #110)"
assert_usage_error "sec migrate undo EXTRA" migrate undo EXTRA
assert_usage_error "sec migrate --undo EXTRA" migrate --undo EXTRA
assert_usage_error "sec migrate revert EXTRA" migrate revert EXTRA
set +e
OUT="$(run_sec "$H" migrate undo EXTRA 2>&1)"; RC=$?
set -e
if [[ $RC -eq 2 ]] && grep -q '^\[ERROR\] sec migrate undo: unexpected trailing argument' <<<"$OUT" && ! grep -q 'Reverting Last Secret Migration Operation' <<<"$OUT"; then pass "undo EXTRA refused before the rollback banner"; else fail "undo EXTRA rc=$RC out=[$OUT]"; fi

echo "[2e] get/set/unlock reject unknown -flags at the operand position instead of misparsing them (issue #71)"
assert_usage_error "sec get --bogus <key>" get --bogus MY_API_KEY
assert_usage_error "sec get --bogus (no key)" get --bogus
assert_usage_error "sec get -x <key>" get -x MY_API_KEY
assert_usage_error "sec get --scope work --bogus <key>" get --scope work --bogus MY_API_KEY
assert_usage_error "sec set --bogus <key> <val>" set --bogus MY_KEY someval
assert_usage_error "sec create --bogus <key> <val>" create --bogus MY_KEY someval
assert_usage_error "sec set --type note --bogus <key> <val>" set --type note --bogus MY_KEY someval
assert_usage_error "sec set -t <key> <val>" set -t MY_KEY someval
assert_usage_error "sec unlock --bogus" unlock --bogus
assert_usage_error "sec rotate --bogus" rotate --bogus
assert_usage_error "sec keep --bogus" keep --bogus
assert_usage_error "sec unlock -x" unlock -x
set +e
BWLOG_BEFORE="$(wc -c <"$BWLOG")"
OUT="$(run_sec "$H" get --bogus MY_API_KEY 2>&1)"; RC=$?
set -e
if [[ $RC -eq 2 ]] && grep -q '^\[ERROR\] sec get: unknown flag' <<<"$OUT" && [[ "$(wc -c <"$BWLOG")" -eq "$BWLOG_BEFORE" ]]; then pass "get --bogus refused before any backend call"; else fail "get --bogus rc=$RC bwlog_changed=$([[ "$(wc -c <"$BWLOG")" -eq "$BWLOG_BEFORE" ]] && echo no || echo yes) out=[$OUT]"; fi

echo "[2f] get/set/create reject trailing operands instead of silently dropping them (issue #74)"
assert_usage_error "sec get <key> extra" get MY_API_KEY extra
assert_usage_error "sec get --scope work <key> extra" get --scope work MY_API_KEY extra
assert_usage_error "sec set <key> <val> extra" set MY_KEY someval extra
assert_usage_error "sec create <key> <val> extra" create MY_KEY someval extra
assert_usage_error "sec set --type note <key> <val> extra" set --type note MY_KEY someval extra
set +e
BWLOG_BEFORE="$(wc -c <"$BWLOG")"
OUT="$(run_sec "$H" get MY_API_KEY extra 2>&1)"; RC=$?
set -e
if [[ $RC -eq 2 ]] && grep -q '^\[ERROR\] sec get: unexpected trailing argument' <<<"$OUT" && [[ "$(wc -c <"$BWLOG")" -eq "$BWLOG_BEFORE" ]]; then pass "get <key> extra refused before any backend call"; else fail "get <key> extra rc=$RC bwlog_changed=$([[ "$(wc -c <"$BWLOG")" -eq "$BWLOG_BEFORE" ]] && echo no || echo yes) out=[$OUT]"; fi

echo "[2h] housekeep/organize + unlock/rotate/keep/setup-keychain reject trailing operands pre-exec (issue #76)"
assert_usage_error "sec housekeep plan trailing" housekeep plan TRAILING
assert_usage_error "sec housekeep plan --bogus" housekeep plan --bogus
assert_usage_error "sec housekeep apply trailing" housekeep apply TRAILING
assert_usage_error "sec housekeep revert trailing" housekeep revert TRAILING
assert_usage_error "sec organize apply --bogus" organize apply --bogus
assert_usage_error "sec rotate trailing" rotate TRAILING
assert_usage_error "sec keep trailing" keep TRAILING
assert_usage_error "sec unlock pw1 pw2" unlock pw1 pw2
assert_usage_error "sec setup-keychain pw1 pw2" setup-keychain pw1 pw2
set +e
BPROG_BEFORE="$(wc -c <"$BWLOG")"
OUT="$(run_sec "$H" rotate TRAILING 2>&1)"; RC=$?
set -e
if [[ $RC -eq 2 ]] && grep -q '^\[ERROR\] sec rotate: unexpected trailing argument' <<<"$OUT" && [[ "$(wc -c <"$BWLOG")" -eq "$BPROG_BEFORE" ]]; then pass "rotate TRAILING refused before any keeper/backend call"; else fail "rotate TRAILING rc=$RC bwlog_changed=$([[ "$(wc -c <"$BWLOG")" -eq "$BPROG_BEFORE" ]] && echo no || echo yes) out=[$OUT]"; fi

echo "[2i] sec completion rejects trailing operands instead of silently dropping them (issue #99)"
assert_usage_error "sec completion zsh EXTRA" completion zsh EXTRA
assert_usage_error "sec completion bash EXTRA" completion bash EXTRA
assert_usage_error "sec completion fish EXTRA" completion fish EXTRA
assert_usage_error "sec completion ps1 EXTRA" completion ps1 EXTRA
set +e
OUT="$(run_sec "$H" completion zsh EXTRA 2>&1)"; RC=$?
set -e
if [[ $RC -eq 2 ]] && grep -q '^\[ERROR\] sec completion: unexpected trailing argument' <<<"$OUT" && ! grep -qE '#compdef|completion for sec-cli|_sec_bash_completion' <<<"$OUT"; then pass "completion zsh EXTRA refused before emitting a script"; else fail "completion zsh EXTRA rc=$RC out=[$OUT]"; fi

echo "[2j] sec help/version reject trailing operands instead of silently dropping them (issue #100)"
assert_usage_error "sec help EXTRA" help EXTRA
assert_usage_error "sec --help EXTRA" --help EXTRA
assert_usage_error "sec version EXTRA" version EXTRA
assert_usage_error "sec -v EXTRA" -v EXTRA
set +e
OUT="$(run_sec "$H" help EXTRA 2>&1)"; RC=$?
set -e
if [[ $RC -eq 2 ]] && grep -q '^\[ERROR\] sec help: unexpected trailing argument' <<<"$OUT" && ! grep -q 'Usage:' <<<"$OUT"; then pass "sec help EXTRA refused before printing the help menu"; else fail "sec help EXTRA rc=$RC out=[$OUT]"; fi

echo "[2k] sec --help lists a usage line for every canonical subcommand (issue #101)"
U="$(run_sec "$H" --help 2>&1)"
_miss=0
for t in get set run sync housekeep migrate unlock rotate setup-keychain completion; do
    grep -qE "^  sec (\[<tenant>\] )?$t([ {]|\$)" <<<"$U" || { fail "sec --help omits the '$t' subcommand; ADAPTERS.md:101 claims it lists every subcommand (issue #101)"; _miss=1; }
done
_ARMS="$(grep -oE '^    [a-z][a-z|-]*\)$' "$REPO_ROOT/bin/sec" | sed -E 's/^ +//; s/\)$//')"
_ARM_N="$(grep -c . <<<"$_ARMS")"
if [[ "$_ARM_N" -lt 8 ]]; then
    fail "expected at least 8 non-flag dispatch arms parsed from bin/sec, got $_ARM_N (issue #101)"; _miss=1
fi
while IFS= read -r arm; do
    [[ -n "$arm" ]] || continue
    tok="${arm%%|*}"
    grep -qE "^  sec (\[<tenant>\] )?$tok([ {]|\$)" <<<"$U" || { fail "dispatch arm '$arm' has no usage line in sec --help (issue #101)"; _miss=1; }
done <<<"$_ARMS"
if [[ $_miss -eq 0 ]]; then pass "sec --help lists a usage line for every canonical subcommand and every non-flag dispatch arm"; fi

echo "[2l] the canonical tenant set is identical across dispatch, usage, and all four completions (issue #102)"
ZF="$(bash "$REPO_ROOT/bin/sec" completion zsh 2>&1)"
BF="$(bash "$REPO_ROOT/bin/sec" completion bash 2>&1)"
FF="$(bash "$REPO_ROOT/bin/sec" completion fish 2>&1)"
PF="$(bash "$REPO_ROOT/bin/sec" completion ps1 2>&1)"
_miss=0
grep -qF '^(bitwarden|bw|1pass|op|bws|vault|infisical|keychain)$' "$REPO_ROOT/bin/sec" || { fail "dispatch tenant-prefix regex drifted from the canonical set (issue #102)"; _miss=1; }
grep -qF 'Configured Tenants: bitwarden (bw), 1pass (op), bws, vault, infisical, keychain' <<<"$U" || { fail "sec --help 'Configured Tenants' line drifted from the canonical set (issue #102)"; _miss=1; }
grep -qF 'tenants=(bitwarden bw 1pass op bws vault infisical keychain)' <<<"$ZF" || { fail "zsh completion tenant list drifted from the canonical set (issue #102)"; _miss=1; }
grep -qF 'tenants="bitwarden bw 1pass op bws vault infisical keychain"' <<<"$BF" || { fail "bash completion tenant list drifted from the canonical set (issue #102)"; _miss=1; }
grep -qF -- "-a 'bitwarden bw 1pass op bws vault infisical keychain'" <<<"$FF" || { fail "fish completion tenant list drifted from the canonical set (issue #102)"; _miss=1; }
grep -qF "@('bitwarden', 'bw', '1pass', 'op', 'bws', 'vault', 'infisical', 'keychain')" <<<"$PF" || { fail "ps1 completion tenant list drifted from the canonical set (issue #102)"; _miss=1; }
if [[ $_miss -eq 0 ]]; then pass "the canonical tenant set is identical across the dispatcher, usage, and all four completions"; fi

echo "[2m] every completion surface offers every dispatcher subcommand (issue #103)"
_sub_n=15
_to_arms="$(grep -oE '^    [a-z][a-z|-]*\)$' "$REPO_ROOT/bin/sec" | sed -E 's/^ +//; s/\)$//')"
_to_help="$(grep -oE '^    -[a-z]\|--[a-z]+\|[a-z]+\)$' "$REPO_ROOT/bin/sec" | sed -E 's/^ +//; s/\)$//' | cut -d'|' -f3)"
_to_sub="$(printf '%s\n%s\n' "$(tr '|' '\n' <<<"$_to_arms")" "$_to_help" | grep -v '^$' | sort -u)"
to_z="$(sed -n '/^    local -a subcommands=(/,/^    )$/p' <<<"$ZF" | grep -oE "^        '[a-z0-9|-]+:" | tr -d " ':" | sort -u)"
to_b="$(sed -n 's/^ *subcmds="\(.*\)"$/\1/p' <<<"$BF" | tr ' ' '\n' | grep -vE '^-' | sort -u)"
to_f="$(grep -oE -- "-a '[a-z0-9][a-z0-9-]*' -d" <<<"$FF" | grep -oE "'[^']+'" | tr -d "'" | sort -u)"
to_p="$(sed -n 's/.*\$subcommands = @(\(.*\))/\1/p' <<<"$PF" | grep -oE "'[^']+'" | tr -d "'" | sort -u)"
to_miss=0
if [[ "$(grep -c . <<<"$_to_sub")" -ne "$_sub_n" ]]; then
    fail "dispatcher offers $(grep -c . <<<"$_to_sub") subcommand tokens, expected $_sub_n (issue #103)"; to_miss=1
fi
for to_pair in "zsh:$to_z" "bash:$to_b" "fish:$to_f" "ps1:$to_p"; do
    to_name="${to_pair%%:*}"; to_list="${to_pair#*:}"
    if [[ "$(grep -c . <<<"$to_list")" -ne "$_sub_n" ]]; then
        fail "$to_name completion parsed $(grep -c . <<<"$to_list") subcommands, expected $_sub_n (issue #103)"; to_miss=1
    fi
    while IFS= read -r to_tok; do
        [[ -n "$to_tok" ]] || continue
        grep -qxF "$to_tok" <<<"$to_list" || { fail "$to_name completion omits the '$to_tok' subcommand the dispatcher offers (issue #103; ADAPTERS.md:264 claims every surface covers every subcommand)"; to_miss=1; }
    done <<<"$_to_sub"
done
if [[ $to_miss -eq 0 ]]; then pass "every completion surface offers every dispatcher subcommand ($_sub_n tokens each, zsh/bash/fish/ps1)"; fi

echo "[2g] sec get --scope rejects a flag-like folder name (issue #75)"
assert_usage_error "sec get --scope --bogus <key>" get --scope --bogus MY_API_KEY
assert_usage_error "sec get --scope -x <key>" get --scope -x MY_API_KEY
set +e
BWLOG_BEFORE="$(wc -c <"$BWLOG")"
OUT="$(run_sec "$H" get --scope --bogus MY_API_KEY 2>&1)"; RC=$?
set -e
if [[ $RC -eq 2 ]] && grep -q '^\[ERROR\] sec get --scope: invalid name' <<<"$OUT" && [[ "$(wc -c <"$BWLOG")" -eq "$BWLOG_BEFORE" ]]; then pass "get --scope --bogus refused before any backend call"; else fail "get --scope --bogus rc=$RC bwlog_changed=$([[ "$(wc -c <"$BWLOG")" -eq "$BWLOG_BEFORE" ]] && echo no || echo yes) out=[$OUT]"; fi

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

echo "[4b] bw get: custom-field fallback finds a field across all vault items"
set +e
OUT="$(run_sec "$H" get token 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && [[ "$OUT" == "cf-token" ]]; then pass "bw get token -> cf-token (custom-field fallback)"; else fail "custom-field get rc=$RC out=$OUT"; fi

echo "[4c] bw get: item/attachment/filename subpath"
set +e
OUT="$(run_sec "$H" get MY_API_KEY/attachment/secret.txt 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && [[ "$OUT" == "attachment-content" ]]; then pass "bw get item/attachment/file -> attachment-content"; else fail "attachment get rc=$RC out=$OUT"; fi

echo "[4d] attachment item lookup: a failing list must exit 1 with a tagged error, not leak a jq parse error as exit 4 (#164)"
H4D="$(new_home "$WORK/h4d")"
set +e
OUT4D="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H4D" \
    "SEC_TEST_BW_FAIL_SEARCH=MY_API_KEY" "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" \
    "SEC_TEST_BWS_LOG=$BWSLOG" "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/sec" bw get MY_API_KEY/attachment/secret.txt 2>&1 </dev/null)"
RC4D=$?
set -e
if [[ $RC4D -eq 1 ]]; then pass "attachment lookup failure exits 1 (not jq's 4)"; else fail "attachment lookup failure rc=$RC4D (expected 1) out=$OUT4D"; fi
if grep -qi "parse error" <<<"$OUT4D"; then fail "raw jq parse error leaked to the user: $OUT4D"; else pass "no raw jq parse error in the output"; fi
if grep -q "^\[ERROR\]" <<<"$OUT4D"; then pass "attachment lookup failure emits a tagged [ERROR]"; else fail "no tagged [ERROR] in: $OUT4D"; fi
if grep -q "attachment-content" <<<"$OUT4D"; then fail "failed lookup still reported attachment content: $OUT4D"; else pass "failed lookup reports no content"; fi
set +e
OUT4DH="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H4D" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" \
    "SEC_TEST_BWS_LOG=$BWSLOG" "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/sec" bw get MY_API_KEY/attachment/secret.txt 2>&1 </dev/null)"
RC4DH=$?
set -e
if [[ $RC4DH -eq 0 ]] && [[ "$OUT4DH" == "attachment-content" ]]; then pass "attachment happy path still works after the guard fix"; else fail "attachment happy path rc=$RC4DH out=$OUT4DH"; fi
set +e
OUT4DMISS="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H4D" \
    "SEC_TEST_BW_FAIL_SEARCH=github-app" "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" \
    "SEC_TEST_BWS_LOG=$BWSLOG" "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/sec" bw get github-app/attachment/report.pdf 2>&1 </dev/null)"
RC4DMISS=$?
set -e
if [[ $RC4DMISS -eq 1 ]]; then pass "attachment lookup failure on a second item name also exits 1"; else fail "second item rc=$RC4DMISS (expected 1) out=$OUT4DMISS"; fi

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

echo "[10b] bw set --type note/card/identity dispatches the item type"
: >"$BWLOG"
set +e
OUT="$(run_sec "$H" set --type note NOTE_KEY noteval 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q '"type": 2' "$BWLOG"; then pass "set --type note -> type 2 in create payload"; else fail "set --type note rc=$RC out=$OUT log=$(tr '\n' ';' <"$BWLOG")"; fi
: >"$BWLOG"
set +e
OUT="$(run_sec "$H" set --type card CARD_KEY cardval 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q '"type": 3' "$BWLOG"; then pass "set --type card -> type 3 in create payload"; else fail "set --type card rc=$RC out=$OUT log=$(tr '\n' ';' <"$BWLOG")"; fi
: >"$BWLOG"
set +e
OUT="$(run_sec "$H" set --type identity IDENT_KEY identval 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q '"type": 4' "$BWLOG"; then pass "set --type identity -> type 4 in create payload"; else fail "set --type identity rc=$RC out=$OUT log=$(tr '\n' ';' <"$BWLOG")"; fi

echo "[10c] bw set: item/field subpath updates the field via bw edit"
: >"$BWLOG"
set +e
OUT="$(run_sec "$H" set MY_API_KEY/username newuser 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "edit item" "$BWLOG"; then pass "set item/field -> bw edit item"; else fail "set field rc=$RC out=$OUT log=$(tr '\n' ';' <"$BWLOG")"; fi
if grep -q "updated in Bitwarden Vault" <<<"$OUT"; then pass "field update reports updated"; else fail "no updated msg: $OUT"; fi

echo "[11] op set create path"
set +e
OUT="$(run_sec "$H" op set NEW_OP_KEY newopval 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]]; then pass "op set exits 0"; else fail "op set rc=$RC out=$OUT"; fi
if grep -q "saved to 1Password" <<<"$OUT"; then pass "reports saved-to-1Password"; else fail "no saved-to-1Password in: $OUT"; fi

echo "[11b] bws set create path"
: >"$BWSLOG"
set +e
OUT="$(run_sec "$H" bws set BWS_KEY bwsval 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "saved to Bitwarden Secrets Manager" <<<"$OUT"; then pass "bws set reports saved-to-BWS"; else fail "bws set rc=$RC out=$OUT"; fi
if grep -q "secret create BWS_KEY bwsval proj-1" "$BWSLOG"; then pass "bws secret create called with key/value/proj"; else fail "unexpected bws create call: $(tr '\n' ';' <"$BWSLOG")"; fi

echo "[11d] set failures name the failing stage, never the secret value (#162)"
set +e
OUTD1="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H" "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_BW_CREATE_RC=1" "$REPO_ROOT/bin/sec" set NEW_BW_KEY bw-stage-val </dev/null 2>&1)"
RC=$?
set -e
if [[ $RC -ne 0 ]]; then pass "bw create failure exits nonzero"; else fail "bw create failure rc=$RC out=$OUTD1"; fi
if grep -q "(stage: bw create item)" <<<"$OUTD1"; then pass "bw failure names the bw create item stage"; else fail "bw failure does not name its stage: $OUTD1"; fi

set +e
OUTD2="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_OP_ITEM_CREATE_RC=1" "$REPO_ROOT/bin/sec" op set NEW_OP_KEY op-stage-val </dev/null 2>&1)"
RC=$?
set -e
if [[ $RC -ne 0 ]]; then pass "op item create failure exits nonzero"; else fail "op item create failure rc=$RC out=$OUTD2"; fi
if grep -q "(stage: op item create)" <<<"$OUTD2"; then pass "op failure names the op item create stage"; else fail "op failure does not name its stage: $OUTD2"; fi

set +e
OUTD3="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H" "SEC_TEST_BWS_LOG=$BWSLOG" "SEC_TEST_BWS_NOPROJ=1" "$REPO_ROOT/bin/sec" bws set NEW_BWS_KEY bws-stage-val </dev/null 2>&1)"
RC=$?
set -e
if [[ $RC -ne 0 ]]; then pass "bws no-project failure exits nonzero"; else fail "bws no-project failure rc=$RC out=$OUTD3"; fi
if grep -q "(stage: bws project list returned no project id)" <<<"$OUTD3"; then pass "bws failure names the missing-project-id stage"; else fail "bws no-project failure does not name its stage: $OUTD3"; fi

set +e
OUTD4="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H" "SEC_TEST_BWS_LOG=$BWSLOG" "SEC_TEST_BWS_CREATE_RC=1" "$REPO_ROOT/bin/sec" bws set NEW_BWS_KEY bws-stage-val </dev/null 2>&1)"
RC=$?
set -e
if [[ $RC -ne 0 ]]; then pass "bws secret create failure exits nonzero"; else fail "bws secret create failure rc=$RC out=$OUTD4"; fi
if grep -q "(stage: bws secret create)" <<<"$OUTD4"; then pass "bws failure names the bws secret create stage"; else fail "bws create failure does not name its stage: $OUTD4"; fi

set +e
OUTD5="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H" "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_BW_ENCODE_EMPTY=1" "$REPO_ROOT/bin/sec" set NEW_ENC_KEY enc-stage-val </dev/null 2>&1)"
RC=$?
set -e
if [[ $RC -ne 0 ]]; then pass "bw empty-payload failure exits nonzero"; else fail "bw empty-payload failure rc=$RC out=$OUTD5"; fi
if grep -q "(stage: payload build (bw get template item | jq | bw encode) produced no output)" <<<"$OUTD5"; then pass "bw empty payload names the payload-build stage, not the create"; else fail "bw empty payload misnames its stage: $OUTD5"; fi
if grep -q "enc-stage-val" <<<"$OUTD5"; then fail "bw empty-payload message leaked the secret value: $OUTD5"; else pass "bw empty-payload message omits the secret value"; fi

for LBL in bw op bws-noproj bws-create; do
    case "$LBL" in
        bw) D_OUT="$OUTD1" ;;
        op) D_OUT="$OUTD2" ;;
        bws-noproj) D_OUT="$OUTD3" ;;
        bws-create) D_OUT="$OUTD4" ;;
    esac
    if grep -q "bws-stage-val\|op-stage-val" <<<"$D_OUT"; then fail "$LBL failure message leaked the secret value: $D_OUT"; else pass "$LBL failure message omits the secret value"; fi
    if grep -q "failed to store secret" <<<"$D_OUT"; then pass "$LBL failure still emits the tagged ERROR line"; else fail "$LBL failure lost the tagged ERROR line: $D_OUT"; fi
done

echo "[11e] harness: the op/vault fakes drain the payload a product stage pipes to them (#192)"
BIGVAL="$(head -c 100000 /dev/zero | tr '\0' x)"
set +e
OUT="$(run_sec "$H" op set BIG_OP_KEY "$BIGVAL" 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "saved to 1Password" <<<"$OUT"; then pass "op set with a >pipe-buffer value exits 0 (no EPIPE/SIGPIPE race)"; else fail "op set with a >pipe-buffer value rc=$RC out=[${OUT:0:200}]"; fi
if grep -q "stage: op item create" <<<"$OUT"; then fail "a large op payload was misreported as a stage failure (EPIPE race): ${OUT:0:200}"; else pass "no fabricated 'op item create' stage failure on a large payload"; fi

set +e
OUT="$(printf '%s' "$BIGVAL" | env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H" "SEC_TEST_VAULT_LOG=$VAULTLOG" vault kv put secret/data/BIG value=- 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]]; then pass "the vault fake drains a >pipe-buffer stdin payload"; else fail "vault fake rc=$RC on a >pipe-buffer payload (EPIPE race): ${OUT:0:200}"; fi

echo "[11c] vault/infisical set refuse honestly (unsupported tenant)"
set +e
OUT="$(run_sec "$H" vault set KEY val 2>&1)"
RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "set not supported for tenant 'vault'" <<<"$OUT"; then pass "vault set exits 1 with unsupported-tenant error"; else fail "vault set rc=$RC out=$OUT"; fi
set +e
OUT="$(run_sec "$H" infisical set KEY val 2>&1)"
RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "set not supported for tenant 'infisical'" <<<"$OUT"; then pass "infisical set exits 1 with unsupported-tenant error"; else fail "infisical set rc=$RC out=$OUT"; fi

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

echo "[12b] run dispatch: bws + infisical delegation"
set +e
OUT="$(run_sec "$H" bws run -- echo bws-run-ok 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "bws-run-ok" <<<"$OUT"; then pass "sec bws run -- echo bws-run-ok"; else fail "bws run rc=$RC out=$OUT"; fi
set +e
OUT="$(run_sec "$H" infisical run -- echo inf-run-ok 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "inf-run-ok" <<<"$OUT"; then pass "sec infisical run -- echo inf-run-ok"; else fail "infisical run rc=$RC out=$OUT"; fi

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
if [[ "$(stat -c '%a' "$H2/.cache/bitwarden" 2>/dev/null || stat -f '%Lp' "$H2/.cache/bitwarden")" == "700" ]]; then pass "cache dir created 0700"; else fail "cache dir mode is $(stat -c '%a' "$H2/.cache/bitwarden" 2>/dev/null || stat -f '%Lp' "$H2/.cache/bitwarden"), expected 700"; fi
if [[ -f "$PLAN" && "$(stat -c '%a' "$PLAN" 2>/dev/null || stat -f '%Lp' "$PLAN")" == "600" ]]; then pass "plan file written 0600"; else fail "plan file mode is $(stat -c '%a' "$PLAN" 2>/dev/null || stat -f '%Lp' "$PLAN" 2>/dev/null || echo missing), expected 600"; fi
if jq -e '.actions | length >= 1' "$PLAN" >/dev/null 2>&1; then pass "plan has >=1 action"; else fail "plan actions missing/empty: $(cat "$PLAN" 2>/dev/null)"; fi
if grep -q "^\[INFO\] Plan Summary" <<<"$OUT"; then pass "prints tagged Plan Summary"; else fail "no tagged Plan Summary in: $OUT"; fi
if grep -q "^\[ OK \] Plan saved to" <<<"$OUT"; then pass "prints tagged Plan saved"; else fail "no tagged Plan saved in: $OUT"; fi

echo "[14b] F048: op plan classifies from full item detail, not the id/name/tags projection"
OPBIN="$WORK/opbin"
mkdir -p "$OPBIN"
cat >"$OPBIN/op" <<'EOF'
#!/usr/bin/env bash
case "${1:-} ${2:-}" in
    "item list")
        echo '[{"id":"op-1","title":"item-one","tags":[]}]'
        ;;
    "item get")
        echo '{"id":"op-1","title":"item-one","fields":[{"id":"username","label":"username","value":"a@example.com"},{"id":"password","label":"password","type":"CONCEALED","value":"'"${SEC_TEST_OP_AWS_KEY}"'"}],"urls":[]}'
        ;;
esac
exit 0
EOF
chmod +x "$OPBIN/op"
OP_AWS_TAIL="2233445566778899"
OP_AWS_KEY="AKIA${OP_AWS_TAIL}"
HOP="$(new_home "$WORK/hop")"
set +e
OUTOP="$(env -i "PATH=$OPBIN:/usr/bin:/bin" "HOME=$HOP" "SEC_TEST_OP_AWS_KEY=$OP_AWS_KEY" "$REPO_ROOT/bin/sec" housekeep plan 2>&1 </dev/null)"
RCOP=$?
set -e
PLANOP="$HOP/.cache/bitwarden/housekeep_plan.json"
if [[ $RCOP -eq 0 ]]; then pass "op housekeep plan exits 0"; else fail "op plan rc=$RCOP out=$OUTOP"; fi
if grep -q "Backend: op" <<<"$OUTOP"; then pass "op plan selects the op backend"; else fail "op plan backend is not op: $OUTOP"; fi
OPCAT="$(jq -r '.actions[0].targetFolder // empty' "$PLANOP" 2>/dev/null || true)"
if [[ "$OPCAT" == "cloud/aws" ]]; then pass "op plan sees the full item (AKIA in password -> cloud/aws)"; else fail "op plan category='$OPCAT' (expected cloud/aws; F048 fidelity)"; fi

echo "[14c] F015 class: housekeep plan fails closed on an unparseable bw listing (issue #143)"
H2D="$(new_home "$WORK/h14c")"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2D" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "SEC_TEST_BW_ITEMS=this is not valid json" \
    "$REPO_ROOT/bin/sec" housekeep plan 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] corrupt or unreadable listing from backend 'bw'" <<<"$OUT"; then pass "unparseable bw listing -> exit 1 + tagged error"; else fail "unparseable bw listing rc=$RC out=[$OUT]"; fi
if grep -q "Plan saved" <<<"$OUT"; then fail "unparseable bw listing still saved a false plan: $OUT"; else pass "unparseable bw listing did not save a false plan"; fi

echo "[14d] F015 class: housekeep plan fails closed on a failing bws listing (issue #143)"
BWSBIN2="$WORK/bwsbin2"
mkdir -p "$BWSBIN2"
cat >"$BWSBIN2/bws" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-} ${2:-}" == "secret list" ]]; then
    n=0
    [[ -f "$SEC_TEST_BWS_COUNT" ]] && n="$(cat "$SEC_TEST_BWS_COUNT")"
    n=$((n + 1))
    echo "$n" >"$SEC_TEST_BWS_COUNT"
    if [[ "$n" -le 1 ]]; then
        echo '[]'
        exit 0
    fi
    exit 1
fi
exit 0
EOF
chmod +x "$BWSBIN2/bws"
H2E="$(new_home "$WORK/h14d")"
set +e
OUT="$(env -i "PATH=$BWSBIN2:/usr/bin:/bin" "HOME=$H2E" \
    "SEC_TEST_BWS_COUNT=$WORK/h14d.count" \
    "$REPO_ROOT/bin/sec" housekeep plan 2>&1 </dev/null)"
RC=$?
set -e
if grep -q "Backend: bws" <<<"$OUT"; then pass "bws plan selects the bws backend"; else fail "bws plan backend is not bws: $OUT"; fi
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] corrupt or unreadable listing from backend 'bws'" <<<"$OUT"; then pass "failing bws listing -> exit 1 + tagged error"; else fail "failing bws listing rc=$RC out=[$OUT]"; fi
if grep -q "Plan saved" <<<"$OUT"; then fail "failing bws listing still saved a false plan: $OUT"; else pass "failing bws listing did not save a false plan"; fi

echo "[14e] failure-honesty: housekeep plan fails closed on garbage folders listing, never jq's exit 4 (issue #165)"
H2F="$(new_home "$WORK/h14e")"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2F" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "SEC_TEST_BW_FOLDERS=bw: server error (not json)" \
    "$REPO_ROOT/bin/sec" housekeep plan 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] corrupt or unreadable listing from backend 'bw'" <<<"$OUT"; then pass "garbage folders listing -> exit 1 + tagged error"; else fail "garbage folders listing rc=$RC out=[$OUT]"; fi
if [[ $RC -eq 4 ]]; then fail "garbage folders listing leaked jq's exit 4"; else pass "no jq exit-code leak on garbage folders listing"; fi
if grep -q "parse error" <<<"$OUT"; then fail "garbage folders listing leaked a raw jq parse error: $OUT"; else pass "no raw jq parse error on garbage folders listing"; fi
if grep -q "Plan saved" <<<"$OUT"; then fail "garbage folders listing still saved a false plan: $OUT"; else pass "garbage folders listing did not save a false plan"; fi

echo "[14f] failure-honesty: housekeep revert survives a failing item read, attempts every action, exits 1 not the child code (issue #165)"
H2G="$(new_home "$WORK/h14f")"
mkdir -p "$H2G/.cache/bitwarden"
cat >"$H2G/.cache/bitwarden/snapshot_latest.json" <<'EOF'
{"backend":"bw","timestamp":"2026-10-15T00:00:00Z","actions":[{"id":"i1","originalName":"alpha","newName":"alpha","targetFolder":"work","currentFolder":"Old","currentFolderId":"f-old","confidence":"90"},{"id":"i2","originalName":"beta","newName":"beta","targetFolder":"home","currentFolder":"Old","currentFolderId":"f-old","confidence":"90"}]}
EOF
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2G" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_BW_GET_ITEM_RC=77" \
    "$REPO_ROOT/bin/sec-organizer" revert 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 1 ]]; then pass "revert with failing reads exits 1"; else fail "revert with failing reads exited $RC, expected 1: $OUT"; fi
if [[ $RC -eq 77 ]]; then fail "revert leaked the child's exit 77"; else pass "no child exit-code leak on failing revert reads"; fi
if [[ "$(grep -c "^\[ERROR\] revert failed: could not read item" <<<"$OUT")" -eq 2 ]]; then pass "both actions attempted, both tagged"; else fail "expected 2 tagged revert-failed lines, got: $OUT"; fi
if grep -q "^\[ERROR\] Revert incomplete" <<<"$OUT"; then pass "tagged Revert incomplete summary"; else fail "no tagged Revert incomplete summary: $OUT"; fi
if grep -q "Revert Successfully Completed" <<<"$OUT"; then fail "reported success for a failed revert"; else pass "no success banner on failed revert"; fi
if grep -q "item not readable" <<<"$OUT"; then fail "revert leaked the child's raw stderr: $OUT"; else pass "no raw child stderr on failing revert reads"; fi
if [[ -f "$H2G/.cache/bitwarden/snapshot_latest.json" ]]; then pass "snapshot kept after failed revert"; else fail "snapshot DELETED after failed revert"; fi

echo "[14g] failure-honesty: housekeep apply survives a failing encode, exits 1 not 141, keeps the plan (issue #165)"
H2H="$(new_home "$WORK/h14g")"
mkdir -p "$H2H/.cache/bitwarden"
cat >"$H2H/.cache/bitwarden/housekeep_plan.json" <<'EOF'
{"backend":"bw","timestamp":"2026-10-15T00:00:00Z","actions":[{"id":"item-1","originalName":"MY_API_KEY","newName":"MY_API_KEY","targetFolder":"work","currentFolder":"","currentFolderId":"","confidence":"90"}]}
EOF
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2H" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_BW_ENCODE_RC=77" \
    "$REPO_ROOT/bin/sec-organizer" apply 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 1 ]]; then pass "apply with failing encode exits 1"; else fail "apply with failing encode exited $RC, expected 1: $OUT"; fi
if [[ $RC -eq 77 || $RC -eq 141 ]]; then fail "apply leaked the child's exit code ($RC)"; else pass "no child exit-code leak on failing apply encode"; fi
if grep -q '^\[ERROR\] apply failed: could not encode updated item "MY_API_KEY"' <<<"$OUT"; then pass "tagged encode-stage error names the item, not the child stderr"; else fail "no tagged encode-stage error: $OUT"; fi
if grep -q "^\[ERROR\] Apply incomplete" <<<"$OUT"; then pass "tagged Apply incomplete summary"; else fail "no tagged Apply incomplete summary: $OUT"; fi
if grep -q "Successfully Applied" <<<"$OUT"; then fail "reported success for a failed apply"; else pass "no success banner on failed apply"; fi
if grep -q "encode failed" <<<"$OUT"; then fail "apply leaked the child's raw stderr: $OUT"; else pass "no raw child stderr on failing apply encode"; fi
if [[ -f "$H2H/.cache/bitwarden/housekeep_plan.json" ]]; then pass "plan kept after failed apply"; else fail "plan DELETED after failed apply"; fi

echo "[14h] failure-honesty: housekeep apply survives a failing folder create, never leaks child stderr (issue #165)"
H2I="$(new_home "$WORK/h14h")"
mkdir -p "$H2I/.cache/bitwarden"
cat >"$H2I/.cache/bitwarden/housekeep_plan.json" <<'EOF'
{"backend":"bw","timestamp":"2026-10-15T00:00:00Z","actions":[{"id":"item-1","originalName":"MY_API_KEY","newName":"MY_API_KEY","targetFolder":"brand-new-folder","currentFolder":"","currentFolderId":"","confidence":"90"}]}
EOF
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2I" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_BW_TEMPLATE_RC=66" \
    "$REPO_ROOT/bin/sec-organizer" apply 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 1 ]]; then pass "apply with failing folder create exits 1"; else fail "apply with failing folder create exited $RC, expected 1: $OUT"; fi
if [[ $RC -eq 66 ]]; then fail "apply leaked the child's exit 66"; else pass "no child exit-code leak on failing folder create"; fi
if grep -q '^\[ERROR\] apply failed: could not create folder "brand-new-folder"' <<<"$OUT"; then pass "tagged create-stage error names the folder, not the child stderr"; else fail "no tagged create-stage error: $OUT"; fi
if grep -q "TOKEN-abc123" <<<"$OUT"; then fail "apply leaked the child's raw stderr token: $OUT"; else pass "no raw child stderr token on failing folder create"; fi
if grep -q "Successfully Applied" <<<"$OUT"; then fail "reported success for a failed apply"; else pass "no success banner on failed apply"; fi
if [[ -f "$H2I/.cache/bitwarden/housekeep_plan.json" ]]; then pass "plan kept after failed apply"; else fail "plan DELETED after failed apply"; fi

echo "[14i] failure-honesty: a failing 'bw status' in the auth preamble exits 1 tagged, never a silent death (issue #166)"
H2J="$(new_home "$WORK/h14i")"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2J" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_BW_STATUS_RC=1" \
    "$REPO_ROOT/bin/sec" bw get MY_API_KEY 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] bitwarden 'bw status' failed" <<<"$OUT"; then pass "failing bw status -> exit 1 + tagged error"; else fail "failing bw status rc=$RC out=[$OUT]"; fi
if [[ -n "$OUT" ]]; then pass "failing bw status is loud, not a silent death"; else fail "failing bw status died silent (empty output, rc=$RC)"; fi
if [[ $RC -eq 4 ]]; then fail "failing bw status leaked jq's exit 4"; else pass "no jq exit-code leak on failing bw status"; fi
if grep -q "parse error" <<<"$OUT"; then fail "failing bw status leaked a raw jq parse error: $OUT"; else pass "no raw jq parse error on failing bw status"; fi
if grep -q "pw-MY_API_KEY" <<<"$OUT"; then fail "failing bw status still printed a secret: $OUT"; else pass "no secret printed on failing bw status"; fi

echo "[14j] failure-honesty: garbage 'bw status' output exits 1 tagged, never jq's raw exit 4 (issue #166)"
H2K="$(new_home "$WORK/h14j")"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2K" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_BW_STATUS_GARBAGE=1" \
    "$REPO_ROOT/bin/sec" bw get MY_API_KEY 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] bitwarden 'bw status' failed" <<<"$OUT"; then pass "garbage bw status -> exit 1 + tagged error"; else fail "garbage bw status rc=$RC out=[$OUT]"; fi
if [[ $RC -eq 4 ]]; then fail "garbage bw status leaked jq's exit 4"; else pass "no jq exit-code leak on garbage bw status"; fi
if grep -q "parse error" <<<"$OUT"; then fail "garbage bw status leaked a raw jq parse error: $OUT"; else pass "no raw jq parse error on garbage bw status"; fi
if grep -q "pw-MY_API_KEY" <<<"$OUT"; then fail "garbage bw status still printed a secret: $OUT"; else pass "no secret printed on garbage bw status"; fi

echo "[14k] failure-honesty: 'sec get --scope' fails closed on a garbage folders listing, never jq's exit 4 (issue #166)"
H2L="$(new_home "$WORK/h14k")"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2L" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_BW_FOLDERS=GARBAGE{{{not-json" \
    "$REPO_ROOT/bin/sec" bw get --scope work MY_API_KEY 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] corrupt or unreadable folder listing from backend 'bw'" <<<"$OUT"; then pass "garbage scope folders -> exit 1 + tagged error"; else fail "garbage scope folders rc=$RC out=[$OUT]"; fi
if [[ $RC -eq 4 ]]; then fail "garbage scope folders leaked jq's exit 4"; else pass "no jq exit-code leak on garbage scope folders"; fi
if grep -q "parse error" <<<"$OUT"; then fail "garbage scope folders leaked a raw jq parse error: $OUT"; else pass "no raw jq parse error on garbage scope folders"; fi
if grep -q "pw-MY_API_KEY" <<<"$OUT"; then fail "garbage scope folders still printed a secret: $OUT"; else pass "no secret printed on garbage scope folders"; fi

echo "[14l] failure-honesty: 'sec bws set' names the failed project-list stage, never dies silent (issue #166)"
H2M="$(new_home "$WORK/h14l")"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2M" \
    "SEC_TEST_BWS_LOG=$BWSLOG" "SEC_TEST_BWS_PROJ_RC=1" \
    "$REPO_ROOT/bin/sec" bws set MY_KEY myval 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] failed to store secret 'MY_KEY' in tenant 'bws' (stage: bws project list failed)" <<<"$OUT"; then pass "failing bws project list -> exit 1 + tagged stage error"; else fail "failing bws project list rc=$RC out=[$OUT]"; fi
if [[ -n "$OUT" ]]; then pass "failing bws project list is loud, not a silent death"; else fail "failing bws project list died silent (empty output, rc=$RC)"; fi
if grep -q "BWS_ACCESS_TOKEN" <<<"$OUT"; then fail "failing bws project list leaked the backend's raw stderr: $OUT"; else pass "no raw backend stderr on failing bws project list"; fi
if grep -q "parse error" <<<"$OUT"; then fail "failing bws project list leaked a raw jq parse error: $OUT"; else pass "no raw jq parse error on failing bws project list"; fi

echo "[14m] failure-honesty: keeper status without a bw CLI exits 1 tagged, never a silent 127 (issue #166)"
H2N="$(new_home "$WORK/h14m")"
set +e
OUT="$(env -i "PATH=/usr/bin:/bin" "HOME=$H2N" \
    "$REPO_ROOT/bin/bw-session-keeper" status 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] bitwarden 'bw status' failed" <<<"$OUT"; then pass "keeper status without bw -> exit 1 + tagged error"; else fail "keeper status without bw rc=$RC out=[$OUT]"; fi
if [[ -n "$OUT" ]]; then pass "keeper status without bw is loud, not a silent death"; else fail "keeper status without bw died silent (empty output, rc=$RC)"; fi
if [[ $RC -eq 127 ]]; then fail "keeper status without bw leaked the child's exit 127"; else pass "no child exit-code leak on keeper status without bw"; fi
if grep -q "parse error" <<<"$OUT"; then fail "keeper status without bw leaked a raw jq parse error: $OUT"; else pass "no raw jq parse error on keeper status without bw"; fi

echo "[14n] failure-honesty: housekeep plan fails closed on a failing folders read, never masks it as an empty vault (issue #169)"
H2O="$(new_home "$WORK/h14n")"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2O" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_BW_FOLDERS_RC=1" \
    "$REPO_ROOT/bin/sec" housekeep plan 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] corrupt or unreadable listing from backend 'bw'" <<<"$OUT"; then pass "failing folders read -> exit 1 + tagged error"; else fail "failing folders read rc=$RC out=[$OUT]"; fi
if grep -q "Plan saved" <<<"$OUT"; then fail "failing folders read still saved a false plan: $OUT"; else pass "failing folders read did not save a false plan"; fi
if grep -q "vault is locked" <<<"$OUT"; then fail "failing folders read leaked the child's raw stderr: $OUT"; else pass "no raw child stderr on failing folders read"; fi

echo "[14o] failure-honesty: housekeep apply fails closed on a failing folders read, keeps the plan (issue #169)"
H2P="$(new_home "$WORK/h14o")"
mkdir -p "$H2P/.cache/bitwarden"
cat >"$H2P/.cache/bitwarden/housekeep_plan.json" <<'EOF'
{"backend":"bw","timestamp":"2026-10-15T00:00:00Z","actions":[{"id":"item-1","originalName":"MY_API_KEY","newName":"MY_API_KEY","targetFolder":"work","currentFolder":"","currentFolderId":"","confidence":"90"}]}
EOF
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2P" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_BW_FOLDERS_RC=1" \
    "$REPO_ROOT/bin/sec-organizer" apply 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] corrupt or unreadable listing from backend 'bw'" <<<"$OUT"; then pass "apply with failing folders read -> exit 1 + tagged error"; else fail "apply failing folders read rc=$RC out=[$OUT]"; fi
if grep -q "Successfully Applied" <<<"$OUT"; then fail "reported success for a failed apply with unreadable folders"; else pass "no success banner on failing folders read"; fi
if grep -q "Creating folder" <<<"$OUT"; then fail "attempted a folder create from an unverified listing: $OUT"; else pass "did not act on an unverified folders listing"; fi
if [[ -f "$H2P/.cache/bitwarden/housekeep_plan.json" ]]; then pass "plan kept after failing folders read"; else fail "plan DELETED after failing folders read"; fi

echo "[14p] failure-honesty: 'sec get --scope' fails closed on a failing folders read, never masks it as a missing folder (issue #191)"
H2Q="$(new_home "$WORK/h14p")"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2Q" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_BW_FOLDERS_RC=1" \
    "$REPO_ROOT/bin/sec" bw get --scope work MY_API_KEY 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] corrupt or unreadable folder listing from backend 'bw'" <<<"$OUT"; then pass "failing folders read -> exit 1 + tagged error"; else fail "failing folders read rc=$RC out=[$OUT]"; fi
if grep -q "scope folder not found" <<<"$OUT"; then fail "failing folders read misreported as 'scope folder not found': $OUT"; else pass "a provider failure is not misreported as a missing folder"; fi
if grep -q "vault is locked" <<<"$OUT"; then fail "failing folders read leaked the child's raw stderr: $OUT"; else pass "no raw child stderr on failing folders read"; fi
if grep -q "pw-MY_API_KEY" <<<"$OUT"; then fail "failing folders read still printed a secret: $OUT"; else pass "no secret printed on failing folders read"; fi

echo "[14q] class guard: no '|| echo []' listing mask survives in the credential-adjacent dispatchers (issue #191)"
MASK_HITS="$(grep -nE "echo[[:space:]]*[\"']?\[\][\"']?" "$REPO_ROOT/bin/sec" "$REPO_ROOT/bin/sec-organizer" "$REPO_ROOT/bin/sec-migrator" 2>/dev/null || true)"
if [[ -z "$MASK_HITS" ]]; then pass "no '|| echo []' empty-array mask in bin/sec, bin/sec-organizer, bin/sec-migrator"; else fail "an empty-array listing mask reappeared: $MASK_HITS"; fi

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

echo "[15b] F0F2 class: migrate fails closed on an unparseable source listing (issue #142)"
H2B="$(new_home "$WORK/h15b")"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2B" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_BW_ITEMS=this is not valid json" \
    "$REPO_ROOT/bin/sec" migrate --from bitwarden --to 1pass --plan 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] corrupt or unreadable listing from source backend 'bitwarden'" <<<"$OUT"; then pass "unparseable source listing -> exit 1 + tagged error"; else fail "unparseable source rc=$RC out=[$OUT]"; fi
if grep -q "Zero items found" <<<"$OUT"; then fail "unparseable source still reported 'Zero items found' (silent no-op): $OUT"; else pass "unparseable source did not report a false zero-items success"; fi

echo "[15c] F015 class: migrate --apply blocks on a corrupt transaction log (issue #142)"
H2C="$(new_home "$WORK/h15c")"
mkdir -p "$H2C/.cache/bitwarden"
printf 'this is not valid json' >"$H2C/.cache/bitwarden/migration_transaction.json"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H2C" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "$REPO_ROOT/bin/sec" migrate --from bitwarden --to 1pass --apply 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 1 ]] && grep -q "^\[ERROR\] corrupt or unreadable migration transaction log" <<<"$OUT"; then pass "corrupt TX log -> apply exit 1 + tagged error"; else fail "corrupt TX apply rc=$RC out=[$OUT]"; fi
if grep -q "Migration Successfully Completed" <<<"$OUT"; then fail "corrupt TX log still completed a migration (masked as empty): $OUT"; else pass "corrupt TX log blocked the migration"; fi

echo "[16] sec-classify.py direct smoke"
set +e
OUT="$(printf '%s' '{"name":"aws-access-key","login":{"username":"a@example.com"},"notes":"","fields":[]}' \
    | python3 "$REPO_ROOT/bin/sec-classify.py" 2>&1)"
RC=$?
set -e
CAT="$(jq -r '.category' <<<"$OUT" 2>/dev/null || echo parse-fail)"
if [[ $RC -eq 0 && "$CAT" == "cloud/aws" ]]; then pass "aws fixture classifies cloud/aws"; else fail "classify rc=$RC category=$CAT out=$OUT"; fi

echo "[16-honesty] README housekeep sample reproduces verbatim (Gmail -> cloud/gcp, PROD_DB -> database)"
set +e
OUT="$(printf '%s' '{"name":"Gmail","login":{"username":"anass.personal@gmail.com","password":"s3cretpw","uris":[{"uri":"https://mail.google.com"}]}}' \
    | python3 "$REPO_ROOT/bin/sec-classify.py" 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -qF '"category": "cloud/gcp"' <<<"$OUT" && grep -qF '"reasons": ["token:google"]' <<<"$OUT" && grep -qF '"suggested_name": "Gmail (anass.personal@gmail.com)"' <<<"$OUT"; then
    pass "Gmail fixture matches the README housekeep sample (cloud/gcp, token:google)"
else
    fail "Gmail fixture drifted from the README sample: rc=$RC out=$OUT"
fi
set +e
OUT="$(printf '%s' '{"name":"PROD_DB","login":{"password":"postgres://prod.example.com:5432/prod"}}' \
    | python3 "$REPO_ROOT/bin/sec-classify.py" 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -qF '"category": "database"' <<<"$OUT" && grep -qF '"reasons": ["regex:postgres://", "token:db", "token:postgres"]' <<<"$OUT" && grep -qF '"confidence": 81' <<<"$OUT"; then
    pass "PROD_DB fixture matches the README housekeep sample (database, 81%)"
else
    fail "PROD_DB fixture drifted from the README sample: rc=$RC out=$OUT"
fi

echo "[16b] F017: classify reads login.password (AKIA key in password field -> cloud/aws)"
AWS_KEY_TAIL="2233445566778899"
set +e
OUT="$(printf '%s' "{\"name\":\"db\",\"login\":{\"username\":\"a@example.com\",\"password\":\"AKIA${AWS_KEY_TAIL}\"},\"notes\":\"\",\"uris\":[]}" \
    | python3 "$REPO_ROOT/bin/sec-classify.py" 2>&1)"
RC=$?
set -e
CAT="$(jq -r '.category' <<<"$OUT" 2>/dev/null || echo parse-fail)"
if [[ $RC -eq 0 && "$CAT" == "cloud/aws" ]]; then pass "AKIA in login.password classifies cloud/aws"; else fail "AKIA in password: rc=$RC category=$CAT out=$OUT"; fi

echo "[16c] F017: a null uri in login.uris does not drop the item to confidence-0"
set +e
OUT="$(printf '%s' '{"name":"genericdb","login":{"username":"a@example.com","uris":[null]},"notes":"postgres db","fields":[]}' \
    | python3 "$REPO_ROOT/bin/sec-classify.py" 2>&1)"
RC=$?
set -e
CONF="$(jq -r '.confidence' <<<"$OUT" 2>/dev/null || echo parse-fail)"
if [[ $RC -eq 0 && "$CONF" != "0" ]]; then pass "null uri does not drop confidence to 0 (got $CONF)"; else fail "null uri dropped item: rc=$RC conf=$CONF out=$OUT"; fi

echo "[16d] F018: iam.gserviceaccount.com classifies cloud/gcp, not cloud/aws"
set +e
OUT="$(printf '%s' '{"name":"gcp-sa","login":{"username":"a@example.com","uris":[{"uri":"https://iam.gserviceaccount.com"}]},"notes":"","fields":[]}' \
    | python3 "$REPO_ROOT/bin/sec-classify.py" 2>&1)"
RC=$?
set -e
CAT="$(jq -r '.category' <<<"$OUT" 2>/dev/null || echo parse-fail)"
if [[ $RC -eq 0 && "$CAT" == "cloud/gcp" ]]; then pass "iam.gserviceaccount.com classifies cloud/gcp"; else fail "gcp SA uri: rc=$RC category=$CAT out=$OUT"; fi

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

echo "[18b] sec.conf: a commented-out key must NOT take effect (issue #55)"
H18B="$(new_home "$WORK/h18b")"
printf '[global]\n# default_backend = bws\n\n[bitwarden]\nauto_rotate = false\n' >"$H18B/.sec/sec.conf"
set +e
OUT18B="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H18B" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/sec" get MY_API_KEY 2>&1 </dev/null)"
RC18B=$?
set -e
if [[ $RC18B -eq 0 ]] && [[ "$OUT18B" == "pw-MY_API_KEY" ]]; then pass "commented default_backend ignored; default bitwarden used"; else fail "commented key was honored (rc=$RC18B out=$OUT18B)"; fi

echo "[18c] sec.conf: a substring key must not collide with the real key (issue #55)"
H18C="$(new_home "$WORK/h18c")"
printf '[global]\ndefault_backend_extra = bws\n\n[bitwarden]\nauto_rotate = false\n' >"$H18C/.sec/sec.conf"
set +e
OUT18C="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H18C" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/sec" get MY_API_KEY 2>&1 </dev/null)"
RC18C=$?
set -e
if [[ $RC18C -eq 0 ]] && [[ "$OUT18C" == "pw-MY_API_KEY" ]]; then pass "substring key default_backend_extra did not set default_backend"; else fail "substring key collided (rc=$RC18C out=$OUT18C)"; fi

echo "[18d] sec.conf: a key written with no '=' must warn on stderr, not vanish (issue #126)"
H18D="$(new_home "$WORK/h18d")"
printf '[global]\ndefault_backend bitwarden\n\n[bitwarden]\nauto_rotate = false\n' >"$H18D/.sec/sec.conf"
set +e
OUT18D="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H18D" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/sec" get MY_API_KEY 2>&1 </dev/null)"
RC18D=$?
set -e
if [[ $RC18D -eq 0 ]] && grep -q "pw-MY_API_KEY" <<<"$OUT18D"; then pass "malformed sec.conf line left routing on the default (bitwarden)"; else fail "malformed line changed routing (rc=$RC18D out=$OUT18D)"; fi
if grep -qF "[WARN] sec.conf: ignoring malformed line 2 (no =): default_backend bitwarden" <<<"$OUT18D"; then pass "malformed sec.conf line warns on stderr, naming the tagged line number"; else fail "no tagged [WARN] for the malformed line: $OUT18D"; fi
H18E="$(new_home "$WORK/h18e")"
printf '[global]\ndefault_backend = bitwarden\n\n[bitwarden]\nauto_rotate = false\n' >"$H18E/.sec/sec.conf"
set +e
OUT18E="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H18E" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/sec" get MY_API_KEY 2>&1 </dev/null)"
RC18E=$?
set -e
if [[ $RC18E -eq 0 ]] && [[ "$OUT18E" == "pw-MY_API_KEY" ]]; then pass "control: a well-formed sec.conf emits no [WARN]"; else fail "control: clean config rc=$RC18E out=$OUT18E"; fi

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

echo "[22c] F011: non-TTY unlock with no stored password fails with a message, not silently"
H9="$(new_home "$WORK/h9")"
set +e
OUT="$(run_keeper "$H9" "$REPO_ROOT/bin/bw-session-keeper" unlock 2>&1)"
RC=$?
set -e
if [[ $RC -ne 0 ]]; then pass "non-TTY unlock exits non-zero"; else fail "non-TTY unlock exited 0 with no password source"; fi
if grep -q "^\[ERROR\]" <<<"$OUT"; then pass "non-TTY unlock emits a tagged [ERROR]"; else fail "non-TTY unlock died with no [ERROR]: $OUT"; fi

echo "[22d] F011: non-TTY setup-keychain with no password fails with a message, not silently"
H10="$(new_home "$WORK/h10")"
set +e
OUT="$(run_keeper "$H10" "$REPO_ROOT/bin/bw-session-keeper" setup-keychain 2>&1)"
RC=$?
set -e
if [[ $RC -ne 0 ]]; then pass "non-TTY setup-keychain exits non-zero"; else fail "non-TTY setup-keychain exited 0 with no password source"; fi
if grep -q "^\[ERROR\]" <<<"$OUT"; then pass "non-TTY setup-keychain emits a tagged [ERROR]"; else fail "non-TTY setup-keychain died with no [ERROR]: $OUT"; fi

echo "[22e] F021: sync with no controller errors instead of exiting 0"
SEC21_DIR="$(mktemp -d "$WORK/sec21.XXXXXX")"
cp "$REPO_ROOT/bin/sec" "$SEC21_DIR/sec"
chmod +x "$SEC21_DIR/sec"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$WORK/empty" "$SEC21_DIR/sec" sync --dry-run 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -ne 0 ]]; then pass "sync without controller exits non-zero"; else fail "sync without controller exited 0"; fi
if grep -q "^\[ERROR\]" <<<"$OUT"; then pass "sync without controller emits a tagged [ERROR]"; else fail "sync without controller died with no [ERROR]: $OUT"; fi

echo "[22f] F025: failing bw list items surfaces the provider error, not not-found"
H11="$(new_home "$WORK/h11")"
set +e
OUT="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H11" \
    "SEC_TEST_BW_LIST_RC=1" "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/sec" bw get missing-key 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -ne 0 ]]; then pass "provider failure exits non-zero"; else fail "provider failure exited 0"; fi
if grep -q "^\[ERROR\]" <<<"$OUT"; then pass "provider failure emits a tagged [ERROR]"; else fail "provider failure died with no [ERROR]: $OUT"; fi
if grep -qi "not found" <<<"$OUT"; then fail "provider failure misreported as not-found: $OUT"; else pass "provider failure is not misreported as not-found"; fi

echo "[22g] F021 class: housekeep/migrate/keeper arms error when their module is absent"
NOMOD_DIR="$(mktemp -d "$WORK/nomod.XXXXXX")"
cp "$REPO_ROOT/bin/sec" "$NOMOD_DIR/sec"
chmod +x "$NOMOD_DIR/sec"
set +e
OUTG1="$(env -i "PATH=/usr/bin:/bin" "HOME=$WORK/empty" "$NOMOD_DIR/sec" housekeep plan 2>&1 </dev/null)"
RCG1=$?
OUTG2="$(env -i "PATH=/usr/bin:/bin" "HOME=$WORK/empty" "$NOMOD_DIR/sec" migrate --plan 2>&1 </dev/null)"
RCG2=$?
OUTG3="$(env -i "PATH=/usr/bin:/bin" "HOME=$WORK/empty" "$NOMOD_DIR/sec" rotate 2>&1 </dev/null)"
RCG3=$?
set -e
if [[ $RCG1 -ne 0 ]] && grep -q "^\[ERROR\]" <<<"$OUTG1"; then pass "housekeep without organizer exits non-zero, tagged"; else fail "housekeep without organizer exited 0 or untagged (rc=$RCG1): $OUTG1"; fi
if [[ $RCG2 -ne 0 ]] && grep -q "^\[ERROR\]" <<<"$OUTG2"; then pass "migrate without migrator exits non-zero, tagged"; else fail "migrate without migrator exited 0 or untagged (rc=$RCG2): $OUTG2"; fi
if [[ $RCG3 -ne 0 ]] && grep -q "^\[ERROR\]" <<<"$OUTG3"; then pass "rotate without keeper exits non-zero, tagged"; else fail "rotate without keeper exited 0 or untagged (rc=$RCG3): $OUTG3"; fi

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

echo "[23d] F027: sec.ps1 rejects unimplemented commands instead of a silent exit 0 (static + pwsh)"
if grep -q 'does not implement' "$REPO_ROOT/bin/sec.ps1"; then pass "sec.ps1 names unimplemented commands"; else fail "sec.ps1 default arm does not report unimplemented commands (F027)"; fi
if grep -q 'exit 2' "$REPO_ROOT/bin/sec.ps1"; then pass "sec.ps1 default arm exits non-zero for unknown commands"; else fail "sec.ps1 default arm leaves a silent exit 0 (F027)"; fi
if command -v pwsh >/dev/null 2>&1; then
    H27PS="$(new_home "$WORK/h27ps")"
    PWSH27="$(command -v pwsh)"
    set +e
    OUT27PS="$(env -i "PATH=/usr/bin:/bin" "HOME=$H27PS" "$PWSH27" -NoProfile -File "$REPO_ROOT/bin/sec.ps1" sync 2>&1)"
    RC27PS=$?
    set -e
    if [[ $RC27PS -ne 0 ]]; then pass "sec.ps1 sync exits non-zero (rc=$RC27PS)"; else fail "sec.ps1 sync silently succeeded with exit 0 (F027)"; fi
    if grep -q '\[ERROR\]' <<<"$OUT27PS"; then pass "sec.ps1 sync emits a tagged [ERROR]"; else fail "sec.ps1 sync emitted no tagged error: $OUT27PS"; fi
    rm -rf "$H27PS"
else
    echo "[INFO] pwsh not present on this host; sec.ps1 F027 functional assertion runs in CI"
fi

echo "[23e] #73: sec.ps1 rejects unknown -flags and trailing args instead of misparsing them as operands"
if grep -q -- '-prefixed operands are rejected' "$REPO_ROOT/bin/sec.ps1"; then pass "sec.ps1 rejects -prefixed operands loudly"; else fail "sec.ps1 still treats unknown -flags as operands (#73)"; fi
if grep -q 'unexpected trailing argument' "$REPO_ROOT/bin/sec.ps1"; then pass "sec.ps1 rejects trailing args instead of dropping them"; else fail "sec.ps1 silently drops trailing args (#73)"; fi
if command -v pwsh >/dev/null 2>&1; then
    H73PS="$(new_home "$WORK/h73ps")"
    FB73="$WORK/fb73"
    mkdir -p "$FB73"
    BWLOG73="$WORK/bw73.log"
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"${SEC_TEST_BW_LOG:?}"\nprintf "%%s\\n" "[]"\n' >"$FB73/bw"
    chmod +x "$FB73/bw"
    PWSH73="$(command -v pwsh)"
    set +e
    OUT73A="$(env -i "PATH=$FB73:/usr/bin:/bin" "HOME=$H73PS" "SEC_TEST_BW_LOG=$BWLOG73" "$PWSH73" -NoProfile -File "$REPO_ROOT/bin/sec.ps1" set --type note mykey myval 2>&1)"
    RC73A=$?
    OUT73B="$(env -i "PATH=$FB73:/usr/bin:/bin" "HOME=$H73PS" "SEC_TEST_BW_LOG=$BWLOG73" "$PWSH73" -NoProfile -File "$REPO_ROOT/bin/sec.ps1" get --bogus mykey 2>&1)"
    RC73B=$?
    OUT73C="$(env -i "PATH=$FB73:/usr/bin:/bin" "HOME=$H73PS" "SEC_TEST_BW_LOG=$BWLOG73" "$PWSH73" -NoProfile -File "$REPO_ROOT/bin/sec.ps1" set mykey myval extra 2>&1)"
    RC73C=$?
    set -e
    if [[ $RC73A -eq 2 ]] && grep -q '\[ERROR\]' <<<"$OUT73A"; then pass "sec.ps1 set --type refused (rc=2, tagged)"; else fail "sec.ps1 set --type not refused (rc=$RC73A): $OUT73A"; fi
    if [[ -f "$BWLOG73" ]] && grep -q 'create' "$BWLOG73"; then fail "sec.ps1 created a secret despite the rejected flag: $(cat "$BWLOG73")"; else pass "no secret created on the rejected set"; fi
    if [[ $RC73B -eq 2 ]] && grep -q '\[ERROR\]' <<<"$OUT73B"; then pass "sec.ps1 get --bogus refused (rc=2, tagged)"; else fail "sec.ps1 get --bogus not refused (rc=$RC73B): $OUT73B"; fi
    if [[ $RC73C -eq 2 ]] && grep -q 'unexpected trailing' <<<"$OUT73C"; then pass "sec.ps1 set trailing arg refused (rc=2)"; else fail "sec.ps1 set trailing arg not refused (rc=$RC73C): $OUT73C"; fi
    rm -rf "$H73PS" "$FB73" "$BWLOG73"
else
    echo "[INFO] pwsh not present on this host; sec.ps1 #73 functional assertions run in CI"
fi

echo "[23f] #163: sec.ps1 set refuses to fall through to bw when bws is installed but has no project id (no silent store substitution)"
if grep -q 'bws project list returned no project id' "$REPO_ROOT/bin/sec.ps1"; then pass "sec.ps1 names the missing-project-id stage"; else fail "sec.ps1 does not report the bws project-list failure stage (#163)"; fi
if grep -q 'Bitwarden Secrets Manager (bws project list returned no project id)' "$REPO_ROOT/bin/sec.ps1"; then pass "sec.ps1's bws arm is terminal on a missing project id (#163)"; else fail "sec.ps1's bws arm still falls through to bw when no project id (#163)"; fi
BASH_STAGE_23F="$(grep -o 'bws project list returned no project id' "$REPO_ROOT/bin/sec" | head -1)"
if [[ -n "$BASH_STAGE_23F" ]] && grep -q "$BASH_STAGE_23F" "$REPO_ROOT/bin/sec.ps1"; then pass "bin/sec and bin/sec.ps1 name the same missing-project-id stage"; else fail "bin/sec and bin/sec.ps1 disagree on the missing-project-id stage (#163)"; fi
if command -v pwsh >/dev/null 2>&1; then
    H163PS="$(new_home "$WORK/h163ps")"
    FB163="$WORK/fb163"
    mkdir -p "$FB163"
    BWLOG163="$WORK/bw163.log"
    BWSLOG163="$WORK/bws163.log"
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"${SEC_TEST_BW_LOG:?}"\nprintf "%%s\\n" "[]"\n' >"$FB163/bw"
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"${SEC_TEST_BWS_LOG:?}"\nprintf "%%s\\n" "[]"\n' >"$FB163/bws"
    chmod +x "$FB163/bw" "$FB163/bws"
    PWSH163="$(command -v pwsh)"
    set +e
    OUT163="$(env -i "PATH=$FB163:/usr/bin:/bin" "HOME=$H163PS" "SEC_TEST_BW_LOG=$BWLOG163" "SEC_TEST_BWS_LOG=$BWSLOG163" "$PWSH163" -NoProfile -File "$REPO_ROOT/bin/sec.ps1" set mykey myval 2>&1)"
    RC163=$?
    set -e
    if [[ $RC163 -ne 0 ]]; then pass "sec.ps1 set refuses when bws has no project id (rc=$RC163)"; else fail "sec.ps1 set silently succeeded via bw despite an unusable bws (rc=0): $OUT163"; fi
    if grep -q 'bws project list returned no project id' <<<"$OUT163"; then pass "sec.ps1 names the bws project-list failure stage"; else fail "sec.ps1 did not name the stage: $OUT163"; fi
    if [[ ! -f "$BWLOG163" ]] || ! grep -q 'create' "$BWLOG163" 2>/dev/null; then pass "no secret written to the Bitwarden Vault (no silent store substitution)"; else fail "sec.ps1 fell through to bw and wrote the secret to the vault: $(cat "$BWLOG163")"; fi
    rm -rf "$H163PS" "$FB163" "$BWLOG163" "$BWSLOG163"
else
    echo "[INFO] pwsh not present on this host; sec.ps1 #163 functional assertions run in CI"
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

echo "[25] F024: op guard tests session validity (op whoami), not account configuration"
H25="$WORK/h25"
mkdir -p "$H25"
OPLOG25="$WORK/op25.log"
: >"$OPLOG25"
set +e
OUT25="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H25" "SEC_TEST_OP_LOG=$OPLOG25" "SEC_TEST_OP_WHOAMI_RC=1" "$REPO_ROOT/bin/sec" op get MY_API_KEY 2>&1)"
RC25=$?
set -e
if [[ $RC25 -eq 0 ]]; then pass "expired session re-authenticated, get succeeds"; else fail "get rc=$RC25 with expired session: $OUT25"; fi
if grep -q "op-pw-MY_API_KEY" <<<"$OUT25"; then pass "value returned after re-auth"; else fail "no value after re-auth: $OUT25"; fi
if grep -q "op signin" "$OPLOG25" 2>/dev/null; then pass "signin prompted when session invalid"; else fail "op signin never attempted: $(tr '\n' ' ' <"$OPLOG25" 2>/dev/null)"; fi
OPLOG25B="$WORK/op25b.log"
: >"$OPLOG25B"
H25B="$WORK/h25b"
mkdir -p "$H25B"
set +e
ERR25="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H25B" "SEC_TEST_OP_LOG=$OPLOG25B" "SEC_TEST_OP_WHOAMI_RC=1" "SEC_TEST_OP_SIGNIN_RC=1" "$REPO_ROOT/bin/sec" op get MY_API_KEY 2>&1)"
RC25B=$?
set -e
if [[ $RC25B -ne 0 ]] && grep -q "^\[ERROR\]" <<<"$ERR25" && ! grep -q "not found" <<<"$ERR25"; then
    pass "failed signin: non-zero exit, tagged error, not misreported as not-found"
else
    fail "failed-signin path wrong (rc=$RC25B): $ERR25"
fi
if grep -q "op signin" "$OPLOG25B" 2>/dev/null; then pass "signin attempted before giving up"; else fail "op signin never attempted on failed path"; fi

echo "[26] #27: --scope on unsupported tenants refuses honestly (exit 2, tagged)"
H26="$WORK/h26"
mkdir -p "$H26"
set +e
OUT26A="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H26" "$REPO_ROOT/bin/sec" bws get --scope proj secret-key 2>&1)"
RC26A=$?
OUT26B="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H26" "$REPO_ROOT/bin/sec" infisical get --scope proj secret-key 2>&1)"
RC26B=$?
set -e
if [[ $RC26A -eq 2 ]] && grep -q "^\[ERROR\] --scope is not supported for tenant 'bws'" <<<"$OUT26A"; then
    pass "bws --scope refused with tagged error, exit 2"
else
    fail "bws --scope wrong (rc=$RC26A): $OUT26A"
fi
if [[ $RC26B -eq 2 ]] && grep -q "^\[ERROR\] --scope is not supported for tenant 'infisical'" <<<"$OUT26B"; then
    pass "infisical --scope refused with tagged error, exit 2"
else
    fail "infisical --scope wrong (rc=$RC26B): $OUT26B"
fi

echo "[27] #27: bw --scope resolves a folder name and restricts lookup"
H27="$WORK/h27"
mkdir -p "$H27"
BWLOG27="$WORK/bw27.log"
: >"$BWLOG27"
ITEMS27='[{"id":"api-1","name":"api-key","notes":null,"login":{"password":"scoped-val","username":"","uris":[]},"fields":[],"folderId":"f-aaa"},{"id":"api-2","name":"api-key","notes":null,"login":{"password":"other-val","username":"","uris":[]},"fields":[],"folderId":"f-bbb"}]'
set +e
ERR27N="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H27" "SEC_TEST_BW_LOG=$BWLOG27" "SEC_TEST_BW_ITEMS=$ITEMS27" "$REPO_ROOT/bin/sec" bw get --scope null api-key 2>&1)"
RC27N=$?
set -e
if [[ $RC27N -eq 1 ]] && grep -q "^\[ERROR\] scope folder name 'null' is reserved" <<<"$ERR27N"; then
    pass "reserved 'null' scope name: exit 1, tagged reserved error"
else
    fail "null-scope path wrong (rc=$RC27N): $ERR27N"
fi
set +e
OUT27="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H27" "SEC_TEST_BW_LOG=$BWLOG27" "SEC_TEST_BW_ITEMS=$ITEMS27" "$REPO_ROOT/bin/sec" bw get --scope work api-key 2>&1)"
RC27=$?
set -e
if [[ $RC27 -eq 0 ]] && grep -q '^scoped-val$' <<<"$OUT27"; then pass "scoped get returns the folder's item value"; else fail "scoped get wrong (rc=$RC27): $OUT27"; fi
if grep -q -- '--folderid f-aaa' "$BWLOG27" 2>/dev/null; then pass "lookup passed --folderid f-aaa"; else fail "no --folderid in bw calls: $(tr '\n' ' ' <"$BWLOG27")"; fi
set +e
ERR27="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H27" "SEC_TEST_BW_LOG=$BWLOG27" "SEC_TEST_BW_ITEMS=$ITEMS27" "$REPO_ROOT/bin/sec" bw get --scope nope api-key 2>&1)"
RC27B=$?
set -e
if [[ $RC27B -eq 1 ]] && grep -q "^\[ERROR\] scope folder not found: 'nope'" <<<"$ERR27"; then
    pass "unresolvable folder: exit 1, tagged scope-folder-not-found"
else
    fail "unresolvable-folder path wrong (rc=$RC27B): $ERR27"
fi

echo "[28] #27: op --scope substitutes the vault in synthesized URIs (bash + ps1)"
H28="$WORK/h28"
mkdir -p "$H28"
OPLOG28="$WORK/op28.log"
: >"$OPLOG28"
set +e
OUT28="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H28" "SEC_TEST_OP_LOG=$OPLOG28" "$REPO_ROOT/bin/sec" op get --scope eng MY_API_KEY 2>&1)"
RC28=$?
set -e
if [[ $RC28 -eq 0 ]] && grep -q '^op-pw-vault-eng$' <<<"$OUT28"; then
    pass "bash op --scope reads from the named vault"
else
    fail "bash op --scope wrong (rc=$RC28): $OUT28"
fi
set +e
OUT28P="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H28" "SEC_TEST_OP_LOG=$OPLOG28" "$REPO_ROOT/bin/sec" op get MY_API_KEY 2>&1)"
RC28P=$?
set -e
if [[ $RC28P -eq 0 ]] && grep -q '^op-pw-MY_API_KEY$' <<<"$OUT28P"; then
    pass "unscoped op get still defaults to the private vault"
else
    fail "unscoped op get changed (rc=$RC28P): $OUT28P"
fi
PWSH28="${PWSH_BIN:-}"
if [ -z "$PWSH28" ]; then PWSH28="$(command -v pwsh 2>/dev/null || true)"; fi
if [ -z "$PWSH28" ] && [ -x /tmp/opencode/pwsh/pwsh ]; then PWSH28=/tmp/opencode/pwsh/pwsh; fi
if [ -n "$PWSH28" ]; then
    FB28="$WORK/fb28"
    mkdir -p "$FB28"
    cp "$FAKEBIN/op" "$FB28/op"
    H28P="$WORK/h28p"
    mkdir -p "$H28P"
    OPLOG28P="$WORK/op28p.log"
    : >"$OPLOG28P"
    set +e
    OUT28PS="$(env -i "PATH=$FB28:/usr/bin:/bin" "HOME=$H28P" "SEC_TEST_OP_LOG=$OPLOG28P" "$PWSH28" -NoProfile -File "$REPO_ROOT/bin/sec.ps1" get --scope eng MY_API_KEY 2>&1)"
    RC28PS=$?
    set -e
    if [[ $RC28PS -eq 0 ]] && grep -q 'op-pw-vault-eng' <<<"$OUT28PS"; then
        pass "ps1 op --scope reads from the named vault"
    else
        fail "ps1 op --scope wrong (rc=$RC28PS): $OUT28PS"
    fi
else
    echo "[INFO] pwsh not found; ps1 --scope assertion runs in CI"
fi

echo "[29] #27: bw ambiguous item name refuses instead of first-match"
H29="$WORK/h29"
mkdir -p "$H29"
BWLOG29="$WORK/bw29.log"
: >"$BWLOG29"
ITEMS29='[{"id":"dup-1","name":"api-key","notes":null,"login":{"password":"dup-one","username":"","uris":[]},"fields":[],"folderId":""},{"id":"dup-2","name":"api-key","notes":null,"login":{"password":"dup-two","username":"","uris":[]},"fields":[],"folderId":""}]'
set +e
ERR29="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H29" "SEC_TEST_BW_LOG=$BWLOG29" "SEC_TEST_BW_ITEMS=$ITEMS29" "$REPO_ROOT/bin/sec" bw get api-key 2>&1)"
RC29=$?
set -e
if [[ $RC29 -eq 1 ]] && grep -q "^\[ERROR\] ambiguous item name 'api-key'" <<<"$ERR29" && grep -q 'dup-1' <<<"$ERR29" && grep -q 'dup-2' <<<"$ERR29"; then
    pass "ambiguous name: exit 1, tagged error lists both matches"
else
    fail "ambiguous-name path wrong (rc=$RC29): $ERR29"
fi
set +e
OUT29B="$(env -i "PATH=$FAKEBIN:/usr/bin:/bin" "HOME=$H29" "SEC_TEST_BW_LOG=$BWLOG29" "SEC_TEST_BW_ITEMS=$ITEMS29" "$REPO_ROOT/bin/sec" bw get api-key/password 2>&1)"
RC29B=$?
set -e
if [[ $RC29B -eq 0 ]] && grep -q '^dup-one$' <<<"$OUT29B"; then
    pass "slash form still extracts the field across matches"
else
    fail "slash form broke (rc=$RC29B): $OUT29B"
fi
PWSH29="${PWSH_BIN:-}"
if [ -z "$PWSH29" ]; then PWSH29="$(command -v pwsh 2>/dev/null || true)"; fi
if [ -z "$PWSH29" ] && [ -x /tmp/opencode/pwsh/pwsh ]; then PWSH29=/tmp/opencode/pwsh/pwsh; fi
if [ -n "$PWSH29" ]; then
    FB29="$WORK/fb29"
    mkdir -p "$FB29"
    cp "$FAKEBIN/bw" "$FB29/bw"
    H29P="$WORK/h29p"
    mkdir -p "$H29P"
    BWLOG29P="$WORK/bw29p.log"
    : >"$BWLOG29P"
    set +e
    ERR29PS="$(env -i "PATH=$FB29:/usr/bin:/bin" "HOME=$H29P" "SEC_TEST_BW_LOG=$BWLOG29P" "SEC_TEST_BW_ITEMS=$ITEMS29" "$PWSH29" -NoProfile -File "$REPO_ROOT/bin/sec.ps1" get api-key 2>&1)"
    RC29PS=$?
    set -e
    if [[ $RC29PS -ne 0 ]] && grep -qi 'ambiguous' <<<"$ERR29PS"; then
        pass "ps1 ambiguous name refuses (was a yellow notice)"
    else
        fail "ps1 ambiguity wrong (rc=$RC29PS): $ERR29PS"
    fi
else
    echo "[INFO] pwsh not found; ps1 ambiguity assertion runs in CI"
fi

echo "[30] #29: ps1 op read failure exits nonzero with an error (not silent success)"
PWSH30="${PWSH_BIN:-}"
if [ -z "$PWSH30" ]; then PWSH30="$(command -v pwsh 2>/dev/null || true)"; fi
if [ -z "$PWSH30" ] && [ -x /tmp/opencode/pwsh/pwsh ]; then PWSH30=/tmp/opencode/pwsh/pwsh; fi
if [ -n "$PWSH30" ]; then
    FB30="$WORK/fb30"
    mkdir -p "$FB30"
    cp "$FAKEBIN/op" "$FB30/op"
    H30="$WORK/h30"
    mkdir -p "$H30"
    OPLOG30="$WORK/op30.log"
    : >"$OPLOG30"
    set +e
    OUT30="$(env -i "PATH=$FB30:/usr/bin:/bin" "HOME=$H30" "SEC_TEST_OP_LOG=$OPLOG30" "$PWSH30" -NoProfile -File "$REPO_ROOT/bin/sec.ps1" get MISSING_ITEM 2>&1)"
    RC30=$?
    set -e
    if [[ $RC30 -ne 0 ]] && grep -q "not found" <<<"$OUT30"; then
        pass "ps1 failed op read: nonzero exit, not-found error"
    else
        fail "ps1 failed op read silent-success (rc=$RC30): [$OUT30]"
    fi
    set +e
    OUT30B="$(env -i "PATH=$FB30:/usr/bin:/bin" "HOME=$H30" "SEC_TEST_OP_LOG=$OPLOG30" "$PWSH30" -NoProfile -File "$REPO_ROOT/bin/sec.ps1" get MY_API_KEY 2>&1)"
    RC30B=$?
    set -e
    if [[ $RC30B -eq 0 ]] && grep -q 'op-pw-MY_API_KEY' <<<"$OUT30B"; then
        pass "ps1 successful op read still returns the value, exit 0"
    else
        fail "ps1 successful op read broke (rc=$RC30B): $OUT30B"
    fi
else
    echo "[INFO] pwsh not found; ps1 op-honesty assertion runs in CI"
fi

echo "[31] #30: ps1 set fails honestly (no backend, or store write fails)"
PWSH31="${PWSH_BIN:-}"
if [ -z "$PWSH31" ]; then PWSH31="$(command -v pwsh 2>/dev/null || true)"; fi
if [ -z "$PWSH31" ] && [ -x /tmp/opencode/pwsh/pwsh ]; then PWSH31=/tmp/opencode/pwsh/pwsh; fi
if [ -n "$PWSH31" ]; then
    H31="$WORK/h31"
    mkdir -p "$H31"
    # A) no backend at all -> nonzero + tagged error, never a silent no-op
    FB31EMPTY="$WORK/fb31empty"
    mkdir -p "$FB31EMPTY"
    set +e
    OUT31A="$(env -i "PATH=$FB31EMPTY:/usr/bin:/bin" "HOME=$H31" "$PWSH31" -NoProfile -File "$REPO_ROOT/bin/sec.ps1" set mykey myval 2>&1)"
    RC31A=$?
    set -e
    if [[ $RC31A -ne 0 ]] && grep -qi "failed to store" <<<"$OUT31A"; then
        pass "ps1 set with no backend: nonzero exit + tagged error"
    else
        fail "ps1 set no-backend silent success (rc=$RC31A): [$OUT31A]"
    fi
    # B) bw present but create fails -> nonzero + tagged error, no false success
    FB31="$WORK/fb31"
    mkdir -p "$FB31"
    cp "$FAKEBIN/bw" "$FB31/bw"
    BWLOG31="$WORK/bw31.log"
    : >"$BWLOG31"
    set +e
    OUT31B="$(env -i "PATH=$FB31:/usr/bin:/bin" "HOME=$H31" "SEC_TEST_BW_LOG=$BWLOG31" "SEC_TEST_BW_CREATE_RC=1" "$PWSH31" -NoProfile -File "$REPO_ROOT/bin/sec.ps1" set mykey myval 2>&1)"
    RC31B=$?
    set -e
    if [[ $RC31B -ne 0 ]] && grep -qi "failed to store" <<<"$OUT31B" && ! grep -q "saved to Bitwarden" <<<"$OUT31B"; then
        pass "ps1 set with failing bw create: nonzero exit, no false success line"
    else
        fail "ps1 set lied on bw create failure (rc=$RC31B): [$OUT31B]"
    fi
    # C) positive control: a working bw still reports success
    set +e
    OUT31C="$(env -i "PATH=$FB31:/usr/bin:/bin" "HOME=$H31" "SEC_TEST_BW_LOG=$BWLOG31" "$PWSH31" -NoProfile -File "$REPO_ROOT/bin/sec.ps1" set mykey myval 2>&1)"
    RC31C=$?
    set -e
    if [[ $RC31C -eq 0 ]] && grep -q "saved to Bitwarden Vault" <<<"$OUT31C"; then
        pass "ps1 set with a working bw reports success, exit 0"
    else
        fail "ps1 set success path broke (rc=$RC31C): [$OUT31C]"
    fi
    # D/E) same honesty for the bws backend
    FB31B="$WORK/fb31b"
    mkdir -p "$FB31B"
    cp "$FAKEBIN/bws" "$FB31B/bws"
    BWSLOG31="$WORK/bws31.log"
    : >"$BWSLOG31"
    set +e
    OUT31D="$(env -i "PATH=$FB31B:/usr/bin:/bin" "HOME=$H31" "SEC_TEST_BWS_LOG=$BWSLOG31" "SEC_TEST_BWS_CREATE_RC=1" "$PWSH31" -NoProfile -File "$REPO_ROOT/bin/sec.ps1" set mykey myval 2>&1)"
    RC31D=$?
    set -e
    if [[ $RC31D -ne 0 ]] && grep -qi "failed to store" <<<"$OUT31D" && ! grep -q "saved to Bitwarden" <<<"$OUT31D"; then
        pass "ps1 set with failing bws create: nonzero exit, no false success line"
    else
        fail "ps1 set lied on bws create failure (rc=$RC31D): [$OUT31D]"
    fi
    set +e
    OUT31E="$(env -i "PATH=$FB31B:/usr/bin:/bin" "HOME=$H31" "SEC_TEST_BWS_LOG=$BWSLOG31" "$PWSH31" -NoProfile -File "$REPO_ROOT/bin/sec.ps1" set mykey myval 2>&1)"
    RC31E=$?
    set -e
    if [[ $RC31E -eq 0 ]] && grep -q "saved to Bitwarden Secrets Manager" <<<"$OUT31E"; then
        pass "ps1 set with a working bws reports success, exit 0"
    else
        fail "ps1 set bws success path broke (rc=$RC31E): [$OUT31E]"
    fi
else
    echo "[INFO] pwsh not found; ps1 set-honesty assertion runs in CI"
fi

echo "[22h] F025 class: get with the tenant CLI absent names the CLI, not 'not found'"
for _t in bws vault infisical; do
    if env -i "PATH=/usr/bin:/bin" command -v "$_t" >/dev/null 2>&1; then
        echo "[INFO] $_t present on the base PATH; absence assertion skipped"
        continue
    fi
    set +e
    OUT22H="$(env -i "PATH=/usr/bin:/bin" "HOME=$WORK/empty22h" "$REPO_ROOT/bin/sec" "$_t" get some-key 2>&1 </dev/null)"
    RC22H=$?
    set -e
    if [[ $RC22H -ne 0 ]] && grep -q "^\[ERROR\] $_t CLI not found for tenant '$_t'\." <<<"$OUT22H"; then
        pass "$_t get without its CLI exits non-zero and names the CLI"
    else
        fail "$_t get without its CLI (rc=$RC22H): [$OUT22H]"
    fi
    if grep -qi "not found in tenant" <<<"$OUT22H"; then
        fail "$_t get without its CLI misreported as secret-not-found"
    else
        pass "$_t get without its CLI is not misreported as secret-not-found"
    fi
done

echo "[22i] completion surfaces tell the truth about 'sec run' injection (issue #43, F001 class)"
set +e
ZSH_COMP="$(bash "$REPO_ROOT/bin/sec" completion zsh 2>&1)"
FISH_COMP="$(bash "$REPO_ROOT/bin/sec" completion fish 2>&1)"
set -e
if grep -q "injection only for bws/op/infisical" <<<"$ZSH_COMP"; then pass "zsh completion states per-tenant run truth"; else fail "zsh completion still promises universal injection"; fi
if grep -q "injection only for bws/op/infisical" <<<"$FISH_COMP"; then pass "fish completion states per-tenant run truth"; else fail "fish completion still promises universal injection"; fi
if grep -q "vault secrets injected" <<<"$ZSH_COMP$FISH_COMP"; then fail "completion still carries the stale unconditional 'vault secrets injected' claim"; else pass "completion dropped the stale unconditional claim"; fi
if [[ -f "$REPO_ROOT/completions/_sec" ]]; then
    if diff -q <(bash "$REPO_ROOT/bin/sec" completion zsh) "$REPO_ROOT/completions/_sec" >/dev/null 2>&1; then pass "completions/_sec matches generated zsh output"; else fail "completions/_sec drifted from 'sec completion zsh'"; fi
    if grep -q "injection only for bws/op/infisical" "$REPO_ROOT/completions/_sec"; then pass "static _sec completion states per-tenant run truth"; else fail "static _sec completion is stale"; fi
fi

echo "[22j] F003 residual: keeper never re-execs itself with the password on argv"
if grep -qF '"$0" unlock' "$REPO_ROOT/bin/bw-session-keeper"; then
    fail "keeper self-invokes with the password on argv: $(grep -nF '"$0" unlock' "$REPO_ROOT/bin/bw-session-keeper")"
else
    pass "no '\"\$0\" unlock' self-exec with password in keeper source"
fi
if grep -qF 'do_unlock "$pass"' "$REPO_ROOT/bin/bw-session-keeper" && grep -qF 'do_unlock "$password"' "$REPO_ROOT/bin/bw-session-keeper"; then
    pass "rotate and setup-keychain unlock in-process via do_unlock"
else
    fail "rotate/setup-keychain do not call do_unlock in-process"
fi

echo "[22k] F003 residual: auto-rotate never exposes the master password on the keeper's own argv"
PPBIN="$WORK/ppbin"
mkdir -p "$PPBIN"
for _b in bash cat chmod mkdir uname tr grep jq; do
    ln -s "$(command -v "$_b")" "$PPBIN/$_b"
done
cat >"$PPBIN/bw" <<'EOF'
#!/usr/bin/env bash
echo "bw $*" >>"${SEC_TEST_BW_LOG:?SEC_TEST_BW_LOG unset}"
case "${1:-}" in
    unlock)
        if [ -n "${BW_UNLOCK_PASS:-}" ]; then
            echo "bw-env-present" >>"${SEC_TEST_BW_LOG:?SEC_TEST_BW_LOG unset}"
        fi
        if [ -r "/proc/$PPID/cmdline" ]; then
            { printf 'CALLER-CMDLINE: '; tr '\0' ' ' <"/proc/$PPID/cmdline"; echo; } >>"${SEC_TEST_BW_LOG:?SEC_TEST_BW_LOG unset}"
        fi
        echo "session-tok-123"
        ;;
    *) exit 0 ;;
esac
EOF
chmod +x "$PPBIN/bw"
H11="$(new_home "$WORK/h11")"
mkdir -p "$H11/.cache/bitwarden"
printf 'rot-pass' >"$H11/.cache/bitwarden/master_pass"
chmod 600 "$H11/.cache/bitwarden/master_pass"
: >"$BWLOG"
set +e
OUT="$(env -i "PATH=$PPBIN" "HOME=$H11" "SEC_ALLOW_PLAINTEXT_MASTER_PASS=1" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_BWS_LOG=$BWSLOG" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_INF_LOG=$INFLOG" \
    "$REPO_ROOT/bin/bw-session-keeper" rotate 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "Vault unlocked successfully" <<<"$OUT"; then pass "auto-rotate unlocks via stored pass"; else fail "auto-rotate rc=$RC out=$OUT"; fi
if grep -q "CALLER-CMDLINE:.*rot-pass" "$BWLOG"; then fail "master password present on caller argv: $(grep CALLER-CMDLINE "$BWLOG")"; else pass "master password absent from the keeper's own argv"; fi
if grep -q 'bw-env-present' "$BWLOG"; then pass "auto-rotate delivers password via BW_UNLOCK_PASS env"; else fail "auto-rotate did not deliver password via env: $(tr '\n' ';' <"$BWLOG")"; fi

echo "[22l] every completion surface offers the create/organize/keep aliases (issue #56)"
set +e
ZSH_C="$(bash "$REPO_ROOT/bin/sec" completion zsh 2>&1)"
BASH_C="$(bash "$REPO_ROOT/bin/sec" completion bash 2>&1)"
FISH_C="$(bash "$REPO_ROOT/bin/sec" completion fish 2>&1)"
PS1_C="$(bash "$REPO_ROOT/bin/sec" completion ps1 2>&1)"
set -e
_miss=0
for _a in create organize keep; do
    grep -qF "'${_a}:" <<<"$ZSH_C" || { fail "zsh completion omits alias '$_a' (issue #56)"; _miss=1; }
    grep -qE "subcmds=\"[^\"]*\b${_a}\b" <<<"$BASH_C" || { fail "bash completion omits alias '$_a' (issue #56)"; _miss=1; }
    grep -qF -- "-a '${_a}'" <<<"$FISH_C" || { fail "fish completion omits alias '$_a' (issue #56)"; _miss=1; }
done
if grep -qF "GetCommandName() -ieq 'sec.ps1'" <<<"$PS1_C" && grep -qF "@('get', 'set', 'run', 'housekeep', 'migrate')" <<<"$PS1_C"; then
    pass "ps1 completion scopes sec.ps1 to the commands it implements (get/set/run/housekeep/migrate, issue #57)"
else
    fail "ps1 completion advertises commands sec.ps1 rejects (issue #57)"; _miss=1
fi
if [[ $_miss -eq 0 ]]; then pass "zsh/bash/fish completion surfaces offer create/organize/keep; ps1 scoped to sec.ps1's subset"; fi

echo "[22p] every completion surface offers --help/-h and --version/-v, scoped to what each target accepts"
_miss=0
if ! { grep -qF -- "--help" <<<"$ZSH_C" && grep -qF -- "--version" <<<"$ZSH_C"; }; then
    fail "zsh completion omits --help/--version"; _miss=1
fi
if ! grep -qF -- "--help -h --version -v" <<<"$BASH_C"; then
    fail "bash completion omits --help/-h/--version/-v"; _miss=1
fi
if ! grep -qF -- "-a '--help -h --version -v'" <<<"$FISH_C"; then
    fail "fish completion omits --help/-h/--version/-v (issue #60)"; _miss=1
fi
if ! grep -qF -- "\$flags = @('--help', '-h', '--version', '-v')" <<<"$PS1_C"; then
    fail "ps1 completion omits --help/-h/--version/-v for sec/sec.exe (issue #60)"; _miss=1
fi
if ! grep -qF -- "\$corecommands + @('--help', '-h')" <<<"$PS1_C"; then
    fail "ps1 completion does not scope sec.ps1 to --help/-h only (bin/sec.ps1 rejects --version, issue #60)"; _miss=1
fi
if [[ $_miss -eq 0 ]]; then pass "all four surfaces offer --help/-h/--version/-v; sec.ps1 limited to --help/-h"; fi

echo "[22q] every completion surface offers the tenant-prefix words (issue #78)"
_miss=0
if ! grep -qF -- "local -a tenants=(bitwarden bw 1pass op bws vault infisical keychain)" <<<"$ZSH_C"; then
    fail "zsh completion omits the tenant-prefix words"; _miss=1
fi
if ! grep -qF -- 'tenants="bitwarden bw 1pass op bws vault infisical keychain"' <<<"$BASH_C"; then
    fail "bash completion omits the tenant-prefix words"; _miss=1
fi
if ! grep -qF -- "-a 'bitwarden bw 1pass op bws vault infisical keychain'" <<<"$FISH_C"; then
    fail "fish completion omits the tenant-prefix words (issue #78)"; _miss=1
fi
if ! grep -qF -- "\$tenants = @('bitwarden', 'bw', '1pass', 'op', 'bws', 'vault', 'infisical', 'keychain')" <<<"$PS1_C"; then
    fail "ps1 completion omits the tenant-prefix words"; _miss=1
fi
if [[ $_miss -eq 0 ]]; then pass "all four completion surfaces offer the tenant-prefix words"; fi

echo "[22r] every completion surface routes the organize alias to the housekeep subcommands (issue #79)"
_miss=0
if ! grep -qF -- "-n '__fish_seen_subcommand_from housekeep organize'" <<<"$FISH_C"; then
    fail "fish completion omits the housekeep subcommands for the organize alias (issue #79)"; _miss=1
fi
if ! grep -qF -- "housekeep|organize)" <<<"$BASH_C"; then
    fail "bash completion omits the organize alias from the housekeep subcommand arm"; _miss=1
fi
if ! grep -qF -- "housekeep|organize)" <<<"$ZSH_C"; then
    fail "zsh completion omits the organize alias from the housekeep subcommand arm"; _miss=1
fi
if ! grep -qF -- "-in @('housekeep', 'organize')" <<<"$PS1_C"; then
    fail "ps1 completion omits the organize alias from the housekeep subcommand arm"; _miss=1
fi
if [[ $_miss -eq 0 ]]; then pass "all four completion surfaces route organize to the housekeep subcommands"; fi

echo "[22s] every completion surface offers the housekeep revert undo/restore aliases (issue #80)"
_miss=0
if ! grep -qF -- "'revert:Rollback last housekeeping operation' 'undo:Rollback last housekeeping operation (alias of revert)' 'restore:Rollback last housekeeping operation (alias of revert)'" <<<"$ZSH_C"; then
    fail "zsh housekeep completion omits the undo/restore aliases (issue #80)"; _miss=1
fi
if ! grep -qF -- 'compgen -W "plan apply revert undo restore"' <<<"$BASH_C"; then
    fail "bash housekeep completion omits the undo/restore aliases (issue #80)"; _miss=1
fi
if ! grep -qF -- "-a 'plan apply revert undo restore'" <<<"$FISH_C"; then
    fail "fish housekeep completion omits the undo/restore aliases (issue #80)"; _miss=1
fi
if ! grep -qF -- "@('plan', 'apply', 'revert', 'undo', 'restore')" <<<"$PS1_C"; then
    fail "ps1 housekeep completion omits the undo/restore aliases (issue #80)"; _miss=1
fi
if ! grep -qF -- 'revert|undo|restore) cmd_revert ;;' "$REPO_ROOT/bin/sec-organizer"; then
    fail "sec-organizer no longer maps undo/restore to revert; the completion is stale (issue #80)"; _miss=1
fi
if [[ $_miss -eq 0 ]]; then pass "all four completion surfaces offer the housekeep revert undo/restore aliases"; fi

echo "[22t] every completion surface offers the powershell shell word; ps1 reads CommandElements only (issue #81)"
_miss=0
if ! grep -qF -- "'powershell:PowerShell completion (alias of ps1)'" <<<"$ZSH_C"; then
    fail "zsh completion omits the powershell shell word (issue #81)"; _miss=1
fi
if ! grep -qF -- 'compgen -W "zsh bash fish ps1 powershell"' <<<"$BASH_C"; then
    fail "bash completion omits the powershell shell word (issue #81)"; _miss=1
fi
if ! grep -qF -- "-a 'zsh bash fish ps1 powershell'" <<<"$FISH_C"; then
    fail "fish completion omits the powershell shell word (issue #81)"; _miss=1
fi
if ! grep -qF -- "@('zsh', 'bash', 'fish', 'ps1', 'powershell')" <<<"$PS1_C"; then
    fail "ps1 completion omits the powershell shell word (issue #81)"; _miss=1
fi
if ! grep -qF -- "\$elements = \$commandAst.CommandElements" <<<"$PS1_C"; then
    fail "ps1 completion no longer reads CommandElements (issue #81)"; _miss=1
fi
if grep -qF -- "ArgumentElements" <<<"$PS1_C"; then
    fail "ps1 completion still references the nonexistent CommandAst.ArgumentElements (issue #81)"; _miss=1
fi
if [[ $_miss -eq 0 ]]; then pass "all four surfaces offer the powershell shell word; ps1 reads CommandElements only"; fi

echo "[22u] every completion surface splits migrate source (--from) vs destination (--to) backend values (issue #108)"
_miss=0
if ! grep -qF -- "backend:(bitwarden 1password bws)" <<<"$ZSH_C"; then
    fail "zsh --from completion omits the source migrate backend values (issue #108)"; _miss=1
fi
if ! grep -qF -- "backend:(bitwarden 1password bws vault infisical)" <<<"$ZSH_C"; then
    fail "zsh --to completion omits the destination migrate backend values (issue #108)"; _miss=1
fi
if ! grep -qF -- '_mb="bitwarden 1password bws"; [[ ${prev} == "--to" ]] && _mb="bitwarden 1password bws vault infisical"' <<<"$BASH_C"; then
    fail "bash completion does not split migrate source vs destination backends (issue #108)"; _miss=1
fi
if ! grep -qF -- "-a 'bitwarden 1password bws'" <<<"$FISH_C"; then
    fail "fish --from completion omits the source migrate backend values (issue #108)"; _miss=1
fi
if ! grep -qF -- "-a 'bitwarden 1password bws vault infisical'" <<<"$FISH_C"; then
    fail "fish --to completion omits the destination migrate backend values (issue #108)"; _miss=1
fi
if ! grep -qF -- "@('bitwarden', '1password', 'bws'); if" <<<"$PS1_C"; then
    fail "ps1 completion does not offer the migrate source backends (issue #108)"; _miss=1
fi
if ! grep -qF -- "+= @('vault', 'infisical')" <<<"$PS1_C"; then
    fail "ps1 completion does not offer the migrate destination backends (issue #108)"; _miss=1
fi
if [[ $_miss -eq 0 ]]; then pass "all four completion surfaces split migrate source vs destination backend values"; fi

echo "[22v] every completion surface offers the bare help/version subcommands (issue #82)"
_miss=0
if ! grep -qF -- "'help:Display help menu (alias of -h/--help)'" <<<"$ZSH_C" || ! grep -qF -- "'version:Display version (alias of -v/--version)'" <<<"$ZSH_C"; then
    fail "zsh completion omits the bare help/version subcommands (issue #82)"; _miss=1
fi
if ! grep -qF -- 'completion help version --help' <<<"$BASH_C"; then
    fail "bash completion omits the bare help/version subcommands (issue #82)"; _miss=1
fi
if ! grep -qF -- "-a 'help'" <<<"$FISH_C" || ! grep -qF -- "-a 'version'" <<<"$FISH_C"; then
    fail "fish completion omits the bare help/version subcommands (issue #82)"; _miss=1
fi
if ! grep -qF -- "'completion', 'help', 'version')" <<<"$PS1_C"; then
    fail "ps1 completion omits the bare help/version subcommands (issue #82)"; _miss=1
fi
if bash "$REPO_ROOT/bin/sec" help >/dev/null 2>&1 && bash "$REPO_ROOT/bin/sec" version >/dev/null 2>&1; then
    :
else
    fail "sec help / sec version no longer run; the completion advertises a dead spelling (issue #82)"; _miss=1
fi
if [[ $_miss -eq 0 ]]; then pass "all four completion surfaces offer the bare help/version subcommands"; fi

echo "[22w] every completion surface offers the get --scope and set/create --type flags (issue #83)"
_miss=0
if ! grep -qF -- "get) _arguments '--scope[Scope lookup to a bw folder or op vault]:scope name:'" <<<"$ZSH_C"; then
    fail "zsh completion omits the get --scope flag (issue #83)"; _miss=1
fi
if ! grep -qF -- "set|create) _arguments '--type[Secret item type]:type:(login note card identity)'" <<<"$ZSH_C"; then
    fail "zsh completion omits the set/create --type flag (issue #83)"; _miss=1
fi
if ! grep -qF -- 'compgen -W "--scope"' <<<"$BASH_C"; then
    fail "bash completion omits the get --scope flag (issue #83)"; _miss=1
fi
if ! grep -qF -- 'compgen -W "login note card identity"' <<<"$BASH_C"; then
    fail "bash completion omits the set/create --type values (issue #83)"; _miss=1
fi
if ! grep -qF -- "-n '__fish_seen_subcommand_from get' -a '--scope'" <<<"$FISH_C"; then
    fail "fish completion omits the get --scope flag (issue #83)"; _miss=1
fi
if ! grep -qF -- "-a 'login note card identity'" <<<"$FISH_C"; then
    fail "fish completion omits the set/create --type values (issue #83)"; _miss=1
fi
if ! grep -qF -- "@('--scope')" <<<"$PS1_C"; then
    fail "ps1 completion omits the get --scope flag (issue #83)"; _miss=1
fi
if ! grep -qF -- "@('login', 'note', 'card', 'identity')" <<<"$PS1_C"; then
    fail "ps1 completion omits the set/create --type values (issue #83)"; _miss=1
fi
if [[ $_miss -eq 0 ]]; then pass "all four completion surfaces offer the get --scope and set/create --type flags"; fi

echo "[22m] bw set: the secret value reaches jq via env and bw via stdin, never argv (#58)"
JQGUARD="$WORK/jqguard"; mkdir -p "$JQGUARD"
REAL_JQ="$(command -v jq)"
cat >"$JQGUARD/jq" <<JQEOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"\${SEC_TEST_JQ_LOG:?SEC_TEST_JQ_LOG unset}"
exec "$REAL_JQ" "\$@"
JQEOF
chmod +x "$JQGUARD/jq"
JQLOG="$WORK/jqguard.log"; : >"$JQLOG"
: >"$BWLOG"
G58="$(new_home "$WORK/h58")"
set +e
OUT="$(printf 'CANARY-SECRET-58b1\n' | env -i "PATH=$JQGUARD:$FAKEBIN:/usr/bin:/bin" "HOME=$G58" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_JQ_LOG=$JQLOG" \
    "$REPO_ROOT/bin/sec" set N58KEY 2>&1)"
RC=$?
set -e
if [[ $RC -eq 0 ]]; then pass "bw set with a stdin-prompted value exits 0"; else fail "bw set rc=$RC out=$OUT"; fi
if grep -q "CANARY-SECRET-58b1" "$JQLOG"; then
    fail "sec set put the secret value on jq's argv (issue #58): $(tr '\n' ';' <"$JQLOG")"
else
    pass "sec set keeps the secret value off jq's argv"
fi
if grep -qE "^bw .*CANARY-SECRET-58b1" "$BWLOG"; then
    fail "sec set put the secret value on bw's argv (issue #58)"
else
    pass "sec set keeps the secret value off bw's argv"
fi
if grep -q "CANARY-SECRET-58b1" "$BWLOG"; then
    pass "bw received the secret value via stdin"
else
    fail "bw never received the secret value (stdin capture empty): $(tr '\n' ';' <"$BWLOG")"
fi

echo "[22n] sec-migrator (bw target) keeps the value off jq and bw argv (#59)"
: >"$JQLOG"; : >"$BWLOG"
MG_ITEMS='[{"id":"m1","name":"MGITEM","login":{"password":"CANARY-MIG-59"}}]'
G59="$(new_home "$WORK/h59")"
set +e
OUT="$(env -i "PATH=$JQGUARD:$FAKEBIN:/usr/bin:/bin" "HOME=$G59" \
    "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_JQ_LOG=$JQLOG" "SEC_TEST_BW_ITEMS=$MG_ITEMS" \
    "$REPO_ROOT/bin/sec" migrate --from bitwarden --to bw --apply 2>&1 </dev/null)"
RC=$?
set -e
if [[ $RC -eq 0 ]] && grep -q "MIGRATING" <<<"$OUT"; then pass "migrate apply (bw target) ran"; else fail "migrate apply rc=$RC out=$OUT"; fi
if grep -q "CANARY-MIG-59" "$JQLOG"; then
    fail "sec-migrator put the secret value on jq's argv (issue #59): $(tr '\n' ';' <"$JQLOG")"
else
    pass "sec-migrator keeps the secret value off jq's argv"
fi
if grep -qE "^bw .*CANARY-MIG-59" "$BWLOG"; then
    fail "sec-migrator put the secret value on bw's argv (issue #59)"
else
    pass "sec-migrator keeps the secret value off bw's argv"
fi
if grep -q "CANARY-MIG-59" "$BWLOG"; then
    pass "sec-migrator delivered the secret value to bw via stdin"
else
    fail "sec-migrator never delivered the secret value via stdin: $(tr '\n' ';' <"$BWLOG")"
fi

echo "[22o] op/vault/infisical storers keep the value off argv (op,vault via stdin; infisical via file) (#59)"
SBIN="$WORK/sbin"; mkdir -p "$SBIN"
OPSLOG="$WORK/op.stdin.log"; VAULTSLOG="$WORK/vault.stdin.log"; INFFLOG="$WORK/inf.file.log"
cat >"$SBIN/op" <<'EOF'
#!/usr/bin/env bash
printf 'op %s\n' "${*//$'\n'/ }" >>"${SEC_TEST_OP_LOG:?SEC_TEST_OP_LOG unset}"
case "${1:-} ${2:-}" in
    "item create")
        _in=""
        if [ ! -t 0 ]; then _in="$(cat)"; fi
        printf '%s' "$_in" >>"${SEC_TEST_OP_STDIN_LOG:?SEC_TEST_OP_STDIN_LOG unset}"
        if [ -n "$_in" ]; then printf '%s' "$_in" | jq -e '.fields[] | select(.id == "password") | .value' >/dev/null 2>&1 || exit 3; fi
        echo '{"id":"op-created"}'
        ;;
    "item list") echo '[]' ;;
esac
if [ "${1:-}" = "whoami" ]; then exit 0; fi
exit 0
EOF
chmod +x "$SBIN/op"
cat >"$SBIN/vault" <<'EOF'
#!/usr/bin/env bash
printf 'vault %s\n' "${*//$'\n'/ }" >>"${SEC_TEST_VAULT_LOG:?SEC_TEST_VAULT_LOG unset}"
if [ "${1:-} ${2:-}" = "kv put" ] && [ ! -t 0 ]; then
    cat >>"${SEC_TEST_VAULT_STDIN_LOG:?SEC_TEST_VAULT_STDIN_LOG unset}"
fi
exit 0
EOF
chmod +x "$SBIN/vault"
cat >"$SBIN/infisical" <<'EOF'
#!/usr/bin/env bash
printf 'infisical %s\n' "${*//$'\n'/ }" >>"${SEC_TEST_INF_LOG:?SEC_TEST_INF_LOG unset}"
if [ "${1:-} ${2:-}" = "secrets set" ]; then
    for _a in "$@"; do
        case "$_a" in
            *@/*) _p="${_a#*@}"; if [ -f "$_p" ]; then cat "$_p" >>"${SEC_TEST_INF_FILE_LOG:?SEC_TEST_INF_FILE_LOG unset}"; fi ;;
        esac
    done
fi
exit 0
EOF
chmod +x "$SBIN/infisical"

: >"$OPLOG"; : >"$OPSLOG"
G59op="$(new_home "$WORK/h59op")"
set +e
printf 'CANARY-OP-59\n' | env -i "PATH=$SBIN:$FAKEBIN:/usr/bin:/bin" "HOME=$G59op" \
    "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_OP_STDIN_LOG=$OPSLOG" \
    "$REPO_ROOT/bin/sec" 1pass set OPK59 >/dev/null 2>&1
RC=$?
set -e
if [[ $RC -eq 0 ]]; then pass "1pass set with a stdin-prompted value exits 0"; else fail "1pass set rc=$RC"; fi
if grep -qF "CANARY-OP-59" "$OPLOG"; then
    fail "sec set put the secret value on op's argv (issue #59): $(tr '\n' ';' <"$OPLOG")"
else
    pass "sec set keeps the secret value off op's argv"
fi
if grep -qF "CANARY-OP-59" "$OPSLOG"; then
    pass "op received the secret value via stdin"
else
    fail "op never received the secret value via stdin: $(tr '\n' ';' <"$OPSLOG")"
fi

MG59='[{"id":"m1","name":"MG59","login":{"password":"CANARY-MIG59"}}]'
: >"$OPLOG"; : >"$OPSLOG"
G59mop="$(new_home "$WORK/h59mop")"
set +e
env -i "PATH=$SBIN:$FAKEBIN:/usr/bin:/bin" "HOME=$G59mop" \
    "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_OP_STDIN_LOG=$OPSLOG" "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_BW_ITEMS=$MG59" \
    "$REPO_ROOT/bin/sec" migrate --from bitwarden --to op --apply >/dev/null 2>&1 </dev/null
RC=$?
set -e
if [[ $RC -eq 0 ]]; then pass "migrate apply (op target) ran"; else fail "migrate apply (op) rc=$RC"; fi
if grep -qF "CANARY-MIG59" "$OPLOG"; then
    fail "sec-migrator put the secret value on op's argv (issue #59): $(tr '\n' ';' <"$OPLOG")"
else
    pass "sec-migrator keeps the secret value off op's argv"
fi
if grep -qF "CANARY-MIG59" "$OPSLOG"; then
    pass "sec-migrator delivered the secret value to op via stdin"
else
    fail "sec-migrator never delivered the secret value to op via stdin"
fi

: >"$OPLOG"; : >"$OPSLOG"
G1p="$(new_home "$WORK/h1passapply")"
set +e
env -i "PATH=$SBIN:$FAKEBIN:/usr/bin:/bin" "HOME=$G1p" \
    "SEC_TEST_OP_LOG=$OPLOG" "SEC_TEST_OP_STDIN_LOG=$OPSLOG" "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_BW_ITEMS=$MG59" \
    "$REPO_ROOT/bin/sec" migrate --from bitwarden --to 1pass --apply >/dev/null 2>&1 </dev/null
RC=$?
set -e
if [[ $RC -eq 0 ]]; then pass "migrate apply (1pass alias target) ran"; else fail "migrate apply (1pass alias target) rc=$RC"; fi

: >"$VAULTLOG"; : >"$VAULTSLOG"
G59v="$(new_home "$WORK/h59v")"
set +e
env -i "PATH=$SBIN:$FAKEBIN:/usr/bin:/bin" "HOME=$G59v" \
    "SEC_TEST_VAULT_LOG=$VAULTLOG" "SEC_TEST_VAULT_STDIN_LOG=$VAULTSLOG" "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_BW_ITEMS=$MG59" \
    "$REPO_ROOT/bin/sec" migrate --from bitwarden --to vault --apply >/dev/null 2>&1 </dev/null
RC=$?
set -e
if [[ $RC -eq 0 ]]; then pass "migrate apply (vault target) ran"; else fail "migrate apply (vault) rc=$RC"; fi
if grep -qF "CANARY-MIG59" "$VAULTLOG"; then
    fail "sec-migrator put the secret value on vault's argv (issue #59): $(tr '\n' ';' <"$VAULTLOG")"
else
    pass "sec-migrator keeps the secret value off vault's argv"
fi
if grep -qF "CANARY-MIG59" "$VAULTSLOG"; then
    pass "sec-migrator delivered the secret value to vault via stdin"
else
    fail "sec-migrator never delivered the secret value to vault via stdin"
fi

: >"$INFLOG"; : >"$INFFLOG"
G59i="$(new_home "$WORK/h59i")"
set +e
env -i "PATH=$SBIN:$FAKEBIN:/usr/bin:/bin" "HOME=$G59i" \
    "SEC_TEST_INF_LOG=$INFLOG" "SEC_TEST_INF_FILE_LOG=$INFFLOG" "SEC_TEST_BW_LOG=$BWLOG" "SEC_TEST_BW_ITEMS=$MG59" \
    "$REPO_ROOT/bin/sec" migrate --from bitwarden --to infisical --apply >/dev/null 2>&1 </dev/null
RC=$?
set -e
if [[ $RC -eq 0 ]]; then pass "migrate apply (infisical target) ran"; else fail "migrate apply (infisical) rc=$RC"; fi
if grep -qF "CANARY-MIG59" "$INFLOG"; then
    fail "sec-migrator put the secret value on infisical's argv (issue #59): $(tr '\n' ';' <"$INFLOG")"
else
    pass "sec-migrator keeps the secret value off infisical's argv"
fi
if grep -qF "CANARY-MIG59" "$INFFLOG"; then
    pass "sec-migrator delivered the secret value to infisical via a 0600 file (@file)"
else
    fail "sec-migrator never delivered the secret value to infisical via file"
fi

echo "[32] bin/sec never expands a possibly-empty array bare (issue #137: bash 3.2 + set -u)"
BARE_ARR=""
while IFS= read -r _arname; do
    [[ -z "$_arname" ]] && continue
    grep -qE "^[[:space:]]*${_arname}=\(\)" "$REPO_ROOT/bin/sec" || continue
    BARE_ARR="$BARE_ARR $_arname"
done < <(sed 's/^/ /' "$REPO_ROOT/bin/sec" \
    | grep -oE '.\$\{[A-Za-z_][A-Za-z0-9_]*\[@\]\}' \
    | sed -E -e 's/^\+.*$//' -e 's/^.?\$\{([A-Za-z_][A-Za-z0-9_]*)\[@\]\}$/\1/' \
    | sort -u)
if [[ -z "$BARE_ARR" ]]; then
    pass "bin/sec expands no array bare (every [ @ ] expansion is \${A[@]+\${A[@]}}-guarded)"
else
    fail "bin/sec expands these possibly-empty arrays bare, which is a fatal unbound variable under set -u on bash < 4.4 (issue #137):$BARE_ARR"
fi

echo
if [[ $FAILS -eq 0 ]]; then
    echo "ALL TESTS PASSED"
    exit 0
fi
echo "$FAILS test(s) failed"
exit 1
