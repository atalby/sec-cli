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

NUM_WORDS="one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty"
num_word() { local live w; live="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"; for w in $NUM_WORDS; do if [[ "$w" != "$live" ]]; then printf '%s\n' "$w"; return 0; fi; done; return 1; }

LIVE_TRACKED="$(cd "$REPO_ROOT" && git ls-files | wc -l | tr -d ' ')"
DRIFT_TRACKED="$((LIVE_TRACKED + 1))"
LIVE_PERSONAS="$(grep -cE '^### [0-9]+\. ' "$REPO_ROOT/skills/architecture-360-audit/profile.md")"
LIVE_SUITES="$(find "$REPO_ROOT/tests" -maxdepth 1 -name 'test_*.sh' | wc -l | tr -d ' ')"
DRIFT_PERSONAS="$((LIVE_PERSONAS + 1))"
DRIFT_SUITES="$((LIVE_SUITES + 1))"
WRONG_CENSUS="$(num_word five)"
WRONG_DIMS="$(num_word twelve)"
WRONG_DISPATCH="$(num_word seven)"
WRONG_HELPERS="$(num_word seven)"
WRONG_ALIASES="$(num_word eight)"
WRONG_PRINCIPLES="$(num_word four)"
WRONG_SCANNERS="$(num_word five)"
WRONG_GATE="$(num_word five)"
WRONG_EXECS="$(num_word five)"
WRONG_CONTROLLERS="$(num_word one)"
WRONG_FORGE_STEPS="$(num_word eleven)"
WRONG_INSTALL="$(num_word nine)"
WRONG_PERS="$(num_word twelve)"
WRONG_ROLES="$(num_word nine)"
WRONG_SENT="$(num_word forty-one)"
WRONG_STEPS="$(num_word eleven)"
WRONG_SUITES="$(num_word five)"

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
if grep -qE "personas: all [0-9]+ reachable" <<<"$OUT"; then
    ok "all personas reachable from manifest"
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
python3 - "$WORK_Q/skills/architecture-360-audit/profile.md" "$WRONG_ROLES" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(It defines\s+)[\w-]+(\s+roles)", r"\g<1>%s\g<2>" % wrong, s, count=1)
if n != 1:
    sys.exit("profile.md numeric-roles phrase not found to corrupt")
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
if grep -qE "pack: profile.md says the pack defines [A-Za-z-]+ roles" <<<"$OUT"; then
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
python3 - "$WORK_S1/skills/architecture-360-audit/profile.md" "$WRONG_DISPATCH" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"`bin/sec` and [\w-]+ sibling dispatchers",
                "`bin/sec` and %s sibling dispatchers" % wrong, s)
if n != 1:
    sys.exit("profile.md bin/ sibling-dispatcher count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_S2/ADAPTERS.md" "$WRONG_HELPERS" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"plus the [\w-]+ sibling `bin/` helpers the suite references",
                "plus the %s sibling `bin/` helpers the suite references" % wrong, s)
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
if grep -qE "profile.md's bin/ sibling-dispatcher census says [0-9]+" <<<"$OUT"; then
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
if grep -qE "ADAPTERS.md says [A-Za-z-]+ helper scripts, live tree has [0-9]+" <<<"$OUT"; then
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
WORK_T5="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_TCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T1" "$WORK_T2" "$WORK_T3" "$WORK_T4" "$WORK_T5" "$WORK_TCTRL"; do
    seed "$W"
done
python3 - "$WORK_T1/skills/architecture-360-audit/profile.md" "$WRONG_CENSUS" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"\b[\w-]+ suites under `tests/`",
                "%s suites under `tests/`" % wrong, s, count=1)
if n != 1:
    sys.exit("profile.md tests/ suite count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_T2/skills/architecture-360-audit/profile.md" "$WRONG_CENSUS" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"runs all \b[\w-]+ suites\b", "runs all %s suites" % wrong, s, count=1)
if n != 1:
    sys.exit("profile.md CI suite-count claim not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_T3/docs/ARCHITECTURE.md" "$WRONG_CENSUS" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"\b[\w-]+ zero-dependency bash suites",
                "%s zero-dependency bash suites" % wrong, s, count=1)
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
if grep -qE "profile.md's tests/ suite census says [0-9]+" <<<"$OUT"; then
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
if grep -qE "profile.md's CI row says it runs all [A-Za-z-]+ suites" <<<"$OUT"; then
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
if grep -qE "ARCHITECTURE.md says [A-Za-z-]+ zero-dependency bash suites" <<<"$OUT"; then
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
python3 - "$WORK_T5/.github/workflows/test.yml" <<'PY'
import sys
p = sys.argv[1]
with open(p, encoding="utf-8") as fh:
    body = fh.read()
body = body.replace("test_write_honesty test_sentinel", "test_write_honesty")
with open(p, "w", encoding="utf-8") as fh:
    fh.write(body)
PY
OUT="$(cd "$WORK_T5" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the CI workflow's run-list drops a live suite"
else
    no "coverage accepted a CI workflow that does not run every live suite"
fi
if grep -qF "the CI workflow's run-list is not the live suite set: live-but-not-run ['test_sentinel']" <<<"$OUT"; then
    ok "coverage names the live suite the CI workflow stopped running"
else
    no "coverage did not name the suite missing from the CI workflow run-list"
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
python3 - "$WORK_U1/docs/MULTI_TENANCY.md" "$WRONG_ALIASES" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"the [\w-]+ fixed aliases", "the %s fixed aliases" % wrong, s)
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
python3 - "$WORK_U4/docs/OPERATOR_MANUAL.md" "$WRONG_PRINCIPLES" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"designed around [\w-]+ core principles",
                "designed around %s core principles" % wrong, s)
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
if grep -qE "MULTI_TENANCY.md says [A-Za-z-]+ fixed aliases, live bin/sec has [0-9]+" <<<"$OUT"; then
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
if grep -qE "OPERATOR_MANUAL.md says [A-Za-z-]+ core principles, live doc lists [0-9]+" <<<"$OUT"; then
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
python3 - "$WORK_W1/skills/architecture-360-audit/SKILL.md" "$WRONG_SCANNERS" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"the [\w-]+ `tests/\*\.sh` suites", "the %s `tests/*.sh` suites" % wrong, s)
if n != 1:
    sys.exit("SKILL.md scanner suite count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_W2/skills/architecture-360-audit/SKILL.md" "$WRONG_GATE" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"executes all [\w-]+ bash suites", "executes all %s bash suites" % wrong, s)
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
if grep -qE 'SKILL.md says the [A-Za-z-]+ `tests/\*\.sh` suites, live tree has [0-9]+' <<<"$OUT"; then
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
if grep -qE "SKILL.md says the gate executes all [A-Za-z-]+ bash suites, live tree has [0-9]+" <<<"$OUT"; then
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
python3 - "$WORK_X1/skills/architecture-360-audit/SKILL.md" "$WRONG_STEPS" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"\b[\w-]+ steps\b", "%s steps" % wrong, s)
if n < 1:
    sys.exit("SKILL.md step count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_X2/skills/architecture-360-audit/SKILL.md" "$WRONG_PERS" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"\b[\w-]+ personas\b", "%s personas" % wrong, s)
if n < 1:
    sys.exit("SKILL.md persona count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_X3/skills/architecture-360-audit/profile.md" "$WRONG_PERS" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
live = re.search(r"numbered 1 through (\d+),", s)
if not live:
    sys.exit("profile.md numbered-personas claim not found to corrupt")
replacement = "1" if int(live.group(1)) != 1 else "2"
s2, n = re.subn(r"numbered 1 through \d+,", "numbered 1 through %s," % replacement, s)
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
if grep -qE "SKILL.md says '[A-Za-z-]+ steps', live SKILL.md has [0-9]+ '## Step' headings" <<<"$OUT"; then
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
if grep -qE "SKILL.md says '[A-Za-z-]+ personas', profile.md declares [0-9]+" <<<"$OUT"; then
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
if grep -qE "profile.md says personas are '[A-Za-z-]+, numbered 1 through [0-9]+', live persona-heading count is [0-9]+" <<<"$OUT"; then
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
PYTEST_COUNT=""
if python3 -c "import pytest" >/dev/null 2>&1; then
    PYTEST_OK=1
    PYTEST_COUNT="$(PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 python3 -m pytest scripts/tests/ --collect-only -q -c /dev/null --confcutdir scripts/tests 2>/dev/null | grep -c '::')"
else
    PYTEST_OK=0
    echo "  skip: pytest unavailable; section 17 skips the pytest-mirror count check (issue #97)"
fi
python3 - "$WORK_Y1/skills/architecture-360-audit/profile.md" "$WRONG_SENT" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"own [\w-]+ sentinel cases", "own %s sentinel cases" % wrong, s)
if n < 1:
    sys.exit("profile.md §3 sentinel count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_Y2/skills/architecture-360-audit/profile.md" "$WRONG_INSTALL" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"\b[\w-]+ install sections\b", "%s install sections" % wrong, s, count=1)
if n != 1:
    sys.exit("profile.md §3 install count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_Y3/ADAPTERS.md" "$PYTEST_COUNT" <<'PY'
import re
import sys
p, live = sys.argv[1], sys.argv[2]
if not live:
    sys.exit(0)
n = int(live)
s = open(p, encoding="utf-8").read()
s2, hits = re.subn(r"is now %d passed" % n, "is now %d passed" % (n - 1), s)
if hits != 1:
    sys.exit("ADAPTERS.md pytest count not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
python3 - "$WORK_Y4/skills/architecture-360-audit/SKILL.md" "$PYTEST_COUNT" <<'PY'
import re
import sys
p, live = sys.argv[1], sys.argv[2]
if not live:
    sys.exit(0)
n = int(live)
s = open(p, encoding="utf-8").read()
s2, hits = re.subn(r"suites \(%d passed" % n, "suites (%d passed" % (n + 1), s)
if hits != 1:
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
if grep -qE "profile.md §3 says '[A-Za-z-]+' for tests/test_sentinel\.sh, live suite has [0-9]+" <<<"$OUT"; then
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
if grep -qE "profile.md §3 says '[A-Za-z-]+' for tests/test_install\.sh, live suite has [0-9]+" <<<"$OUT"; then
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
    if grep -q "ADAPTERS.md says pytest mirror is $((PYTEST_COUNT - 1)) passed, live collection counts $PYTEST_COUNT" <<<"$OUT"; then
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
    if grep -q "SKILL.md says pytest mirror is $((PYTEST_COUNT + 1)) passed, live collection counts $PYTEST_COUNT" <<<"$OUT"; then
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
WORK_Z4="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_ZCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_Z1" "$WORK_Z2" "$WORK_Z3" "$WORK_Z4" "$WORK_ZCTRL"; do
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
python3 - "$WORK_Z4/README.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"^- .*`sec migrate`.*$",
    "- `sec migrate`: stream secrets between (`Bitwarden` `<->` `1Password` `<->` `bws` `<->` `Infisical` `<->` `Vault`).",
    s, count=1, flags=re.M,
)
if n < 1:
    sys.exit("README.md migrate bullet not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_Z4" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero on a README migrate bullet presenting destination-only backends as bidirectional sources"
else
    no "coverage accepted a README migrate bullet with unscoped destination-only backends"
fi
if grep -q "without scoping them as targets" <<<"$OUT"; then
    ok "coverage names the unscoped destination-only backends in the README migrate bullet"
else
    no "coverage did not name the unscoped destination-only backends"
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
python3 - "$WORK_R1/RESUME.md" "$DRIFT_TRACKED" "$DRIFT_PERSONAS" "$DRIFT_SUITES" <<'PY'
import re
import sys
p = sys.argv[1]
tracked, personas, suites = sys.argv[2], sys.argv[3], sys.argv[4]
if not tracked or not personas or not suites:
    sys.exit("no replacement value available for the RESUME.md count line")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"\d+ tracked files, \d+ personas, \d+ bash suites",
    "%s tracked files, %s personas, %s bash suites" % (tracked, personas, suites),
    s,
    count=1,
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
    "RESUME\.md says $DRIFT_TRACKED tracked files, live tree has [0-9]+" \
    "RESUME\.md says $DRIFT_PERSONAS personas, profile\.md declares [0-9]+" \
    "RESUME\.md says $DRIFT_SUITES bash suites, live tree has [0-9]+"; do
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
python3 - "$WORK_R2/RESUME.md" "$DRIFT_TRACKED" "$DRIFT_PERSONAS" "$DRIFT_SUITES" <<'PY'
import re, sys
p = sys.argv[1]
tracked, personas, suites = sys.argv[2], sys.argv[3], sys.argv[4]
if not tracked or not personas or not suites:
    sys.exit("no replacement value available for the RESUME.md count line")
s = open(p, encoding="utf-8").read()
_m = re.search(r"\d+ tracked files, \d+ personas, \d+ bash suites", s)
if not _m:
    sys.exit("expected exactly one structural-count line in RESUME.md")
_correct = _m.group(0)
s2, n = re.subn(
    r"\d+ tracked files, \d+ personas, \d+ bash suites",
    "%s tracked files, %s personas, %s bash suites" % (tracked, personas, suites),
    s,
    count=1,
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
if grep -qE "RESUME\.md says $DRIFT_TRACKED tracked files, live tree has [0-9]+" <<<"$OUT"; then
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

echo "[31] README.md + docs/ARCHITECTURE.md front backend universe + sync targets, plus docs/OPERATOR_MANUAL.md's and ARCHITECTURE's sync-controller-bullet sync-target claims, must match the live tree (issue #122, extended by #174/#178)"
WORK_B1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_B2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_B3="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_B4="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_B5="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_B6="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_BCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_B1" "$WORK_B2" "$WORK_B3" "$WORK_B4" "$WORK_B5" "$WORK_B6" "$WORK_BCTRL"; do
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
python3 - "$WORK_B3/docs/ARCHITECTURE.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "1Password (`op`), Infisical, and HashiCorp Vault"
new = "1Password (`op`) and HashiCorp Vault"
if old not in s:
    sys.exit("docs/ARCHITECTURE.md front sentence has no Infisical backend to remove")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_B3" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when docs/ARCHITECTURE.md's front sentence omits a live backend"
else
    no "coverage accepted a docs/ARCHITECTURE.md front sentence missing a live backend"
fi
if grep -qF "docs/ARCHITECTURE.md's front sentence omits live backend(s): infisical" <<<"$OUT"; then
    ok "coverage names the omitted backend in docs/ARCHITECTURE.md"
else
    no "coverage did not name the omitted backend in docs/ARCHITECTURE.md"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_B4/docs/ARCHITECTURE.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "GCP Secret Manager and GitLab group variables"
new = "GCP Secret Manager"
if old not in s:
    sys.exit("docs/ARCHITECTURE.md front sentence has no GitLab sync target to remove")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_B4" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when docs/ARCHITECTURE.md's front sentence omits a live sync target"
else
    no "coverage accepted a docs/ARCHITECTURE.md front sentence missing a live sync target"
fi
if grep -qF "docs/ARCHITECTURE.md's front sentence omits live sync target: gitlab group variables" <<<"$OUT"; then
    ok "coverage names the omitted sync target in docs/ARCHITECTURE.md"
else
    no "coverage did not name the omitted sync target in docs/ARCHITECTURE.md"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_B5/docs/OPERATOR_MANUAL.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "is not read) to GCP Secret Manager and GitLab group variables."
new = "is not read) to GitLab group variables."
if old not in s:
    sys.exit("docs/OPERATOR_MANUAL.md carries no sync-target claim to corrupt")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_B5" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when docs/OPERATOR_MANUAL.md's sync-target claim omits a live target"
else
    no "coverage accepted a docs/OPERATOR_MANUAL.md sync-target claim missing a live target"
    printf '%s\n' "$OUT"
fi
if grep -qF "docs/OPERATOR_MANUAL.md's sync-target claim omits live sync target: gcp secret manager" <<<"$OUT"; then
    ok "coverage names the omitted sync target in docs/OPERATOR_MANUAL.md"
else
    no "coverage did not name the omitted sync target in docs/OPERATOR_MANUAL.md"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_B6/docs/ARCHITECTURE.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "is not read) to GCP Secret Manager and GitLab group CI/CD variables."
new = "is not read) to GitLab group CI/CD variables."
if old not in s:
    sys.exit("docs/ARCHITECTURE.md sync-controller bullet carries no sync-target claim to corrupt")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_B6" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when docs/ARCHITECTURE.md's sync-controller bullet omits a live sync target"
else
    no "coverage accepted a docs/ARCHITECTURE.md sync-controller bullet missing a live sync target"
    printf '%s\n' "$OUT"
fi
if grep -qF "docs/ARCHITECTURE.md's sync-target claim omits live sync target: gcp secret manager" <<<"$OUT"; then
    ok "coverage names the omitted sync target in the docs/ARCHITECTURE.md sync-controller bullet"
else
    no "coverage did not name the omitted sync target in the docs/ARCHITECTURE.md sync-controller bullet"
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
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"\b\d+-persona taxonomy total\b",
                lambda m: "%d-persona taxonomy total" % (int(m.group(0).split("-")[0]) + 1),
                s, count=1)
if n != 1:
    sys.exit("ADAPTERS.md: no persona-taxonomy count to probe")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_P2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the persona-taxonomy count drifts from PACK.md"
else
    no "coverage accepted a drifted persona-taxonomy count"
    printf '%s\n' "$OUT"
fi
if grep -qE "says [0-9]+-persona taxonomy total, PACK\.md enumerates [0-9]+" <<<"$OUT"; then
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

echo "[37] profile.md's persona-1 SYNC_KEYS + persona-11 timeout counts must match the live code (issues #130/#131/#132)"
WORK_S1="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S2="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S3="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_SCTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_S1" "$WORK_S2" "$WORK_S3" "$WORK_SCTRL"; do
    seed "$W"
done
python3 - "$WORK_S1/skills/architecture-360-audit/profile.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "has **4 timeout sites**"
new = "has **5 timeout sites**"
if old not in s:
    sys.exit("profile.md: no '4 timeout sites' claim to probe")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_S1" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when profile.md's sync-controller timeout-site count drifts"
else
    no "coverage accepted a drifted sync-controller timeout-site count"
    printf '%s\n' "$OUT"
fi
if grep -qE "says the sync controller has 5 timeout sites, live code has 4" <<<"$OUT"; then
    ok "coverage names the sync-controller timeout-site drift"
else
    no "coverage did not name the sync-controller timeout-site drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_S2/install.sh" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "git clone --depth 1"
new = "timeout 30 git clone --depth 1"
if old not in s:
    sys.exit("install.sh: no 'git clone --depth 1' site to probe")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_S2" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when install.sh gains a timeout against profile.md's zero claim"
else
    no "coverage accepted a live install.sh timeout against a zero claim"
    printf '%s\n' "$OUT"
fi
if grep -qE "says install.sh has zero timeout occurrences, live file has 1" <<<"$OUT"; then
    ok "coverage names the install.sh zero-timeout drift"
else
    no "coverage did not name the install.sh zero-timeout drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_S3/bin/sec-sync-controller.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = '    "STRIPE_SECRET_KEY",\n'
new = ''
if old not in s:
    sys.exit("controller: no STRIPE_SECRET_KEY entry to probe")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_S3" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when SYNC_KEYS loses a key but profile.md still cites six"
else
    no "coverage accepted a drifted SYNC_KEYS list"
    printf '%s\n' "$OUT"
fi
if grep -qE "says SYNC_KEYS names six env keys, live list has 5" <<<"$OUT"; then
    ok "coverage names the SYNC_KEYS count drift"
else
    no "coverage did not name the SYNC_KEYS count drift"
    printf '%s\n' "$OUT"
fi
if grep -qE "SYNC_KEYS list is not the live controller's: cited-only \['STRIPE_SECRET_KEY'\]" <<<"$OUT"; then
    ok "coverage names the drifted SYNC_KEYS member"
else
    no "coverage did not name the drifted SYNC_KEYS member"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_SCTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (SYNC_KEYS + timeout counts match the live code) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[38] profile.md's suite-count spellings + persona dimensions + bin decomposition must match the live tree (issue #133)"
WORK_S8A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S8B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S8C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S8D="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S8CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_S8A" "$WORK_S8B" "$WORK_S8C" "$WORK_S8D" "$WORK_S8CTRL"; do
    seed "$W"
done
python3 - "$WORK_S8A/skills/architecture-360-audit/profile.md" "$WRONG_SUITES" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"\b[\w-]+ green\b", "%s green" % wrong, s, count=1)
if n != 1:
    sys.exit("profile.md: no numeric suite-count spelling to probe")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_S8A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when profile.md's suite-count spelling drifts"
else
    no "coverage accepted a drifted suite-count spelling"
    printf '%s\n' "$OUT"
fi
if grep -qE "says '[A-Za-z-]+ \.\.\. suite\(s\)', live tree has [0-9]+ bash suites" <<<"$OUT"; then
    ok "coverage names the drifted suite-count spelling"
else
    no "coverage did not name the drifted suite-count spelling"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_S8B/skills/architecture-360-audit/profile.md" "$WRONG_DIMS" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"\b[\w-]+ fixed dimensions\b", "%s fixed dimensions" % wrong, s, count=1)
if n != 1:
    sys.exit("profile.md: no numeric fixed-dimension claim to probe")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_S8B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when profile.md's persona-dimension count drifts"
else
    no "coverage accepted a drifted persona-dimension count"
    printf '%s\n' "$OUT"
fi
if grep -qE "says '[A-Za-z-]+ fixed dimensions', live persona-heading count is [0-9]+" <<<"$OUT"; then
    ok "coverage names the drifted persona-dimension count"
else
    no "coverage did not name the drifted persona-dimension count"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_S8C/skills/architecture-360-audit/profile.md" "$WRONG_EXECS" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"\b[\w-]+ sibling executables\b", "%s sibling executables" % wrong, s, count=1)
if n != 1:
    sys.exit("profile.md: no numeric decomposition claim to probe")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_S8C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when profile.md's bin component decomposition drifts"
else
    no "coverage accepted a drifted bin component decomposition"
    printf '%s\n' "$OUT"
fi
if grep -qE "component decomposition says [A-Za-z-]+ sibling executables, live tree has [0-9]+ non-controller non-MCP" <<<"$OUT"; then
    ok "coverage names the drifted bin component decomposition"
else
    no "coverage did not name the drifted bin component decomposition"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_S8D/skills/architecture-360-audit/profile.md" "$WRONG_CONTROLLERS" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(\b[\w-]+ sibling executables, )[\w-]+( Python controller)",
                r"\g<1>%s\g<2>" % wrong, s, count=1)
if n != 1:
    sys.exit("profile.md: no numeric controller claim to probe")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_S8D" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when profile.md's bin Python-controller count drifts"
else
    no "coverage accepted a drifted bin Python-controller count"
    printf '%s\n' "$OUT"
fi
if grep -qE "component decomposition says [A-Za-z-]+ Python controller\(s\), live tree has [0-9]+" <<<"$OUT"; then
    ok "coverage names the drifted bin Python-controller count"
else
    no "coverage did not name the drifted bin Python-controller count"
    printf '%s\n' "$OUT"
fi

OUT="$(cd "$WORK_S8CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (suite-count spellings + dimensions + bin decomposition match) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[39] profile.md's executed-commands 'git ls-files | wc -l' transcript must match the live count (issue #134)"
WORK_S9A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S9CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_S9A" "$WORK_S9CTRL"; do
    seed "$W"
done
python3 - "$WORK_S9A/skills/architecture-360-audit/profile.md" "$DRIFT_TRACKED" "$LIVE_TRACKED" <<'PY'
import re
import sys
p = sys.argv[1]
drift = sys.argv[2]
live = sys.argv[3]
if not drift or not live:
    sys.exit("no tracked-file count available for the transcript probe")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"git ls-files \| wc -l\n    \d+\n",
                "git ls-files | wc -l\n    %s\n" % drift, s, count=1)
if n != 1:
    sys.exit("profile.md: no tracked-file-count transcript to probe")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_S9A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when profile.md's executed transcript drifts"
else
    no "coverage accepted a drifted tracked-file-count transcript"
    printf '%s\n' "$OUT"
fi
if grep -qE "executed-commands transcript says $DRIFT_TRACKED tracked files, but git ls-files reports $LIVE_TRACKED" <<<"$OUT"; then
    ok "coverage names the drifted executed-commands transcript"
else
    no "coverage did not name the drifted executed-commands transcript"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_S9CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (executed-commands transcript matches the live count) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[40] profile.md's suite counts must bind to their own line, not the next mention (issue #135)"
WORK_S10A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S10B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S10CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_S10A" "$WORK_S10B" "$WORK_S10CTRL"; do
    seed "$W"
done
python3 - "$WORK_S10A/skills/architecture-360-audit/profile.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
shadow = "Intro note: the largest suite is tests/test_dispatch.sh and it exercises the whole dispatcher.\n"
if "Intro note:" in s:
    sys.exit("profile.md: shadow prologue already present")
open(p, "w", encoding="utf-8").write(shadow + s)
PY
OUT="$(cd "$WORK_S10A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "coverage exits 0 when an earlier no-count tests/test_dispatch.sh mention precedes the count row"
else
    no "coverage mis-bound an earlier same-suite mention to the next count (exited $RC)"
    printf '%s\n' "$OUT"
fi
if grep -qE '\[ERROR\] suite count' <<<"$OUT"; then
    no "coverage still reports a suite-count drift for the shadowed mention"
    printf '%s\n' "$OUT"
else
    ok "coverage does not mis-bind an earlier same-suite mention to a later count"
fi
python3 - "$WORK_S10B/skills/architecture-360-audit/profile.md" <<'PY'
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
    sys.exit("dispatch count row not found to drift")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_S10B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage still exits nonzero when a bound suite count genuinely drifts"
else
    no "coverage accepted a drifted bound suite count"
    printf '%s\n' "$OUT"
fi
if grep -qE "says 999 for tests/test_dispatch\.sh, live suites have [0-9]+" <<<"$OUT"; then
    ok "coverage names the genuinely drifted suite count"
else
    no "coverage did not name the drifted suite count"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_S10CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (suite counts bind on their own row) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[41] 360-audit-skill-forge's declared shape must match the live SKILL.md (issue #136)"
WORK_S11A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S11B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S11CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_S11A" "$WORK_S11B" "$WORK_S11CTRL"; do
    seed "$W"
done
python3 - "$WORK_S11A/skills/360-audit-skill-forge/SKILL.md" "$WRONG_FORGE_STEPS" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"\b[\w-]+ steps,", "%s steps," % wrong, s, count=1)
if n != 1:
    sys.exit("forge step-count claim not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_S11A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the forge's step count drifts from the live SKILL.md"
else
    no "coverage accepted a forge step-count drift"
    printf '%s\n' "$OUT"
fi
if grep -qE "360-audit-skill-forge says '[A-Za-z-]+ steps', live SKILL.md has [0-9]+" <<<"$OUT"; then
    ok "coverage names the forge step-count drift"
else
    no "coverage did not name the forge step-count drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_S11B/skills/360-audit-skill-forge/SKILL.md" "$WRONG_DIMS" <<'PY'
import re
import sys
p = sys.argv[1]
wrong = sys.argv[2]
if not wrong:
    sys.exit("no replacement numeral word available")
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"\b[\w-]+ bound audit dimensions\b", "%s bound audit dimensions" % wrong, s, count=1)
if n != 1:
    sys.exit("forge persona/dimension claim not found to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_S11B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the forge's dimension count drifts from the live profile.md"
else
    no "coverage accepted a forge dimension-count drift"
    printf '%s\n' "$OUT"
fi
if grep -qE "360-audit-skill-forge says '[A-Za-z-]+ personas/dimensions', profile.md declares [0-9]+" <<<"$OUT"; then
    ok "coverage names the forge dimension-count drift"
else
    no "coverage did not name the forge dimension-count drift"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_S11CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (forge matches the live SKILL.md) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[42] citations verifies the repo docs' file:line anchors, not just the audit skill's (issue #138)"
WORK_S12A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S12B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S12CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_S12A" "$WORK_S12B" "$WORK_S12CTRL"; do
    seed "$W"
done
DOC_LINES="$(wc -l <"$WORK_S12A/docs/ARCHITECTURE.md" | tr -d ' ')"
SUITE_LINES="$(wc -l <"$WORK_S12A/tests/test_dispatch.sh" | tr -d ' ')"
printf '\nInjected anchor: `docs/ARCHITECTURE.md:%s`\n' "$((DOC_LINES + 1))" >>"$WORK_S12A/RESUME.md"
OUT="$(cd "$WORK_S12A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" citations 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "citations exits nonzero when a RESUME.md anchor runs past the cited file"
else
    no "citations accepted a RESUME.md anchor past the end of the cited file"
    printf '%s\n' "$OUT"
fi
if grep -qE "RESUME.md:[0-9]+ cites docs/ARCHITECTURE.md:$((DOC_LINES + 1)) -- line $((DOC_LINES + 1)) beyond end of file" <<<"$OUT"; then
    ok "citations names the out-of-range RESUME.md anchor"
else
    no "citations did not name the out-of-range RESUME.md anchor"
    printf '%s\n' "$OUT"
fi
printf '\nInjected range: `tests/test_dispatch.sh:%s-%s`\n' "$SUITE_LINES" "$((SUITE_LINES - 1))" >>"$WORK_S12B/HISTORY.md"
OUT="$(cd "$WORK_S12B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" citations 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "citations exits nonzero on a reversed doc anchor range"
else
    no "citations accepted a reversed doc anchor range"
    printf '%s\n' "$OUT"
fi
if grep -qE "HISTORY.md:[0-9]+ cites tests/test_dispatch.sh:$SUITE_LINES-$((SUITE_LINES - 1)) -- reversed range" <<<"$OUT"; then
    ok "citations names the reversed doc anchor range"
else
    no "citations did not name the reversed doc anchor range"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_S12CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" citations 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (every doc anchor resolves) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\([1-9][0-9]* anchor\(s\) in the repo docs also resolve\)" <<<"$OUT"; then
    ok "the control copy proves doc anchors were actually scanned, not skipped"
else
    no "the control copy's OK line did not report a doc anchor count"
    printf '%s\n' "$OUT"
fi
echo "[39] a shadow allow-list / alias regex must not mask the real bin guard (issue #140 shadow class)"
WORK_S13A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S13B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S13CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_S13A" "$WORK_S13B" "$WORK_S13CTRL"; do
    seed "$W"
done
python3 - "$WORK_S13A/bin/sec-migrator" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
m = re.search(r'(case "\$DST" in\n\s*)([a-z0-9|]+)(\))', s)
if not m or "infisical" not in m.group(2):
    sys.exit("bin/sec-migrator: no destination allow-list carrying infisical to probe")
s = s[:m.start(2)] + re.sub(r"\|?infisical", "", m.group(2), count=1) + s[m.end(2):]
idx = s.index('case "$DST" in')
shadow = (
    'case "$DST" in\n'
    '    1password|1pass|op|bitwarden|bw|bws|infisical|vault)\n'
    '        echo "Destination backend not supported for bulk migration." >&2\n'
    '        exit 1\n'
    '        ;;\n'
    'esac\n\n'
)
open(p, "w", encoding="utf-8").write(s[:idx] + shadow + s[idx:])
PY
OUT="$(cd "$WORK_S13A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when a second case \"\$DST\" allow-list shadows the real one"
else
    no "coverage accepted a shadowed migrator destination allow-list"
    printf '%s\n' "$OUT"
fi
if grep -q "migrator destination allow-list is" <<<"$OUT"; then
    ok "coverage names the shadowed migrator destination allow-list"
else
    no "coverage did not name the shadowed migrator destination allow-list"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_S13B/bin/sec" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
m = re.search(r'\[\[ "\$1" =~ \^\(([a-z0-9|]+)\)\$ \]\]', s)
if not m or "keychain" not in m.group(1):
    sys.exit("bin/sec: no dispatcher alias gate carrying keychain to probe")
s = s[:m.start(1)] + re.sub(r"\|?keychain", "", m.group(1), count=1) + s[m.end(1):]
idx = s.index('if [[ $# -ge 2 ]] && [[ "$1" =~')
shadow = 'if [[ $# -ge 2 ]] && [[ "$1" =~ ^(%s)$ ]]; then :; fi\n' % m.group(1)
open(p, "w", encoding="utf-8").write(s[:idx] + shadow + s[idx:])
PY
OUT="$(cd "$WORK_S13B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when a dead alias regex shadows the real gate"
else
    no "coverage accepted a shadowed tenant alias gate"
    printf '%s\n' "$OUT"
fi
if grep -q "dispatcher alias gates" <<<"$OUT"; then
    ok "coverage names the shadowed tenant alias set"
else
    no "coverage did not name the shadowed tenant alias set"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_S13CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (unmutated bin guards) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
echo "[40] a shadow fetch_source_items() block must not mask the real migrator source guard (issue #141 shadow class)"
WORK_S14A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S14B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S14CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_S14A" "$WORK_S14B" "$WORK_S14CTRL"; do
    seed "$W"
done
python3 - "$WORK_S14A/bin/sec-migrator" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
m = re.search(r"        bws\)\n            bws secret list [^\n]*\n            ;;\n", s)
if not m:
    sys.exit("bin/sec-migrator: no bws source arm to probe")
s = s[:m.start()] + s[m.end():]
idx = s.index("fetch_source_items() {")
shadow = (
    "fetch_source_items() {\n"
    '    case "$SRC" in\n'
    "        bitwarden|bw)\n"
    "            :\n"
    "            ;;\n"
    "        1password|1pass|op)\n"
    "            :\n"
    "            ;;\n"
    "        bws)\n"
    "            :\n"
    "            ;;\n"
    "        *)\n"
    "            :\n"
    "            ;;\n"
    "    esac\n"
    "}\n\n"
)
open(p, "w", encoding="utf-8").write(s[:idx] + shadow + s[idx:])
PY
OUT="$(cd "$WORK_S14A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when a shadowed fetch_source_items() block masks the real source guard"
else
    no "coverage accepted a shadowed migrator source allow-list"
    printf '%s\n' "$OUT"
fi
if grep -q "fetch_source_items() source blocks" <<<"$OUT"; then
    ok "coverage names the shadowed migrator source allow-list"
else
    no "coverage did not name the shadowed migrator source allow-list"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_S14B/bin/sec-migrator" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
m = re.search(r"        bws\)\n            bws secret list [^\n]*\n            ;;\n", s)
if not m:
    sys.exit("bin/sec-migrator: no bws source arm to probe")
open(p, "w", encoding="utf-8").write(s[:m.start()] + s[m.end():])
PY
OUT="$(cd "$WORK_S14B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage still catches a genuinely dropped migrator source arm"
else
    no "coverage accepted a migrator source arm dropped from the real block"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_S14CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (unmutated fetch_source_items) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
echo "[43] AGENTS.md and docs/ARCHITECTURE.md HIAE Protocol version banners must agree (issue #144)"
WORK_S15A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S15B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S15C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_S15CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_S15A" "$WORK_S15B" "$WORK_S15C" "$WORK_S15CTRL"; do
    seed "$W"
done
python3 - "$WORK_S15A/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(\*\*HIAE Protocol Version\*\*:\s*)v[\d.]+", r"\g<1>v9.9.9", s, count=1)
if n != 1:
    sys.exit("docs/ARCHITECTURE.md carries no HIAE Protocol Version banner to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_S15A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when docs/ARCHITECTURE.md's banner disagrees with AGENTS.md"
else
    no "coverage accepted an ARCHITECTURE banner disagreeing with AGENTS.md"
    printf '%s\n' "$OUT"
fi
if grep -qE "docs/ARCHITECTURE.md banner says v9\.9\.9, AGENTS.md says v[0-9]+\.[0-9]+" <<<"$OUT"; then
    ok "coverage names both banner versions in the mismatch"
else
    no "coverage did not name both banner versions in the mismatch"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_S15B/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"\*\*HIAE Protocol Version\*\*:[^\n]*\n", "", s, count=1)
if n != 1:
    sys.exit("docs/ARCHITECTURE.md carries no HIAE Protocol Version banner to remove")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_S15B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the ARCHITECTURE banner is missing entirely"
else
    no "coverage accepted a missing ARCHITECTURE banner"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/ARCHITECTURE.md carries no HIAE Protocol version banner" <<<"$OUT"; then
    ok "coverage names the missing ARCHITECTURE banner"
else
    no "coverage did not name the missing ARCHITECTURE banner"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_S15C/AGENTS.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"\(HIAE Protocol v[\d.]+\)", "", s, count=1)
if n != 1:
    sys.exit("AGENTS.md carries no HIAE Protocol banner to remove")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_S15C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when AGENTS.md's own banner is missing"
else
    no "coverage accepted a missing AGENTS.md banner"
    printf '%s\n' "$OUT"
fi
if grep -q "AGENTS.md carries no HIAE Protocol version banner" <<<"$OUT"; then
    ok "coverage names the missing AGENTS.md banner"
else
    no "coverage did not name the missing AGENTS.md banner"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_S15CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (banners agree) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] HIAE banner: docs/ARCHITECTURE.md matches AGENTS.md \(v[0-9]+\.[0-9]+(\.[0-9]+)?\)" <<<"$OUT"; then
    ok "the control copy's OK line names the matched banner version"
else
    no "the control copy's OK line did not name the matched banner version"
    printf '%s\n' "$OUT"
fi
echo "[44] ARCHITECTURE.md + OPERATOR_MANUAL.md timeout claims and the live controller must agree (issue #145)"
WORK_T16A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T16B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T16C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T16CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T16A" "$WORK_T16B" "$WORK_T16C" "$WORK_T16CTRL"; do
    seed "$W"
done
python3 - "$WORK_T16A/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"(has a timeout \(default )\d+(s, `SEC_SYNC_TIMEOUT` overrides\))",
    r"\g<1>99\g<2>",
    s,
    count=1,
)
if n != 1:
    sys.exit("docs/ARCHITECTURE.md carries no timeout claim to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T16A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when ARCHITECTURE.md's timeout default drifts"
else
    no "coverage accepted a drifted ARCHITECTURE timeout default"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/ARCHITECTURE.md says default timeout is 99s, expected 60s" <<<"$OUT"; then
    ok "coverage names ARCHITECTURE.md's drifted timeout default"
else
    no "coverage did not name the ARCHITECTURE timeout default drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T16B/docs/OPERATOR_MANUAL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"(Each backend call is bounded \(default )\d+(s, `SEC_SYNC_TIMEOUT` overrides\))",
    r"\g<1>30\g<2>",
    s,
    count=1,
)
if n != 1:
    sys.exit("docs/OPERATOR_MANUAL.md carries no timeout claim to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T16B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when OPERATOR_MANUAL.md's timeout default drifts"
else
    no "coverage accepted a drifted OPERATOR_MANUAL timeout default"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/OPERATOR_MANUAL.md says default timeout is 30s, expected 60s" <<<"$OUT"; then
    ok "coverage names OPERATOR_MANUAL.md's drifted timeout default"
else
    no "coverage did not name the OPERATOR_MANUAL timeout default drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T16C/bin/sec-sync-controller.py" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r'(BACKEND_TIMEOUT = float\(os\.environ\.get\("SEC_SYNC_TIMEOUT", ")\d+("\)\))',
    r"\g<1>30\g<2>",
    s,
    count=1,
)
if n != 1:
    sys.exit("bin/sec-sync-controller.py carries no BACKEND_TIMEOUT default to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T16C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the controller's BACKEND_TIMEOUT default drifts"
else
    no "coverage accepted a drifted controller BACKEND_TIMEOUT default"
    printf '%s\n' "$OUT"
fi
if grep -q "bin/sec-sync-controller.py BACKEND_TIMEOUT default is 30, expected 60" <<<"$OUT"; then
    ok "coverage names the controller's drifted BACKEND_TIMEOUT default"
else
    no "coverage did not name the controller BACKEND_TIMEOUT drift"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T16CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (timeout claims agree) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] timeout claim:" <<<"$OUT"; then
    ok "the control copy's OK line names the timeout claim"
else
    no "the control copy's OK line did not name the timeout claim"
    printf '%s\n' "$OUT"
fi
echo "[45] docs/SECURITY.md's file-permission claims must match the live chmod calls (issue #145)"
WORK_T17A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T17B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T17C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T17D="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T17CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T17A" "$WORK_T17B" "$WORK_T17C" "$WORK_T17D" "$WORK_T17CTRL"; do
    seed "$W"
done
python3 - "$WORK_T17A/docs/SECURITY.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"(~/.sec/sec\.conf`?: Configuration file mode `)0600(`)",
    r"\g<1>0644\g<2>",
    s,
    count=1,
)
if n != 1:
    sys.exit("docs/SECURITY.md carries no sec.conf mode 0600 to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T17A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when SECURITY.md's stated mode disagrees with its own chmod"
else
    no "coverage accepted a SECURITY.md mode disagreeing with its own chmod"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/SECURITY.md: ~/.sec/sec.conf states mode 0644 but its own chmod says 600" <<<"$OUT"; then
    ok "coverage names the SECURITY.md self-inconsistent mode"
else
    no "coverage did not name the SECURITY.md self-inconsistent mode"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T17B/docs/SECURITY.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"(~/.sec/sec\.conf`?: Configuration file mode `)0600(` \(`chmod )600(`\))",
    r"\g<1>0644\g<2>644\g<3>",
    s,
    count=1,
)
if n != 1:
    sys.exit("docs/SECURITY.md carries no sec.conf mode/chmod pair to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T17B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when SECURITY.md's mode disagrees with the live chmod"
else
    no "coverage accepted a SECURITY.md mode disagreeing with the live chmod"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/SECURITY.md: ~/.sec/sec.conf claims mode 0644, live chmod is 600" <<<"$OUT"; then
    ok "coverage names the SECURITY.md mode vs live-chmod mismatch"
else
    no "coverage did not name the SECURITY.md mode vs live-chmod mismatch"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T17C/docs/SECURITY.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"- `~/.cache/bitwarden/session`: [^\n]*\n", "", s, count=1)
if n != 1:
    sys.exit("docs/SECURITY.md carries no session line to remove")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T17C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when SECURITY.md stops documenting a guarded path"
else
    no "coverage accepted a SECURITY.md that drops a guarded path"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/SECURITY.md no longer documents a mode for ~/.cache/bitwarden/session" <<<"$OUT"; then
    ok "coverage names the SECURITY.md path it no longer documents"
else
    no "coverage did not name the dropped SECURITY.md path"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T17D/bin/bw-session-keeper" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r'chmod 600 "\$SESSION_FILE"', 'chmod 644 "$SESSION_FILE"', s, count=1)
if n != 1:
    sys.exit("bin/bw-session-keeper carries no SESSION_FILE chmod to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T17D" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when a live chmod drifts from SECURITY.md"
else
    no "coverage accepted a live chmod drifting from SECURITY.md"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/SECURITY.md: ~/.cache/bitwarden/session claims mode 0600, live chmod is 644" <<<"$OUT"; then
    ok "coverage names the live-chmod drift for the session key"
else
    no "coverage did not name the live-chmod drift for the session key"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T17CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (permissions agree) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] security perms:" <<<"$OUT"; then
    ok "the control copy's OK line names the SECURITY.md permission check"
else
    no "the control copy's OK line did not name the SECURITY.md permission check"
    printf '%s\n' "$OUT"
fi
echo
echo "[46] README.md + docs/MULTI_TENANCY.md sec.conf mode prose must match the live bin/sec chmod (issue #146)"
WORK_T18A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T18B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T18C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T18D="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T18CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T18A" "$WORK_T18B" "$WORK_T18C" "$WORK_T18D" "$WORK_T18CTRL"; do
    seed "$W"
done
python3 - "$WORK_T18A/README.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(`~/.sec/sec\.conf` \(mode `)0600(`\))", r"\g<1>0644\g<2>", s, count=1)
if n != 1:
    sys.exit("README.md carries no sec.conf (mode 0600) prose to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T18A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when README.md's sec.conf mode drifts"
else
    no "coverage accepted a README.md sec.conf mode drift"
    printf '%s\n' "$OUT"
fi
if grep -q "README.md states mode 0644 but the live bin/sec chmod says 600" <<<"$OUT"; then
    ok "coverage names the README.md sec.conf mode drift"
else
    no "coverage did not name the README.md sec.conf mode drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T18B/docs/MULTI_TENANCY.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"(`~/.sec/sec\.conf` \(mode `)0600(`\))", r"\g<1>0644\g<2>", s, count=1)
if n != 1:
    sys.exit("docs/MULTI_TENANCY.md carries no sec.conf (mode 0600) prose to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T18B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when docs/MULTI_TENANCY.md's sec.conf mode drifts"
else
    no "coverage accepted a docs/MULTI_TENANCY.md sec.conf mode drift"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/MULTI_TENANCY.md states mode 0644 but the live bin/sec chmod says 600" <<<"$OUT"; then
    ok "coverage names the docs/MULTI_TENANCY.md sec.conf mode drift"
else
    no "coverage did not name the docs/MULTI_TENANCY.md sec.conf mode drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T18C/bin/sec" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r'chmod 600 "\$CONFIG_FILE"', 'chmod 644 "$CONFIG_FILE"', s, count=1)
if n != 1:
    sys.exit("bin/sec carries no CONFIG_FILE chmod to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T18C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the live sec.conf chmod drifts from the doc prose"
else
    no "coverage accepted a live sec.conf chmod drift from the doc prose"
    printf '%s\n' "$OUT"
fi
if grep -q "README.md states mode 0600 but the live bin/sec chmod says 644" <<<"$OUT"; then
    ok "coverage names the live sec.conf chmod drift"
else
    no "coverage did not name the live sec.conf chmod drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T18D/README.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r" \(mode `0600`\)", "", s, count=1)
if n != 1:
    sys.exit("README.md carries no sec.conf mode clause to remove")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T18D" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when README.md stops stating the sec.conf mode"
else
    no "coverage accepted README.md dropping the sec.conf mode claim"
    printf '%s\n' "$OUT"
fi
if grep -q "README.md no longer states the ~/.sec/sec.conf mode in the guarded form" <<<"$OUT"; then
    ok "coverage names the dropped README.md sec.conf mode claim"
else
    no "coverage did not name the dropped README.md sec.conf mode claim"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T18CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (sec.conf mode prose agrees) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] sec.conf mode prose:" <<<"$OUT"; then
    ok "the control copy's OK line names the sec.conf mode prose check"
else
    no "the control copy's OK line did not name the sec.conf mode prose check"
    printf '%s\n' "$OUT"
fi
echo "[47] ADAPTERS.md's 'current suites:' guard must not be shadowed by an earlier inline mention (issue #147)"
WORK_T19A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T19CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T19A" "$WORK_T19CTRL"; do
    seed "$W"
done
python3 - "$WORK_T19A/ADAPTERS.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
if "current suites:" not in s:
    sys.exit("ADAPTERS.md carries no current-suites snapshot line")
lines = s.splitlines(keepends=True)
shadow = "Note: an earlier inline current suites: dispatch 0, write-honesty 0, sentinel 0, sync-guard 0, install 0; mention must not shadow the snapshot.\n"
lines.insert(1, shadow)
open(p, "w", encoding="utf-8").write("".join(lines))
PY
OUT="$(cd "$WORK_T19A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "coverage ignores an earlier inline 'current suites:' mention"
else
    no "coverage let an earlier inline 'current suites:' mention shadow the real snapshot"
    printf '%s\n' "$OUT"
fi
if grep -q "adapters suite counts:" <<<"$OUT"; then
    ok "coverage still resolves the real 'current suites:' snapshot"
else
    no "coverage did not resolve the real 'current suites:' snapshot"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T19CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (unshadowed snapshot) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -q "adapters suite counts:" <<<"$OUT"; then
    ok "the control copy's OK line names the adapters suite counts"
else
    no "the control copy's OK line did not name the adapters suite counts"
    printf '%s\n' "$OUT"
fi

echo "[48] RESUME.md's Verified-baseline count mirrors must not be shadowed by an earlier mention (issue #148)"
WORK_T20A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T20CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T20A" "$WORK_T20CTRL"; do
    seed "$W"
done
python3 - "$WORK_T20A/RESUME.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
sec = re.search(r"(?m)^## Verified baseline.*?\n([\s\S]*?)\n## ", s)
if not sec:
    sys.exit("RESUME.md: no Verified baseline section to probe")
body = sec.group(1)
cm = re.search(
    r"mirrors in sync\): ([a-z_]+) (\d+), ([a-z_]+) (\d+), ([a-z_]+) (\d+),"
    r" ([a-z_]+) (\d+),\s*\n([a-z_]+) (\d+)\.",
    body,
)
if not cm:
    sys.exit("RESUME.md: baseline section has no mirrors-in-sync line")
am = re.search(r"Sentinel = (\d+) cases / (\d+) assertions", body)
if not am:
    sys.exit("RESUME.md: baseline section has no Sentinel line")
g = cm.groups()
shadow = (
    "\nHistorical echo (must not shadow the baseline): the suite counts (all"
    " mirrors in sync): {k0} {n0}, {k1} {n1}, {k2} {n2}, {k3} {n3},\n"
    "{k4} {n4}. Sentinel = {c} cases / {a} assertions.\n\n"
).format(
    k0=g[0], n0=g[1], k1=g[2], n1=g[3], k2=g[4], n2=g[5], k3=g[6], n3=g[7],
    k4=g[8], n4=g[9], c=am.group(1), a=am.group(2),
)
drift = re.sub(r"sentinel (\d+)", lambda m: "sentinel " + str(int(m.group(1)) - 1), body, count=1)
drift = re.sub(
    r"(Sentinel = \d+ cases / )(\d+)( assertions)",
    lambda m: m.group(1) + str(int(m.group(2)) - 1) + m.group(3),
    drift,
    count=1,
)
if drift == body:
    sys.exit("RESUME.md: baseline counts not found to drift")
s = s[: sec.start()] + shadow + s[sec.start():].replace(body, drift, 1)
open(p, "w", encoding="utf-8").write(s)
PY
OUT="$(cd "$WORK_T20A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when an earlier echo shadows the baseline count mirrors"
else
    no "coverage let an earlier echo shadow the baseline count mirrors"
    printf '%s\n' "$OUT"
fi
if grep -q "RESUME.md says sentinel [0-9]*, live suite has" <<<"$OUT"; then
    ok "coverage names the real drifted suite count behind the shadow"
else
    no "coverage did not name the real drifted suite count behind the shadow"
    printf '%s\n' "$OUT"
fi
if grep -q "RESUME.md says Sentinel = [0-9]* assertions, live suite has" <<<"$OUT"; then
    ok "coverage names the real drifted assertion total behind the shadow"
else
    no "coverage did not name the real drifted assertion total behind the shadow"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T20CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (unshadowed baseline) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi

echo "[49] README.md / OPERATOR_MANUAL.md / ARCHITECTURE.md natural-language mode claims must match the live chmod/umask calls (issue #149)"
WORK_T21A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T21B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T21C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T21D="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T21E="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T21F="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T21CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T21A" "$WORK_T21B" "$WORK_T21C" "$WORK_T21D" "$WORK_T21E" "$WORK_T21F" "$WORK_T21CTRL"; do
    seed "$W"
done
python3 - "$WORK_T21A/README.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"Saves mode `0600` metadata-only snapshots",
    "Saves mode `0644` metadata-only snapshots",
    s,
    count=1,
)
if n != 1:
    sys.exit("README.md carries no snapshot mode 0600 claim to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T21A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when README.md's snapshot mode drifts"
else
    no "coverage accepted a README.md snapshot mode drift"
    printf '%s\n' "$OUT"
fi
if grep -q "README.md states the pre-apply snapshot mode 0644, but the sec-organizer snapshot chmod says 600" <<<"$OUT"; then
    ok "coverage names the README.md snapshot mode drift"
else
    no "coverage did not name the README.md snapshot mode drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T21B/docs/OPERATOR_MANUAL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"`~/.cache/bitwarden/snapshot_latest\.json`",
    "`~/.cache/bitwarden/old_snapshot.json`",
    s,
    count=1,
)
if n != 1:
    sys.exit("docs/OPERATOR_MANUAL.md carries no snapshot path to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T21B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when OPERATOR_MANUAL.md's snapshot path drifts"
else
    no "coverage accepted an OPERATOR_MANUAL.md snapshot path drift"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/OPERATOR_MANUAL.md names ~/.cache/bitwarden/old_snapshot.json, but the live snapshot path is ~/.cache/bitwarden/snapshot_latest.json" <<<"$OUT"; then
    ok "coverage names the OPERATOR_MANUAL.md snapshot path drift"
else
    no "coverage did not name the OPERATOR_MANUAL.md snapshot path drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T21C/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"sessions stored in a 0600 plaintext file",
    "sessions stored in a 0644 plaintext file",
    s,
    count=1,
)
if n != 1:
    sys.exit("docs/ARCHITECTURE.md carries no session 0600 claim to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T21C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when ARCHITECTURE.md's session mode drifts"
else
    no "coverage accepted an ARCHITECTURE.md session mode drift"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/ARCHITECTURE.md states the session-file mode 0644, but the bw-session-keeper session chmod says 600" <<<"$OUT"; then
    ok "coverage names the ARCHITECTURE.md session mode drift"
else
    no "coverage did not name the ARCHITECTURE.md session mode drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T21D/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s, n1 = re.subn(r"`umask 077`", "`umask 022`", s, count=1)
s, n2 = re.subn(
    r"`chmod 700` on `~/.cache/bitwarden`", "`chmod 755` on `~/.cache/bitwarden`", s, count=1
)
s, n3 = re.subn(r"the plan lands 0600", "the plan lands 0644", s, count=1)
if n1 != 1 or n2 != 1 or n3 != 1:
    sys.exit(f"docs/ARCHITECTURE.md sec-organizer claims not found: {n1} {n2} {n3}")
open(p, "w", encoding="utf-8").write(s)
PY
OUT="$(cd "$WORK_T21D" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when ARCHITECTURE.md's umask/cache-dir/plan modes drift"
else
    no "coverage accepted ARCHITECTURE.md umask/cache-dir/plan drifts"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/ARCHITECTURE.md states the umask 022, but the sec-organizer umask says 77" <<<"$OUT"; then
    ok "coverage names the ARCHITECTURE.md umask drift"
else
    no "coverage did not name the ARCHITECTURE.md umask drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T21E/install.sh" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r'chmod 600 "\$CONFIG_DIR/sec\.conf"',
    'chmod 644 "$CONFIG_DIR/sec.conf"',
    s,
    count=1,
)
if n != 1:
    sys.exit("install.sh carries no CONFIG_DIR/sec.conf chmod to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T21E" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the live install.sh sec.conf chmod drifts"
else
    no "coverage accepted a live install.sh sec.conf chmod drift"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/ARCHITECTURE.md states the sec.conf mode 600, but the install.sh sec.conf chmod says 644" <<<"$OUT"; then
    ok "coverage names the live install.sh sec.conf chmod drift"
else
    no "coverage did not name the live install.sh sec.conf chmod drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T21F/README.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(
    r"Saves mode `0600` metadata-only snapshots",
    "Saves metadata-only snapshots",
    s,
    count=1,
)
if n != 1:
    sys.exit("README.md carries no snapshot mode clause to remove")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T21F" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when README.md stops stating the snapshot mode"
else
    no "coverage accepted README.md dropping the snapshot mode claim"
    printf '%s\n' "$OUT"
fi
if grep -q "README.md no longer states the pre-apply snapshot mode in the guarded form" <<<"$OUT"; then
    ok "coverage names the dropped README.md snapshot mode claim"
else
    no "coverage did not name the dropped README.md snapshot mode claim"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T21CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (mode prose agrees) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] natural-language mode claims:" <<<"$OUT"; then
    ok "the control copy's OK line names the natural-language mode claim check"
else
    no "the control copy's OK line did not name the natural-language mode claim check"
    printf '%s\n' "$OUT"
fi
echo "[50] README.md / ARCHITECTURE.md runtime-dependency lists and the documented SEC_* env vars must match install.sh + bin/ (issue #150)"
WORK_T22A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T22B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T22C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T22D="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T22CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T22A" "$WORK_T22B" "$WORK_T22C" "$WORK_T22D" "$WORK_T22CTRL"; do
    seed "$W"
done
python3 - "$WORK_T22A/README.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"`python3`", "`python4`", s, count=1)
if n != 1:
    sys.exit("README.md carries no `python3` dependency token to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T22A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when README.md's runtime-dependency list drifts"
else
    no "coverage accepted a README.md runtime-dependency drift"
    printf '%s\n' "$OUT"
fi
if grep -q "README.md names runtime dependencies jq, python4, but install.sh checks jq, python3" <<<"$OUT"; then
    ok "coverage names the README.md runtime-dependency drift"
else
    no "coverage did not name the README.md runtime-dependency drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T22B/install.sh" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"for _dep in jq python3; do", "for _dep in jq python3 yq; do", s, count=1)
if n != 1:
    sys.exit("install.sh carries no 'for _dep in jq python3' loop to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T22B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the live install.sh dependency list drifts"
else
    no "coverage accepted a live install.sh dependency drift"
    printf '%s\n' "$OUT"
fi
if grep -q "README.md names runtime dependencies jq, python3, but install.sh checks jq, python3, yq" <<<"$OUT"; then
    ok "coverage names the live install.sh dependency drift"
else
    no "coverage did not name the live install.sh dependency drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T22C/docs/OPERATOR_MANUAL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"SEC_ALLOW_PLAINTEXT_MASTER_PASS=1", "SEC_ALLOW_PLAINTEXT_MASTER_PW=1", s, count=1)
if n != 1:
    sys.exit("docs/OPERATOR_MANUAL.md carries no SEC_ALLOW_PLAINTEXT_MASTER_PASS to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T22C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when a documented SEC_* env var has no live reader"
else
    no "coverage accepted a documented SEC_* env var with no live reader"
    printf '%s\n' "$OUT"
fi
if grep -q "the docs name SEC_ALLOW_PLAINTEXT_MASTER_PW, but no bin/ source or install.sh reads it" <<<"$OUT"; then
    ok "coverage names the unread documented SEC_* env var"
else
    no "coverage did not name the unread documented SEC_* env var"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T22D/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"Runtime dependencies beyond coreutils:", "Runtime deps:", s, count=1)
if n != 1:
    sys.exit("docs/ARCHITECTURE.md carries no runtime-dependency sentence to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T22D" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when ARCHITECTURE.md stops stating the runtime-dependency list"
else
    no "coverage accepted ARCHITECTURE.md dropping the runtime-dependency claim"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/ARCHITECTURE.md no longer states the runtime-dependency list in the guarded form" <<<"$OUT"; then
    ok "coverage names the dropped ARCHITECTURE.md runtime-dependency claim"
else
    no "coverage did not name the dropped ARCHITECTURE.md runtime-dependency claim"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T22CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (dep/env claims agree) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] runtime-dependency \+ env-var claims:" <<<"$OUT"; then
    ok "the control copy's OK line names the runtime-dependency/env-var check"
else
    no "the control copy's OK line did not name the runtime-dependency/env-var check"
    printf '%s\n' "$OUT"
fi
echo "[51] README.md / ARCHITECTURE.md run-injection backend claims must match the live bin/sec run arm (issue #151)"
WORK_T23A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T23B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T23C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T23D="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T23E="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T23F="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T23G="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T23CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T23A" "$WORK_T23B" "$WORK_T23C" "$WORK_T23D" "$WORK_T23E" "$WORK_T23F" "$WORK_T23G" "$WORK_T23CTRL"; do
    seed "$W"
done
python3 - "$WORK_T23A/README.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"env injection only for bws/op/infisical;", "env injection only for bws/op/vault;", s, count=1)
if n != 1:
    sys.exit("README.md carries no 'env injection only for bws/op/infisical;' comment to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T23A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when README.md's run-injection backend comment drifts"
else
    no "coverage accepted a README.md run-injection backend drift"
    printf '%s\n' "$OUT"
fi
if grep -q "README.md names run-injection backends bws, op, vault, but bin/sec injects via bws, infisical, op" <<<"$OUT"; then
    ok "coverage names the README.md run-injection backend drift"
else
    no "coverage did not name the README.md run-injection backend drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T23B/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"`bws`/`op`/`infisical`, secrets reach", "`bws`/`op`/`vault`, secrets reach", s, count=1)
if n != 1:
    sys.exit("docs/ARCHITECTURE.md carries no in-memory-injection backend list to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T23B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when ARCHITECTURE.md's run-injection backend list drifts"
else
    no "coverage accepted an ARCHITECTURE.md run-injection backend drift"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/ARCHITECTURE.md names run-injection backends bws, op, vault, but bin/sec injects via bws, infisical, op" <<<"$OUT"; then
    ok "coverage names the ARCHITECTURE.md run-injection backend drift"
else
    no "coverage did not name the ARCHITECTURE.md run-injection backend drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T23C/bin/sec" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"1pass\|op\)(\s+)exec op run", r"1pass|op|vault)\1exec op run", s, count=1)
if n != 1:
    sys.exit("bin/sec carries no '1pass|op) exec op run' arm to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T23C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the live bin/sec run arm gains an injection backend"
else
    no "coverage accepted a live bin/sec run-injection backend drift"
    printf '%s\n' "$OUT"
fi
if grep -q "README.md names run-injection backends bws, infisical, op, but bin/sec injects via bws, infisical, op, vault" <<<"$OUT"; then
    ok "coverage names the live bin/sec run-injection backend drift"
else
    no "coverage did not name the live bin/sec run-injection backend drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T23D/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"secrets reach child process environments", "secrets reach child env", s, count=1)
if n != 1:
    sys.exit("docs/ARCHITECTURE.md carries no in-memory-injection sentence to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T23D" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when ARCHITECTURE.md stops stating the run-injection claim"
else
    no "coverage accepted ARCHITECTURE.md dropping the run-injection claim"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/ARCHITECTURE.md no longer states the run-injection backend set in the guarded form" <<<"$OUT"; then
    ok "coverage names the dropped ARCHITECTURE.md run-injection claim"
else
    no "coverage did not name the dropped ARCHITECTURE.md run-injection claim"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T23E/docs/OPERATOR_MANUAL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"credentials into RAM only for `bws`/`op`/`infisical` \(", "credentials into RAM only for `bws`/`op`/`vault` (", s, count=1)
if n != 1:
    sys.exit("docs/OPERATOR_MANUAL.md carries no 'credentials into RAM only for `bws`/`op`/`infisical`' list to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T23E" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when OPERATOR_MANUAL.md's injection-backend list drifts"
else
    no "coverage accepted an OPERATOR_MANUAL.md run-injection backend drift"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/OPERATOR_MANUAL.md names run-injection backends bws, op, vault, but bin/sec injects via bws, infisical, op" <<<"$OUT"; then
    ok "coverage names the OPERATOR_MANUAL.md run-injection backend drift"
else
    no "coverage did not name the OPERATOR_MANUAL.md run-injection backend drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T23F/docs/OPERATOR_MANUAL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"only when the tenant is `bws`, `op` or `infisical`", "only when the tenant is `bws`, `op` or `vault`", s, count=1)
if n != 1:
    sys.exit("docs/OPERATOR_MANUAL.md carries no 'only when the tenant is `bws`, `op` or `infisical`' sentence to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T23F" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when OPERATOR_MANUAL.md's run-injection sentence drifts"
else
    no "coverage accepted an OPERATOR_MANUAL.md run-injection sentence drift"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/OPERATOR_MANUAL.md names run-injection backends bws, op, vault, but bin/sec injects via bws, infisical, op" <<<"$OUT"; then
    ok "coverage names the OPERATOR_MANUAL.md run-injection sentence drift"
else
    no "coverage did not name the OPERATOR_MANUAL.md run-injection sentence drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T23G/docs/SECURITY.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"Vendor run-wrappers \(`bws`/`op`/`infisical`\) inject secrets", "Vendor run-wrappers (`bws`/`op`/`vault`) inject secrets", s, count=1)
if n != 1:
    sys.exit("docs/SECURITY.md carries no 'Vendor run-wrappers (`bws`/`op`/`infisical`) inject secrets' clause to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T23G" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when SECURITY.md's run-injection backend set drifts"
else
    no "coverage accepted a SECURITY.md run-injection backend drift"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/SECURITY.md names run-injection backends bws, op, vault, but bin/sec injects via bws, infisical, op" <<<"$OUT"; then
    ok "coverage names the SECURITY.md run-injection backend drift"
else
    no "coverage did not name the SECURITY.md run-injection backend drift"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T23CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (run-injection claims agree) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] run-injection claims:" <<<"$OUT"; then
    ok "the control copy's OK line names the run-injection check"
else
    no "the control copy's OK line did not name the run-injection check"
    printf '%s\n' "$OUT"
fi
echo
echo "[52] README.md / ARCHITECTURE.md classifier-category claims must name live bin/sec-classify.py CATEGORY_WEIGHTS keys (issue #152)"
WORK_T24A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T24B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T24C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T24D="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T24CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T24A" "$WORK_T24B" "$WORK_T24C" "$WORK_T24D" "$WORK_T24CTRL"; do
    seed "$W"
done
python3 - "$WORK_T24A/README.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"`infrastructure/ssh`\)\.", "`infrastructure/shell`).", s, count=1)
if n != 1:
    sys.exit("README.md carries no classifier category list to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T24A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when README.md names a non-live classifier category"
else
    no "coverage accepted a README.md classifier-category drift"
    printf '%s\n' "$OUT"
fi
if grep -q "README.md names classifier categories infrastructure/shell, but bin/sec-classify.py's CATEGORY_WEIGHTS declares" <<<"$OUT"; then
    ok "coverage names the README.md classifier-category drift"
else
    no "coverage did not name the README.md classifier-category drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T24B/bin/sec-classify.py" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r'"infrastructure/ssh": \{', '"infrastructure/sshd": {', s, count=1)
if n != 1:
    sys.exit("bin/sec-classify.py carries no 'infrastructure/ssh' category key to rename")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T24B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when a live classifier category is renamed away"
else
    no "coverage accepted a renamed live classifier category"
    printf '%s\n' "$OUT"
fi
if grep -q "README.md names classifier categories infrastructure/ssh, but bin/sec-classify.py's CATEGORY_WEIGHTS declares" <<<"$OUT"; then
    ok "coverage names the README.md category that drifted from a renamed live key"
else
    no "coverage did not name the drifted README.md category"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T24C/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"claims `cloud/gcp` instead", "claims `cloud/google` instead", s, count=1)
if n != 1:
    sys.exit("docs/ARCHITECTURE.md carries no 'claims `cloud/gcp`' clause to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T24C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when ARCHITECTURE.md names a non-live classifier category"
else
    no "coverage accepted an ARCHITECTURE.md classifier-category drift"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/ARCHITECTURE.md says a GCP service-account URI claims cloud/google, but bin/sec-classify.py's CATEGORY_WEIGHTS declares" <<<"$OUT"; then
    ok "coverage names the ARCHITECTURE.md classifier-category drift"
else
    no "coverage did not name the ARCHITECTURE.md classifier-category drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T24D/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"now classifies `cloud/aws`", "classifies `cloud/aws`", s, count=1)
if n != 1:
    sys.exit("docs/ARCHITECTURE.md carries no 'now classifies `cloud/aws`' clause to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T24D" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when ARCHITECTURE.md drops the classifier sentence shape"
else
    no "coverage accepted a dropped ARCHITECTURE.md classifier sentence"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/ARCHITECTURE.md no longer states the login-field classification examples in the guarded form" <<<"$OUT"; then
    ok "coverage names the dropped ARCHITECTURE.md classifier sentence"
else
    no "coverage did not name the dropped ARCHITECTURE.md classifier sentence"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T24CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (classifier categories agree) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] classifier categories:" <<<"$OUT"; then
    ok "the control copy's OK line names the classifier-category check"
else
    no "the control copy's OK line did not name the classifier-category check"
    printf '%s\n' "$OUT"
fi
echo
echo "[53] OPERATOR_MANUAL.md's completion shell set, alias, and completions/_sec must match the live bin/sec completion dispatch (issue #153)"
WORK_T25A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T25B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T25C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T25D="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T25CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T25A" "$WORK_T25B" "$WORK_T25C" "$WORK_T25D" "$WORK_T25CTRL"; do
    seed "$W"
done
python3 - "$WORK_T25A/docs/OPERATOR_MANUAL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"`sec completion \{zsh\|bash\|fish\|ps1\}`", "`sec completion {zsh|bash|fish|ksh}`", s, count=1)
if n != 1:
    sys.exit("docs/OPERATOR_MANUAL.md carries no completion shell set to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T25A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when OPERATOR_MANUAL.md's completion shell set drifts"
else
    no "coverage accepted a completion shell-set drift"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/OPERATOR_MANUAL.md names completion shells bash, fish, ksh, zsh, but bin/sec accepts" <<<"$OUT"; then
    ok "coverage names the completion shell-set drift"
else
    no "coverage did not name the completion shell-set drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T25B/docs/OPERATOR_MANUAL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"`powershell` is accepted as an alias for `ps1`", "`pwsh` is accepted as an alias for `ps1`", s, count=1)
if n != 1:
    sys.exit("docs/OPERATOR_MANUAL.md carries no completion alias sentence to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T25B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the completion alias drifts"
else
    no "coverage accepted a completion alias drift"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/OPERATOR_MANUAL.md documents the completion alias pwsh -> ps1, but bin/sec groups powershell with ps1" <<<"$OUT"; then
    ok "coverage names the completion alias drift"
else
    no "coverage did not name the completion alias drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T25C/completions/_sec" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2 = s.replace("_sec", "_secX", 1)
if s2 == s:
    sys.exit("completions/_sec carries no token to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T25C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when completions/_sec drifts from the live zsh output"
else
    no "coverage accepted a completions/_sec drift"
    printf '%s\n' "$OUT"
fi
if grep -q "completions/_sec is not byte-identical to live 'bin/sec completion zsh' output" <<<"$OUT"; then
    ok "coverage names the completions/_sec byte drift"
else
    no "coverage did not name the completions/_sec byte drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T25D/docs/OPERATOR_MANUAL.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r" \(`powershell` is accepted as an alias for `ps1`\)", "", s, count=1)
if n != 1:
    sys.exit("docs/OPERATOR_MANUAL.md carries no completion alias parenthetical to drop")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T25D" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when OPERATOR_MANUAL.md drops the completion-alias sentence"
else
    no "coverage accepted a dropped completion-alias sentence"
    printf '%s\n' "$OUT"
fi
if grep -q "docs/OPERATOR_MANUAL.md no longer states the completion-alias sentence" <<<"$OUT"; then
    ok "coverage names the dropped completion-alias sentence"
else
    no "coverage did not name the dropped completion-alias sentence"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T25CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (completion surfaces agree) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] completion surfaces:" <<<"$OUT"; then
    ok "the control copy's OK line names the completion-surface check"
else
    no "the control copy's OK line did not name the completion-surface check"
    printf '%s\n' "$OUT"
fi
echo "[54] docs/ARCHITECTURE.md's + README.md's bin/sec.ps1 native subset + bin/sec-only full surface must match the live dispatch (issues #154/#177)"
WORK_T26A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T26B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T26C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T26D="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T26E="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T26CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T26A" "$WORK_T26B" "$WORK_T26C" "$WORK_T26D" "$WORK_T26E" "$WORK_T26CTRL"; do
    seed "$W"
done
python3 - "$WORK_T26A/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"`get`, `set`, `run` natively", "`get`, `set`, `sync` natively", s, count=1)
if n != 1:
    sys.exit("docs/ARCHITECTURE.md carries no bin/sec.ps1 native subset to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T26A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when ARCHITECTURE.md's bin/sec.ps1 native subset drifts"
else
    no "coverage accepted a bin/sec.ps1 native-subset drift"
    printf '%s\n' "$OUT"
fi
if grep -qF "docs/ARCHITECTURE.md names bin/sec.ps1 native subcommands get, housekeep, migrate, set, sync, but bin/sec.ps1 implements get, housekeep, migrate, run, set" <<<"$OUT"; then
    ok "coverage names the bin/sec.ps1 native-subset drift"
else
    no "coverage did not name the bin/sec.ps1 native-subset drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T26B/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"`setup-keychain`, `completion`, and", "`setup-keychain`, `migrate`, and", s, count=1)
if n != 1:
    sys.exit("docs/ARCHITECTURE.md carries no bin/sec 'full surface' list to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T26B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when ARCHITECTURE.md names a ps1 command as bin/sec-only"
else
    no "coverage accepted a bin/sec-only command that ps1 also implements"
    printf '%s\n' "$OUT"
fi
if grep -qF "docs/ARCHITECTURE.md says \`migrate\` lives only in bin/sec, but bin/sec.ps1 also implements it" <<<"$OUT"; then
    ok "coverage names the bin/sec-only command ps1 also implements"
else
    no "coverage did not name the bin/sec-only command ps1 also implements"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T26C/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"\(`sync`, `unlock`, `rotate`", "(`snych`, `unlock`, `rotate`", s, count=1)
if n != 1:
    sys.exit("docs/ARCHITECTURE.md carries no bin/sec 'full surface' list to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T26C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when ARCHITECTURE.md names a non-command as bin/sec-only"
else
    no "coverage accepted a non-command in the bin/sec surface list"
    printf '%s\n' "$OUT"
fi
if grep -qF "docs/ARCHITECTURE.md names \`snych\` as part of bin/sec's surface, but bin/sec dispatches no \`snych\` command" <<<"$OUT"; then
    ok "coverage names the non-command in the bin/sec surface list"
else
    no "coverage did not name the non-command in the bin/sec surface list"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T26D/docs/ARCHITECTURE.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r" by delegating to the bash helpers", " by delegating", s, count=1)
if n != 1:
    sys.exit("docs/ARCHITECTURE.md carries no bin/sec.ps1 delegation phrase to drop")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T26D" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when ARCHITECTURE.md drops the bin/sec.ps1 native-subset sentence"
else
    no "coverage accepted a dropped bin/sec.ps1 native-subset sentence"
    printf '%s\n' "$OUT"
fi
if grep -qF "docs/ARCHITECTURE.md no longer states bin/sec.ps1's native subcommand subset in the guarded form" <<<"$OUT"; then
    ok "coverage names the dropped bin/sec.ps1 native-subset sentence"
else
    no "coverage did not name the dropped bin/sec.ps1 native-subset sentence"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T26E/README.md" <<'PY'
import re
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s2, n = re.subn(r"\(core: `get`/`set`/`run`; full surface via Git Bash\)", "(core: `get`/`sync`/`run`; full surface via Git Bash)", s, count=1)
if n != 1:
    sys.exit("README.md carries no Multi-OS PowerShell cell to corrupt")
open(p, "w", encoding="utf-8").write(s2)
PY
OUT="$(cd "$WORK_T26E" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when README.md's Multi-OS PowerShell cell drifts"
else
    no "coverage accepted a README.md Multi-OS PowerShell-cell drift"
    printf '%s\n' "$OUT"
fi
if grep -qF "README.md's Windows Native PowerShell cell names get, run, sync, but bin/sec.ps1 implements natively (non-delegating) get, run, set" <<<"$OUT"; then
    ok "coverage names the README.md Multi-OS PowerShell-cell drift"
else
    no "coverage did not name the README.md Multi-OS PowerShell-cell drift"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T26CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (ps1 surface agrees) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] ps1 surface:" <<<"$OUT"; then
    ok "the control copy's OK line names the ps1-surface check"
else
    no "the control copy's OK line did not name the ps1-surface check"
    printf '%s\n' "$OUT"
fi
echo "[57] docs/SECURITY.md's executables enumeration must match the live bin/ tree grouped by shebang (issue #155)"
WORK_T33A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T33B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T33C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T33D="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T33CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T33A" "$WORK_T33B" "$WORK_T33C" "$WORK_T33D" "$WORK_T33CTRL"; do
    seed "$W"
done
python3 - "$WORK_T33A/docs/SECURITY.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "`bin/sec-migrator`, `bin/hyer-mcp.sh`), Python 3"
new = "`bin/sec-migrator`), Python 3"
if s.count(old) != 1:
    sys.exit("docs/SECURITY.md carries no POSIX Bash executable list to corrupt")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_T33A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when SECURITY.md drops a bash executable from its POSIX Bash group"
else
    no "coverage accepted a dropped bash executable in SECURITY.md's POSIX Bash group"
    printf '%s\n' "$OUT"
fi
if grep -qF "docs/SECURITY.md names POSIX Bash executables bin/bw-session-keeper, bin/sec, bin/sec-migrator, bin/sec-organizer, but the live bin/ tree has bin/bw-session-keeper, bin/hyer-mcp.sh, bin/sec, bin/sec-migrator, bin/sec-organizer" <<<"$OUT"; then
    ok "coverage names the dropped bash executable in SECURITY.md's POSIX Bash group"
else
    no "coverage did not name the dropped bash executable in SECURITY.md's POSIX Bash group"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T33B/docs/SECURITY.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "`bin/sec-classify.py`, `bin/sec-sync-controller.py`), and PowerShell"
new = "`bin/sec-classify.py`), and PowerShell"
if s.count(old) != 1:
    sys.exit("docs/SECURITY.md carries no Python 3 executable list to corrupt")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_T33B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when SECURITY.md drops a python executable from its Python 3 group"
else
    no "coverage accepted a dropped python executable in SECURITY.md's Python 3 group"
    printf '%s\n' "$OUT"
fi
if grep -qF "docs/SECURITY.md names Python 3 executables bin/sec-classify.py, but the live bin/ tree has bin/sec-classify.py, bin/sec-sync-controller.py" <<<"$OUT"; then
    ok "coverage names the dropped python executable in SECURITY.md's Python 3 group"
else
    no "coverage did not name the dropped python executable in SECURITY.md's Python 3 group"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T33C/docs/SECURITY.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "`bin/sec-migrator`, `bin/hyer-mcp.sh`), Python 3"
new = "`bin/sec-migrator`, `bin/hyer-mcp.sh`, `bin/ghost.sh`), Python 3"
if s.count(old) != 1:
    sys.exit("docs/SECURITY.md carries no POSIX Bash executable list to extend")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_T33C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when SECURITY.md names a nonexistent bash executable"
else
    no "coverage accepted a nonexistent bash executable in SECURITY.md"
    printf '%s\n' "$OUT"
fi
if grep -qF "docs/SECURITY.md names POSIX Bash executables bin/bw-session-keeper, bin/ghost.sh, bin/hyer-mcp.sh, bin/sec, bin/sec-migrator, bin/sec-organizer, but the live bin/ tree has bin/bw-session-keeper, bin/hyer-mcp.sh, bin/sec, bin/sec-migrator, bin/sec-organizer" <<<"$OUT"; then
    ok "coverage names the nonexistent bash executable in SECURITY.md"
else
    no "coverage did not name the nonexistent bash executable in SECURITY.md"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T33D/docs/SECURITY.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
if s.count("Executables are human-readable") != 1:
    sys.exit("docs/SECURITY.md carries no executable-enumeration anchor phrase to drop")
open(p, "w", encoding="utf-8").write(s.replace("Executables are human-readable", "Executables are legible", 1))
PY
OUT="$(cd "$WORK_T33D" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when SECURITY.md drops the executable-enumeration anchor phrase"
else
    no "coverage accepted a dropped executable-enumeration anchor phrase in SECURITY.md"
    printf '%s\n' "$OUT"
fi
if grep -qF "docs/SECURITY.md no longer enumerates its executables in the guarded 'Executables are human-readable ...' form" <<<"$OUT"; then
    ok "coverage names the dropped executable-enumeration anchor phrase"
else
    no "coverage did not name the dropped executable-enumeration anchor phrase"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T33CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (SECURITY.md executable list agrees) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] security executables:" <<<"$OUT"; then
    ok "the control copy's OK line names the security-executables check"
else
    no "the control copy's OK line did not name the security-executables check"
    printf '%s\n' "$OUT"
fi
echo "[58] docs/OPERATOR_MANUAL.md + docs/ARCHITECTURE.md + skills/architecture-360-audit/SKILL.md's sec sync exit-code contract must match bin/sec-sync-controller.py (issues #156, #157)"
WORK_T34A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T34B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T34C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T34D="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T34E="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T34CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T34A" "$WORK_T34B" "$WORK_T34C" "$WORK_T34D" "$WORK_T34E" "$WORK_T34CTRL"; do
    seed "$W"
done
python3 - "$WORK_T34A/docs/OPERATOR_MANUAL.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "`3` one or more backend writes failed"
new = "three one or more backend writes failed"
if s.count(old) != 1:
    sys.exit("docs/OPERATOR_MANUAL.md carries no sync exit-code `3` to drop")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_T34A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when OPERATOR_MANUAL.md drops the sync '3' exit code"
else
    no "coverage accepted a dropped sync '3' exit code in OPERATOR_MANUAL.md"
    printf '%s\n' "$OUT"
fi
if grep -qF "docs/OPERATOR_MANUAL.md's sync exit codes are [0, 1, 2], but bin/sec-sync-controller.py returns [0, 1, 2, 3]" <<<"$OUT"; then
    ok "coverage names the dropped sync '3' exit code in OPERATOR_MANUAL.md"
else
    no "coverage did not name the dropped sync '3' exit code in OPERATOR_MANUAL.md"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T34B/docs/OPERATOR_MANUAL.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "`0` every attempted write succeeded"
new = "`9` every attempted write succeeded"
if s.count(old) != 1:
    sys.exit("docs/OPERATOR_MANUAL.md carries no sync exit-code `0` to corrupt")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_T34B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when OPERATOR_MANUAL.md names a bogus sync exit code"
else
    no "coverage accepted a bogus sync exit code in OPERATOR_MANUAL.md"
    printf '%s\n' "$OUT"
fi
if grep -qF "docs/OPERATOR_MANUAL.md's sync exit codes are [1, 2, 3, 9], but bin/sec-sync-controller.py returns [0, 1, 2, 3]" <<<"$OUT"; then
    ok "coverage names the bogus sync exit code in OPERATOR_MANUAL.md"
else
    no "coverage did not name the bogus sync exit code in OPERATOR_MANUAL.md"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T34C/docs/ARCHITECTURE.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "(contract: 0 success / 1 no keys / 2 confirmation / 3 backend write failure)"
new = "(contract: 0 success / 1 no keys / 3 backend write failure)"
if s.count(old) != 1:
    sys.exit("docs/ARCHITECTURE.md carries no sync exit-code contract clause to corrupt")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_T34C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when ARCHITECTURE.md drops the sync '2' exit code"
else
    no "coverage accepted a dropped sync '2' exit code in ARCHITECTURE.md"
    printf '%s\n' "$OUT"
fi
if grep -qF "docs/ARCHITECTURE.md's sync exit-code contract is [0, 1, 3], but bin/sec-sync-controller.py returns [0, 1, 2, 3]" <<<"$OUT"; then
    ok "coverage names the dropped sync '2' exit code in ARCHITECTURE.md"
else
    no "coverage did not name the dropped sync '2' exit code in ARCHITECTURE.md"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T34D/bin/sec-sync-controller.py" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "No active keys found"
new = "No active keys present"
if s.count(old) != 1:
    sys.exit("bin/sec-sync-controller.py carries no 'No active keys found' anchor to drop")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_T34D" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when bin/sec-sync-controller.py drops an exit-code meaning anchor"
else
    no "coverage accepted a dropped exit-code meaning anchor in bin/sec-sync-controller.py"
    printf '%s\n' "$OUT"
fi
if grep -qF "bin/sec-sync-controller.py no longer carries the 1-code anchor 'No active keys found'" <<<"$OUT"; then
    ok "coverage names the dropped exit-code meaning anchor in bin/sec-sync-controller.py"
else
    no "coverage did not name the dropped exit-code meaning anchor in bin/sec-sync-controller.py"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T34E/skills/architecture-360-audit/SKILL.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "exit codes 0/1/2/3)"
new = "exit codes 0/1/2)"
if s.count(old) != 1:
    sys.exit("skills/architecture-360-audit/SKILL.md carries no sync 'exit codes 0/1/2/3' clause to corrupt")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_T34E" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when SKILL.md drops the sync '3' exit code"
else
    no "coverage accepted a dropped sync '3' exit code in SKILL.md"
    printf '%s\n' "$OUT"
fi
if grep -qF "skills/architecture-360-audit/SKILL.md's sync exit codes are [0, 1, 2], but bin/sec-sync-controller.py returns [0, 1, 2, 3]" <<<"$OUT"; then
    ok "coverage names the dropped sync '3' exit code in SKILL.md"
else
    no "coverage did not name the dropped sync '3' exit code in SKILL.md"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T34CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (sync exit-code contract agrees) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] sync exit codes:" <<<"$OUT"; then
    ok "the control copy's OK line names the sync-exit-code check"
else
    no "the control copy's OK line did not name the sync-exit-code check"
    printf '%s\n' "$OUT"
fi
echo "[59] docs/SECURITY.md's process-table / in-memory-injection mitigations must still exist in the live bin/ code (issue #158)"
WORK_T35A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T35B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T35CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for W in "$WORK_T35A" "$WORK_T35B" "$WORK_T35CTRL"; do
    seed "$W"
done
python3 - "$WORK_T35A/docs/SECURITY.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "read -rsp"
new = "read -rs"
if s.count(old) != 1:
    sys.exit("docs/SECURITY.md carries no `read -rsp` mitigation to drop")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_T35A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when SECURITY.md drops a stdin-prompt mitigation token"
else
    no "coverage accepted a dropped stdin-prompt mitigation token in SECURITY.md"
    printf '%s\n' "$OUT"
fi
if grep -qF 'docs/SECURITY.md no longer states its `read -rsp` mitigation' <<<"$OUT"; then
    ok "coverage names the dropped stdin-prompt mitigation token in SECURITY.md"
else
    no "coverage did not name the dropped stdin-prompt mitigation token in SECURITY.md"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T35B/bin/bw-session-keeper" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "bw unlock --passwordenv"
new = "bw unlock --pwenv"
if s.count(old) != 1:
    sys.exit("bin/bw-session-keeper carries no `bw unlock --passwordenv` anchor to drop")
open(p, "w", encoding="utf-8").write(s.replace(old, new, 1))
PY
OUT="$(cd "$WORK_T35B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the live bin/ code drops a claimed mitigation mechanism"
else
    no "coverage accepted a dropped mitigation mechanism in the live bin/ code"
    printf '%s\n' "$OUT"
fi
if grep -qF 'docs/SECURITY.md still claims the `bw unlock --passwordenv` mitigation, but bin/bw-session-keeper no longer carries `bw unlock --passwordenv`' <<<"$OUT"; then
    ok "coverage names the dropped mitigation mechanism in the live bin/ code"
else
    no "coverage did not name the dropped mitigation mechanism in the live bin/ code"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T35CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (process-table mitigations agree) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] security process table:" <<<"$OUT"; then
    ok "the control copy's OK line names the process-table mitigation check"
else
    no "the control copy's OK line did not name the process-table mitigation check"
    printf '%s\n' "$OUT"
fi
echo "[60] docs/SECURITY.md's snapshot-contents field enumeration must match bin/sec-organizer's live snapshot schema (issue #159)"
WORK_T36A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T36B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T36CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for _w in "$WORK_T36A" "$WORK_T36B" "$WORK_T36CTRL"; do
    seed "$_w"
done
python3 - "$WORK_T36A/docs/SECURITY.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "`newName`, "
if s.count(old) != 1:
    sys.exit("docs/SECURITY.md field list no longer carries the `newName` token to drop")
open(p, "w", encoding="utf-8").write(s.replace(old, "", 1))
PY
OUT="$(cd "$WORK_T36A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when SECURITY.md drops a live snapshot field"
else
    no "coverage accepted a dropped snapshot field in SECURITY.md"
    printf '%s\n' "$OUT"
fi
if grep -qF 'docs/SECURITY.md enumerates snapshot fields' <<<"$OUT"; then
    ok "coverage names the drifted snapshot field enumeration"
else
    no "coverage did not name the drifted snapshot field enumeration"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T36B/bin/sec-organizer" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = '"newName": $new_name'
if s.count(old) != 1:
    sys.exit("bin/sec-organizer no longer carries the \"newName\" action field to rename")
open(p, "w", encoding="utf-8").write(s.replace(old, '"proposedName": $new_name', 1))
PY
OUT="$(cd "$WORK_T36B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the live snapshot schema drifts from the doc"
else
    no "coverage accepted a live snapshot schema drift from the doc"
    printf '%s\n' "$OUT"
fi
if grep -qF 'but bin/sec-organizer writes' <<<"$OUT"; then
    ok "coverage names the live snapshot schema drift"
else
    no "coverage did not name the live snapshot schema drift"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T36CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (snapshot field enumeration agrees) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
 if grep -qE "\[ OK \] security snapshot fields:" <<<"$OUT"; then
     ok "the control copy's OK line names the snapshot-fields check"
 else
     no "the control copy's OK line did not name the snapshot-fields check"
     printf '%s\n' "$OUT"
 fi
echo "[61] docs/ARCHITECTURE.md's install-path claims must match install.sh's live behavior (issue #160)"
WORK_T37A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T37B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T37C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T37D="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T37E="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T37CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for _w in "$WORK_T37A" "$WORK_T37B" "$WORK_T37C" "$WORK_T37D" "$WORK_T37E" "$WORK_T37CTRL"; do
    seed "$_w"
done
python3 - "$WORK_T37A/docs/ARCHITECTURE.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "to `~/.local/bin`, `sec.conf` created mode"
if s.count(old) != 1:
    sys.exit("docs/ARCHITECTURE.md's install.sh bullet no longer names the install destination")
open(p, "w", encoding="utf-8").write(s.replace(old, "to `~/.local/sbin`, `sec.conf` created mode", 1))
PY
OUT="$(cd "$WORK_T37A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the doc's install destination drifts"
else
    no "coverage accepted an install-destination drift in the doc"
    printf '%s\n' "$OUT"
fi
if grep -qF "but install.sh's INSTALL_DIR defaults to" <<<"$OUT"; then
    ok "coverage names the live INSTALL_DIR on an install-destination drift"
else
    no "coverage did not name the live INSTALL_DIR"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T37B/install.sh" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = 'BOOTSTRAP_DIR="${SEC_BOOTSTRAP_DIR:-$HOME/.sec-cli}"'
if s.count(old) != 1:
    sys.exit("install.sh no longer binds BOOTSTRAP_DIR to the documented default")
open(p, "w", encoding="utf-8").write(s.replace(old, 'BOOTSTRAP_DIR="${SEC_BOOTSTRAP_DIR:-$HOME/.sec-bootstrap}"', 1))
PY
OUT="$(cd "$WORK_T37B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the live bootstrap dir drifts from the doc"
else
    no "coverage accepted a live bootstrap-dir drift from the doc"
    printf '%s\n' "$OUT"
fi
if grep -qF "but install.sh's BOOTSTRAP_DIR defaults to" <<<"$OUT"; then
    ok "coverage names the live BOOTSTRAP_DIR on a bootstrap-dir drift"
else
    no "coverage did not name the live BOOTSTRAP_DIR"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T37C/install.sh" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = '    cp "$SCRIPT_DIR/bin/sec.ps1" "$INSTALL_DIR/sec.ps1"\n'
if s.count(old) != 1:
    sys.exit("install.sh no longer copies bin/sec.ps1")
open(p, "w", encoding="utf-8").write(s.replace(old, "", 1))
PY
OUT="$(cd "$WORK_T37C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when install.sh stops copying a tracked bin/ helper"
else
    no "coverage accepted a copied-set drift in install.sh"
    printf '%s\n' "$OUT"
fi
if grep -qF "uncopied" <<<"$OUT"; then
    ok "coverage names the uncopied bin/ helper on a copied-set drift"
else
    no "coverage did not name the uncopied bin/ helper"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T37D/install.sh" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = 'if [[ -f "$SCRIPT_DIR/LICENSE" ]]; then\n    cp "$SCRIPT_DIR/LICENSE" "$INSTALL_DIR/sec-cli-LICENSE"\nfi\n'
if s.count(old) != 1:
    sys.exit("install.sh no longer copies LICENSE under the documented name")
open(p, "w", encoding="utf-8").write(
    s.replace(old, 'if [[ -f "$SCRIPT_DIR/LICENSE" ]]; then\n    cp "$SCRIPT_DIR/LICENSE" "$INSTALL_DIR/LICENSE"\nfi\n', 1)
)
PY
OUT="$(cd "$WORK_T37D" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the live LICENSE copy name drifts"
else
    no "coverage accepted a LICENSE copy-name drift in install.sh"
    printf '%s\n' "$OUT"
fi
if grep -qF "but install.sh writes the LICENSE copy as" <<<"$OUT"; then
    ok "coverage names the live LICENSE copy name"
else
    no "coverage did not name the live LICENSE copy name"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T37E/install.sh" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = """        if ! command -v git >/dev/null 2>&1; then
            echo "=== ERROR: git is required for a piped install (clones $REPO_URL) but was not found on PATH. Install git, or run the tracked install.sh from a checkout. ==="
            exit 1
        fi
"""
if s.count(old) != 1:
    sys.exit("install.sh no longer carries the missing-git diagnosis block")
open(p, "w", encoding="utf-8").write(s.replace(old, "", 1))
PY
OUT="$(cd "$WORK_T37E" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the missing-git diagnosis disappears"
else
    no "coverage accepted a missing-git diagnosis removal"
    printf '%s\n' "$OUT"
fi
if grep -qF "no longer diagnoses a missing git before the bootstrap clone" <<<"$OUT"; then
    ok "coverage names the lost missing-git diagnosis"
else
    no "coverage did not name the lost missing-git diagnosis"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T37CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (install-path claims agree) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] install-path claims:" <<<"$OUT"; then
    ok "the control copy's OK line names the install-path check"
else
    no "the control copy's OK line did not name the install-path check"
    printf '%s\n' "$OUT"
fi

echo "[62] docs/MULTI_TENANCY.md's auto_rotate table must match bin/sec's live ensure_tenant_auth arms (issue #160)"
WORK_T38A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T38B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T38C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T38D="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T38E="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T38CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for _w in "$WORK_T38A" "$WORK_T38B" "$WORK_T38C" "$WORK_T38D" "$WORK_T38E" "$WORK_T38CTRL"; do
    seed "$_w"
done
python3 - "$WORK_T38A/docs/MULTI_TENANCY.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "| `1pass` | no |"
if s.count(old) != 1:
    sys.exit("docs/MULTI_TENANCY.md no longer marks 1pass as not consulting auto_rotate")
open(p, "w", encoding="utf-8").write(s.replace(old, "| `1pass` | yes |", 1))
PY
OUT="$(cd "$WORK_T38A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the doc claims a backend consults auto_rotate that does not"
else
    no "coverage accepted a doc auto_rotate-consulted claim the live code contradicts"
    printf '%s\n' "$OUT"
fi
if grep -qF "docs/MULTI_TENANCY.md says 1pass is 'yes', but bin/sec's ensure_tenant_auth makes it 'no'" <<<"$OUT"; then
    ok "coverage names the drifted backend in the auto_rotate table"
else
    no "coverage did not name the drifted backend in the auto_rotate table"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T38B/bin/sec" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "        1pass|op)\n            if ! op whoami"
if s.count(old) != 1:
    sys.exit("bin/sec no longer starts the 1pass auth arm with the op whoami probe")
open(p, "w", encoding="utf-8").write(
    s.replace(old, '        1pass|op)\n            if [[ "$auto_rotate" == "true" ]]; then :; fi\n            if ! op whoami', 1)
)
PY
OUT="$(cd "$WORK_T38B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the live code starts consulting auto_rotate for a backend the doc excludes"
else
    no "coverage accepted a live auto_rotate-consulted set wider than the doc's"
    printf '%s\n' "$OUT"
fi
if grep -qF "but bin/sec's ensure_tenant_auth makes it 'yes'" <<<"$OUT"; then
    ok "coverage names the live auto_rotate-consulted widening"
else
    no "coverage did not name the live auto_rotate-consulted widening"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T38C/docs/MULTI_TENANCY.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "fallback, not an `auto_rotate = false` branch"
if s.count(old) != 1:
    sys.exit("docs/MULTI_TENANCY.md no longer carries the fallback-vs-auto_rotate=false sentence")
open(p, "w", encoding="utf-8").write(s.replace(old, "the auto_rotate = false branch", 1))
PY
OUT="$(cd "$WORK_T38C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the prompt-is-a-fallback sentence is lost"
else
    no "coverage accepted the loss of the prompt-is-a-fallback sentence"
    printf '%s\n' "$OUT"
fi
if grep -qF "no longer states that the interactive prompt is a fallback" <<<"$OUT"; then
    ok "coverage names the lost prompt-fallback anchor"
else
    no "coverage did not name the lost prompt-fallback anchor"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T38D/README.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "`bws`, `infisical`, and `keychain` carry no auth arm"
if s.count(old) != 1:
    sys.exit("README.md no longer enumerates the no-auth-arm backends in the guarded form")
open(p, "w", encoding="utf-8").write(s.replace(old, "`bws` and `infisical` carry no auth arm", 1))
PY
OUT="$(cd "$WORK_T38D" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the README auto_rotate bullet drops a live no-auth-arm backend"
else
    no "coverage accepted a README auto_rotate bullet missing a live no-auth-arm backend"
    printf '%s\n' "$OUT"
fi
if grep -qF "README.md's Smart Session Auto-Rotation bullet does not name the live backend \`keychain\`" <<<"$OUT"; then
    ok "coverage names the backend the README auto_rotate bullet dropped"
else
    no "coverage did not name the backend the README auto_rotate bullet dropped"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T38E/README.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = ", so `ensure_tenant_auth` performs no session handling for them."
if s.count(old) != 1:
    sys.exit("README.md no longer states the no-auth-arm backends get no session handling")
open(p, "w", encoding="utf-8").write(s.replace(old, ", and any locked tenant falls back to a prompt.", 1))
PY
OUT="$(cd "$WORK_T38E" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the README auto_rotate bullet re-introduces the 'any locked tenant' overclaim"
else
    no "coverage accepted the README auto_rotate bullet's 'any locked tenant' overclaim"
    printf '%s\n' "$OUT"
fi
if grep -qF "README.md's Smart Session Auto-Rotation bullet overclaims 'any locked tenant'" <<<"$OUT"; then
    ok "coverage names the README auto_rotate bullet's over-broad prompt claim"
else
    no "coverage did not name the README auto_rotate bullet's over-broad prompt claim"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T38CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (auto_rotate claims agree) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] auto_rotate claims:" <<<"$OUT"; then
    ok "the control copy's OK line names the auto_rotate check"
else
    no "the control copy's OK line did not name the auto_rotate check"
    printf '%s\n' "$OUT"
fi
echo
echo "[63] docs/SECURITY.md's plaintext-fallback contract must match bin/bw-session-keeper + bin/sec-migrator (issue #161)"
WORK_T39A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T39B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T39C="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T39CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for _w in "$WORK_T39A" "$WORK_T39B" "$WORK_T39C" "$WORK_T39CTRL"; do
    seed "$_w"
done
python3 - "$WORK_T39A/docs/SECURITY.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "the fallback file is mode-0600 at `~/.cache/bitwarden/master_pass`"
if s.count(old) != 1:
    sys.exit("docs/SECURITY.md no longer states the mode-0600 fallback path")
open(p, "w", encoding="utf-8").write(
    s.replace(old, "the fallback file is mode-0644 at `~/.cache/bitwarden/master_pass`", 1)
)
PY
OUT="$(cd "$WORK_T39A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the doc claims a looser fallback-file mode than the live chmod"
else
    no "coverage accepted a mode-0644 master-pass fallback claim the live chmod contradicts"
    printf '%s\n' "$OUT"
fi
if grep -qF "claims the fallback file is mode-0600, but bin/bw-session-keeper chmods it" <<<"$OUT"; then
    ok "coverage names the fallback-file mode drift"
else
    no "coverage did not name the fallback-file mode drift"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T39B/bin/bw-session-keeper" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = '        if [[ "${SEC_ALLOW_PLAINTEXT_MASTER_PASS:-0}" != "1" ]]; then\n            echo "[ERROR] No keychain backend (security/secret-tool); refusing to store the master password in a plaintext file. Install libsecret (secret-tool) or set SEC_ALLOW_PLAINTEXT_MASTER_PASS=1 to accept the mode-0600 file fallback." >&2\n            exit 1\n        fi\n'
if s.count(old) != 1:
    sys.exit("bin/bw-session-keeper no longer refuses the plaintext store without the opt-in")
open(p, "w", encoding="utf-8").write(s.replace(old, "", 1))
PY
OUT="$(cd "$WORK_T39B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the live store-side refusal is removed"
else
    no "coverage accepted live code that stores the master password in plaintext without the opt-in"
    printf '%s\n' "$OUT"
fi
if grep -qF "claims the keeper refuses to store a plaintext file without SEC_ALLOW_PLAINTEXT_MASTER_PASS" <<<"$OUT"; then
    ok "coverage names the missing store-side refusal"
else
    no "coverage did not name the missing store-side refusal"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T39C/docs/SECURITY.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "the transient `infisical` staging file, created 0600 and unlinked immediately after `secrets set`"
if s.count(old) != 1:
    sys.exit("docs/SECURITY.md no longer describes the infisical staging file")
open(p, "w", encoding="utf-8").write(
    s.replace(old, "the transient `infisical` staging file, created 0644 and unlinked at exit", 1)
)
PY
OUT="$(cd "$WORK_T39C" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the infisical staging-file claim drifts from bin/sec-migrator"
else
    no "coverage accepted an infisical staging-file claim the live code contradicts"
    printf '%s\n' "$OUT"
fi
if grep -qF "does not carry the guarded 'created 0600' mode for the infisical staging file" <<<"$OUT"; then
    ok "coverage names the drifted infisical staging-file mode"
else
    no "coverage did not name the drifted infisical staging-file mode"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T39CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (plaintext-fallback contract agrees) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] plaintext-fallback contract:" <<<"$OUT"; then
    ok "the control copy's OK line names the plaintext-fallback check"
else
    no "the control copy's OK line did not name the plaintext-fallback check"
    printf '%s\n' "$OUT"
fi
echo
echo "[64] docs/ARCHITECTURE.md's bin/hyer-mcp.sh component bullet must match the live launcher (issue #173)"
WORK_T40A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T40B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T40CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for _w in "$WORK_T40A" "$WORK_T40B" "$WORK_T40CTRL"; do
    seed "$_w"
done
python3 - "$WORK_T40A/docs/ARCHITECTURE.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "`~/sandbox/hyer`"
if s.count(old) != 1:
    sys.exit("docs/ARCHITECTURE.md no longer states the HYER_HOME default in the guarded form")
open(p, "w", encoding="utf-8").write(s.replace(old, "`~/elsewhere/hyer`", 1))
PY
OUT="$(cd "$WORK_T40A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the hyer-mcp bullet's HYER_HOME default drifts from the launcher"
else
    no "coverage accepted a hyer-mcp HYER_HOME default the live launcher contradicts"
    printf '%s\n' "$OUT"
fi
if grep -qF "does not name the live HYER_HOME default" <<<"$OUT"; then
    ok "coverage names the drifted HYER_HOME default in the hyer-mcp bullet"
else
    no "coverage did not name the drifted HYER_HOME default in the hyer-mcp bullet"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T40B/docs/ARCHITECTURE.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "`hyer-gitlab-pat`"
if s.count(old) != 1:
    sys.exit("docs/ARCHITECTURE.md no longer names the hyer-mcp secret in the guarded form")
open(p, "w", encoding="utf-8").write(s.replace(old, "`some-stale-token-name`", 1))
PY
OUT="$(cd "$WORK_T40B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the hyer-mcp bullet names a secret the launcher does not read"
else
    no "coverage accepted a hyer-mcp secret the live launcher does not read"
    printf '%s\n' "$OUT"
fi
if grep -qF "does not name the live secret" <<<"$OUT"; then
    ok "coverage names the drifted secret in the hyer-mcp bullet"
else
    no "coverage did not name the drifted secret in the hyer-mcp bullet"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T40CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (hyer-mcp bullet agrees with the launcher) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] hyer-mcp claims:" <<<"$OUT"; then
    ok "the control copy's OK line names the hyer-mcp check"
else
    no "the control copy's OK line did not name the hyer-mcp check"
    printf '%s\n' "$OUT"
fi
echo "[65] project-owned doc path citations must resolve on disk, and every history/ archive needs an Archive-index row (issue #181)"
WORK_T41A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T41B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T41CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for _w in "$WORK_T41A" "$WORK_T41B" "$WORK_T41CTRL"; do
    seed "$_w"
done
python3 - "$WORK_T41A/docs/ARCHITECTURE.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "`bin/sec-migrator`"
if s.count(old) != 1:
    sys.exit("docs/ARCHITECTURE.md no longer cites bin/sec-migrator in the guarded form")
open(p, "w", encoding="utf-8").write(s.replace(old, "`bin/sec-migrator-retired`", 1))
PY
OUT="$(cd "$WORK_T41A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when a project-owned doc cites a path that resolves to nothing"
else
    no "coverage accepted a project-owned doc citation of a path that resolves to nothing"
    printf '%s\n' "$OUT"
fi
if grep -qF 'docs/ARCHITECTURE.md cites `bin/sec-migrator-retired`' <<<"$OUT"; then
    ok "coverage names the unresolvable citation and the doc that made it"
else
    no "coverage did not name the unresolvable citation and the doc that made it"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T41B/HISTORY.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "- [2026-10-14](history/2026-10-14.md)\n"
if s.count(old) != 1:
    sys.exit("HISTORY.md no longer carries the 2026-10-14 Archive-index row in the guarded form")
out = s.replace(old, "", 1)
if "`history/2026-10-14.md`" not in out:
    sys.exit("HISTORY.md no longer mentions history/2026-10-14.md in backticks; the probe would stop testing the index-row distinction")
open(p, "w", encoding="utf-8").write(out)
PY
OUT="$(cd "$WORK_T41B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when an archive has only a backticked mention and no Archive-index row"
else
    no "coverage accepted an archive whose only HISTORY.md mention is a backticked narrative pointer"
    printf '%s\n' "$OUT"
fi
if grep -qF "2026-10-14.md" <<<"$OUT" && grep -qF "Archive index" <<<"$OUT"; then
    ok "coverage names the archive that lost its Archive-index row"
else
    no "coverage did not name the archive that lost its Archive-index row"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T41CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (every doc citation resolves, every archive indexed) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] doc path citations:" <<<"$OUT"; then
    ok "the control copy's OK line names the doc-path-citation check"
else
    no "the control copy's OK line did not name the doc-path-citation check"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] narrative history:" <<<"$OUT"; then
    ok "the control copy's OK line names the narrative-history check"
else
    no "the control copy's OK line did not name the narrative-history check"
    printf '%s\n' "$OUT"
fi
echo "[66] phantom backends must not reappear in ADAPTERS.md / the audit SKILL / profile.md (issue #182)"
WORK_T42A="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T42B="$(mktemp -d "$WORK_ROOT/XXXX")"
WORK_T42CTRL="$(mktemp -d "$WORK_ROOT/XXXX")"
for _w in "$WORK_T42A" "$WORK_T42B" "$WORK_T42CTRL"; do
    seed "$_w"
done
python3 - "$WORK_T42A/ADAPTERS.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "Infisical/Vault plus\n"
if s.count(old) != 1:
    sys.exit("ADAPTERS.md no longer states the multi-backend design in the guarded form")
open(p, "w", encoding="utf-8").write(s.replace(old, "Infisical/Vault/AWS Secrets Manager plus\n", 1))
PY
OUT="$(cd "$WORK_T42A" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when ADAPTERS.md's multi-backend design names a removed backend"
else
    no "coverage accepted an ADAPTERS.md multi-backend design naming a removed backend"
    printf '%s\n' "$OUT"
fi
if grep -qF "still names the removed backend 'AWS Secrets Manager'" <<<"$OUT"; then
    ok "coverage names the removed ADAPTERS.md backend"
else
    no "coverage did not name the removed ADAPTERS.md backend"
    printf '%s\n' "$OUT"
fi
python3 - "$WORK_T42B/skills/architecture-360-audit/SKILL.md" <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = "(GCP Secret Manager, GitLab group variables) versus the"
if s.count(old) != 1:
    sys.exit("SKILL.md no longer states the standing target-list example in the guarded form")
open(p, "w", encoding="utf-8").write(s.replace(old, "(GCP Secret Manager, GitLab group variables, Vercel projects) versus the", 1))
PY
OUT="$(cd "$WORK_T42B" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -ne 0 ]]; then
    ok "coverage exits nonzero when the audit SKILL's standing example names the removed Vercel target"
else
    no "coverage accepted an audit SKILL standing example naming the removed Vercel target"
    printf '%s\n' "$OUT"
fi
if grep -qF "still names the removed Vercel target" <<<"$OUT"; then
    ok "coverage names the removed Vercel target in the SKILL standing example"
else
    no "coverage did not name the removed Vercel target in the SKILL standing example"
    printf '%s\n' "$OUT"
fi
OUT="$(cd "$WORK_T42CTRL" && git init -q . && git add -A && "skills/architecture-360-audit/sentinel.sh" coverage 2>&1)"
RC=$?
if [[ $RC -eq 0 ]]; then
    ok "control copy (no phantom backends) exits 0"
else
    no "control copy exited $RC, expected 0"
    printf '%s\n' "$OUT"
fi
if grep -qE "\[ OK \] phantom backends:" <<<"$OUT"; then
    ok "the control copy's OK line names the phantom-backend check"
else
    no "the control copy's OK line did not name the phantom-backend check"
    printf '%s\n' "$OUT"
fi
echo
if [[ $fail -eq 0 ]]; then
    echo "ALL TESTS PASSED"
    exit 0
fi
echo "$fail test(s) failed"
exit 1
