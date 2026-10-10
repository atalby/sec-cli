#!/usr/bin/env bash
# Runs the four fast bash test suites as part of the pre-commit gate
# (issue #2: pre-commit Step 5 never runs tests/*.sh)
# The heavy test_dispatch.sh suite is opt-in behind SEC_TEST_DISPATCH=1

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_SUITES=(
    "tests/test_install.sh"
    "tests/test_sync_guard.sh"
    "tests/test_write_honesty.sh"
    "tests/test_sentinel.sh"
)

PASS=0
FAIL=0

for _test in "${TEST_SUITES[@]}"; do
    if [ -f "$SCRIPT_DIR/$_test" ]; then
        echo -e "Running test suite: $_test"
        if bash "$SCRIPT_DIR/$_test" >/dev/null 2>&1; then
            echo -e "  ${GREEN}PASSED${NC}"
            PASS=$((PASS + 1))
        else
            echo -e "  ${RED}FAILED${NC}"
            FAIL=$((FAIL + 1))
        fi
    else
        echo -e "  SKIPPED: $_test not found"
    fi
done

echo -e "Fast test suites: ${PASS} passed, ${FAIL} failed"

if [ "$FAIL" -gt 0 ]; then
    echo -e "${YELLOW}One or more fast test suites failed. Review before commit.${NC}"
    exit 1
fi

exit 0
