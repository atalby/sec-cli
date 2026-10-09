#!/usr/bin/env bash
# tests/test_sync_guard.sh — zero-dependency regression tests for
# bin/sec-sync-controller.py safety guards (issue #3) and the
# dispatcher's sync usage line.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

FAILS=0
pass() { echo "  ok: $1"; }
fail() { echo "  FAIL: $1"; FAILS=$((FAILS + 1)); }

FAKEBIN="$WORK/fakebin"
mkdir -p "$FAKEBIN"
CANARY="$WORK/gcloud-canary.log"
cat >"$FAKEBIN/gcloud" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null 2>&1 || true
echo "gcloud $*" >>"${SEC_TEST_CANARY:?SEC_TEST_CANARY unset}"
rc=0
case "$*" in
    *"versions add"*) rc="${SEC_TEST_GCLOUD_RC:-0}" ;;
esac
if [ "${SEC_TEST_GCLOUD_FAIL:-0}" = "1" ]; then rc=1; fi
if [ "$rc" != "0" ]; then echo "shim: simulated backend failure" >&2; fi
exit "$rc"
EOF
chmod +x "$FAKEBIN/gcloud"

CTRL="$REPO_ROOT/bin/sec-sync-controller.py"

# run_ctrl [NAME=VALUE ...] -- [controller flags ...]
# Everything before a literal -- is an environment assignment for the
# sanitized env; everything after it goes to the controller as a flag.
run_ctrl() {
    local envs=() flags=() seen=0 a
    for a in "$@"; do
        if [[ "$a" == "--" ]]; then seen=1; continue; fi
        if [[ $seen -eq 0 ]]; then envs+=("$a"); else flags+=("$a"); fi
    done
    env -i "PATH=$FAKEBIN:/usr/bin:/bin" "SEC_TEST_CANARY=$CANARY" \
        ${envs[@]+"${envs[@]}"} python3 "$CTRL" ${flags[@]+"${flags[@]}"}
}

echo "[1] --dry-run previews present keys without writing anywhere"
rm -f "$CANARY"
set +e
OUT1="$(run_ctrl GEMINI_API_KEY=fake-gem-key GITLAB_TOKEN=fake-gl -- --dry-run 2>&1)"
RC1=$?
set -e
if [[ $RC1 -eq 0 ]]; then pass "--dry-run exits 0"; else fail "--dry-run exited $RC1, expected 0"; fi
if grep -q "^\[INFO\] SEC CENTRAL SECRET SYNC CONTROLLER — DRY RUN" <<<"$OUT1"; then pass "output announces tagged dry-run mode"; else fail "output does not announce tagged dry-run mode"; fi
if grep -q "gemini-api-key" <<<"$OUT1"; then pass "plan lists present key name"; else fail "plan does not list present key name"; fi
if grep -q "fake-gem-key" <<<"$OUT1"; then fail "dry-run LEAKED a secret value"; else pass "no secret values printed"; fi
if [[ -f "$CANARY" ]]; then fail "dry-run invoked gcloud (canary fired)"; else pass "dry-run never invoked gcloud"; fi

echo "[2] non-interactive run without --yes refuses to push (exit 2)"
rm -f "$CANARY"
set +e
OUT2="$(run_ctrl GEMINI_API_KEY=fake-gem-key -- </dev/null 2>&1)"
RC2=$?
set -e
if [[ $RC2 -eq 2 ]]; then pass "exits 2 (confirmation required)"; else fail "exited $RC2, expected 2"; fi
if grep -qi "confirmation\|--yes" <<<"$OUT2"; then pass "explains how to confirm"; else fail "no confirmation guidance in output"; fi
if [[ -f "$CANARY" ]]; then fail "refused run still invoked gcloud"; else pass "refused run never invoked gcloud"; fi

echo "[3] no keys present fails loudly (exit 1), not a fake success"
set +e
OUT3="$(run_ctrl -- </dev/null 2>&1)"
RC3=$?
set -e
if [[ $RC3 -eq 1 ]]; then pass "exits 1 when zero keys present"; else fail "exited $RC3, expected 1"; fi
if grep -qi "no keys\|no active\|0 keys" <<<"$OUT3"; then pass "says no keys were found"; else fail "does not say no keys were found"; fi

echo "[4] --yes proceeds (gcloud shimmed, no GitLab token = no network)"
rm -f "$CANARY"
set +e
OUT4="$(run_ctrl GEMINI_API_KEY=fake-gem-key -- --yes </dev/null 2>&1)"
RC4=$?
set -e
if [[ $RC4 -eq 0 ]]; then pass "--yes run exits 0"; else fail "--yes run exited $RC4"; fi
if grep -q "secrets versions add gemini-api-key" "$CANARY" 2>/dev/null; then
    pass "gcloud shimmed path received the secret version add"
else
    fail "gcloud shim never saw 'secrets versions add gemini-api-key' (canary: $(cat "$CANARY" 2>/dev/null | tr '\n' ';'))"
fi
if grep -q "^\[WARN\] GITLAB_TOKEN not set; skipping GitLab" <<<"$OUT4"; then
    pass "GitLab skipped without token (no network attempted)"
else
    fail "GitLab skip message missing"
fi
if grep -q "fake-gem-key" <<<"$OUT4"; then fail "--yes run LEAKED a secret value"; else pass "no secret values printed on push"; fi

echo "[5] --help documents the guards; dispatcher usage advertises --dry-run"
set +e
OUTH="$(run_ctrl -- --help 2>&1)"
RCH=$?
set -e
if [[ $RCH -eq 0 ]]; then pass "--help exits 0"; else fail "--help exited $RCH"; fi
if grep -q -- "--dry-run" <<<"$OUTH" && grep -q -- "--yes" <<<"$OUTH"; then
    pass "--help lists --dry-run and --yes"
else
    fail "--help missing --dry-run/--yes"
fi
DHELP="$("$REPO_ROOT/bin/sec" --help 2>&1 || true)"
if grep -q -- "--dry-run" <<<"$DHELP"; then
    pass "sec usage line mentions --dry-run"
else
    fail "sec usage line does not mention --dry-run"
fi

echo "[6] unknown flag is rejected before any work (exit 2, no gcloud)"
rm -f "$CANARY"
set +e
OUT6="$(run_ctrl -- --frobnicate </dev/null 2>&1)"
RC6=$?
set -e
if [[ $RC6 -eq 2 ]]; then pass "unknown flag exits 2"; else fail "unknown flag exited $RC6, expected 2"; fi
if [[ -f "$CANARY" ]]; then fail "unknown flag still invoked gcloud"; else pass "no backend touched on bad usage"; fi

echo "[7] dry-run names the GCP destination from GCP_PROJECT_ID (F044)"
rm -f "$CANARY"
set +e
OUT7="$(run_ctrl GEMINI_API_KEY=fake-gem-key GCP_PROJECT_ID=dest-proj-test -- --dry-run 2>&1)"
RC7=$?
set -e
if [[ $RC7 -eq 0 ]]; then pass "[7] dry-run exits 0"; else fail "[7] dry-run exited $RC7"; fi
if grep -q "dest-proj-test" <<<"$OUT7"; then pass "[7] plan names the configured project"; else fail "[7] plan never names GCP_PROJECT_ID (dest-proj-test)"; fi
if [[ -f "$CANARY" ]]; then fail "[7] destination check touched gcloud in dry-run"; else pass "[7] still zero backend calls in dry-run"; fi

echo "[8] dry-run names the GitLab destination from GITLAB_GROUP_ID (F044)"
set +e
OUT8="$(run_ctrl GEMINI_API_KEY=fake-gem-key GITLAB_TOKEN=fake-gl-token GITLAB_GROUP_ID=dest-group-99 -- --dry-run 2>&1)"
RC8=$?
set -e
if [[ $RC8 -eq 0 ]]; then pass "[8] dry-run exits 0"; else fail "[8] dry-run exited $RC8"; fi
if grep -q "dest-group-99" <<<"$OUT8"; then pass "[8] plan names the configured group"; else fail "[8] plan never names GITLAB_GROUP_ID (dest-group-99)"; fi
if grep -q "skipped" <<<"$OUT8"; then fail "[8] token-set dry-run still shows GitLab skipped"; else pass "[8] GitLab shown as active target when token present"; fi

echo "[9] real --yes push sends --project=<GCP_PROJECT_ID> to gcloud (F044)"
rm -f "$CANARY"
set +e
OUT9="$(run_ctrl GEMINI_API_KEY=fake-gem-key GCP_PROJECT_ID=dest-proj-yes -- --yes </dev/null 2>&1)"
RC9=$?
set -e
if [[ $RC9 -eq 0 ]]; then pass "[9] push exits 0"; else fail "[9] push exited $RC9"; fi
if grep -q -- "--project=dest-proj-yes" "$CANARY" 2>/dev/null; then
    pass "[9] gcloud shim saw the configured project"
else
    fail "[9] canary lacks --project=dest-proj-yes (canary: $(tr '\n' ';' <"$CANARY" 2>/dev/null))"
fi

echo "[10] backend write failure exits 3 with a FAILED notice, no secret leak (F044)"
rm -f "$CANARY"
set +e
OUT10="$(run_ctrl GEMINI_API_KEY=fake-gem-key SEC_TEST_GCLOUD_FAIL=1 -- --yes </dev/null 2>&1)"
RC10=$?
set -e
if [[ $RC10 -eq 3 ]]; then pass "[10] exits 3 on backend write failure"; else fail "[10] exited $RC10, expected 3"; fi
if grep -q "^\[ERROR\] CENTRAL SECRET SYNC FAILED" <<<"$OUT10"; then pass "[10] output marks the sync FAILED with [ERROR] tag"; else fail "[10] no tagged FAILED notice on write failure"; fi
if grep -q "fake-gem-key" <<<"$OUT10"; then fail "[10] failure path LEAKED a secret value"; else pass "[10] no secret values printed on failure"; fi

echo "[11] a failing backend write must exit 3, never a fake success (issue #6)"
rm -f "$CANARY"
set +e
OUT7="$(run_ctrl GEMINI_API_KEY=fake-gem-key SEC_TEST_GCLOUD_RC=1 -- --yes </dev/null 2>&1)"
RC7=$?
set -e
if [[ $RC7 -eq 3 ]]; then pass "failed write exits 3 (backend failure)"; else fail "failed write exited $RC7, expected 3"; fi
if grep -q "^\[ OK \] GCP Secret Manager: .* updated successfully" <<<"$OUT7"; then
    fail "failing gcloud still printed 'updated successfully'"
else
    pass "no false success line on failed write"
fi
if grep -q "shim: simulated backend failure" <<<"$OUT7"; then
    pass "failure notice carries the backend's own stderr"
else
    fail "failure notice omits backend stderr (no root cause)"
fi
if grep -qi "failed" <<<"$OUT7"; then pass "summary reports the failure"; else fail "no failure summary"; fi
if grep -q "fake-gem-key" <<<"$OUT7"; then fail "failure output LEAKED a secret value"; else pass "no secret values printed on failure"; fi

echo "[12] backend timeouts are configured (no unbounded gcloud/urlopen)"
NTO="$(grep -c 'timeout=' "$CTRL" || true)"
if [[ "$NTO" -ge 3 ]]; then pass "controller sets timeout= at $NTO call sites (>=3)"; else fail "only $NTO timeout= sites, expected >=3 (unbounded backend calls)"; fi

echo "[13] --help documents exit 3 so the extended contract is discoverable"
set +e
OUTH3="$(run_ctrl -- --help 2>&1)"
RCH3=$?
set -e
if [[ $RCH3 -eq 0 ]]; then pass "--help exits 0"; else fail "--help exited $RCH3"; fi
if grep -Eq '3 .*backend' <<<"$OUTH3"; then
    pass "--help documents exit 3 (backend write failure)"
else
    fail "--help does not document exit 3"
fi

echo ""
if [[ $FAILS -eq 0 ]]; then
    echo "ALL TESTS PASSED"
    exit 0
fi
echo "$FAILS TEST(S) FAILED"
exit 1
