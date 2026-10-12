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
trap 'rm -rf "$WORK" "$WORK_A" "$WORK_B" "$WORK_C" "$WORK_D" "$WORK_E" "$WORK_F" "$WORK_G" "$WORK_H" "$WORK_I" "$WORK_J" "$WORK_K" "$WORK_L"' EXIT
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

echo "[5] a stale-content citation is detected (anchor-content lint, issue #34)"
WORK_A="$(mktemp -d)"
WORK_B="$(mktemp -d)"
for W in "$WORK_A" "$WORK_B"; do
    cp -a "$REPO_ROOT/." "$W/"
    rm -rf "$W/.git"
done
printf '\nStale anchor: `usage()` at `bin/sec:1`\n' >>"$WORK_A/skills/architecture-360-audit/profile.md"
OUT="$(cd "$WORK_A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" citations 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "lint exits nonzero on a stale-content anchor"
else
    no "lint accepted a stale-content anchor"
fi
if grep -q "bin/sec:1" <<<"$OUT"; then
    ok "lint names the stale anchor"
else
    no "lint did not name the stale anchor"
fi
USAGE_LINE="$(grep -nE '^usage\(\) \{' "$WORK_B/bin/sec" | head -1 | cut -d: -f1)"
printf '\nControl anchor: `usage()` at `bin/sec:%s`\n' "$USAGE_LINE" >>"$WORK_B/skills/architecture-360-audit/profile.md"
OUT="$(cd "$WORK_B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" citations 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "lint accepts a well-formed anchor"
else
    no "lint rejected a well-formed anchor"
    printf '%s\n' "$OUT"
fi

WORK_K="$(mktemp -d)"
WORK_L="$(mktemp -d)"
for W in "$WORK_K" "$WORK_L"; do
    cp -a "$REPO_ROOT/." "$W/"
    rm -rf "$W/.git"
done
printf '\nQuoted stale: "uo pipefail" cited at `tests/test_sentinel.sh:3`\n' >>"$WORK_K/skills/architecture-360-audit/profile.md"
OUT="$(cd "$WORK_K" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" citations 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "lint exits nonzero on a stale quoted-prose anchor"
else
    no "lint accepted a stale quoted-prose anchor"
fi
if grep -q "tests/test_sentinel.sh:3" <<<"$OUT"; then
    ok "lint names the stale quoted-prose anchor"
else
    no "lint did not name the stale quoted-prose anchor"
fi
printf '\nQuoted control: "uo pipefail" cited at `tests/test_sentinel.sh:2`\n' >>"$WORK_L/skills/architecture-360-audit/profile.md"
OUT="$(cd "$WORK_L" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" citations 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "lint accepts a well-formed quoted-prose anchor"
else
    no "lint rejected a well-formed quoted-prose anchor"
    printf '%s\n' "$OUT"
fi

echo "[6] a phantom identifier claim is detected (claim-existence lint, issue #35)"
PH="SEC_$(printf 'PHANTOM')_$(printf 'BACKEND')_KEY"
WORK_C="$(mktemp -d)"
WORK_D="$(mktemp -d)"
for W in "$WORK_C" "$WORK_D"; do
    cp -a "$REPO_ROOT/." "$W/"
    rm -rf "$W/.git"
done
printf '\nPhantom claim: `%s` read at startup\n' "$PH" >>"$WORK_C/skills/architecture-360-audit/profile.md"
OUT="$(cd "$WORK_C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" citations 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "lint exits nonzero on a phantom identifier"
else
    no "lint accepted a phantom identifier"
fi
if grep -q "$PH" <<<"$OUT"; then
    ok "lint names the phantom identifier"
else
    no "lint did not name the phantom identifier"
fi
printf '\nControl claim: `SEC_SYNC_TIMEOUT` bounds each backend call\n' >>"$WORK_D/skills/architecture-360-audit/profile.md"
OUT="$(cd "$WORK_D" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" citations 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "lint accepts a real identifier"
else
    no "lint rejected a real identifier"
    printf '%s\n' "$OUT"
fi

echo "[7] the coverage denominator in profile.md matches the live tracked-file count (issue #46)"
WORK_E="$(mktemp -d)"
WORK_F="$(mktemp -d)"
for W in "$WORK_E" "$WORK_F"; do
    cp -a "$REPO_ROOT/." "$W/"
    rm -rf "$W/.git"
done
REAL_COUNT="$(cd "$REPO_ROOT" && git ls-files | wc -l | tr -d ' ')"
DOC_COUNT="$(grep -oE 'Denominator: \*\*[0-9]+ tracked files' "$REPO_ROOT/skills/architecture-360-audit/profile.md" | grep -oE '[0-9]+' | head -1)"
if [[ -n "$DOC_COUNT" && "$REAL_COUNT" == "$DOC_COUNT" ]]; then
    ok "profile.md denominator ($DOC_COUNT) matches tracked files ($REAL_COUNT)"
else
    no "profile.md denominator (${DOC_COUNT:-none}) != tracked files ($REAL_COUNT)"
fi
python3 - "$WORK_E/skills/architecture-360-audit/profile.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
open(p, "w", encoding="utf-8").write(
    re.sub(r"(Denominator: \*\*)\d+( tracked files)", r"\g<1>999999\g<2>", s, count=1)
)
PY
OUT="$(cd "$WORK_E" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted denominator"
else
    no "coverage accepted a drifted denominator"
fi
if grep -q "denominator" <<<"$OUT"; then
    ok "coverage names the denominator mismatch"
else
    no "coverage did not name the denominator mismatch"
fi
OUT="$(cd "$WORK_F" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct denominator) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[8] HISTORY.md must stay rotated into history/ archives (issue #47)"
WORK_G="$(mktemp -d)"
WORK_H="$(mktemp -d)"
for W in "$WORK_G" "$WORK_H"; do
    cp -a "$REPO_ROOT/." "$W/"
    rm -rf "$W/.git"
done
printf '\n### 2026-99-99 — injected dated entry\n- x\n' >>"$WORK_G/HISTORY.md"
OUT="$(cd "$WORK_G" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a dated entry in HISTORY.md"
else
    no "coverage accepted a dated entry in HISTORY.md"
fi
if grep -q "HISTORY.md" <<<"$OUT"; then
    ok "coverage names HISTORY.md"
else
    no "coverage did not name HISTORY.md"
fi
OUT="$(cd "$WORK_H" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (rotated history) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[9] cited suite section counts must match the live suites (the #48 drift class)"
WORK_I="$(mktemp -d)"
WORK_J="$(mktemp -d)"
for W in "$WORK_I" "$WORK_J"; do
    cp -a "$REPO_ROOT/." "$W/"
    rm -rf "$W/.git"
done
python3 - "$WORK_I/skills/architecture-360-audit/profile.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"(test_dispatch\.sh` -> ALL TESTS PASSED \()[0-9]+( sections\))",
    r"\g<1>999\g<2>",
    s,
    count=1,
)
if n != 1:
    sys.exit("dispatch count row not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_I" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted suite count"
else
    no "coverage accepted a drifted suite count"
fi
if grep -q "test_dispatch.sh" <<<"$OUT"; then
    ok "coverage names the drifted suite"
else
    no "coverage did not name the drifted suite"
fi
OUT="$(cd "$WORK_J" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct suite counts) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[10] the runtime-dependency sentence names jq's real reach, not housekeep alone (issue #54)"
for f in README.md docs/ARCHITECTURE.md; do
    line="$(grep -m1 'Runtime dependencies beyond coreutils' "$REPO_ROOT/$f" || true)"
    if [[ -n "$line" ]]; then
        ok "$f states its runtime dependencies"
    else
        no "$f has no runtime-dependency sentence"
    fi
    if grep -qE 'jq` \(housekeep\)' <<<"$line"; then
        no "$f claims jq is housekeep-only"
    else
        ok "$f does not claim jq is housekeep-only"
    fi
    if grep -qE 'jq` \([^)]*get[^)]*\)' <<<"$line"; then
        ok "$f names the get path among jq's uses"
    else
        no "$f omits the get path from jq's uses"
    fi
done
if grep -q 'jq: housekeep;' "$REPO_ROOT/install.sh"; then
    no "install.sh warning claims jq is housekeep-only"
else
    ok "install.sh warning does not claim jq is housekeep-only"
fi
if grep -qE 'jq: [^;]*get' "$REPO_ROOT/install.sh"; then
    ok "install.sh warning names the get path among jq's uses"
else
    no "install.sh warning omits the get path from jq's uses"
fi

echo "[11] cited census counts match the live tree (the #49 drift class, issue #84)"
WORK_K="$(mktemp -d)"
WORK_L="$(mktemp -d)"
WORK_M="$(mktemp -d)"
for W in "$WORK_K" "$WORK_L" "$WORK_M"; do
    cp -a "$REPO_ROOT/." "$W/"
    rm -rf "$W/.git"
done
python3 - "$WORK_K/skills/architecture-360-audit/profile.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(Markdown \()\d+(\s+files?\))", r"\g<1>999\g<2>", s, count=1)
if n != 1:
    sys.exit("ecosystem markdown census not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_K" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted ecosystem census"
else
    no "coverage accepted a drifted ecosystem census"
fi
if grep -q "census" <<<"$OUT"; then
    ok "coverage names the census mismatch"
else
    no "coverage did not name the census mismatch"
fi
python3 - "$WORK_M/skills/architecture-360-audit/profile.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(`sec-organizer` )\d+", r"\g<1>999", s, count=1)
if n != 1:
    sys.exit("[ TAG ] census row not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_M" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted [ TAG ] census"
else
    no "coverage accepted a drifted [ TAG ] census"
fi
if grep -q "sec-organizer" <<<"$OUT"; then
    ok "coverage names the drifted [ TAG ] census row"
else
    no "coverage did not name the drifted [ TAG ] census row"
fi
OUT="$(cd "$WORK_L" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct census) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[12] ADAPTERS.md's 'current suites' snapshot matches the live suites (issue #85)"
WORK_N="$(mktemp -d)"
WORK_O="$(mktemp -d)"
for W in "$WORK_N" "$WORK_O"; do
    cp -a "$REPO_ROOT/." "$W/"
    rm -rf "$W/.git"
done
python3 - "$WORK_N/ADAPTERS.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(current suites:\s*dispatch\s+)\d+", r"\g<1>999", s, count=1)
if n != 1:
    sys.exit("ADAPTERS 'current suites' dispatch count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_N" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted ADAPTERS suite snapshot"
else
    no "coverage accepted a drifted ADAPTERS suite snapshot"
fi
if grep -q "ADAPTERS.md says dispatch 999" <<<"$OUT"; then
    ok "coverage names the drifted ADAPTERS suite snapshot"
else
    no "coverage did not name the drifted ADAPTERS suite snapshot"
fi
OUT="$(cd "$WORK_O" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct ADAPTERS snapshot) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[13] profile.md's cited pack taxonomy matches PACK.md (issue #86)"
WORK_P="$(mktemp -d)"
WORK_Q="$(mktemp -d)"
WORK_R="$(mktemp -d)"
for W in "$WORK_P" "$WORK_Q" "$WORK_R"; do
    cp -a "$REPO_ROOT/." "$W/"
    rm -rf "$W/.git"
done
python3 - "$WORK_P/skills/architecture-360-audit/profile.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(`packs/solo-founder-governance`\s*)v\d+\.\d+\.\d+", r"\g<1>v9.9.9", s, count=1)
if n != 1:
    sys.exit("profile.md pack version not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_Q/skills/architecture-360-audit/profile.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(It defines\s+)nine(\s+roles)", r"\g<1>eight\g<2>", s, count=1)
if n != 1:
    sys.exit("profile.md 'nine roles' phrase not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_P" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a stale pack version"
else
    no "coverage accepted a stale pack version"
fi
if grep -q "pack: profile.md cites pack v9.9.9" <<<"$OUT"; then
    ok "coverage names the stale pack version"
else
    no "coverage did not name the stale pack version"
fi
OUT="$(cd "$WORK_Q" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a stale pack role count"
else
    no "coverage accepted a stale pack role count"
fi
if grep -q "pack: profile.md says the pack defines eight roles" <<<"$OUT"; then
    ok "coverage names the stale pack role count"
else
    no "coverage did not name the stale pack role count"
fi
OUT="$(cd "$WORK_R" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct pack prose) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo
if [[ $fail -eq 0 ]]; then
    echo "ALL TESTS PASSED"
    exit 0
fi
echo "$fail test(s) failed"
exit 1
