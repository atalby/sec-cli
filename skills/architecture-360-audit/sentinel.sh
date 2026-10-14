#!/usr/bin/env bash
# Coverage and citation sentinel for the architecture-360-audit skill.
#
# Two subcommands, both of which FAIL (exit non-zero), never warn. Exactly
# two: coverage default, citations the companion.
#
#   coverage:
#     1. Every tracked file must be claimed by at least one coverage-manifest
#        row in profile.md. An untracked-but-tracked-intended file is invisible
#        here until staged; an unclaimed tracked file is unaudited surface.
#     2. Every live gitignored dependency surface must be claimed by a row in
#        profile.md's "Gitignored surfaces" section. A `git ls-files`
#        enumeration is structurally blind to these, so a sentinel that only
#        walks tracked files reports a clean tree while a whole installed
#        dependency surface sits unowned.
#
#     It also fails on a manifest row that matches nothing, because a renamed
#     or deleted file leaves a row that silently claims nothing. Exactly one
#     row is exempt from that check: docs/360/**, the forward declaration for
#     run artifacts that do not exist until the first audit run.
#
#   citations:
#     Re-verify every `file:line` (and `file:line,line` / `file:line-line`)
#     anchor that SKILL.md or profile.md cites. A citation that no longer
#     resolves -- file gone, or the line beyond the file's end -- is how a
#     persona with a stale anchor produces a confident wrong finding, so it
#     exits non-zero and names each one. It also content-checks each anchor
#     against the claim beside it -- a backticked symbol or a double-quoted
#     phrase -- so an anchor whose cited line dropped the claim's symbol
#     fails too (issues #34, #66).
#
# Usage:  ./sentinel.sh [coverage] [--list]   check tracked + gitignored
#                                              surface coverage (default)
#         ./sentinel.sh citations             re-verify every citation anchor
#
# Exit codes: 0 all accounted for; 1 unaudited surface / broken citation;
# 2 bad invocation.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="$SKILL_DIR/profile.md"
SKILL="$SKILL_DIR/SKILL.md"
REPO_ROOT="$(git -C "$SKILL_DIR" rev-parse --show-toplevel)"

TAG_OK="[ OK ]"
TAG_WARN="[WARN]"
TAG_ERROR="[ERROR]"

emit() { printf '%s %s\n' "$1" "$2"; }

usage() {
  printf 'usage: %s [coverage] [--list] | citations\n' "$0" >&2
  exit 2
}

SUBCMD="coverage"
LIST=0
for arg in "$@"; do
  case "$arg" in
    coverage) SUBCMD="coverage" ;;
    citations) SUBCMD="citations" ;;
    --list) LIST=1 ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
done

command -v python3 >/dev/null 2>&1 || {
  emit "$TAG_ERROR" "python3 is required by this sentinel and was not found on PATH"
  exit 1
}

[ -f "$PROFILE" ] || {
  emit "$TAG_ERROR" "profile.md not found beside this script: $PROFILE"
  exit 1
}

cd "$REPO_ROOT"

if [ "$SUBCMD" = "citations" ]; then
  exec python3 - "$SKILL" "$PROFILE" "$REPO_ROOT" <<'PY'
import os
import re
import subprocess
import sys

skill, profile, repo = sys.argv[1], sys.argv[2], sys.argv[3]
OK, ERROR = "[ OK ]", "[ERROR]"
EXTS = r"py|sh|md|json|yml|yaml|ps1|toml|example|gitignore"
EXTLESS = r"bin/sec|bin/bw-session-keeper|bin/sec-migrator|bin/sec-organizer|completions/_sec|LICENSE"
pattern = re.compile(
    r"((?:[A-Za-z0-9_./-]+\.(?:%s)|%s)):(\d+(?:[,-]\d+)*)" % (EXTS, EXTLESS)
)
backtick = re.compile(r"`([^`]+)`")
quote = re.compile(r'"([^"]+)"')
path_only = re.compile(
    r"^(?:[A-Za-z0-9_./-]+\.(?:%s)|%s|\.gitignore)$" % (EXTS, EXTLESS)
)
path_like = re.compile(r"^(?:~|\.{0,2})?/?(?:[A-Za-z0-9_.-]+/)+[A-Za-z0-9_.-]*/?$")
anchor_ish = re.compile(r"[A-Za-z0-9_./-]+:\d")
STOPWORDS = {
    "the", "and", "with", "for", "that", "this", "from", "issue", "path",
    "file", "line", "lines", "row", "claim", "claims", "verbatim", "still",
    "are", "was", "were", "not", "its", "into", "only", "real", "true",
    "false", "names", "name", "named", "exists", "exist", "missing",
    "test", "tests", "suite", "suites", "section", "top", "left", "right",
    "bin", "sec", "cli", "sh", "md", "py", "json", "yml", "yaml", "ps1",
    "toml", "example", "gitignore", "license", "install", "readme",
    "adapters", "skill", "profile", "docs", "architecture", "security",
    "operator", "manual", "registry", "history", "resume", "agents",
    "code", "any", "runs", "run", "via", "per", "out", "set",
}
broken = []

tracked = subprocess.run(
    ["git", "ls-files"], capture_output=True, text=True, check=True
).stdout.split("\n")
tracked = [f for f in tracked if f]
by_basename = {}
for f in tracked:
    by_basename.setdefault(os.path.basename(f), []).append(f)


def resolve(path):
    if path in tracked:
        return path
    hits = by_basename.get(os.path.basename(path), [])
    return hits[0] if len(hits) == 1 else None


def lines_in(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return sum(1 for _ in fh)


def cited_lines(spec):
    out = []
    for token in spec.split(","):
        fields = token.split("-", 1)
        if len(fields) == 2 and int(fields[1]) < int(fields[0]):
            continue
        out.append((int(fields[0]), int(fields[-1])))
    return out


def content_of(path):
    with open(os.path.join(repo, path), encoding="utf-8", errors="replace") as fh:
        return fh.read().split("\n")


def symbol_tokens(text):
    toks = []
    for t in re.split(r"[^A-Za-z0-9_$.()'\"-]+", text):
        tl = t.lower().strip("'\"()")
        if len(tl) < 2 or tl in STOPWORDS or not re.search(r"[A-Za-z]", tl):
            continue
        if re.fullmatch(r"\.[a-z]+", tl):
            continue
        toks.append(tl)
    return toks


IDENT = re.compile(r"^[A-Za-z][A-Za-z0-9_]*$")


def symbolish(span):
    if not IDENT.match(span):
        return False
    return "_" in span or re.search(r"[a-z][A-Z]", span)


claim_sources = {os.path.relpath(s, repo) for s in (skill, profile)}
contents = []
for f in tracked:
    if f in claim_sources:
        continue
    try:
        with open(f, encoding="utf-8", errors="replace") as fh:
            contents.append(fh.read())
    except OSError:
        continue


def phantom_claims(src_name, text):
    seen = {}
    for lineno, line in enumerate(text.split("\n"), 1):
        for m in backtick.finditer(line):
            span = m.group(1)
            if "://" in span:
                continue
            if path_only.match(span) or path_like.match(span):
                continue
            if anchor_ish.search(span):
                continue
            if not symbolish(span):
                continue
            seen.setdefault(span, lineno)
    hits = []
    for span, lineno in seen.items():
        if not any(span in c for c in contents):
            hits.append(
                "%s:%d claims `%s` -- no such identifier anywhere in the tree"
                % (src_name, lineno, span)
            )
    return hits


def stale_content_anchors(src_name, text):
    paragraphs = re.split(r"\n\s*\n", text)
    offset = 0
    hits = []
    for para in paragraphs:
        flat = para.replace("\n", " ")
        base = text.index(para, offset)
        offset = base + len(para)
        anchors = []
        for m in pattern.finditer(flat):
            if "://" in m.group(1) or m.group(1).startswith("/"):
                continue
            if os.path.basename(m.group(1)) in {"x.py", "y.py", "example.py"}:
                continue
            anchors.append(m)
        if not anchors:
            continue
        para_lines = para.split("\n")
        is_table = all(l.lstrip().startswith("|") for l in para_lines if l.strip())
        line_of = {}
        lineno = text.count("\n", 0, base) + 1
        for i, ch in enumerate(para):
            if ch == "\n":
                lineno += 1
            line_of[i] = lineno
        spans = []
        for finder in (backtick, quote):
            for m in finder.finditer(flat):
                if "://" in m.group(1):
                    continue
                if path_only.match(m.group(1)) or path_like.match(m.group(1)):
                    continue
                if anchor_ish.search(m.group(1)):
                    continue
                spans.append(m)
        for m in anchors:
            same_line = sum(
                1 for a in anchors if line_of[a.start()] == line_of[m.start()]
            )
            if same_line >= 3:
                continue
            near = []
            for s in spans:
                if is_table and line_of.get(s.start()) != line_of[m.start()]:
                    continue
                gap = (
                    0
                    if s.start() <= m.end() and m.start() <= s.end()
                    else max(s.start() - m.end(), m.start() - s.end())
                )
                if gap <= 45:
                    near.append(s.group(1))
            toks = []
            for span in near:
                toks.extend(symbol_tokens(span))
            if not toks:
                continue
            full = resolve(m.group(1))
            if full is None:
                continue
            content = content_of(full)
            hit = False
            for t in toks:
                pat = re.compile(r"(?<![A-Za-z0-9_])%s(?![A-Za-z0-9_])" % re.escape(t))
                for a, b in cited_lines(m.group(2)):
                    for n in range(a - 1, min(b, len(content))):
                        if pat.search(content[n].lower()):
                            hit = True
                            break
                    if hit:
                        break
                if hit:
                    break
            if not hit:
                hits.append(
                    "%s:%d cites %s:%s -- the cited line holds none of %s"
                    % (src_name, line_of[m.start()], m.group(1), m.group(2), toks)
                )
    return hits


def anchor_problems(src_name, lineno, path, spec):
    if "://" in path or path.startswith("/"):
        return
    if os.path.basename(path) in {"x.py", "y.py", "example.py"}:
        return
    full = resolve(path)
    if full is None:
        return [f"{src_name}:{lineno} cites {path}:{spec} -- no such tracked path"]
    total = lines_in(os.path.join(repo, full))
    hits = []
    for token in spec.split(","):
        fields = token.split("-", 1)
        if len(fields) == 2 and int(fields[1]) < int(fields[0]):
            hits.append(f"{src_name}:{lineno} cites {path}:{spec} -- reversed range")
            continue
        if int(fields[-1]) > total:
            hits.append(
                f"{src_name}:{lineno} cites {path}:{spec} -- "
                f"line {fields[-1]} beyond end of file ({total} lines)"
            )
    return hits


def anchor_sources():
    out = []
    for name in ("ADAPTERS.md", "RESUME.md", "HISTORY.md"):
        if name in tracked:
            out.append(name)
    docs = os.path.join(repo, "docs")
    for name in sorted(os.listdir(docs)) if os.path.isdir(docs) else []:
        if name.endswith(".md"):
            rel = os.path.relpath(os.path.join(docs, name), repo)
            if rel in tracked:
                out.append(rel)
    return out


for src in (skill, profile):
    with open(src, encoding="utf-8") as fh:
        text = fh.read()
    for lineno, line in enumerate(text.split("\n"), 1):
        for m in pattern.finditer(line):
            broken.extend(
                anchor_problems(os.path.basename(src), lineno, m.group(1), m.group(2))
            )
    for lineno, line in enumerate(text.split("\n"), 1):
        for m in re.finditer(r"\blines? \d+", line):
            broken.append(
                "%s:%d uses a bare '%s' reference -- cite a file:line anchor instead"
                % (os.path.basename(src), lineno, m.group(0))
            )
    broken.extend(stale_content_anchors(os.path.basename(src), text))
    broken.extend(phantom_claims(os.path.basename(src), text))

doc_anchor_count = 0
for src in anchor_sources():
    with open(os.path.join(repo, src), encoding="utf-8", errors="replace") as fh:
        doc_text = fh.read()
    for lineno, line in enumerate(doc_text.split("\n"), 1):
        for m in pattern.finditer(line):
            doc_anchor_count += 1
            broken.extend(anchor_problems(src, lineno, m.group(1), m.group(2)))

if broken:
    for b in broken:
        print(f"{ERROR} {b}")
    print(f"{ERROR} {len(broken)} citation problem(s): broken anchors, stale-content anchors, phantom claims")
    sys.exit(1)
print(
    f"{OK} citations: every file:line anchor in SKILL.md and profile.md resolves"
    f" ({doc_anchor_count} anchor(s) in the repo docs also resolve)"
)
sys.exit(0)
PY
fi

# Rows exempt from the stale-row check, because they legitimately match
# nothing until the audit they instrument has been run at least once.
ALLOW_EMPTY_ROWS="docs/360/**"

python3 - "$PROFILE" "$REPO_ROOT" "$ALLOW_EMPTY_ROWS" "$LIST" <<'PY'
import fnmatch
import os
import re
import subprocess
import sys

profile, repo, allow_empty, want_list = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"
OK, WARN, ERROR = "[ OK ]", "[WARN]", "[ERROR]"
failures = []


def rows_from(marker_prefix, stop_prefix=None):
    """Manifest rows are the first cell of a markdown table line whose first
    cell is a backticked glob. Section-scoped so the Personas table, which has
    no globs, cannot be mistaken for one."""
    out, inside = [], False
    with open(profile, encoding="utf-8") as fh:
        for line in fh:
            if line.startswith(marker_prefix):
                inside = True
                continue
            if inside and stop_prefix and line.startswith(stop_prefix):
                break
            if not inside:
                continue
            if line.startswith("| `") and line.count("|") >= 2:
                glob = line.split("|")[1].strip().strip("`")
                who = line.split("|")[2].strip()
                if glob and who:
                    out.append((glob, who))
    return out


tracked = subprocess.run(
    ["git", "ls-files"], capture_output=True, text=True, check=True
).stdout.split("\n")
tracked = [f for f in tracked if f]

cov_rows = rows_from("## Coverage manifest", "## Gitignored surfaces")
git_rows = rows_from("## Gitignored surfaces")

# --- 1. tracked-file coverage -------------------------------------------------
unclaimed = []
for f in tracked:
    if not any(fnmatch.fnmatch(f, g) for g, _ in cov_rows):
        unclaimed.append(f)

# --- 2. stale manifest rows ---------------------------------------------------
allow = set(allow_empty.split())
stale = [g for g, _ in cov_rows if g not in allow and not any(fnmatch.fnmatch(f, g) for f in tracked)]

# --- 3. gitignored dependency surfaces ----------------------------------------
# Existence is decided on disk, not from .gitignore text: a surface that is
# installed and NOT ignored is the more dangerous case, so both are reported.
SENTINEL_DIR = os.path.join(repo, "skills", "architecture-360-audit")

SURFACES = [
    (".agents/", ".agents", "persona 4"),
    ("__pycache__/", "__pycache__", "persona 3"),
    (".cache/", ".cache", "persona 7"),
    (".ruff_cache/", ".ruff_cache", "persona 3"),
    (".pytest_cache/", ".pytest_cache", "persona 3"),
    (".claude/", ".claude", "persona 4"),
    (".opencode/", ".opencode", "persona 4"),
    ("graphify-out/", "graphify-out", "persona 8"),
    ("graft/", "graft", "persona 8"),
]

MANIFEST_NAMES = [
    "package.json", "package-lock.json", "go.mod", "go.sum",
    "Cargo.toml", "Cargo.lock", "pom.xml", "build.gradle", "Gemfile",
    "composer.json", "pyproject.toml", "requirements.txt", "mix.exs",
    "Makefile", "uv.lock", "Pipfile",
]
# No manifest ecosystem exists in this repository and that absence is itself
# the persona 8 finding, so the sentinel reports the census rather than
# failing on it. Any manifest that DOES appear on disk is an ecosystem this
# profile never bound and must fail until profile.md claims it.
HARD_REQUIRED_IF_PRESENT = set(MANIFEST_NAMES)

present_surfaces, unclaimed_surfaces, new_ecosystems = [], [], []
for label, dirname, owner in SURFACES:
    hits = []
    for root, dirs, _files in os.walk(repo):
        if ".git" in dirs:
            dirs.remove(".git")
        if SENTINEL_DIR in root or root.startswith(SENTINEL_DIR):
            continue
        if dirname in dirs:
            hits.append(os.path.relpath(os.path.join(root, dirname), repo))
            dirs.remove(dirname)
    if not hits:
        continue
    present_surfaces.append((label, owner, len(hits)))
    if not any(fnmatch.fnmatch(label + "/", g) or fnmatch.fnmatch(label, g) or label in g for g, _ in git_rows):
        unclaimed_surfaces.append((label, owner, hits[:5]))

found_manifests = []
for root, dirs, files in os.walk(repo):
    if ".git" in dirs:
        dirs.remove(".git")
    if root.startswith(SENTINEL_DIR):
        continue
    dirs[:] = [d for d in dirs if d not in {"node_modules", ".terraform", ".terragrunt-cache", "__pycache__"}]
    for name in files:
        if name in MANIFEST_NAMES:
            found_manifests.append(os.path.relpath(os.path.join(root, name), repo))

unclaimed_manifests = [m for m in found_manifests if not any(fnmatch.fnmatch(m, g) for g, _ in git_rows)]
for m in found_manifests:
    base = os.path.basename(m)
    if base in HARD_REQUIRED_IF_PRESENT and not any(fnmatch.fnmatch(m, g) for g, _ in git_rows):
        new_ecosystems.append(m)

# --- 4. personas must all be reachable ----------------------------------------
used = set()
for _g, who in cov_rows:
    for tok in who.replace(",", " ").split():
        if tok.isdigit():
            used.add(int(tok))
missing_personas = [i for i in range(1, 13) if i not in used]

# --- 5. prose denominator must match the live tracked-file count --------------
profile_text = open(profile, encoding="utf-8").read()
denom_match = re.search(r"Denominator:\s*\*\*(\d+)\s+tracked files\*\*", profile_text)
denominator = int(denom_match.group(1)) if denom_match else None
# The same quantity is quoted in the "Commands (executed)" transcript as the
# output of `git ls-files | wc -l`; guard that twin too (issue #134), since a
# drifted transcript is invisible to the prose-denominator check alone.
transcript_match = re.search(r"git ls-files \| wc -l\n\s*(\d+)", profile_text)
transcript_count = int(transcript_match.group(1)) if transcript_match else None

# --- 6. narrative history must stay rotated (AGENTS.md §5) --------------------
# HISTORY.md is force-loaded by every session, so it must hold only a short
# current-state summary; the full narrative lives in per-period archives under
# history/. Fail if a dated entry has crept back in, if the summary bloats past
# budget, or if an archive file is orphaned (not linked from HISTORY.md).
HISTORY_BUDGET = 8192
history_path = os.path.join(repo, "HISTORY.md")
history_text = open(history_path, encoding="utf-8").read() if os.path.exists(history_path) else ""
dated_entries = [ln for ln in history_text.splitlines() if ln.startswith("### ")]
history_bytes = len(history_text.encode("utf-8"))
history_dir = os.path.join(repo, "history")
archived = sorted(f for f in os.listdir(history_dir) if f.endswith(".md")) if os.path.isdir(history_dir) else []
orphaned = [f for f in archived if f"history/{f}" not in history_text]

# --- 7. cited suite section counts must match the live suites -----------------
suite_counts = {}
for _s in ("install", "sync_guard", "write_honesty", "sentinel", "dispatch"):
    _p = os.path.join(repo, "tests", f"test_{_s}.sh")
    if os.path.exists(_p):
        with open(_p, encoding="utf-8") as _fh:
            suite_counts[_s] = sum(1 for _ln in _fh if _ln.startswith('echo "['))
suite_mismatches = []
for _s, _live in suite_counts.items():
    if profile_text.find(f"test_{_s}.sh") < 0:
        suite_mismatches.append(f"profile.md does not cite tests/test_{_s}.sh")
        continue
    _cited = re.findall(rf"test_{_s}\.sh[^\n]*?\((\d+)\s+(?:sections|cases)\b", profile_text)
    if not _cited:
        suite_mismatches.append(f"profile.md cites no '(N sections|cases)' count for tests/test_{_s}.sh")
        continue
    for _num in dict.fromkeys(_cited):
        if int(_num) != _live:
            suite_mismatches.append(f"profile.md says {_num} for tests/test_{_s}.sh, live suites have {_live}")


# --- 8. cited census counts must match the live tree (the #49 drift class) -----
def _glob_count(*globs):
    return sum(1 for f in tracked if any(fnmatch.fnmatch(f, g) for g in globs))


census_mismatches = []


def _check_census(label, pattern, live):
    _cm = re.search(pattern, profile_text)
    if not _cm:
        census_mismatches.append(f"profile.md carries no {label} census line")
    elif int(_cm.group(1)) != live:
        census_mismatches.append(f"profile.md's {label} census says {_cm.group(1)}, live tree has {live}")


_check_census("ecosystem markdown-file", r"Markdown \((\d+)\s+files?\)", _glob_count("*.md"))
_check_census("ecosystem python-file", r"Python 3 \((\d+)\s+files?[,:)]", _glob_count("*.py"))
_check_census("ecosystem config-file", r"JSON/YAML/TOML\s+configuration \((\d+)\s+files?\)",
              _glob_count("*.json", "*.yaml", "*.yml", "*.toml"))

_tag_claim = re.search(
    r"(\d+) of the (\d+) tracked `bin/` entries emit tagged\s+output \((.*?)\)",
    profile_text,
    re.S,
)
_tag_bins = [f for f in tracked if f.startswith("bin/") and f.count("/") == 1]
if not _tag_claim:
    census_mismatches.append("profile.md carries no [ TAG ]-emission census line")
else:
    _claim_nonzero, _claim_total, _claim_body = (
        int(_tag_claim.group(1)), int(_tag_claim.group(2)), _tag_claim.group(3)
    )
    _live_nonzero = 0
    for _path in _tag_bins:
        with open(_path, encoding="utf-8", errors="replace") as _fh:
            _n = sum(1 for _ln in _fh if re.search(r"\[ ?(OK|INFO|WARN|ERROR) ?\]", _ln))
        if not _n:
            continue
        _live_nonzero += 1
        _m = re.search(r"`%s` (\d+)" % re.escape(os.path.basename(_path)), _claim_body)
        if not _m:
            census_mismatches.append(f"profile.md's [ TAG ] census names no count for {_path}")
        elif int(_m.group(1)) != _n:
            census_mismatches.append(
                f"profile.md's [ TAG ] census says {_path} {_m.group(1)}, live has {_n}"
            )
    if _claim_total != len(_tag_bins):
        census_mismatches.append(
            f"profile.md's [ TAG ] census says {_claim_total} tracked bin/ entries, live tree has {len(_tag_bins)}"
        )
    if _claim_nonzero != _live_nonzero:
        census_mismatches.append(
            f"profile.md's [ TAG ] census says {_claim_nonzero} emit tagged, live tree has {_live_nonzero}"
        )


# --- 9. ADAPTERS.md's mirrored suite counts must match the live suites --------
adapters_mismatches = []
try:
    with open(os.path.join(repo, "ADAPTERS.md"), encoding="utf-8") as _fh:
        _adapters_text = _fh.read()
except OSError:
    _adapters_text = ""
_cs_scope = re.search(r"current suites:([^;]*)", _adapters_text)
if not _cs_scope:
    adapters_mismatches.append("ADAPTERS.md carries no 'current suites:' snapshot line")
else:
    for _label, _key in (
        ("dispatch", "dispatch"),
        ("write-honesty", "write_honesty"),
        ("sentinel", "sentinel"),
        ("sync-guard", "sync_guard"),
        ("install", "install"),
    ):
        _am = re.search(r"%s\s+(\d+)" % re.escape(_label), _cs_scope.group(1))
        _live = suite_counts.get(_key)
        if not _am:
            adapters_mismatches.append(f"ADAPTERS.md 'current suites' names no count for {_label}")
        elif _live is not None and int(_am.group(1)) != _live:
            adapters_mismatches.append(
                f"ADAPTERS.md says {_label} {_am.group(1)}, live suite has {_live}"
            )
# The Test-suites bullets carry the same counts a second time (issue #87).
if _adapters_text:
    for _s, _live in suite_counts.items():
        _counts = re.findall(
            r"test_%s\.sh`?\s*\((\d+)\s+(?:sections|cases)\b" % re.escape(_s),
            _adapters_text,
        )
        if not _counts:
            adapters_mismatches.append(
                f"ADAPTERS.md cites no '(N sections|cases)' count for tests/test_{_s}.sh"
            )
            continue
        for _c in _counts:
            if int(_c) != _live:
                adapters_mismatches.append(
                    f"ADAPTERS.md says {_c} for tests/test_{_s}.sh, live suite has {_live}"
                )


# --- 10. profile.md's cited pack taxonomy must match PACK.md (issue #86) ------
pack_mismatches = []
_NUM_WORDS = {
    "zero": 0,
    "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6,
    "seven": 7, "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12,
    "thirteen": 13, "fourteen": 14, "fifteen": 15, "sixteen": 16,
    "seventeen": 17, "eighteen": 18, "nineteen": 19, "twenty": 20,
    "twenty-one": 21, "twenty-two": 22, "twenty-three": 23,
    "twenty-four": 24, "twenty-five": 25, "twenty-six": 26,
    "twenty-seven": 27, "twenty-eight": 28, "twenty-nine": 29,
    "thirty": 30, "thirty-two": 32, "thirty-three": 33, "thirty-four": 34,
    "thirty-five": 35, "thirty-six": 36, "thirty-seven": 37, "thirty-eight": 38,
    "thirty-nine": 39, "forty": 40, "forty-one": 41, "forty-two": 42,
    "forty-three": 43, "forty-four": 44, "forty-five": 45,
    "forty-six": 46, "forty-seven": 47,
}
try:
    with open(os.path.join(repo, "packs", "solo-founder-governance", "PACK.md"), encoding="utf-8") as _fh:
        _pack_text = _fh.read()
except OSError:
    _pack_text = ""
if not _pack_text:
    pack_mismatches.append("packs/solo-founder-governance/PACK.md not found")
else:
    _pv = re.search(r"Pack version:\s*(v\d+\.\d+\.\d+)", _pack_text)
    _pack_version = _pv.group(1) if _pv else None
    _pack_roles = sum(1 for _ln in _pack_text.splitlines() if re.match(r"\d+\. \*\*`Persona", _ln))
    _cited_version = re.search(r"`packs/solo-founder-governance`\s*(v\d+\.\d+\.\d+)", profile_text)
    _cited_roles = re.search(r"It defines\s+(\w+)\s+roles", profile_text)
    if not _cited_version:
        pack_mismatches.append("profile.md cites no packs/solo-founder-governance version")
    elif _pack_version and _cited_version.group(1) != _pack_version:
        pack_mismatches.append(
            f"profile.md cites pack {_cited_version.group(1)}, PACK.md declares {_pack_version}"
        )
    if not _cited_roles:
        pack_mismatches.append("profile.md states no pack role count")
    elif _NUM_WORDS.get(_cited_roles.group(1)) != _pack_roles:
        pack_mismatches.append(
            f"profile.md says the pack defines {_cited_roles.group(1)} roles, PACK.md enumerates {_pack_roles}"
        )

# ADAPTERS.md's Opted-in Policy Packs section carries its own copy of the
# same census (issue #129): one `packs/<name> (vX.Y.Z)` citation per opted-in
# pack plus the solo-founder persona-taxonomy total. Each must match the
# live packs/<name>/PACK.md; a pack bump that updates profile.md but not
# ADAPTERS.md previously drifted unseen.
if _adapters_text:
    _cited_packs = set()
    for _pkg_m in re.finditer(r"`(packs/[a-z0-9-]+) \((v\d+\.\d+\.\d+)\)`", _adapters_text):
        _pkg_name, _pkg_cited = _pkg_m.group(1), _pkg_m.group(2)
        _cited_packs.add(_pkg_name)
        try:
            with open(os.path.join(repo, _pkg_name, "PACK.md"), encoding="utf-8") as _pf:
                _pkg_live = _pf.read()
        except OSError:
            pack_mismatches.append(f"ADAPTERS.md cites {_pkg_name} but no PACK.md exists beside it")
            continue
        _pkg_live_v = re.search(r"Pack version:\s*(v\d+\.\d+\.\d+)", _pkg_live)
        if not _pkg_live_v:
            pack_mismatches.append(f"packs/{_pkg_name}/PACK.md declares no 'Pack version:'")
        elif _pkg_live_v.group(1) != _pkg_cited:
            pack_mismatches.append(
                f"ADAPTERS.md cites {_pkg_name} {_pkg_cited}, PACK.md declares {_pkg_live_v.group(1)}"
            )
    for _pd in sorted(os.listdir(os.path.join(repo, "packs"))):
        if _pd.startswith(".") or not os.path.isfile(os.path.join(repo, "packs", _pd, "PACK.md")):
            continue
        if f"packs/{_pd}" not in _cited_packs:
            pack_mismatches.append(f"packs/{_pd}/PACK.md exists but ADAPTERS.md does not cite it")
    _pers_m = re.search(r"(\d+)-persona taxonomy total", _adapters_text)
    if not _pers_m:
        pack_mismatches.append("ADAPTERS.md states no solo-founder persona-taxonomy count")
    elif _pack_text:
        _live_personas = len(re.findall(r"(?m)^### \d+\. ", _pack_text))
        if int(_pers_m.group(1)) != _live_personas:
            pack_mismatches.append(
                f"ADAPTERS.md says {_pers_m.group(1)}-persona taxonomy total, PACK.md enumerates {_live_personas}"
            )

# --- 11. docs/ARCHITECTURE.md's producer census must match the live emitters (#88) ---
producers_mismatches = []
_live_producers = []
for _f in tracked:
    if _f.startswith("bin/") and _f.count("/") == 1:
        try:
            with open(os.path.join(repo, _f), encoding="utf-8", errors="replace") as _bfh:
                _btext = _bfh.read()
        except OSError:
            continue
        if re.search(r"\[ ?(OK|INFO|WARN|ERROR) ?\]", _btext):
            _live_producers.append(os.path.basename(_f))
_live_producers.sort()
try:
    with open(os.path.join(repo, "docs", "ARCHITECTURE.md"), encoding="utf-8") as _fh:
        _arch_text = _fh.read()
except OSError:
    _arch_text = ""
if not _arch_text:
    producers_mismatches.append("docs/ARCHITECTURE.md not found")
else:
    _prod = re.search(r"All (\w+) producers \(([^)]*)\)", _arch_text)
    if not _prod:
        producers_mismatches.append("docs/ARCHITECTURE.md carries no 'All N producers (...)' sentence")
    else:
        _cited_count = _NUM_WORDS.get(_prod.group(1))
        _cited_set = sorted(
            {t.strip().strip("`").split("/")[-1] for t in _prod.group(2).split(",") if t.strip()}
        )
        if _cited_count != len(_live_producers):
            producers_mismatches.append(
                f"ARCHITECTURE.md says {_prod.group(1)} producers, live tree has {len(_live_producers)}"
            )
        if _cited_set != _live_producers:
            producers_mismatches.append(
                f"ARCHITECTURE.md lists producers {_cited_set}, live emitters are {_live_producers}"
            )

# --- 12. ADAPTERS.md's skills registry census must match skills/ + REGISTRY.md (#89) --
registry_mismatches = []
_skill_root = os.path.join(repo, "skills")
_live_skill_dirs = set()
if os.path.isdir(_skill_root):
    for _d in os.listdir(_skill_root):
        _dp = os.path.join(_skill_root, _d)
        if os.path.isdir(_dp) and os.path.exists(os.path.join(_dp, "SKILL.md")):
            _live_skill_dirs.add(_d)
_live_skill_count = len(_live_skill_dirs)

try:
    with open(os.path.join(_skill_root, "REGISTRY.md"), encoding="utf-8") as _fh:
        _reg_text = _fh.read()
except OSError:
    _reg_text = ""
_registry_rows = []
for _ln in _reg_text.splitlines():
    if not _ln.startswith("|"):
        continue
    _cells = [c.strip() for c in _ln.strip().strip("|").split("|")]
    if len(_cells) < 4:
        continue
    if _cells[0] == "Skill" or (_cells[0] and set(_cells[0]) == {"-"}):
        continue
    _registry_rows.append(_cells)

_row_dirs = {}
_dist_counts = {}
for _c in _registry_rows:
    _dm = re.match(r"`skills/([^/]+)/SKILL\.md`", _c[1])
    if _dm:
        _row_dirs[_dm.group(1)] = _c[0]
    _dist_counts[_c[3]] = _dist_counts.get(_c[3], 0) + 1

_live_rows = len(_registry_rows)
_live_hub = _dist_counts.get("hub-internal", 0)
_live_local = _dist_counts.get("adopter", 0) + _dist_counts.get("project-specific", 0)

for _d in sorted(_row_dirs):
    if _d not in _live_skill_dirs:
        registry_mismatches.append(
            f"REGISTRY.md lists a skills/ row for a skill dir that does not exist: {_d}"
        )
for _d in sorted(_live_skill_dirs):
    if _d not in _row_dirs:
        registry_mismatches.append(f"live skill dir skills/{_d} has no skills/ row in REGISTRY.md")

if not _registry_rows:
    registry_mismatches.append("skills/REGISTRY.md holds no parseable skill rows")
else:
    _sk_sec = re.search(r"^##\s+Skills registry\s*$(.*?)^##\s", _adapters_text, re.S | re.M)
    if not _sk_sec:
        registry_mismatches.append("ADAPTERS.md carries no '## Skills registry' section")
    else:
        _sk_text = _sk_sec.group(1)

        def _check_registry(label, pattern, live):
            _rm = re.search(pattern, _sk_text)
            if not _rm:
                registry_mismatches.append(f"ADAPTERS.md's skills registry census states no {label}")
            elif int(_rm.group(1)) != live:
                registry_mismatches.append(
                    f"ADAPTERS.md's skills registry census says {_rm.group(1)} {label}, live tree has {live}"
                )

        _check_registry("skill dirs", r"(\d+) skill dirs under `skills/`", _live_skill_count)
        _adopt_m = re.search(r"(\d+) adopter-distributable", _sk_text)
        _own_m = re.search(r"plus (\d+) project-specific", _sk_text)
        if not _adopt_m or not _own_m:
            registry_mismatches.append(
                "ADAPTERS.md's skills registry census states no adopter-distributable/"
                "project-specific split"
            )
        elif int(_adopt_m.group(1)) + int(_own_m.group(1)) != _live_local:
            registry_mismatches.append(
                f"ADAPTERS.md's skills registry census says {int(_adopt_m.group(1))} adopter-distributable "
                f"plus {int(_own_m.group(1))} project-specific, live registry has {_live_local}"
            )
        _check_registry("hub-internal rows", r"plus (\d+)\s+`?\.hyer/skills/`?\s+hub-internal rows", _live_hub)
        _check_registry("skill rows", r"(\d+) skill rows", _live_rows)

# --- 13. profile.md + ADAPTERS.md's bin/ helper census must match the live tree (#90) --
bin_helper_mismatches = []
_bin_helpers = sorted(
    f for f in tracked if f.startswith("bin/") and f.count("/") == 1 and f != "bin/sec"
)
_live_bin_helpers = len(_bin_helpers)

_dispatch_suite_path = os.path.join(repo, "tests", "test_dispatch.sh")
try:
    with open(_dispatch_suite_path, encoding="utf-8") as _fh:
        _dispatch_text = _fh.read()
except OSError:
    _dispatch_text = ""
if not _dispatch_text:
    bin_helper_mismatches.append("tests/test_dispatch.sh is missing or empty")
else:
    _referenced = set(
        re.findall(r"(?:REPO_ROOT/)?bin/([A-Za-z0-9._-]+)", _dispatch_text)
    )
    for _h in _bin_helpers:
        if os.path.basename(_h) not in _referenced:
            bin_helper_mismatches.append(
                f"tracked bin/ helper {_h} is not referenced by tests/test_dispatch.sh"
            )
    _live_dispatch_helpers = sum(
        1 for _h in _bin_helpers if os.path.basename(_h) in _referenced
    )
    _ad_helper_m = re.search(
        r"plus the (\w+) sibling `bin/` helpers the suite references", _adapters_text
    )
    if not _ad_helper_m:
        bin_helper_mismatches.append(
            "ADAPTERS.md states no dispatch-suite helper census for tests/test_dispatch.sh"
        )
    elif _NUM_WORDS.get(_ad_helper_m.group(1)) != _live_dispatch_helpers:
        bin_helper_mismatches.append(
            f"ADAPTERS.md says {_ad_helper_m.group(1)} helper scripts, "
            f"live tree has {_live_dispatch_helpers}"
        )

_prof_bin_m = re.search(r"`bin/sec` and (\w+) sibling dispatchers", profile_text)
if not _prof_bin_m:
    bin_helper_mismatches.append(
        "profile.md carries no 'bin/sec and N sibling dispatchers' census line"
    )
elif _NUM_WORDS.get(_prof_bin_m.group(1)) != _live_bin_helpers:
    bin_helper_mismatches.append(
        f"profile.md's bin/ sibling-dispatcher census says {_NUM_WORDS.get(_prof_bin_m.group(1))}, "
        f"live tree has {_live_bin_helpers}"
    )

_prof_exec_m = re.search(r"(\w+) sibling executables, (\w+) Python controller", profile_text)
if not _prof_exec_m:
    bin_helper_mismatches.append(
        "profile.md carries no 'N sibling executables, N Python controller' component decomposition"
    )
else:
    _live_controllers = [
        _h for _h in _bin_helpers if os.path.basename(_h).endswith("-controller.py")
    ]
    _live_execs = [
        _h for _h in _bin_helpers
        if not os.path.basename(_h).endswith("-controller.py")
        and "mcp" not in os.path.basename(_h)
    ]
    if _NUM_WORDS.get(_prof_exec_m.group(1)) != len(_live_execs):
        bin_helper_mismatches.append(
            f"profile.md's component decomposition says {_prof_exec_m.group(1)} sibling "
            f"executables, live tree has {len(_live_execs)} non-controller non-MCP bin/ helpers"
        )
    if _NUM_WORDS.get(_prof_exec_m.group(2)) != len(_live_controllers):
        bin_helper_mismatches.append(
            f"profile.md's component decomposition says {_prof_exec_m.group(2)} Python "
            f"controller(s), live tree has {len(_live_controllers)}"
        )

# --- 14. profile.md + ARCHITECTURE.md + SKILL.md's bash suite census must match the live tree (#91/#95) --
suite_census_mismatches = []
_live_suites = sorted(f for f in tracked if f.startswith("tests/") and f.endswith(".sh"))
_live_suite_count = len(_live_suites)

_prof_suite_m = re.search(r"(\w+) suites under `tests/`", profile_text)
if not _prof_suite_m:
    suite_census_mismatches.append("profile.md carries no 'N suites under tests/' census")
elif _NUM_WORDS.get(_prof_suite_m.group(1)) != _live_suite_count:
    suite_census_mismatches.append(
        f"profile.md's tests/ suite census says {_NUM_WORDS.get(_prof_suite_m.group(1))}, "
        f"live tree has {_live_suite_count}"
    )

_prof_ci_m = re.search(r"runs all (\w+) suites", profile_text)
if not _prof_ci_m:
    suite_census_mismatches.append("profile.md's CI row states no suite count")
elif _NUM_WORDS.get(_prof_ci_m.group(1)) != _live_suite_count:
    suite_census_mismatches.append(
        f"profile.md's CI row says it runs all {_prof_ci_m.group(1)} suites, "
        f"live tree has {_live_suite_count}"
    )

_norm_prof = re.sub(r"\s+", " ", profile_text)
for _sm in re.finditer(r"\b(\w+) (?:green |bash )?suites?\b", _norm_prof):
    _sw = _sm.group(1)
    if _sw in _NUM_WORDS and _NUM_WORDS[_sw] != _live_suite_count:
        suite_census_mismatches.append(
            f"profile.md says '{_sw} ... suite(s)', live tree has {_live_suite_count} bash suites"
        )

if not _arch_text:
    suite_census_mismatches.append("docs/ARCHITECTURE.md not found")
else:
    _arch_suite_m = re.search(r"(\w+) zero-dependency bash suites", _arch_text)
    if not _arch_suite_m:
        suite_census_mismatches.append("docs/ARCHITECTURE.md carries no bash suite census")
    elif _NUM_WORDS.get(_arch_suite_m.group(1)) != _live_suite_count:
        suite_census_mismatches.append(
            f"ARCHITECTURE.md says {_arch_suite_m.group(1)} zero-dependency bash suites, "
            f"live tree has {_live_suite_count}"
        )
    _cited_suites = set(re.findall(r"`(test_[A-Za-z0-9._-]+\.sh)`", _arch_text))
    _live_suite_names = {os.path.basename(s) for s in _live_suites}
    _orphan_cited = sorted(_cited_suites - _live_suite_names)
    _uncited_live = sorted(_live_suite_names - _cited_suites)
    if _orphan_cited or _uncited_live:
        suite_census_mismatches.append(
            "ARCHITECTURE.md lists suites that are not the live tracked suites: "
            f"cited-but-absent {_orphan_cited or 'none'}, present-but-uncited {_uncited_live or 'none'}"
        )

try:
    with open(os.path.join(os.path.dirname(profile), "SKILL.md"), encoding="utf-8") as _fh:
        _skill_text = _fh.read()
except OSError:
    _skill_text = ""
if not _skill_text:
    suite_census_mismatches.append("skills/architecture-360-audit/SKILL.md not found")
else:
    _skill_scanners_m = re.search(r"the (\w+) `tests/\*\.sh` suites", _skill_text)
    if not _skill_scanners_m:
        suite_census_mismatches.append("SKILL.md carries no 'the N `tests/*.sh` suites' scanner claim")
    elif _NUM_WORDS.get(_skill_scanners_m.group(1)) != _live_suite_count:
        suite_census_mismatches.append(
            f"SKILL.md says the {_skill_scanners_m.group(1)} `tests/*.sh` suites, "
            f"live tree has {_live_suite_count}"
        )
    _skill_gate_m = re.search(r"executes all (\w+) bash suites", _skill_text)
    if not _skill_gate_m:
        suite_census_mismatches.append("SKILL.md carries no 'executes all N bash suites' claim")
    elif _NUM_WORDS.get(_skill_gate_m.group(1)) != _live_suite_count:
        suite_census_mismatches.append(
            f"SKILL.md says the gate executes all {_skill_gate_m.group(1)} bash suites, "
            f"live tree has {_live_suite_count}"
        )

# --- 15. structural prose claims (tenant aliases, CI checkout pin, principle count) must match (#94) --
struct_mismatches = []

try:
    with open(os.path.join(repo, "docs", "MULTI_TENANCY.md"), encoding="utf-8") as _fh:
        _multi_text = _fh.read()
except OSError:
    _multi_text = ""
try:
    with open(os.path.join(repo, "docs", "OPERATOR_MANUAL.md"), encoding="utf-8") as _fh:
        _op_text = _fh.read()
except OSError:
    _op_text = ""
try:
    with open(os.path.join(repo, "bin", "sec"), encoding="utf-8") as _fh:
        _sec_text = _fh.read()
except OSError:
    _sec_text = ""
try:
    with open(os.path.join(repo, ".github", "workflows", "test.yml"), encoding="utf-8") as _fh:
        _wf_text = _fh.read()
except OSError:
    _wf_text = ""

_live_aliases = None
_sec_alias_m = None
_alias_gates = []
for _alias_cand in re.finditer(r"=~\s*\^\(([a-z0-9|]+)\)\$", _sec_text):
    _alias_start = _sec_text.rfind("\n", 0, _alias_cand.start()) + 1
    _alias_stop = _sec_text.find("\n", _alias_cand.end())
    _alias_line = _sec_text[_alias_start:(len(_sec_text) if _alias_stop < 0 else _alias_stop)].strip()
    if _alias_line.startswith('if [[ $# -ge 2 ]] && [[ "$1" =~ ^('):
        _alias_gates.append(_alias_cand)
if _alias_gates:
    _sec_alias_m = _alias_gates[0]
    _live_aliases = set(_sec_alias_m.group(1).split("|"))
    if len(_alias_gates) > 1:
        struct_mismatches.append(
            f"bin/sec carries {len(_alias_gates)} dispatcher alias gates, expected exactly 1"
        )
_multi_m = re.search(r"the (\w+) fixed aliases \(([^)]+)\)", _multi_text)
if not _multi_m:
    struct_mismatches.append("docs/MULTI_TENANCY.md carries no 'N fixed aliases (...)' claim")
elif _live_aliases is None:
    struct_mismatches.append("bin/sec carries no tenant-alias regex to compare MULTI_TENANCY.md against")
else:
    _cited_aliases = {
        _a.strip()
        for _grp in _multi_m.group(2).split(",")
        for _a in _grp.split("/")
        if _a.strip()
    }
    if _NUM_WORDS.get(_multi_m.group(1)) != len(_live_aliases):
        struct_mismatches.append(
            f"MULTI_TENANCY.md says {_multi_m.group(1)} fixed aliases, live bin/sec has {len(_live_aliases)}"
        )
    if _cited_aliases != _live_aliases:
        struct_mismatches.append(
            "MULTI_TENANCY.md's alias list is not the live bin/sec alias set: "
            f"cited-only {sorted(_cited_aliases - _live_aliases) or 'none'}, "
            f"live-only {sorted(_live_aliases - _cited_aliases) or 'none'}"
        )

_wf_m = re.search(r"actions/checkout@([0-9a-f]{7,40})(?:\s*#\s*(\S+))?", _wf_text)
_prof_pin_m = re.search(r"actions/checkout`?\s*pinned to the full commit SHA of (v\d+\.\d+\.\d+)", profile_text)
if not _prof_pin_m:
    struct_mismatches.append("profile.md carries no 'actions/checkout pinned to the full commit SHA of vX' claim")
elif not _wf_m:
    struct_mismatches.append("workflow does not pin actions/checkout, contradicting profile.md")
else:
    _wf_sha, _wf_ver = _wf_m.group(1), _wf_m.group(2)
    if len(_wf_sha) != 40:
        struct_mismatches.append(
            f"workflow pins actions/checkout to '{_wf_sha}', not a full 40-char commit SHA as profile.md claims"
        )
    if _wf_ver != _prof_pin_m.group(1):
        struct_mismatches.append(
            f"profile.md cites actions/checkout version {_prof_pin_m.group(1)}, workflow pins {_wf_ver or 'untagged'}"
        )

_op_m = re.search(r"designed around (\w+) core principles", _op_text)
_live_principles = len(re.findall(r"^\d+\. \*\*", _op_text, re.M))
if not _op_m:
    struct_mismatches.append("docs/OPERATOR_MANUAL.md carries no 'N core principles' claim")
elif _NUM_WORDS.get(_op_m.group(1)) != _live_principles:
        struct_mismatches.append(
            f"OPERATOR_MANUAL.md says {_op_m.group(1)} core principles, live doc lists {_live_principles}"
        )

# --- 16. SKILL.md's own structural counts (steps, personas, scopes, severity set) must match (#96) --
skill_struct_mismatches = []

_norm_skill = re.sub(r"\s+", " ", _skill_text)
_skill_step_count = len(re.findall(r"(?m)^## Step ", _skill_text))
for _word in re.findall(r"\b(\w+) steps\b", _norm_skill):
    if _word in _NUM_WORDS and _NUM_WORDS[_word] != _skill_step_count:
        skill_struct_mismatches.append(
            f"SKILL.md says '{_word} steps', live SKILL.md has {_skill_step_count} '## Step' headings"
        )

_live_personas = len(re.findall(r"(?m)^### \d+\. ", profile_text))
for _word in re.findall(r"\b(\w+) personas\b", _norm_skill):
    if _word in _NUM_WORDS and _NUM_WORDS[_word] != _live_personas:
        skill_struct_mismatches.append(
            f"SKILL.md says '{_word} personas', profile.md declares {_live_personas}"
        )
_prof_num = re.search(r"(\w+), numbered 1 through (\d+),", profile_text)
if not _prof_num:
    skill_struct_mismatches.append("profile.md carries no 'Twelve, numbered 1 through 12' claim")
elif _NUM_WORDS.get(_prof_num.group(1).lower()) != _live_personas or int(_prof_num.group(2)) != _live_personas:
    skill_struct_mismatches.append(
        f"profile.md says personas are '{_prof_num.group(1)}, numbered 1 through {_prof_num.group(2)}', "
        f"live persona-heading count is {_live_personas}"
    )

_dim_m = re.search(r"\b(\w+) fixed dimensions\b", re.sub(r"\s+", " ", profile_text))
if not _dim_m:
    skill_struct_mismatches.append("profile.md carries no 'N fixed dimensions' claim")
elif _NUM_WORDS.get(_dim_m.group(1)) != _live_personas:
    skill_struct_mismatches.append(
        f"profile.md says '{_dim_m.group(1)} fixed dimensions', live persona-heading count is {_live_personas}"
    )

_skill_scope_m = re.search(r"Offer exactly (\w+) scopes", _norm_skill)
_live_scopes = len(re.findall(r"(?m)^- \*\*[A-Za-z]+ sweep", _skill_text))
if not _skill_scope_m:
    skill_struct_mismatches.append("SKILL.md carries no 'Offer exactly N scopes' claim")
elif _NUM_WORDS.get(_skill_scope_m.group(1)) != _live_scopes:
    skill_struct_mismatches.append(
        f"SKILL.md says 'Offer exactly {_skill_scope_m.group(1)} scopes', live Step 1 offers {_live_scopes}"
    )

_skill_sev_m = re.search(r"one of (\w+) values only: `([^`]+)`, `([^`]+)`, `([^`]+)`", _norm_skill)
_sev_set = {"blocking", "important", "nit"}
if not _skill_sev_m:
    skill_struct_mismatches.append("SKILL.md carries no 'one of N values only: ...' severity claim")
else:
    _sev_cited = {_skill_sev_m.group(2), _skill_sev_m.group(3), _skill_sev_m.group(4)}
    if _NUM_WORDS.get(_skill_sev_m.group(1)) != len(_sev_cited):
        skill_struct_mismatches.append(
            f"SKILL.md says 'one of {_skill_sev_m.group(1)} values only', but names {len(_sev_cited)}"
        )
    if _sev_cited != _sev_set:
        skill_struct_mismatches.append(
            f"SKILL.md's severity set is {sorted(_sev_cited)}, canonical is {sorted(_sev_set)}"
        )

forge_mismatches = []
_forge_path = os.path.join(repo, "skills", "360-audit-skill-forge", "SKILL.md")
try:
    with open(_forge_path, encoding="utf-8") as _fh:
        _forge_text = _fh.read()
except OSError:
    _forge_text = ""
if not _forge_text:
    forge_mismatches.append("skills/360-audit-skill-forge/SKILL.md not found")
else:
    _norm_forge = re.sub(r"\s+", " ", _forge_text)
    _live_top_headings = len(re.findall(r"(?m)^#{1,2} ", _skill_text))
    _forge_shape = re.search(r"(\w+) steps, (\w+) headings counting the title", _norm_forge)
    if not _forge_shape:
        forge_mismatches.append(
            "360-audit-skill-forge carries no 'N steps, N headings counting the title' shape claim"
        )
    else:
        if _forge_shape.group(1).lower() in _NUM_WORDS and _NUM_WORDS[_forge_shape.group(1).lower()] != _skill_step_count:
            forge_mismatches.append(
                f"360-audit-skill-forge says '{_forge_shape.group(1)} steps', live SKILL.md has {_skill_step_count} '## Step' headings"
            )
        if _forge_shape.group(2).lower() in _NUM_WORDS and _NUM_WORDS[_forge_shape.group(2).lower()] != _live_top_headings:
            forge_mismatches.append(
                f"360-audit-skill-forge says '{_forge_shape.group(2)} headings counting the title', live SKILL.md has {_live_top_headings} top-level headings"
            )
    for _fw in re.findall(r"\b(\w+) (?:bound audit dimensions|personas|dimensions)\b", _norm_forge):
        if _fw.lower() in _NUM_WORDS and _NUM_WORDS[_fw.lower()] != _live_personas:
            forge_mismatches.append(
                f"360-audit-skill-forge says '{_fw} personas/dimensions', profile.md declares {_live_personas}"
            )
    for _fw in re.findall(r"\b(\w+) values only\b", _norm_forge):
        if _fw.lower() in _NUM_WORDS and _NUM_WORDS[_fw.lower()] != len(_sev_set):
            forge_mismatches.append(
                f"360-audit-skill-forge says '{_fw} severity values only', canonical set has {len(_sev_set)}"
            )
    for _fw in re.findall(r"Offer exactly (\w+) scopes", _norm_forge):
        if _fw.lower() in _NUM_WORDS and _NUM_WORDS[_fw.lower()] != _live_scopes:
            forge_mismatches.append(
                f"360-audit-skill-forge says 'Offer exactly {_fw} scopes', live Step 1 offers {_live_scopes}"
            )


# --- 17. profile.md's §3 count-words + the pytest mirror's collected count must match (#97) --
count_claim_mismatches = []

# profile.md:640-641 — "Nine install sections, sixteen guard sections,
# thirteen write-honesty sections, and the audit instrument's own ten
# sentinel cases pass today". Section 7 guards profile.md:22's counts; this
# is the unguarded second site.
_sec3 = re.search(
    r"([\w-]+) install sections, ([\w-]+) guard sections, ([\w-]+) write-honesty"
    r"\s+sections, and the audit instrument's own ([\w-]+) sentinel cases",
    profile_text,
    re.S,
)
if not _sec3:
    count_claim_mismatches.append(
        "profile.md carries no 'N install sections, N guard sections, "
        "N write-honesty sections, N sentinel cases' sentence"
    )
else:
    for _word, _key in (
        (_sec3.group(1), "install"),
        (_sec3.group(2), "sync_guard"),
        (_sec3.group(3), "write_honesty"),
        (_sec3.group(4), "sentinel"),
    ):
        _live = suite_counts.get(_key)
        if _live is None:
            count_claim_mismatches.append(
                f"profile.md §3 cites tests/test_{_key}.sh but no such suite exists"
            )
        elif _NUM_WORDS.get(_word.lower()) != _live:
            count_claim_mismatches.append(
                f"profile.md §3 says '{_word}' for tests/test_{_key}.sh, live suite has {_live}"
            )

# The pytest mirror's collected count, cited as "29 passed" in ADAPTERS.md
# and SKILL.md. Live count comes from pytest --collect-only.
try:
    import pytest  # noqa: F401
    _pytest_available = True
except ImportError:
    _pytest_available = False

if _pytest_available:
    _collect = subprocess.run(
        [sys.executable, "-m", "pytest", "scripts/tests/", "--collect-only", "-q",
         "-c", os.devnull, "--confcutdir", "scripts/tests"],
        cwd=repo, capture_output=True, text=True,
        env={**os.environ, "PYTEST_DISABLE_PLUGIN_AUTOLOAD": "1"},
    )
    _collected = sum(1 for _ln in _collect.stdout.splitlines() if "::" in _ln)
    for _label, _pattern, _text in (
        ("ADAPTERS.md", r"pytest scripts/tests/ -q` is now (\d+) passed", _adapters_text),
        ("SKILL.md", r"all five bash suites \((\d+) passed", _skill_text),
    ):
        _found = re.findall(_pattern, _text)
        if not _found:
            count_claim_mismatches.append(f"{_label} carries no pytest 'N passed' claim")
        else:
            for _v in dict.fromkeys(_found):
                if int(_v) != _collected:
                    count_claim_mismatches.append(
                        f"{_label} says pytest mirror is {_v} passed, live collection counts {_collected}"
                    )
    # HISTORY.md's current-state summary cites the pytest mirror count too
    # ("the pytest mirror (N tests) passes") -- a fourth unguarded mirror
    # (#116). history_text is read for section 6 above.
    _hm = re.findall(r"pytest mirror \((\d+)\s+tests\)", history_text)
    if not _hm:
        count_claim_mismatches.append("HISTORY.md carries no pytest 'N tests' claim")
    else:
        for _v in dict.fromkeys(_hm):
            if int(_v) != _collected:
                count_claim_mismatches.append(
                    f"HISTORY.md says pytest mirror is {_v} tests, live collection counts {_collected}"
                )

# RESUME.md is itself a hand-bumped count mirror (its 'suite counts ... mirrors
# in sync' line + the 'Sentinel = N cases / M assertions' total) with no guard.
try:
    with open(os.path.join(repo, "RESUME.md"), encoding="utf-8") as _fh:
        _resume_text = _fh.read()
except OSError:
    _resume_text = ""

_resume_counts_m = re.search(
    r"mirrors in sync\): ([a-z_]+) (\d+), ([a-z_]+) (\d+), ([a-z_]+) (\d+),"
    r" ([a-z_]+) (\d+),\s*\n([a-z_]+) (\d+)\.",
    _resume_text,
)
if not _resume_counts_m:
    count_claim_mismatches.append("RESUME.md carries no 'suite counts ... mirrors in sync' line")
else:
    _rg = _resume_counts_m.groups()
    for _i in range(0, len(_rg), 2):
        _key, _num = _rg[_i], int(_rg[_i + 1])
        _live = suite_counts.get(_key)
        if _live is None:
            count_claim_mismatches.append(
                f"RESUME.md cites suite '{_key}' but no tests/test_{_key}.sh exists"
            )
        elif _live != _num:
            count_claim_mismatches.append(
                f"RESUME.md says {_key} {_num}, live suite has {_live}"
            )

_resume_assert_m = re.search(r"Sentinel = (\d+) cases / (\d+) assertions", _resume_text)
if not _resume_assert_m:
    count_claim_mismatches.append("RESUME.md carries no 'Sentinel = N cases / M assertions' line")
else:
    _rcases, _rasserts = int(_resume_assert_m.group(1)), int(_resume_assert_m.group(2))
    _live_cases = suite_counts.get("sentinel")
    try:
        with open(os.path.join(repo, "tests", "test_sentinel.sh"), encoding="utf-8") as _fh:
            _tsent_text = _fh.read()
    except OSError:
        _tsent_text = ""
    _live_asserts = sum(
        1 for _ln in _tsent_text.splitlines() if re.match(r"\s*(ok|no) ", _ln)
    )
    if _live_cases is not None and _rcases != _live_cases:
        count_claim_mismatches.append(
            f"RESUME.md says Sentinel = {_rcases} cases, live suite has {_live_cases}"
        )
    if _rasserts != _live_asserts:
        count_claim_mismatches.append(
            f"RESUME.md says Sentinel = {_rasserts} assertions, live suite has {_live_asserts}"
        )

_resume_baseline_m = re.search(
    r"(?m)^## Verified baseline.*?\n([\s\S]*?)\n## ", _resume_text
)
if not _resume_baseline_m:
    count_claim_mismatches.append("RESUME.md carries no '## Verified baseline' section")
else:
    _rbytes_m = re.search(r"(\d+)/(\d+) bytes", _resume_baseline_m.group(1))
    if not _rbytes_m:
        count_claim_mismatches.append(
            "RESUME.md's Verified baseline states no 'N/8192 bytes' HISTORY.md size"
        )
    else:
        _rsize, _rbudget = int(_rbytes_m.group(1)), int(_rbytes_m.group(2))
        if _rsize != history_bytes:
            count_claim_mismatches.append(
                f"RESUME.md says HISTORY.md is {_rsize} bytes, live file is {history_bytes}"
            )
        if _rbudget != HISTORY_BUDGET:
            count_claim_mismatches.append(
                f"RESUME.md states a {_rbudget}-byte HISTORY.md budget, the guard's is {HISTORY_BUDGET}"
            )

_resume_struct_all = re.findall(
    r"(\d+) tracked files, (\d+) personas, (\d+) bash suites", _resume_text
)
if not _resume_struct_all:
    count_claim_mismatches.append(
        "RESUME.md carries no 'N tracked files, N personas, N bash suites' line"
    )
else:
    for _triple in dict.fromkeys(_resume_struct_all):
        _rt, _rp, _rs = (int(_v) for _v in _triple)
        if _rt != len(tracked):
            count_claim_mismatches.append(
                f"RESUME.md says {_rt} tracked files, live tree has {len(tracked)}"
            )
        if _rp != _live_personas:
            count_claim_mismatches.append(
                f"RESUME.md says {_rp} personas, profile.md declares {_live_personas}"
            )
        if _rs != _live_suite_count:
            count_claim_mismatches.append(
                f"RESUME.md says {_rs} bash suites, live tree has {_live_suite_count}"
            )

# --- 18. README.md's quoted `sec --help` + default sec.conf blocks + migrate backend list
#         must match the live CLI (issue #107) ---------------------------------
readme_mismatches = []
try:
    with open(os.path.join(repo, "README.md"), encoding="utf-8") as _fh:
        _readme_text = _fh.read()
except OSError:
    _readme_text = ""

try:
    _live_help = subprocess.run(
        ["bash", os.path.join(repo, "bin", "sec"), "--help"],
        capture_output=True, text=True, check=True,
    ).stdout.rstrip("\n")
except Exception as _exc:
    _live_help = None
    readme_mismatches.append(f"could not run 'bin/sec --help' to compare README.md against: {_exc}")

_readme_fence_m = re.search(r"```text\n(sec-cli v[^\n]*\n[\s\S]*?)\n```", _readme_text)
if _readme_fence_m is None:
    readme_mismatches.append("README.md carries no fenced ```text sec-cli help block")
elif _live_help is not None and _readme_fence_m.group(1) != _live_help:
    readme_mismatches.append(
        "README.md's quoted `sec --help` block is not byte-identical to live 'bin/sec --help' output"
    )

_sec_conf_m = re.search(r'cat <<EOF > "\$CONFIG_FILE"\n([\s\S]*?)\nEOF', _sec_text)
if _sec_conf_m is None:
    readme_mismatches.append("bin/sec carries no 'cat <<EOF > $CONFIG_FILE' default-config heredoc")

_CONF_DOC_SURFACES = ("README.md", "docs/MULTI_TENANCY.md", "sec.conf.example")


def _conf_sample_body(rel_path, raw):
    if raw is None:
        return None
    if rel_path == "sec.conf.example":
        return raw.rstrip("\n")
    fences = re.findall(r"```ini\n([\s\S]*?)\n```", raw)
    if not fences:
        return None
    if len(fences) > 1:
        readme_mismatches.append(
            f"{rel_path} carries {len(fences)} fenced ```ini blocks, so which one is the "
            "sec.conf sample is ambiguous; keep exactly one"
        )
    return fences[0]


if _sec_conf_m is not None:
    _conf_canonical = _sec_conf_m.group(1)
    for _rel in _CONF_DOC_SURFACES:
        try:
            with open(os.path.join(repo, _rel), encoding="utf-8") as _fh:
                _conf_raw = _fh.read()
        except OSError as _exc:
            _conf_raw = None
            readme_mismatches.append(f"could not read the {_rel} sec.conf sample surface: {_exc}")
        _conf_body = _conf_sample_body(_rel, _conf_raw)
        if _conf_body is None:
            if _conf_raw is not None:
                readme_mismatches.append(f"{_rel} carries no fenced ```ini sec.conf sample")
            continue
        if _conf_body != _conf_canonical:
            readme_mismatches.append(
                f"{_rel}'s sec.conf sample is not byte-identical to bin/sec's ensure_config "
                "heredoc (the only text bin/sec ever writes); keep explanatory prose outside "
                "the fence"
            )

    _sample_keys = sorted(set(re.findall(r"^\s*([a-z_]+)\s*=", _conf_canonical, re.M)))
    _cfg_reads = re.findall(r"get_cfg_val\s+(?:\"[^\"]*\"|\$\w+)\s+\"([a-z_]+)\"", _sec_text)
    _unread_sample_keys = [_k for _k in _sample_keys if _k not in _cfg_reads]
    if _unread_sample_keys:
        readme_mismatches.append(
            "README.md's sec.conf sample key(s) are read by no code in bin/sec (the sole config owner): "
            + ", ".join(_unread_sample_keys)
        )

try:
    with open(os.path.join(repo, "bin", "sec-migrator"), encoding="utf-8") as _fh:
        _mig_text = _fh.read()
except OSError:
    _mig_text = ""
_ALIAS = {
    "bitwarden": "bitwarden", "bw": "bitwarden", "bws": "bws",
    "1password": "1password", "1pass": "1password", "op": "1password",
    "infisical": "infisical", "vault": "vault",
}
_mig_dst_blocks = [
    _mig_dst_cand
    for _mig_dst_cand in re.finditer(r'case "\$DST" in\n\s*([a-z0-9|]+)\)([\s\S]*?)esac', _mig_text)
    if "[ERROR] Destination backend" in _mig_dst_cand.group(2)
]
_mig_dst_m = _mig_dst_blocks[0] if _mig_dst_blocks else None
if len(_mig_dst_blocks) > 1:
    readme_mismatches.append(
        f"bin/sec-migrator carries {len(_mig_dst_blocks)} destination allow-list blocks, expected exactly 1"
    )
_readme_mig_m = re.search(r"^- .*`sec migrate`.*$", _readme_text, re.M)
if _mig_dst_m is None:
    readme_mismatches.append("bin/sec-migrator carries no 'case \"$DST\" in' backend allow-list")
elif _readme_mig_m is None:
    readme_mismatches.append("README.md carries no 'sec migrate' feature bullet")
else:
    _live_dst = {_ALIAS[_t] for _t in _mig_dst_m.group(1).split("|") if _t in _ALIAS}
    _missing = sorted(_b for _b in _live_dst if _b not in _readme_mig_m.group(0).lower())
    if _missing:
        readme_mismatches.append(
            "README.md's 'sec migrate' bullet omits live destination backend(s): "
            + ", ".join(_missing)
        )

# --- 19. sec migrate's source vs destination backend sets must agree across
#         the migrator allow-lists, all four shells, and OPERATOR_MANUAL (issue #108) --
migrate_mismatches = []


def _mig_canon(_s):
    return {_ALIAS[_t] for _t in re.findall(r"[a-z0-9]+", _s.lower()) if _t in _ALIAS}


_mig_src_blocks = [
    _c
    for _c in re.finditer(
        r'fetch_source_items\(\) \{\n\s*case "\$SRC" in\n([\s\S]*?)\n\s*\*\)', _mig_text
    )
]
_mig_src_block_m = _mig_src_blocks[0] if _mig_src_blocks else None
if len(_mig_src_blocks) > 1:
    migrate_mismatches.append(
        "bin/sec-migrator carries %d fetch_source_items() source blocks, expected exactly 1"
        % len(_mig_src_blocks)
    )
_mig_src_set = None
if _mig_src_block_m is None:
    migrate_mismatches.append("bin/sec-migrator carries no fetch_source_items() source case block")
else:
    _mig_src_set = set()
    for _ln in _mig_src_block_m.group(1).splitlines():
        _am = re.match(r"\s*([a-z0-9|]+)\)", _ln)
        if _am:
            _mig_src_set |= _mig_canon(_am.group(1))

_mig_dst_set = None
if _mig_dst_m is None:
    migrate_mismatches.append("bin/sec-migrator carries no destination ('case \"$DST\" in') allow-list")
else:
    _mig_dst_set = _mig_canon(_mig_dst_m.group(1))

if _mig_src_set is not None and _mig_dst_set is not None:
    _mig_surfaces = [
        ("bin/sec zsh --from", re.search(r"--from\[[^\]]*\]:backend:\(([^)]*)\)", _sec_text), "src"),
        ("bin/sec zsh --to", re.search(r"--to\[[^\]]*\]:backend:\(([^)]*)\)", _sec_text), "dst"),
        ("bin/sec fish --from", re.search(r"contains --from \(commandline -opc\)' -a '([^']*)'", _sec_text), "src"),
        ("bin/sec fish --to", re.search(r"contains --to \(commandline -opc\)' -a '([^']*)'", _sec_text), "dst"),
        ("bin/sec bash --from", re.search(r'_mb="([^"]*)"; \[\[ \$\{prev\} == "--to" \]\] && _mb="([^"]*)"', _sec_text), "bash"),
        ("bin/sec ps1", re.search(r"\$migrateWords = @\(([^)]*)\);.*?\+= @\(([^)]*)\)", _sec_text), "ps1"),
        ("OPERATOR_MANUAL.md --from", re.search(r"- `--from <src>`:[^\n]*?\(([^)]*)\)", _op_text), "src"),
        ("OPERATOR_MANUAL.md --to", re.search(r"- `--to <dst>`:[^\n]*?\(([^)]*)\)", _op_text), "dst"),
        ("bin/sec-migrator usage --from", re.search(r"source \(--from\):[^\"]*", _mig_text), "src"),
        ("bin/sec-migrator usage --to", re.search(r"target \(--to\):[^\"]*", _mig_text), "dst"),
    ]
    for _name, _m, _kind in _mig_surfaces:
        if _m is None:
            migrate_mismatches.append(f"{_name} surface not found to compare against the migrator allow-lists")
            continue
        if _kind == "src":
            _got = _mig_canon(_m.group(1) if _m.groups() else _m.group(0))
            if _got != _mig_src_set:
                migrate_mismatches.append(
                    f"{_name} lists {sorted(_got)}, migrator source allow-list is {sorted(_mig_src_set)}"
                )
        elif _kind == "dst":
            _got = _mig_canon(_m.group(1) if _m.groups() else _m.group(0))
            if _got != _mig_dst_set:
                migrate_mismatches.append(
                    f"{_name} lists {sorted(_got)}, migrator destination allow-list is {sorted(_mig_dst_set)}"
                )
        elif _kind == "bash":
            _s, _d = _mig_canon(_m.group(1)), _mig_canon(_m.group(2))
            if _s != _mig_src_set:
                migrate_mismatches.append(
                    f"{_name} lists {sorted(_s)}, migrator source allow-list is {sorted(_mig_src_set)}"
                )
            if _d != _mig_dst_set:
                migrate_mismatches.append(
                    f"{_name} lists {sorted(_d)}, migrator destination allow-list is {sorted(_mig_dst_set)}"
                )
        elif _kind == "ps1":
            _s, _add = _mig_canon(_m.group(1)), _mig_canon(_m.group(2))
            if _s != _mig_src_set:
                migrate_mismatches.append(
                    f"{_name} source list is {sorted(_s)}, migrator source allow-list is {sorted(_mig_src_set)}"
                )
            if _s | _add != _mig_dst_set:
                migrate_mismatches.append(
                    f"{_name} destination list is {sorted(_s | _add)}, migrator destination allow-list is {sorted(_mig_dst_set)}"
                )

# --- 18b. README.md's front-page backend universe + sync targets must match the
#         live migrator allow-lists and the sync controller's `Targets:` header
#         (issue #122) ----------------------------------------------------------
_readme_front_m = re.search(r"unifies secret management across[^\n]+", _readme_text)
if _readme_front_m is None:
    readme_mismatches.append("README.md carries no 'unifies secret management across' front sentence")
else:
    _front_lower = _readme_front_m.group(0).lower()
    if _mig_src_set is None or _mig_dst_set is None:
        readme_mismatches.append(
            "bin/sec-migrator backend allow-lists unavailable to compare README.md's front universe against"
        )
    else:
        _universe = _mig_src_set | _mig_dst_set
        _claimed = {_ALIAS[_t] for _t in re.findall(r"[a-z0-9]+", _front_lower) if _t in _ALIAS}
        _missing = sorted(_universe - _claimed)
        if _missing:
            readme_mismatches.append(
                "README.md's front sentence omits live backend(s): " + ", ".join(_missing)
            )
    try:
        with open(os.path.join(repo, "bin", "sec-sync-controller.py"), encoding="utf-8") as _fh:
            _ctrl_text = _fh.read()
    except OSError:
        _ctrl_text = ""
    _targets_m = re.search(r"^Targets: (.+)$", _ctrl_text, re.M)
    if _targets_m is None:
        readme_mismatches.append("bin/sec-sync-controller.py carries no 'Targets:' header")
    else:
        for _tgt in _targets_m.group(1).split(","):
            _tgt = _tgt.strip().lower()
            if _tgt and _tgt not in _front_lower:
                readme_mismatches.append(
                    "README.md's front sentence omits live sync target: %s" % _tgt
                )

# --- 20. OPERATOR_MANUAL.md's documented `-v/--version` output must match the
#         live `sec version` (issue #114) --------------------------------
version_mismatches = []
try:
    _live_version = subprocess.run(
        ["bash", os.path.join(repo, "bin", "sec"), "version"],
        capture_output=True, text=True, check=True,
    ).stdout.strip()
except Exception as _exc:
    _live_version = None
    version_mismatches.append(
        f"could not run 'bin/sec version' to compare OPERATOR_MANUAL.md against: {_exc}"
    )

_op_version_m = re.search(
    r"\| `-v` \| `--version` \| Displays `sec-cli` version information \(`([^`]*)`\)",
    _op_text,
)
if _op_version_m is None:
    version_mismatches.append(
        "OPERATOR_MANUAL.md carries no `-v`/`--version` 'Displays ...' row"
    )
elif _live_version is not None and _op_version_m.group(1) != _live_version:
    version_mismatches.append(
        f"OPERATOR_MANUAL.md documents `--version` as '{_op_version_m.group(1)}', "
        f"live 'bin/sec version' prints '{_live_version}'"
    )

# --- 21. bin/sec's hardcoded `Configured Tenants:` help line must match the
#         live dispatcher alias regex (issue #127) --------------------------
tenant_line_mismatches = []
_help_tenants_m = re.search(r'^\s*echo "Configured Tenants: ([^"]+)"', _sec_text, re.M)
if _help_tenants_m is None:
    tenant_line_mismatches.append(
        "bin/sec carries no `echo \"Configured Tenants: ...\"` help line"
    )
elif _live_aliases is None:
    tenant_line_mismatches.append(
        "bin/sec carries no tenant-alias regex to compare the help line against"
    )
else:
    _cited_aliases = set()
    for _entry in _help_tenants_m.group(1).split(","):
        _names = re.findall(r"[a-z0-9]+", _entry)
        if not _names:
            continue
        _cited_aliases.add(_names[0])
        _cited_aliases.update(_names[1:])
    if _cited_aliases != _live_aliases:
        tenant_line_mismatches.append(
            "bin/sec's `Configured Tenants:` help line is not the live dispatcher alias set: "
            f"help-only {sorted(_cited_aliases - _live_aliases) or 'none'}, "
            f"routable-only {sorted(_live_aliases - _cited_aliases) or 'none'}"
        )

# --- 22. profile.md's persona-11 timeout counts + persona-1 SYNC_KEYS census
#         must match the live controller / install.sh / bin/sec (#130/#131/#132) --
code_census_mismatches = []
try:
    with open(os.path.join(repo, "bin", "sec-sync-controller.py"), encoding="utf-8") as _fh:
        _ctrl_src = _fh.read()
except OSError:
    _ctrl_src = ""
try:
    with open(os.path.join(repo, "install.sh"), encoding="utf-8") as _fh:
        _install_src = _fh.read()
except OSError:
    _install_src = ""

# persona 1: "SYNC_KEYS ... names the six env keys (verified ...: A, B, ...)"
_sync_block_m = re.search(r"SYNC_KEYS = \[(.*?)\]", _ctrl_src, re.S)
_sync_cited_m = re.search(
    r"([\w-]+) env keys \(verified \d{4}-\d{2}-\d{2}: ([^)]+)\)", profile_text
)
if not _sync_block_m:
    code_census_mismatches.append("bin/sec-sync-controller.py carries no SYNC_KEYS list")
elif not _sync_cited_m:
    code_census_mismatches.append("profile.md states no 'N env keys (verified ...: ...)' SYNC_KEYS claim")
else:
    _sync_live = re.findall(r'"([A-Z0-9_]+)"', _sync_block_m.group(1))
    _sync_cited = [n.strip() for n in _sync_cited_m.group(2).split(",") if n.strip()]
    if _NUM_WORDS.get(_sync_cited_m.group(1)) != len(_sync_live):
        code_census_mismatches.append(
            f"profile.md says SYNC_KEYS names {_sync_cited_m.group(1)} env keys, "
            f"live list has {len(_sync_live)}"
        )
    if _sync_cited != _sync_live:
        code_census_mismatches.append(
            "profile.md's SYNC_KEYS list is not the live controller's: cited-only "
            f"{sorted(set(_sync_cited) - set(_sync_live)) or 'none'}, live-only "
            f"{sorted(set(_sync_live) - set(_sync_cited)) or 'none'}"
        )

# persona 11: "bin/sec-sync-controller.py has **N timeout sites**"
_prof_timeout_m = re.search(r"has \*\*(\d+) timeout sites\*\*", profile_text)
if not _prof_timeout_m:
    code_census_mismatches.append("profile.md states no 'N timeout sites' claim for the sync controller")
else:
    _live_timeouts = len(re.findall(r"timeout=", _ctrl_src))
    if int(_prof_timeout_m.group(1)) != _live_timeouts:
        code_census_mismatches.append(
            f"profile.md says the sync controller has {_prof_timeout_m.group(1)} timeout sites, "
            f"live code has {_live_timeouts} 'timeout=' occurrence(s)"
        )

# persona 11: "install.sh and bin/sec still have **zero** timeout occurrences"
_prof_zero_m = re.search(r"still have \*\*(\w+)\*\* timeout occurrences", profile_text)
if not _prof_zero_m:
    code_census_mismatches.append(
        "profile.md states no 'still have N timeout occurrences' claim for install.sh/bin/sec"
    )
else:
    _timeout_re = re.compile(r"timeout|--max-time|--connect-timeout", re.I)
    for _label, _src in (("install.sh", _install_src), ("bin/sec", _sec_text)):
        _live_zero = len(_timeout_re.findall(_src))
        if _NUM_WORDS.get(_prof_zero_m.group(1)) != _live_zero:
            code_census_mismatches.append(
                f"profile.md says {_label} has {_prof_zero_m.group(1)} timeout occurrences, "
                f"live file has {_live_zero}"
            )

hiae_mismatches = []
_HIAE_BANNER_RE = re.compile(
    r"HIAE Protocol(?:\s+Version)?[:,\*\s]*v?(\d+\.\d+(?:\.\d+)?)", re.IGNORECASE
)
try:
    with open(os.path.join(repo, "AGENTS.md"), encoding="utf-8") as _fh:
        _agents_text = _fh.read()
except OSError:
    _agents_text = ""
try:
    with open(os.path.join(repo, "docs", "ARCHITECTURE.md"), encoding="utf-8") as _fh:
        _hiae_arch_text = _fh.read()
except OSError:
    _hiae_arch_text = ""
_agents_hiae = _HIAE_BANNER_RE.search(re.sub(r"\s+", " ", _agents_text))
_arch_hiae = _HIAE_BANNER_RE.search(re.sub(r"\s+", " ", _hiae_arch_text))
if not _agents_hiae:
    hiae_mismatches.append("AGENTS.md carries no HIAE Protocol version banner")
if not _arch_hiae:
    hiae_mismatches.append("docs/ARCHITECTURE.md carries no HIAE Protocol version banner")
if _agents_hiae and _arch_hiae and _agents_hiae.group(1) != _arch_hiae.group(1):
    hiae_mismatches.append(
        f"docs/ARCHITECTURE.md banner says v{_arch_hiae.group(1)}, "
        f"AGENTS.md says v{_agents_hiae.group(1)}"
    )

# --- 24. ARCHITECTURE.md + OPERATOR_MANUAL.md timeout claim must match the live controller ---
timeout_claim_mismatches = []
try:
    with open(os.path.join(repo, "docs", "ARCHITECTURE.md"), encoding="utf-8") as _fh:
        _arch_text = _fh.read()
except OSError:
    _arch_text = ""
try:
    with open(os.path.join(repo, "docs", "OPERATOR_MANUAL.md"), encoding="utf-8") as _fh:
        _op_text = _fh.read()
except OSError:
    _op_text = ""
try:
    with open(os.path.join(repo, "bin", "sec-sync-controller.py"), encoding="utf-8") as _fh:
        _ctrl_src = _fh.read()
except OSError:
    _ctrl_src = ""

# Extract timeout claim from ARCHITECTURE.md: "every backend call has a timeout (default 60s, SEC_SYNC_TIMEOUT overrides)"
_arch_timeout_m = re.search(r"every backend call has a timeout \(default (\d+)s, `SEC_SYNC_TIMEOUT` overrides\)", _arch_text)
if not _arch_timeout_m:
    timeout_claim_mismatches.append("docs/ARCHITECTURE.md carries no 'every backend call has a timeout (default Ns, SEC_SYNC_TIMEOUT overrides)' claim")
else:
    _arch_timeout_val = int(_arch_timeout_m.group(1))
    if _arch_timeout_val != 60:
        timeout_claim_mismatches.append(f"docs/ARCHITECTURE.md says default timeout is {_arch_timeout_val}s, expected 60s")

# Extract timeout claim from OPERATOR_MANUAL.md: "Each backend call is bounded (default 60s, SEC_SYNC_TIMEOUT overrides)"
_op_timeout_m = re.search(r"Each backend call is bounded \(default (\d+)s, `SEC_SYNC_TIMEOUT` overrides\)", _op_text)
if not _op_timeout_m:
    timeout_claim_mismatches.append("docs/OPERATOR_MANUAL.md carries no 'Each backend call is bounded (default Ns, SEC_SYNC_TIMEOUT overrides)' claim")
else:
    _op_timeout_val = int(_op_timeout_m.group(1))
    if _op_timeout_val != 60:
        timeout_claim_mismatches.append(f"docs/OPERATOR_MANUAL.md says default timeout is {_op_timeout_val}s, expected 60s")

# Verify the live controller has timeout= on all backend calls and default is 60s
if _ctrl_src:
    # Check BACKEND_TIMEOUT default is 60
    _backend_timeout_m = re.search(r'BACKEND_TIMEOUT = float\(os\.environ\.get\("SEC_SYNC_TIMEOUT", "(\d+)"\)\)', _ctrl_src)
    if not _backend_timeout_m:
        timeout_claim_mismatches.append("bin/sec-sync-controller.py carries no BACKEND_TIMEOUT default assignment")
    else:
        _backend_timeout_val = int(_backend_timeout_m.group(1))
        if _backend_timeout_val != 60:
            timeout_claim_mismatches.append(f"bin/sec-sync-controller.py BACKEND_TIMEOUT default is {_backend_timeout_val}, expected 60")

    # Verify all subprocess.run / Popen.communicate / urlopen calls have timeout= parameter
    # Check a window of lines since timeout= may be on the next line
    lines = _ctrl_src.split('\n')
    in_except_block = False
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("except ") and "TimeoutExpired" in stripped:
            in_except_block = True
            continue
        if in_except_block and stripped and not line.startswith(" ") and not line.startswith("\t"):
            in_except_block = False
        if in_except_block:
            continue
        # Check for backend calls that should have timeout= (check current + next 5 lines)
        window = ' '.join(lines[i:i+6])
        if "subprocess.run(" in line and "timeout=" not in window:
            timeout_claim_mismatches.append(f"bin/sec-sync-controller.py line {i+1}: subprocess.run without timeout=")
        if "p.communicate(" in line and "timeout=" not in window:
            timeout_claim_mismatches.append(f"bin/sec-sync-controller.py line {i+1}: p.communicate without timeout=")
        if "urllib.request.urlopen(" in line and "timeout=" not in window:
            timeout_claim_mismatches.append(f"bin/sec-sync-controller.py line {i+1}: urlopen without timeout=")

# --- 25. docs/SECURITY.md's file-permission claims must match the live chmod calls ---
security_perm_mismatches = []
try:
    with open(os.path.join(repo, "docs", "SECURITY.md"), encoding="utf-8") as _fh:
        _security_text = _fh.read()
except OSError:
    _security_text = ""
_security_srcs = {}
for _rel in ("bin/sec", "bin/bw-session-keeper", "bin/sec-organizer", "bin/sec-migrator"):
    try:
        with open(os.path.join(repo, *_rel.split("/")), encoding="utf-8") as _fh:
            _security_srcs[_rel] = _fh.read()
    except OSError:
        _security_srcs[_rel] = ""

# Resolve $VAR / ${VAR} assignments so a chmod's target can be compared to the
# path the doc writes.
_security_env = {"HOME": "~"}
for _rel in ("bin/sec", "bin/bw-session-keeper", "bin/sec-organizer", "bin/sec-migrator"):
    for _vm in re.finditer(r'^\s*([A-Za-z_]\w*)="([^"]*)"', _security_srcs[_rel], re.M):
        _security_env.setdefault(_vm.group(1), _vm.group(2))


def _security_expand(_val):
    for _ in range(6):
        _new = re.sub(
            r"\$\{?(\w+)\}?",
            lambda _m: _security_env.get(_m.group(1), _m.group(0)),
            _val,
        )
        if _new == _val:
            break
        _val = _new
    return re.sub(r"\$\{?\w+\}?", "*", _val)


# doc path -> (source file, variable the path is assigned to)
_SECURITY_PERMS = {
    "~/.sec/": ("bin/sec", "CONFIG_DIR"),
    "~/.sec/sec.conf": ("bin/sec", "CONFIG_FILE"),
    "~/.cache/bitwarden/": ("bin/bw-session-keeper", "CACHE_DIR"),
    "~/.cache/bitwarden/session": ("bin/bw-session-keeper", "SESSION_FILE"),
    "~/.cache/bitwarden/snapshot_*.json": ("bin/sec-organizer", "snapshot_file"),
    "~/.cache/bitwarden/migration_transaction.json": ("bin/sec-migrator", "TX_FILE"),
}
_security_block = re.search(
    r"## [^\n]*File Permissions Architecture(.*?)(?=\n## |\Z)", _security_text, re.S
)
_security_claims = {}
if not _security_block:
    security_perm_mismatches.append("docs/SECURITY.md carries no 'File Permissions Architecture' section")
else:
    for _pm in re.finditer(
        r"- `([^`]+)`: [^\n]*?mode `(\d{4})` \(`chmod (0?[0-7]{3})`\)", _security_block.group(1)
    ):
        _p_path, _p_mode, _p_chmod = _pm.group(1), _pm.group(2), _pm.group(3)
        if ("0" + _p_chmod.lstrip("0")) != _p_mode:
            security_perm_mismatches.append(
                f"docs/SECURITY.md: {_p_path} states mode {_p_mode} but its own chmod says {_p_chmod}"
            )
        _security_claims[_p_path] = _p_mode

    for _p_path, _p_mode in _security_claims.items():
        if _p_path not in _SECURITY_PERMS:
            security_perm_mismatches.append(
                f"docs/SECURITY.md states a mode for {_p_path}, but the sentinel binds no live source to it"
            )
            continue
        _src_rel, _var = _SECURITY_PERMS[_p_path]
        _src = _security_srcs.get(_src_rel, "")
        _live_expr = _security_env.get(_var)
        _live_path = _security_expand(_live_expr) if _live_expr else ""
        _p_regex = re.escape(_p_path.rstrip("/")).replace(r"\*", ".*")
        if not re.fullmatch(_p_regex, _live_path.rstrip("/")):
            security_perm_mismatches.append(
                f"docs/SECURITY.md: {_p_path} maps to {_src_rel} ${_var}, "
                f"whose live assignment is '{_live_path or 'unset'}'"
            )
            continue
        _live_chmod_m = re.search(r'chmod (\d+) "\$' + re.escape(_var) + r'"', _src)
        if not _live_chmod_m:
            security_perm_mismatches.append(
                f"docs/SECURITY.md: {_p_path} is claimed mode {_p_mode}, "
                f"but {_src_rel} has no chmod on ${_var}"
            )
        elif ("0" + _live_chmod_m.group(1).lstrip("0")) != _p_mode:
            security_perm_mismatches.append(
                f"docs/SECURITY.md: {_p_path} claims mode {_p_mode}, "
                f"live chmod is {_live_chmod_m.group(1)}"
            )

    for _p_path in _SECURITY_PERMS:
        if _p_path not in _security_claims:
            security_perm_mismatches.append(
                f"docs/SECURITY.md no longer documents a mode for {_p_path}"
            )

if want_list:
    print(f"{OK} manifest rows: {len(cov_rows)} tracked rows, {len(git_rows)} gitignored rows")
    print(f"{OK} tracked files: {len(tracked)}")
    print(f"{OK} personas reachable from the manifest: {sorted(used)}")
    print(f"{OK} skills tree: {len(_live_skill_dirs)} skill dir(s), registry {len(_registry_rows)} row(s)")
    print(f"{OK} bin/ helpers: {_live_bin_helpers} tracked sibling(s), all referenced by tests/test_dispatch.sh")
    print(f"{OK} bash suites: {_live_suite_count} tracked tests/*.sh suite(s)")
    for label, owner, n in present_surfaces:
        print(f"{OK} surface present: {label} ({n} location(s)) -> {owner}")
    for m in found_manifests:
        print(f"{OK} manifest file on disk: {m}")
    if not found_manifests:
        print(f"{WARN} no package.json / pyproject.toml / requirements.txt / Makefile anywhere: "
              f"there is no dependency surface to scan (persona 8)")

if unclaimed:
    failures.append(f"{len(unclaimed)} tracked file(s) no persona accounts for (unaudited surface)")
    for f in unclaimed:
        print(f"{ERROR} unaccounted tracked file: {f}")
if stale:
    failures.append(f"{len(stale)} manifest row(s) match no tracked file")
    for g in stale:
        print(f"{ERROR} stale manifest row: {g}")
if unclaimed_surfaces:
    failures.append(f"{len(unclaimed_surfaces)} live gitignored surface(s) unclaimed by profile.md")
    for label, owner, hits in unclaimed_surfaces:
        print(f"{ERROR} unclaimed gitignored surface: {label} (expected owner {owner}) e.g. {hits}")
if unclaimed_manifests:
    failures.append(f"{len(unclaimed_manifests)} dependency manifest file(s) on disk unclaimed")
    for m in unclaimed_manifests:
        print(f"{ERROR} unclaimed dependency manifest: {m}")
if new_ecosystems:
    failures.append(f"{len(new_ecosystems)} unmodelled ecosystem manifest(s) on disk")
    for m in new_ecosystems:
        print(f"{ERROR} unmodelled ecosystem manifest: {m}")
if missing_personas:
    failures.append(f"persona(s) {missing_personas} referenced by no manifest row")
if denominator is None:
    failures.append("profile.md coverage denominator line (Denominator: **N tracked files**) not found")
elif denominator != len(tracked):
    failures.append(
        f"profile.md coverage denominator says {denominator} tracked files, "
        f"but git ls-files reports {len(tracked)}"
    )
if transcript_count is None:
    failures.append("profile.md executed-commands 'git ls-files | wc -l' transcript line not found")
elif transcript_count != len(tracked):
    failures.append(
        f"profile.md executed-commands transcript says {transcript_count} tracked files, "
        f"but git ls-files reports {len(tracked)}"
    )
if dated_entries:
    failures.append(f"HISTORY.md holds {len(dated_entries)} dated '### ' entr(ies); rotate them into history/ (AGENTS.md §5)")
if history_bytes > HISTORY_BUDGET:
    failures.append(f"HISTORY.md is {history_bytes} bytes, over the {HISTORY_BUDGET}-byte summary budget; archive the narrative")
if orphaned:
    failures.append(f"history/ archive(s) not linked from HISTORY.md: {orphaned}")
if suite_mismatches:
    failures.append(f"{len(suite_mismatches)} cited suite section count(s) drifted from the live suites")
    for _m in suite_mismatches:
        print(f"{ERROR} suite count: {_m}")
if census_mismatches:
    failures.append(f"{len(census_mismatches)} cited census count(s) drifted from the live tree")
    for _m in census_mismatches:
        print(f"{ERROR} census: {_m}")
if adapters_mismatches:
    failures.append(f"{len(adapters_mismatches)} ADAPTERS.md suite count(s) drifted from the live suites")
    for _m in adapters_mismatches:
        print(f"{ERROR} adapters suite: {_m}")
if pack_mismatches:
    failures.append(f"{len(pack_mismatches)} pack-taxonomy drift(s) vs the live packs/ PACK.md files")
    for _m in pack_mismatches:
        print(f"{ERROR} pack: {_m}")
if producers_mismatches:
    failures.append(f"{len(producers_mismatches)} producer-census drift(s) vs docs/ARCHITECTURE.md")
    for _m in producers_mismatches:
        print(f"{ERROR} producers: {_m}")
if registry_mismatches:
    failures.append(f"{len(registry_mismatches)} skills registry drift(s) vs ADAPTERS.md + skills/REGISTRY.md")
    for _m in registry_mismatches:
        print(f"{ERROR} registry: {_m}")
if bin_helper_mismatches:
    failures.append(
        f"{len(bin_helper_mismatches)} bin/ helper census drift(s) vs profile.md + ADAPTERS.md + tests/test_dispatch.sh"
    )
    for _m in bin_helper_mismatches:
        print(f"{ERROR} bin helper: {_m}")
if suite_census_mismatches:
    failures.append(
        f"{len(suite_census_mismatches)} bash suite census drift(s) vs profile.md + docs/ARCHITECTURE.md + SKILL.md"
    )
    for _m in suite_census_mismatches:
        print(f"{ERROR} suite census: {_m}")
if struct_mismatches:
    failures.append(f"{len(struct_mismatches)} structural prose claim(s) drifted from the live tree")
    for _m in struct_mismatches:
        print(f"{ERROR} structural prose: {_m}")
if skill_struct_mismatches:
    failures.append(f"{len(skill_struct_mismatches)} SKILL.md/profile.md structural count(s) drifted from the live skill files")
    for _m in skill_struct_mismatches:
        print(f"{ERROR} skill structure: {_m}")
if forge_mismatches:
    failures.append(f"{len(forge_mismatches)} 360-audit-skill-forge structural count(s) drifted from the live SKILL.md")
    for _m in forge_mismatches:
        print(f"{ERROR} skill forge: {_m}")
if count_claim_mismatches:
    failures.append(f"{len(count_claim_mismatches)} profile.md §3 / pytest-mirror count claim(s) drifted from the live suites")
    for _m in count_claim_mismatches:
        print(f"{ERROR} count claim: {_m}")
if readme_mismatches:
    failures.append(f"{len(readme_mismatches)} README.md drift(s) vs the live CLI")
    for _m in readme_mismatches:
        print(f"{ERROR} README: {_m}")
if migrate_mismatches:
    failures.append(f"{len(migrate_mismatches)} sec migrate source/destination drift(s) across surfaces")
    for _m in migrate_mismatches:
        print(f"{ERROR} migrate: {_m}")
if version_mismatches:
    failures.append(f"{len(version_mismatches)} OPERATOR_MANUAL.md --version drift(s) vs the live CLI")
    for _m in version_mismatches:
        print(f"{ERROR} version: {_m}")
if tenant_line_mismatches:
    failures.append(
        f"{len(tenant_line_mismatches)} bin/sec 'Configured Tenants:' help line drift(s) vs the live alias regex"
    )
    for _m in tenant_line_mismatches:
        print(f"{ERROR} tenant help line: {_m}")
if code_census_mismatches:
    failures.append(
        f"{len(code_census_mismatches)} profile.md code-prose count(s) drifted from the live controller/install.sh/bin/sec"
    )
    for _m in code_census_mismatches:
        print(f"{ERROR} code census: {_m}")
if hiae_mismatches:
    failures.append(f"{len(hiae_mismatches)} HIAE Protocol version banner drift(s) vs AGENTS.md")
    for _m in hiae_mismatches:
        print(f"{ERROR} HIAE banner: {_m}")
if timeout_claim_mismatches:
    failures.append(f"{len(timeout_claim_mismatches)} timeout claim drift(s) vs ARCHITECTURE.md/OPERATOR_MANUAL.md/bin/sec-sync-controller.py")
    for _m in timeout_claim_mismatches:
        print(f"{ERROR} timeout claim: {_m}")
if security_perm_mismatches:
    failures.append(f"{len(security_perm_mismatches)} SECURITY.md file-permission drift(s) vs the live chmod calls")
    for _m in security_perm_mismatches:
        print(f"{ERROR} security perms: {_m}")

if failures:
    for f in failures:
        print(f"{ERROR} {f}")
    sys.exit(1)

print(f"{OK} coverage: all {len(tracked)} tracked files claimed by {len(cov_rows)} manifest rows")
print(f"{OK} coverage denominator: profile.md states {denominator} tracked files, matches git ls-files")
print(f"{OK} coverage denominator transcript: profile.md's executed 'git ls-files | wc -l' quotes {transcript_count}, matches git ls-files")
print(f"{OK} narrative history: HISTORY.md is a {history_bytes}-byte summary, {len(archived)} archive(s) linked under history/")
print(f"{OK} suite counts: profile.md matches the live suites ({', '.join(f'{s} {n}' for s, n in sorted(suite_counts.items()))})")
print(f"{OK} census counts: profile.md matches the live tree (markdown, python, config, [ TAG ] per-file)")
print(f"{OK} adapters suite counts: ADAPTERS.md 'current suites' snapshot + per-suite mentions match the live suites")
print(f"{OK} pack prose: profile.md's + ADAPTERS.md's cited pack versions + persona-taxonomy count match the live PACK.md files")
print(f"{OK} producer census: docs/ARCHITECTURE.md's producer count + list match the live bin/ emitters")
print(f"{OK} skills registry: ADAPTERS.md's census matches {len(_live_skill_dirs)} live skill dir(s) + {len(_registry_rows)} REGISTRY.md row(s)")
print(f"{OK} bin/ helper census: profile.md + ADAPTERS.md match {_live_bin_helpers} tracked sibling helper(s), all referenced by tests/test_dispatch.sh")
print(f"{OK} suite census: profile.md + ARCHITECTURE.md + SKILL.md match {_live_suite_count} tracked bash suite(s), ARCHITECTURE.md's suite list matches the tracked names")
print(f"{OK} structural prose: MULTI_TENANCY.md tenant aliases + profile.md CI checkout pin + OPERATOR_MANUAL.md principle count match the live tree")
print(f"{OK} skill structure: SKILL.md steps + personas + scopes + severity set match the live skill files")
print(f"{OK} skill forge: 360-audit-skill-forge's declared steps/headings/personas/scopes/severity match the live SKILL.md")
print(f"{OK} count claims: profile.md §3 count-words + ADAPTERS.md/SKILL.md pytest-mirror count + RESUME.md suite counts match the live suites")
print(f"{OK} README: quoted `sec --help` + sec.conf sample + migrate backend list match the live CLI")
print(f"{OK} migrate surfaces: source/destination backend sets agree across migrator, 4 shells + OPERATOR_MANUAL")
print(f"{OK} version claim: OPERATOR_MANUAL.md's documented `--version` output matches live 'bin/sec version'")
print(f"{OK} tenant help line: bin/sec's `Configured Tenants:` lists exactly the routable aliases")
print(f"{OK} code census: profile.md's SYNC_KEYS count + sync-controller timeout sites + install.sh/bin/sec zero-timeout claim match the live code")
print(f"{OK} HIAE banner: docs/ARCHITECTURE.md matches AGENTS.md (v{_agents_hiae.group(1)})")
print(f"{OK} timeout claim: ARCHITECTURE.md + OPERATOR_MANUAL.md default 60s + SEC_SYNC_TIMEOUT override match bin/sec-sync-controller.py")
print(f"{OK} security perms: docs/SECURITY.md's file-mode claims match the live chmod calls")
print(f"{OK} gitignored surfaces: {len(present_surfaces)} present, all claimed in profile.md")
print(f"{OK} personas: all {_live_personas} reachable from the manifest")
sys.exit(0)
PY
