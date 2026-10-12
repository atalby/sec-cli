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
if grep -q "\[ OK \] skills tree: .* skill dir(s), registry .* row(s)" <<<"$OUT"; then
    ok "--list reports the live skills tree and registry row census"
else
    no "--list skills tree census line missing"
fi
if grep -q "\[ OK \] skills registry: ADAPTERS.md's census matches" <<<"$OUT"; then
    ok "--list reports the ADAPTERS.md skills registry census verdict"
else
    no "--list skills registry verdict line missing"
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

echo "[14] ADAPTERS.md's per-suite '(N sections|cases)' counts match the live suites (issue #87)"
WORK_S="$(mktemp -d)"
WORK_T="$(mktemp -d)"
for W in "$WORK_S" "$WORK_T"; do
    cp -a "$REPO_ROOT/." "$W/"
    rm -rf "$W/.git"
done
python3 - "$WORK_S/ADAPTERS.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(test_dispatch\.sh`\s*\()\d+", r"\g<1>999", s, count=1)
if n != 1:
    sys.exit("ADAPTERS per-suite dispatch count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_S" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted ADAPTERS per-suite count"
else
    no "coverage accepted a drifted ADAPTERS per-suite count"
fi
if grep -q "ADAPTERS.md says 999 for tests/test_dispatch.sh" <<<"$OUT"; then
    ok "coverage names the drifted ADAPTERS per-suite count"
else
    no "coverage did not name the drifted ADAPTERS per-suite count"
fi
OUT="$(cd "$WORK_T" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct ADAPTERS per-suite counts) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[15] docs/ARCHITECTURE.md's producer census matches the live bin/ emitters (issue #88)"
WORK_U="$(mktemp -d)"
WORK_V="$(mktemp -d)"
WORK_W="$(mktemp -d)"
for W in "$WORK_U" "$WORK_V" "$WORK_W"; do
    cp -a "$REPO_ROOT/." "$W/"
    rm -rf "$W/.git"
done
python3 - "$WORK_U/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(All )\w+( producers \()", r"\g<1>three\g<2>", s)
if n != 1:
    sys.exit("ARCHITECTURE producer count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_V/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(`sec\.ps1`\))", "`bogus-tool`)", s)
if n != 1:
    sys.exit("ARCHITECTURE producer list not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_U" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted ARCHITECTURE producer count"
else
    no "coverage accepted a drifted ARCHITECTURE producer count"
fi
if grep -q "ARCHITECTURE.md says three producers, live tree has" <<<"$OUT"; then
    ok "coverage names the drifted ARCHITECTURE producer count"
else
    no "coverage did not name the drifted ARCHITECTURE producer count"
fi
OUT="$(cd "$WORK_V" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted ARCHITECTURE producer list"
else
    no "coverage accepted a drifted ARCHITECTURE producer list"
fi
if grep -q "ARCHITECTURE.md lists producers" <<<"$OUT"; then
    ok "coverage names the drifted ARCHITECTURE producer list"
else
    no "coverage did not name the drifted ARCHITECTURE producer list"
fi
OUT="$(cd "$WORK_W" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct ARCHITECTURE producer census) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[16] ADAPTERS.md's skills registry census matches the live skills/ tree + REGISTRY.md (issue #89)"
WORK_X="$(mktemp -d)"
WORK_Y="$(mktemp -d)"
WORK_Z="$(mktemp -d)"
WORK_V2="$(mktemp -d)"
WORK_CTRL="$(mktemp -d)"
for W in "$WORK_X" "$WORK_Y" "$WORK_Z" "$WORK_V2" "$WORK_CTRL"; do
    cp -a "$REPO_ROOT/." "$W/"
    rm -rf "$W/.git"
done
python3 - "$WORK_X/ADAPTERS.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(\d+) skill dirs under `skills/`", "99 skill dirs under `skills/`", s)
if n != 1:
    sys.exit("ADAPTERS skill-dir count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_Y/ADAPTERS.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(\d+) skill rows", "99 skill rows", s)
if n != 1:
    sys.exit("ADAPTERS skill-row count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_Z/skills/REGISTRY.md" <<'PY'
import re
import sys
p = sys.argv[1]
lines = open(p, encoding="utf-8").read().splitlines(keepends=True)
kept = [ln for ln in lines if not ln.startswith("| moving-stable-tag |")]
if len(kept) == len(lines):
    sys.exit("REGISTRY hub-internal row not found to drop")
open(p, "w", encoding="utf-8").write("".join(kept))
PY
python3 - "$WORK_V2/skills/REGISTRY.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s3, n3 = re.subn(r"`skills/adopt-persona/SKILL\.md`", "`skills/adopt-persona-drifted/SKILL.md`", s)
if n3 != 1:
    sys.exit("REGISTRY skills/ row not found to corrupt")
open(p, "w", encoding="utf-8").write(s3)
PY
OUT="$(cd "$WORK_X" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted ADAPTERS skill-dir count"
else
    no "coverage accepted a drifted ADAPTERS skill-dir count"
fi
if grep -q "ADAPTERS.md's skills registry census says 99 skill dirs" <<<"$OUT"; then
    ok "coverage names the drifted ADAPTERS skill-dir count"
else
    no "coverage did not name the drifted ADAPTERS skill-dir count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_Y" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted ADAPTERS skill-row count"
else
    no "coverage accepted a drifted ADAPTERS skill-row count"
fi
if grep -q "ADAPTERS.md's skills registry census says 99 skill rows" <<<"$OUT"; then
    ok "coverage names the drifted ADAPTERS skill-row count"
else
    no "coverage did not name the drifted ADAPTERS skill-row count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_Z" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when REGISTRY.md drops a hub-internal row"
else
    no "coverage accepted a REGISTRY.md missing a hub-internal row"
fi
if grep -q "hub-internal rows" <<<"$OUT"; then
    ok "coverage names the drifted hub-internal row count"
else
    no "coverage did not name the drifted hub-internal row count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_V2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when a REGISTRY.md skills/ row points at no live skill dir"
else
    no "coverage accepted a REGISTRY.md skills/ row pointing at no live skill dir"
fi
if grep -q "lists a skills/ row for a skill dir that does not exist" <<<"$OUT"; then
    ok "coverage names the REGISTRY.md skills/ row with no live dir"
else
    no "coverage did not name the REGISTRY.md skills/ row with no live dir"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct skills registry census) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[17] bin/ helper counts cited in profile.md + ADAPTERS.md match the live tree (issue #90)"
WORK_S1="$(mktemp -d)"
WORK_S2="$(mktemp -d)"
WORK_S3="$(mktemp -d)"
WORK_SCTRL="$(mktemp -d)"
for W in "$WORK_S1" "$WORK_S2" "$WORK_S3" "$WORK_SCTRL"; do
    cp -a "$REPO_ROOT/." "$W/"
    rm -rf "$W/.git"
done
python3 - "$WORK_S1/skills/architecture-360-audit/profile.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"`bin/sec` and (\w+) sibling dispatchers",
                "`bin/sec` and nine sibling dispatchers", s)
if n != 1:
    sys.exit("profile.md bin/ sibling-dispatcher count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_S2/ADAPTERS.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"plus the (\w+) sibling `bin/` helpers the suite references",
                "plus the nine sibling `bin/` helpers the suite references", s)
if n != 1:
    sys.exit("ADAPTERS.md dispatch-suite helper count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_S3/tests/test_dispatch.sh" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"hyer-mcp\.sh", "hyer-mcp-unreferenced.sh", s)
if n < 1:
    sys.exit("test_dispatch.sh bin/hyer-mcp.sh references not found to unhook")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_S1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted profile.md bin/ sibling-dispatcher count"
else
    no "coverage accepted a drifted profile.md bin/ sibling-dispatcher count"
fi
if grep -q "profile.md's bin/ sibling-dispatcher census says 9" <<<"$OUT"; then
    ok "coverage names the drifted profile.md bin/ sibling-dispatcher count"
else
    no "coverage did not name the drifted profile.md bin/ sibling-dispatcher count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_S2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted ADAPTERS.md dispatch-suite helper count"
else
    no "coverage accepted a drifted ADAPTERS.md dispatch-suite helper count"
fi
if grep -q "ADAPTERS.md says nine helper scripts, live tree has" <<<"$OUT"; then
    ok "coverage names the drifted ADAPTERS.md dispatch-suite helper count"
else
    no "coverage did not name the drifted ADAPTERS.md dispatch-suite helper count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_S3" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when a tracked bin/ helper is unreferenced by the dispatch suite"
else
    no "coverage accepted an unreferenced tracked bin/ helper"
fi
if grep -q "is not referenced by tests/test_dispatch.sh" <<<"$OUT"; then
    ok "coverage names the bin/ helper the dispatch suite no longer references"
else
    no "coverage did not name the bin/ helper the dispatch suite no longer references"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_SCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct bin/ helper census) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[18] bash suite count + list cited in profile.md + docs/ARCHITECTURE.md match the live tree (issue #91)"
WORK_T1="$(mktemp -d)"
WORK_T2="$(mktemp -d)"
WORK_T3="$(mktemp -d)"
WORK_T4="$(mktemp -d)"
WORK_TCTRL="$(mktemp -d)"
for W in "$WORK_T1" "$WORK_T2" "$WORK_T3" "$WORK_T4" "$WORK_TCTRL"; do
    cp -a "$REPO_ROOT/." "$W/"
    rm -rf "$W/.git"
done
python3 - "$WORK_T1/skills/architecture-360-audit/profile.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(\w+) suites under `tests/`",
                "nine suites under `tests/`", s)
if n != 1:
    sys.exit("profile.md tests/ suite count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_T2/skills/architecture-360-audit/profile.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"runs all (\w+) suites", "runs all nine suites", s)
if n != 1:
    sys.exit("profile.md CI suite-count claim not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_T3/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(\w+) zero-dependency bash suites",
                "nine zero-dependency bash suites", s)
if n != 1:
    sys.exit("ARCHITECTURE.md bash suite count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_T4/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"`test_write_honesty\.sh`", "`test_write_honesty-v2.sh`", s)
if n != 1:
    sys.exit("ARCHITECTURE.md suite-list entry not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted profile.md tests/ suite count"
else
    no "coverage accepted a drifted profile.md tests/ suite count"
fi
if grep -q "profile.md's tests/ suite census says 9" <<<"$OUT"; then
    ok "coverage names the drifted profile.md tests/ suite count"
else
    no "coverage did not name the drifted profile.md tests/ suite count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted profile.md CI suite count"
else
    no "coverage accepted a drifted profile.md CI suite count"
fi
if grep -q "profile.md's CI row says it runs all nine suites" <<<"$OUT"; then
    ok "coverage names the drifted profile.md CI suite count"
else
    no "coverage did not name the drifted profile.md CI suite count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T3" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted ARCHITECTURE.md bash suite count"
else
    no "coverage accepted a drifted ARCHITECTURE.md bash suite count"
fi
if grep -q "ARCHITECTURE.md says nine zero-dependency bash suites" <<<"$OUT"; then
    ok "coverage names the drifted ARCHITECTURE.md bash suite count"
else
    no "coverage did not name the drifted ARCHITECTURE.md bash suite count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T4" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when ARCHITECTURE.md lists a suite that is not tracked"
else
    no "coverage accepted an ARCHITECTURE.md suite list naming an untracked suite"
fi
if grep -q "ARCHITECTURE.md lists suites that are not the live tracked suites" <<<"$OUT"; then
    ok "coverage names the ARCHITECTURE.md suite absent from the live tree"
else
    no "coverage did not name the ARCHITECTURE.md suite absent from the live tree"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_TCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct suite census) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[19] structural prose claims (tenant aliases, CI checkout pin, principle count) match the live tree (issue #94)"
WORK_U1="$(mktemp -d)"
WORK_U2="$(mktemp -d)"
WORK_U3="$(mktemp -d)"
WORK_U4="$(mktemp -d)"
WORK_UCTRL="$(mktemp -d)"
for W in "$WORK_U1" "$WORK_U2" "$WORK_U3" "$WORK_U4" "$WORK_UCTRL"; do
    cp -a "$REPO_ROOT/." "$W/"
    rm -rf "$W/.git"
done
python3 - "$WORK_U1/docs/MULTI_TENANCY.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"the (\w+) fixed aliases", "the nine fixed aliases", s)
if n != 1:
    sys.exit("MULTI_TENANCY alias count word not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_U2/docs/MULTI_TENANCY.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"1pass/op, bws, vault, infisical, keychain\)",
                "1pass/op, bws, vault, infisical)", s)
if n != 1:
    sys.exit("MULTI_TENANCY alias list not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_U3/skills/architecture-360-audit/profile.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(full commit SHA of )v4\.2\.2", r"\g<1>v9.9.9", s)
if n != 1:
    sys.exit("profile.md CI checkout version not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_U4/docs/OPERATOR_MANUAL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"designed around (\w+) core principles",
                "designed around five core principles", s)
if n != 1:
    sys.exit("OPERATOR_MANUAL principle count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_U1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted MULTI_TENANCY.md alias count"
else
    no "coverage accepted a drifted MULTI_TENANCY.md alias count"
fi
if grep -q "MULTI_TENANCY.md says nine fixed aliases, live bin/sec has 8" <<<"$OUT"; then
    ok "coverage names the drifted MULTI_TENANCY.md alias count"
else
    no "coverage did not name the drifted MULTI_TENANCY.md alias count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_U2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted MULTI_TENANCY.md alias list"
else
    no "coverage accepted a drifted MULTI_TENANCY.md alias list"
fi
if grep -q "MULTI_TENANCY.md's alias list is not the live bin/sec alias set" <<<"$OUT"; then
    ok "coverage names the drifted MULTI_TENANCY.md alias list"
else
    no "coverage did not name the drifted MULTI_TENANCY.md alias list"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_U3" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted profile.md CI checkout version"
else
    no "coverage accepted a drifted profile.md CI checkout version"
fi
if grep -q "profile.md cites actions/checkout version v9.9.9, workflow pins v4.2.2" <<<"$OUT"; then
    ok "coverage names the drifted profile.md CI checkout version"
else
    no "coverage did not name the drifted profile.md CI checkout version"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_U4" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted OPERATOR_MANUAL.md principle count"
else
    no "coverage accepted a drifted OPERATOR_MANUAL.md principle count"
fi
if grep -q "OPERATOR_MANUAL.md says five core principles, live doc lists 4" <<<"$OUT"; then
    ok "coverage names the drifted OPERATOR_MANUAL.md principle count"
else
    no "coverage did not name the drifted OPERATOR_MANUAL.md principle count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_UCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct structural prose claims) exits 0"
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
