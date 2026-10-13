#!/usr/bin/env bash
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SENTINEL="$REPO_ROOT/skills/architecture-360-audit/sentinel.sh"

pass=0
fail=0
ok() { echo "  ok: $1"; pass=$((pass + 1)); }
no() { echo "  fail: $1"; fail=$((fail + 1)); }

WORK_ROOT="$(mktemp -d)"
SEED_TAR="$(mktemp "$WORK_ROOT/seed.XXXXXX")"
(cd "$REPO_ROOT" && git ls-files -z | tar --null -T - -cf "$SEED_TAR")
seed() { tar -C "$1" -xf "$SEED_TAR"; }
trap 'rm -rf "$WORK_ROOT"' EXIT

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
WORK="$(mktemp -d "$WORK_ROOT/XXXX")"
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
WORK_A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_B="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_A" "$WORK_B"; do
    seed "$W"
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

WORK_K="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_L="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_K" "$WORK_L"; do
    seed "$W"
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
WORK_C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_D="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_C" "$WORK_D"; do
    seed "$W"
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
WORK_E="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_F="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_E" "$WORK_F"; do
    seed "$W"
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
WORK_G="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_H="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_G" "$WORK_H"; do
    seed "$W"
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
WORK_I="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_J="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_I" "$WORK_J"; do
    seed "$W"
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
WORK_K="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_L="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_M="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_K" "$WORK_L" "$WORK_M"; do
    seed "$W"
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
WORK_N="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_O="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_N" "$WORK_O"; do
    seed "$W"
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
WORK_P="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_Q="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_R="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_P" "$WORK_Q" "$WORK_R"; do
    seed "$W"
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
WORK_S="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_S" "$WORK_T"; do
    seed "$W"
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
WORK_U="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_V="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_W="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_U" "$WORK_V" "$WORK_W"; do
    seed "$W"
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
WORK_X="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_Y="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_Z="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_V2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_X" "$WORK_Y" "$WORK_Z" "$WORK_V2" "$WORK_CTRL"; do
    seed "$W"
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
WORK_S1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S3="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_SCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_S1" "$WORK_S2" "$WORK_S3" "$WORK_SCTRL"; do
    seed "$W"
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
WORK_T1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T3="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T4="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_TCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T1" "$WORK_T2" "$WORK_T3" "$WORK_T4" "$WORK_TCTRL"; do
    seed "$W"
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
WORK_U1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_U2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_U3="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_U4="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_UCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_U1" "$WORK_U2" "$WORK_U3" "$WORK_U4" "$WORK_UCTRL"; do
    seed "$W"
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

echo "[20] bash suite counts cited in SKILL.md match the live tree (issue #95)"
WORK_W1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_W2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_WCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_W1" "$WORK_W2" "$WORK_WCTRL"; do
    seed "$W"
done
python3 - "$WORK_W1/skills/architecture-360-audit/SKILL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"the \w+ `tests/\*\.sh` suites", "the nine `tests/*.sh` suites", s)
if n != 1:
    sys.exit("SKILL.md scanner suite count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_W2/skills/architecture-360-audit/SKILL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"executes all \w+ bash suites", "executes all nine bash suites", s)
if n != 1:
    sys.exit("SKILL.md gate suite count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_W1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted SKILL.md scanner suite count"
else
    no "coverage accepted a drifted SKILL.md scanner suite count"
fi
if grep -q 'SKILL.md says the nine `tests/\*\.sh` suites, live tree has 5' <<<"$OUT"; then
    ok "coverage names the drifted SKILL.md scanner suite count"
else
    no "coverage did not name the drifted SKILL.md scanner suite count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_W2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted SKILL.md gate suite count"
else
    no "coverage accepted a drifted SKILL.md gate suite count"
fi
if grep -q "SKILL.md says the gate executes all nine bash suites, live tree has 5" <<<"$OUT"; then
    ok "coverage names the drifted SKILL.md gate suite count"
else
    no "coverage did not name the drifted SKILL.md gate suite count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_WCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct SKILL.md suite counts) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[21] SKILL.md's own step/persona/scope/severity counts match the live skill files (issue #96)"
WORK_X1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_X2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_X3="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_X4="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_XCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_X1" "$WORK_X2" "$WORK_X3" "$WORK_X4" "$WORK_XCTRL"; do
    seed "$W"
done
python3 - "$WORK_X1/skills/architecture-360-audit/SKILL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"eleven steps", "nine steps", s)
if n < 1:
    sys.exit("SKILL.md step count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_X2/skills/architecture-360-audit/SKILL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"twelve personas", "nine personas", s)
if n < 1:
    sys.exit("SKILL.md persona count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_X3/skills/architecture-360-audit/profile.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"numbered 1 through 12,", "numbered 1 through 9,", s)
if n != 1:
    sys.exit("profile.md numbered-personas claim not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_X4/skills/architecture-360-audit/SKILL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"`blocking`, `important`, `nit`", "`blocking`, `important`, `minor`", s)
if n != 1:
    sys.exit("SKILL.md severity set not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_X1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted SKILL.md step count"
else
    no "coverage accepted a drifted SKILL.md step count"
fi
if grep -q "SKILL.md says 'nine steps', live SKILL.md has 11 '## Step' headings" <<<"$OUT"; then
    ok "coverage names the drifted SKILL.md step count"
else
    no "coverage did not name the drifted SKILL.md step count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_X2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted SKILL.md persona count"
else
    no "coverage accepted a drifted SKILL.md persona count"
fi
if grep -q "SKILL.md says 'nine personas', profile.md declares 12" <<<"$OUT"; then
    ok "coverage names the drifted SKILL.md persona count"
else
    no "coverage did not name the drifted SKILL.md persona count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_X3" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted profile.md numbered-personas claim"
else
    no "coverage accepted a drifted profile.md numbered-personas claim"
fi
if grep -q "profile.md says personas are 'Twelve, numbered 1 through 9', live persona-heading count is 12" <<<"$OUT"; then
    ok "coverage names the drifted profile.md numbered-personas claim"
else
    no "coverage did not name the drifted profile.md numbered-personas claim"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_X4" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted SKILL.md severity set"
else
    no "coverage accepted a drifted SKILL.md severity set"
fi
if grep -q "SKILL.md's severity set is" <<<"$OUT"; then
    ok "coverage names the drifted SKILL.md severity set"
else
    no "coverage did not name the drifted SKILL.md severity set"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_XCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct SKILL.md structural counts) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[22] profile.md §3 count-words + pytest-mirror count match the live suites (issue #97)"
WORK_Y1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_Y2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_Y3="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_Y4="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_YCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_Y1" "$WORK_Y2" "$WORK_Y3" "$WORK_Y4" "$WORK_YCTRL"; do
    seed "$W"
done
if python3 -c "import pytest" >/dev/null 2>&1; then
    PYTEST_OK=1
else
    PYTEST_OK=0
    echo "  skip: pytest unavailable; section 17 skips the pytest-mirror count check (issue #97)"
fi
python3 - "$WORK_Y1/skills/architecture-360-audit/profile.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"own [\w-]+ sentinel cases", "own twelve sentinel cases", s)
if n < 1:
    sys.exit("profile.md §3 sentinel count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_Y2/skills/architecture-360-audit/profile.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"Nine install sections", "Eight install sections", s)
if n != 1:
    sys.exit("profile.md §3 install count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_Y3/ADAPTERS.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"is now 53 passed", "is now 52 passed", s)
if n != 1:
    sys.exit("ADAPTERS.md pytest count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_Y4/skills/architecture-360-audit/SKILL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"suites \(53 passed", "suites (54 passed", s)
if n != 1:
    sys.exit("SKILL.md pytest count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_Y1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted profile.md §3 sentinel count"
else
    no "coverage accepted a drifted profile.md §3 sentinel count"
fi
if grep -qE "profile.md §3 says 'twelve' for tests/test_sentinel\.sh, live suite has [0-9]+" <<<"$OUT"; then
    ok "coverage names the drifted profile.md §3 sentinel count"
else
    no "coverage did not name the drifted profile.md §3 sentinel count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_Y2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted profile.md §3 install count"
else
    no "coverage accepted a drifted profile.md §3 install count"
fi
if grep -q "profile.md §3 says 'Eight' for tests/test_install.sh, live suite has 9" <<<"$OUT"; then
    ok "coverage names the drifted profile.md §3 install count"
else
    no "coverage did not name the drifted profile.md §3 install count"
    printf '%s\n' "$OUT"
fi
if [[ "$PYTEST_OK" -eq 1 ]]; then
    OUT="$(cd "$WORK_Y3" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
    RC=$?
    if [[ $RC -ne 0 ]]; then
        ok "coverage exits nonzero on a drifted ADAPTERS.md pytest count"
    else
        no "coverage accepted a drifted ADAPTERS.md pytest count"
    fi
    if grep -q "ADAPTERS.md says pytest mirror is 52 passed, live collection counts 53" <<<"$OUT"; then
        ok "coverage names the drifted ADAPTERS.md pytest count"
    else
        no "coverage did not name the drifted ADAPTERS.md pytest count"
        printf '%s\n' "$OUT"
    fi
    OUT="$(cd "$WORK_Y4" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
    RC=$?
    if [[ $RC -ne 0 ]]; then
        ok "coverage exits nonzero on a drifted SKILL.md pytest count"
    else
        no "coverage accepted a drifted SKILL.md pytest count"
    fi
    if grep -q "SKILL.md says pytest mirror is 54 passed, live collection counts 53" <<<"$OUT"; then
        ok "coverage names the drifted SKILL.md pytest count"
    else
        no "coverage did not name the drifted SKILL.md pytest count"
        printf '%s\n' "$OUT"
    fi
fi
OUT="$(cd "$WORK_YCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct §3 count-words + pytest count) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[23] README.md's quoted CLI help + sec.conf sample + migrate backends must match the live code (issue #107)"
WORK_Z1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_Z2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_Z3="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_ZCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_Z1" "$WORK_Z2" "$WORK_Z3" "$WORK_ZCTRL"; do
    seed "$W"
done
python3 - "$WORK_Z1/README.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
m = re.search(r"(```text\n)([\s\S]*?)(\n```)", s)
if not m:
    sys.exit("README.md text fence not found to corrupt")
body, n = re.subn(r"sec housekeep", "sec housekeepX", m.group(2), count=1)
if n < 1:
    sys.exit("README.md help line not found to corrupt")
open(p, "w", encoding="utf-8").write(s[:m.start()] + m.group(1) + body + m.group(3) + s[m.end():])
PY
python3 - "$WORK_Z2/README.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
m = re.search(r"(```ini\n)([\s\S]*?)(\n```)", s)
if not m:
    sys.exit("README.md ini fence not found to corrupt")
body, n = re.subn(r"default_backend = bitwarden", "default_backend = 1password", m.group(2), count=1)
if n < 1:
    sys.exit("README.md ini sample not found to corrupt")
open(p, "w", encoding="utf-8").write(s[:m.start()] + m.group(1) + body + m.group(3) + s[m.end():])
PY
python3 - "$WORK_Z3/README.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"^- .*`sec migrate`.*$",
    "- `sec migrate`: stream secrets between Bitwarden and 1Password only.",
    s, count=1, flags=re.M,
)
if n < 1:
    sys.exit("README.md migrate bullet not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_Z1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted README help block"
else
    no "coverage accepted a drifted README help block"
fi
if grep -q "not byte-identical to live 'bin/sec --help' output" <<<"$OUT"; then
    ok "coverage names the drifted README help block"
else
    no "coverage did not name the drifted README help block"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_Z2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted README sec.conf sample"
else
    no "coverage accepted a drifted README sec.conf sample"
fi
if grep -q "sec.conf sample is not byte-identical to bin/sec's ensure_config heredoc" <<<"$OUT"; then
    ok "coverage names the drifted README sec.conf sample"
else
    no "coverage did not name the drifted README sec.conf sample"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_Z3" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a README migrate bullet missing live backends"
else
    no "coverage accepted a README migrate bullet missing live backends"
fi
if grep -q "bullet omits live destination backend(s): bws, infisical" <<<"$OUT"; then
    ok "coverage names the backends missing from the README migrate bullet"
else
    no "coverage did not name the backends missing from the README migrate bullet"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_ZCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct README help + sec.conf + migrate bullet) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[24] sec migrate's --from/--to backend sets must agree across completions + OPERATOR_MANUAL + migrator (issue #108)"
WORK_M1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_M2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_MCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_M1" "$WORK_M2" "$WORK_MCTRL"; do
    seed "$W"
done
python3 - "$WORK_M1/bin/sec" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"--from\[Source vault backend\]:backend:\(bitwarden 1password bws\)",
    "--from[Source vault backend]:backend:(bitwarden 1password bws vault infisical)",
    s, count=1,
)
if n < 1:
    sys.exit("bin/sec zsh --from completion not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_M2/docs/OPERATOR_MANUAL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"- `--from <src>`:.*",
    "- `--from <src>`: Source vault provider (`bitwarden`/`bw`, `1password`/`op`, `bws`, `infisical`, `vault`).",
    s, count=1,
)
if n < 1:
    sys.exit("OPERATOR_MANUAL --from line not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_M1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when a shell --from completion drifts from the migrator source allow-list"
else
    no "coverage accepted a drifted shell --from completion"
fi
if grep -q "migrate: bin/sec zsh --from lists" <<<"$OUT"; then
    ok "coverage names the drifted zsh --from completion"
else
    no "coverage did not name the drifted zsh --from completion"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_M2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when OPERATOR_MANUAL's --from set drifts from the migrator"
else
    no "coverage accepted a drifted OPERATOR_MANUAL --from set"
fi
if grep -q "migrate: OPERATOR_MANUAL.md --from lists" <<<"$OUT"; then
    ok "coverage names the drifted OPERATOR_MANUAL --from set"
else
    no "coverage did not name the drifted OPERATOR_MANUAL --from set"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_MCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (consistent migrate source/destination sets) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[25] RESUME.md's suite-count + Sentinel cases/assertions mirrors must match the live suites (issue #109)"
WORK_R1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_R2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_RCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_R1" "$WORK_R2" "$WORK_RCTRL"; do
    seed "$W"
done
python3 - "$WORK_R1/RESUME.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"(mirrors in sync\): dispatch \d+, install \d+, sentinel )\d+",
    r"\g<1>99", s, count=1,
)
if n < 1:
    sys.exit("RESUME.md suite-counts line not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_R2/RESUME.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"(Sentinel = \d+ cases / )\d+( assertions)",
    r"\g<1>999\g<2>", s, count=1,
)
if n < 1:
    sys.exit("RESUME.md Sentinel assertions line not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_R1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted RESUME.md suite count"
else
    no "coverage accepted a drifted RESUME.md suite count"
fi
if grep -q "RESUME.md says sentinel 99, live suite has" <<<"$OUT"; then
    ok "coverage names the drifted RESUME.md suite count"
else
    no "coverage did not name the drifted RESUME.md suite count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_R2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted RESUME.md assertion total"
else
    no "coverage accepted a drifted RESUME.md assertion total"
fi
if grep -q "RESUME.md says Sentinel = 999 assertions, live suite has" <<<"$OUT"; then
    ok "coverage names the drifted RESUME.md assertion total"
else
    no "coverage did not name the drifted RESUME.md assertion total"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_RCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct RESUME.md counts) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[26] OPERATOR_MANUAL.md's documented --version output must match the live sec version (issue #114)"
WORK_V1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_VCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_V1" "$WORK_VCTRL"; do
    seed "$W"
done
python3 - "$WORK_V1/docs/OPERATOR_MANUAL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"\(`sec-cli version [^`]*`\)", "(`sec-cli v9.9.9`)", s, count=1)
if n != 1:
    sys.exit("OPERATOR_MANUAL.md --version parenthetical not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_V1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a drifted OPERATOR_MANUAL.md --version output"
else
    no "coverage accepted a drifted OPERATOR_MANUAL.md --version output"
fi
if grep -q "version: OPERATOR_MANUAL.md documents" <<<"$OUT"; then
    ok "coverage names the drifted OPERATOR_MANUAL.md --version output"
else
    no "coverage did not name the drifted OPERATOR_MANUAL.md --version output"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_VCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct OPERATOR_MANUAL.md --version) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[27] HISTORY.md's current-state pytest-mirror count must match the live suite (issue #116)"
WORK_H1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_HCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_H1" "$WORK_HCTRL"; do
    seed "$W"
done
if python3 -c "import pytest" >/dev/null 2>&1; then
    python3 - "$WORK_H1/HISTORY.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"pytest mirror \((\d+)", lambda m: "pytest mirror (%d" % (int(m.group(1)) - 1), s)
if n < 1:
    sys.exit("HISTORY.md pytest-mirror count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
    OUT="$(cd "$WORK_H1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
    RC=$?
    if [[ $RC -ne 0 ]]; then
        ok "coverage exits nonzero on a drifted HISTORY.md pytest count"
    else
        no "coverage accepted a drifted HISTORY.md pytest count"
    fi
    if grep -qE "HISTORY\.md says pytest mirror is [0-9]+ tests, live collection counts [0-9]+" <<<"$OUT"; then
        ok "coverage names the drifted HISTORY.md pytest count"
    else
        no "coverage did not name the drifted HISTORY.md pytest count"
        printf '%s\n' "$OUT"
    fi
else
    echo "  skip: pytest unavailable; the HISTORY.md pytest-mirror count check (issue #116) degrades (cf. #98)"
fi
OUT="$(cd "$WORK_HCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct HISTORY.md pytest count) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[28] RESUME.md's current-state tracked-files / personas / bash-suites counts must match the live tree (issue #117)"
WORK_R1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_RCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_R1" "$WORK_RCTRL"; do
    seed "$W"
done
python3 - "$WORK_R1/RESUME.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"\d+ tracked files, \d+ personas, \d+ bash suites",
    "107 tracked files, 11 personas, 4 bash suites",
    s,
)
if n != 1:
    sys.exit("RESUME.md structural-count line not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_R1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on drifted RESUME.md structural counts"
else
    no "coverage accepted drifted RESUME.md structural counts"
fi
for _m in \
    "RESUME\.md says 107 tracked files, live tree has [0-9]+" \
    "RESUME\.md says 11 personas, profile\.md declares 12" \
    "RESUME\.md says 4 bash suites, live tree has 5"; do
    if grep -qE "$_m" <<<"$OUT"; then
        ok "coverage names the drift: $_m"
    else
        no "coverage did not name: $_m"
        printf '%s\n' "$OUT"
    fi
done
OUT="$(cd "$WORK_RCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct RESUME.md structural counts) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[29] a claim quoted earlier in the doc must not hide drift in the real current-state line (issue #118)"
WORK_R2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_R2CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_R2" "$WORK_R2CTRL"; do
    seed "$W"
done
python3 - "$WORK_R2/RESUME.md" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
_m = re.search(r"\d+ tracked files, \d+ personas, \d+ bash suites", s)
if not _m:
    sys.exit("expected exactly one structural-count line in RESUME.md")
_correct = _m.group(0)
s2, n = re.subn(
    r"\d+ tracked files, \d+ personas, \d+ bash suites",
    "107 tracked files, 11 personas, 4 bash suites",
    s,
)
if n != 1:
    sys.exit("expected exactly one structural-count line in RESUME.md")
head, sep, tail = s2.partition("\n")
open(p, "w", encoding="utf-8").write(
    head + sep + "\nAn earlier mention: " + _correct + ".\n" + tail
)
PY
python3 - "$WORK_R2CTRL/RESUME.md" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
_m = re.search(r"\d+ tracked files, \d+ personas, \d+ bash suites", s)
if not _m:
    sys.exit("expected exactly one structural-count line in RESUME.md")
if len(re.findall(r"\d+ tracked files, \d+ personas, \d+ bash suites", s)) != 1:
    sys.exit("expected exactly one structural-count line in RESUME.md")
head, sep, tail = s.partition("\n")
open(p, "w", encoding="utf-8").write(
    head + sep + "\nAn earlier mention: " + _m.group(0) + ".\n" + tail
)
PY
OUT="$(cd "$WORK_R2" && git init -q && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the real line drifts despite an earlier correct mention"
else
    no "coverage accepted drift hidden behind an earlier correct mention"
fi
if grep -qE "RESUME\.md says 107 tracked files, live tree has [0-9]+" <<<"$OUT"; then
    ok "coverage names the drifted real line despite the earlier correct mention"
else
    no "coverage did not name the drifted real line"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_R2CTRL" && git init -q && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (two agreeing mentions) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[30] a bare 'line N' reference in profile.md/SKILL.md must fail citations (issue #121)"
WORK_BR="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_BRCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_BR" "$WORK_BRCTRL"; do
    seed "$W"
done
python3 - "$WORK_BR/skills/architecture-360-audit/profile.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
if "line 999" in s:
    sys.exit("probe already present in profile.md")
if not s.endswith("\n"):
    s += "\n"
open(p, "w", encoding="utf-8").write(
    s + "Drift probe: the guard appears at line 999 in some file.\n"
)
PY
OUT="$(cd "$WORK_BR" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" citations 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "citations exits nonzero on a bare 'line N' reference"
else
    no "citations accepted a bare 'line N' reference"
fi
if grep -qF "uses a bare 'line 999' reference -- cite a file:line anchor instead" <<<"$OUT"; then
    ok "citations names the bare reference"
else
    no "citations did not name the bare reference"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_BRCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" citations 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (no bare references) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[31] README.md's front-page backend universe + sync targets must match the live tree (issue #122)"
WORK_B1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_B2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_BCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_B1" "$WORK_B2" "$WORK_BCTRL"; do
    seed "$W"
done
python3 - "$WORK_B1/README.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
if "**Infisical**, " not in s:
    sys.exit("README.md front sentence has no **Infisical** token to remove")
open(p, "w", encoding="utf-8").write(s.replace("**Infisical**, ", "", 1))
PY
OUT="$(cd "$WORK_B1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when README.md's front sentence omits a live backend"
else
    no "coverage accepted a README.md front sentence missing a live backend"
fi
if grep -qF "README.md's front sentence omits live backend(s): infisical" <<<"$OUT"; then
    ok "coverage names the omitted backend"
else
    no "coverage did not name the omitted backend"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_B2/README.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
if "& **GitLab group variables**" not in s:
    sys.exit("README.md front sentence has no GitLab sync target to remove")
open(p, "w", encoding="utf-8").write(s.replace("& **GitLab group variables**", "", 1))
PY
OUT="$(cd "$WORK_B2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when README.md's front sentence omits a live sync target"
else
    no "coverage accepted a README.md front sentence missing a live sync target"
fi
if grep -qF "README.md's front sentence omits live sync target: gitlab group variables" <<<"$OUT"; then
    ok "coverage names the omitted sync target"
else
    no "coverage did not name the omitted sync target"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_BCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (unmodified README.md) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[32] every sec.conf sample surface must be byte-identical to the heredoc, and every key read (issue #123, widened by #125)"
WORK_C1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_C2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_C3="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_C4="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_C5="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_C6="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_C7="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_CCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_C1" "$WORK_C2" "$WORK_C3" "$WORK_C4" "$WORK_C5" "$WORK_C6" "$WORK_C7" "$WORK_CCTRL"; do
    seed "$W"
done
python3 - "$WORK_C1/README.md" "$WORK_C1/bin/sec" <<'PY'
import sys
readme, sec = sys.argv[1], sys.argv[2]
for p in (readme, sec):
    s = open(p, encoding="utf-8").read()
    if "[bitwarden]\nauto_rotate = true" not in s:
        sys.exit(f"{p}: no '[bitwarden]\\nauto_rotate = true' block to probe")
    open(p, "w", encoding="utf-8").write(
        s.replace("[bitwarden]\nauto_rotate = true", "[bitwarden]\ncli = bw\nauto_rotate = true", 1)
    )
PY
OUT="$(cd "$WORK_C1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the sec.conf sample carries a key no code reads"
else
    no "coverage accepted a sec.conf sample key that no code reads"
fi
if grep -qF "sec.conf sample key(s) are read by no code in bin/sec (the sole config owner): cli" <<<"$OUT"; then
    ok "coverage names the unread sample key"
else
    no "coverage did not name the unread sample key"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_C2/README.md" "$WORK_C2/bin/sec" <<'PY'
import sys
readme, sec = sys.argv[1], sys.argv[2]
for p in (readme, sec):
    s = open(p, encoding="utf-8").read()
    if "[bitwarden]\nauto_rotate = true" not in s:
        sys.exit(f"{p}: no '[bitwarden]\\nauto_rotate = true' block to probe")
    open(p, "w", encoding="utf-8").write(
        s.replace(
            "[bitwarden]\nauto_rotate = true",
            "[bitwarden]\ncli = bw\nbogus = true\nauto_rotate = true",
            1,
        )
    )
PY
OUT="$(cd "$WORK_C2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the sec.conf sample carries multiple keys no code reads"
else
    no "coverage accepted sec.conf sample keys that no code reads"
fi
if grep -qF "read by no code in bin/sec (the sole config owner): bogus, cli" <<<"$OUT"; then
    ok "coverage names every unread sample key in sorted order"
else
    no "coverage did not name every unread sample key"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_C3/README.md" "$WORK_C3/bin/sec" <<'PY'
import sys
readme, sec = sys.argv[1], sys.argv[2]
for p in (readme, sec):
    s = open(p, encoding="utf-8").read()
    if "[bitwarden]\nauto_rotate = true" not in s:
        sys.exit(f"{p}: no '[bitwarden]\\nauto_rotate = true' block to probe")
    open(p, "w", encoding="utf-8").write(
        s.replace("[bitwarden]\nauto_rotate = true", "[bitwarden]\ncli = bw\nauto_rotate = true", 1)
    )
s = open(sec, encoding="utf-8").read()
anchor = 'DEFAULT_BACKEND="$(get_cfg_val "global" "default_backend" "bitwarden")"'
if anchor not in s:
    sys.exit("bin/sec: no DEFAULT_BACKEND get_cfg_val anchor to probe")
open(sec, "w", encoding="utf-8").write(s.replace(anchor, '_key_probe="cli"\n' + anchor, 1))
PY
OUT="$(cd "$WORK_C3" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when an unread sample key is only a bare quoted literal in bin/sec"
else
    no "coverage accepted a sample key proven read only by a bare quoted literal in bin/sec"
fi
if grep -qF "read by no code in bin/sec (the sole config owner): cli" <<<"$OUT"; then
    ok "coverage names the sample key that is quoted but never a get_cfg_val read"
else
    no "coverage did not name the quoted-but-unread sample key"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_C4/docs/MULTI_TENANCY.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
if "[bws]\nauto_rotate = true" not in s:
    sys.exit("docs/MULTI_TENANCY.md: no '[bws]\\nauto_rotate = true' block to probe")
open(p, "w", encoding="utf-8").write(
    s.replace("[bws]\nauto_rotate = true", "[bws]\nauto_rotate = false", 1)
)
PY
OUT="$(cd "$WORK_C4" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the MULTI_TENANCY.md sec.conf sample drifts from the heredoc"
else
    no "coverage accepted a drifted docs/MULTI_TENANCY.md sec.conf sample"
fi
if grep -qF "docs/MULTI_TENANCY.md's sec.conf sample is not byte-identical to bin/sec's ensure_config" <<<"$OUT"; then
    ok "coverage names docs/MULTI_TENANCY.md as the drifted surface"
else
    no "coverage did not name docs/MULTI_TENANCY.md as the drifted surface"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_C5/sec.conf.example" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
if "default_backend = bitwarden" not in s:
    sys.exit("sec.conf.example: no default_backend line to probe")
open(p, "w", encoding="utf-8").write(
    s.replace("default_backend = bitwarden", "default_backend = bws", 1)
)
PY
OUT="$(cd "$WORK_C5" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when sec.conf.example drifts from the heredoc"
else
    no "coverage accepted a drifted sec.conf.example"
fi
if grep -qF "sec.conf.example's sec.conf sample is not byte-identical to bin/sec's ensure_config" <<<"$OUT"; then
    ok "coverage names sec.conf.example as the drifted surface"
else
    no "coverage did not name sec.conf.example as the drifted surface"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_C6/docs/MULTI_TENANCY.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
if "```ini\n" not in s or "\n```" not in s:
    sys.exit("docs/MULTI_TENANCY.md: no ini fence to unwrap")
open(p, "w", encoding="utf-8").write(s.replace("```ini\n", "~~~ini\n", 1))
PY
OUT="$(cd "$WORK_C6" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when a sec.conf sample surface has no fenced ini block"
else
    no "coverage accepted a sec.conf sample surface with no fenced ini block"
fi
if grep -qF "docs/MULTI_TENANCY.md carries no fenced \`\`\`ini sec.conf sample" <<<"$OUT"; then
    ok "coverage names the surface that lost its fenced ini block"
else
    no "coverage did not name the surface that lost its fenced ini block"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_C7/docs/MULTI_TENANCY.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
if s.count("```ini\n") != 1:
    sys.exit("docs/MULTI_TENANCY.md: expected exactly one ini fence to duplicate")
open(p, "w", encoding="utf-8").write(s + "\n```ini\n[global]\ndefault_backend = bitwarden\n```\n")
PY
OUT="$(cd "$WORK_C7" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when a sec.conf sample surface carries two ini fences"
else
    no "coverage accepted a sec.conf sample surface carrying two ini fences"
fi
if grep -qE "docs/MULTI_TENANCY\.md carries 2 fenced \`\`\`ini blocks" <<<"$OUT"; then
    ok "coverage names the ambiguous surface and its fence count"
else
    no "coverage did not name the ambiguous surface and its fence count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_CCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (unmodified sec.conf sample) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[33] RESUME.md's Verified-baseline HISTORY.md size must match the live file"
WORK_V1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_V2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_VCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_V1" "$WORK_V2" "$WORK_VCTRL"; do
    seed "$W"
done
python3 - "$WORK_V1/RESUME.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
m = re.search(r"(?m)^## Verified baseline.*?\n([\s\S]*?)\n## ", s)
if not m:
    sys.exit("RESUME.md: no '## Verified baseline' section to probe")
blk = m.group(1)
r = re.search(r"(\d+)/(\d+) bytes", blk)
if not r:
    sys.exit("RESUME.md: no 'N/8192 bytes' claim in the Verified baseline section")
s2, n = re.subn(r"\d+/(\d+) bytes", lambda m2: "%d/%s bytes" % (int(r.group(1)) + 1, m2.group(1)), s)
if n < 1:
    sys.exit("RESUME.md: byte claim not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_V1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when RESUME.md's HISTORY.md size is drifted"
else
    no "coverage accepted a drifted RESUME.md HISTORY.md size"
    printf '%s\n' "$OUT"
fi
if grep -qE "RESUME\.md says HISTORY\.md is [0-9]+ bytes, live file is [0-9]+" <<<"$OUT"; then
    ok "coverage names the drifted HISTORY.md size and the live size"
else
    no "coverage did not name the drifted HISTORY.md size"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_V2/RESUME.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
marker = "## Shipped this session"
if marker not in s:
    sys.exit("RESUME.md: no shipped-this-session section to probe")
s2, n = s.replace("## Shipped this session", marker + "\n\n9999/8192 bytes", 1), 1
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_V2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "coverage ignores a HISTORY.md size claim outside the Verified-baseline section"
else
    no "coverage read a HISTORY.md size claim from outside the Verified-baseline section"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_VCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (correct RESUME.md HISTORY.md size) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[34] bin/sec's Configured-Tenants help line must match the live dispatcher alias regex"
WORK_T1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_TCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T1" "$WORK_T2" "$WORK_TCTRL"; do
    seed "$W"
done
python3 - "$WORK_T1/bin/sec" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
m = re.search(r"=~\s*\^\(([a-z0-9|]+)\)\$", s)
if not m:
    sys.exit("bin/sec: no tenant-alias regex to probe")
s2, n = re.subn(
    r"=~\s*\^\(([a-z0-9|]+)\)\$",
    lambda m2: "=~ ^(%s|dashvault)$" % m2.group(1),
    s,
    count=1,
)
if n != 1:
    sys.exit("bin/sec: tenant-alias regex not replaced")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when a routable alias is missing from the help line"
else
    no "coverage accepted a help line that omits a routable alias"
    printf '%s\n' "$OUT"
fi
if grep -qE "routable-only \['[a-z]+" <<<"$OUT"; then
    ok "coverage names the alias that is routable but absent from the help line"
else
    no "coverage did not name the routable-only alias"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T2/bin/sec" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
m = re.search(r'^(\s*echo "Configured Tenants: )([^"]+)(")$', s, re.M)
if not m:
    sys.exit("bin/sec: no 'Configured Tenants:' help line to probe")
padded = m.group(2) + ", phantomtenant"
open(p, "w", encoding="utf-8").write(
    s[: m.start()] + m.group(1) + padded + m.group(3) + s[m.end():]
)
PY
OUT="$(cd "$WORK_T2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the help line lists a tenant that is no longer routable"
else
    no "coverage accepted a help line listing a non-routable tenant"
    printf '%s\n' "$OUT"
fi
if grep -qE "help-only \['[a-z]+" <<<"$OUT"; then
    ok "coverage names the alias that is listed but no longer routable"
else
    no "coverage did not name the help-only alias"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_TCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (help line matches the alias regex) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[35] the Verified-baseline size guard ignores a mid-line '## Verified baseline' mention in narrative"
WORK_S1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S2="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_S1" "$WORK_S2"; do
    seed "$W"
done
python3 - "$WORK_S1/RESUME.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
marker = "## Shipped this session"
if marker not in s:
    sys.exit("RESUME.md: no shipped-this-session section to probe")
plant = (
    marker
    + "\n\n- #999 probe: the `## Verified baseline` section stays scoped"
    " (mid-line mention).\n- #999 probe tail: stale 9999/8192 bytes"
    " inside the shadowed span.\n"
)
s2, n = s.replace(marker, plant, 1), 1
if n != 1:
    sys.exit("RESUME.md: shipped-this-session marker not found to probe")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_S1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "coverage exits 0 despite a mid-line '## Verified baseline' mention and stale size claim in the shadowed span"
else
    no "coverage read the size claim shadowed by a mid-line '## Verified baseline' mention"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_S2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (no planted mention) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[36] ADAPTERS.md's pack-version + persona-taxonomy census matches the live packs/ PACK.md files"
WORK_P1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_P2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_PCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_P1" "$WORK_P2" "$WORK_PCTRL"; do
    seed "$W"
done
python3 - "$WORK_P1/ADAPTERS.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "`packs/solo-founder-governance (v1.4.0)`"
new = "`packs/solo-founder-governance (v9.9.9)`"
if old not in s:
    sys.exit("ADAPTERS.md: no solo-founder pack citation to probe")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_P1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when ADAPTERS.md cites a pack version that drifted from PACK.md"
else
    no "coverage accepted a drifted pack version citation"
    printf '%s\n' "$OUT"
fi
if grep -qE "cites packs/solo-founder-governance v9\.9\.9, PACK\.md declares v1\.4\.0" <<<"$OUT"; then
    ok "coverage names the drifted pack citation and the live PACK.md version"
else
    no "coverage did not name the pack version drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_P2/ADAPTERS.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "9-persona taxonomy total"
new = "10-persona taxonomy total"
if old not in s:
    sys.exit("ADAPTERS.md: no persona-taxonomy count to probe")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_P2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the persona-taxonomy count drifts from PACK.md"
else
    no "coverage accepted a drifted persona-taxonomy count"
    printf '%s\n' "$OUT"
fi
if grep -qE "says 10-persona taxonomy total, PACK\.md enumerates 9" <<<"$OUT"; then
    ok "coverage names the persona-taxonomy drift"
else
    no "coverage did not name the persona-taxonomy drift"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_PCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (pack census matches PACK.md) exits 0"
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
