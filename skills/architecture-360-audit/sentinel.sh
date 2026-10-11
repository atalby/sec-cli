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
#     exits non-zero and names each one.
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
        for m in backtick.finditer(flat):
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


for src in (skill, profile):
    with open(src, encoding="utf-8") as fh:
        text = fh.read()
    for lineno, line in enumerate(text.split("\n"), 1):
        for m in pattern.finditer(line):
            path, spec = m.group(1), m.group(2)
            if "://" in path or path.startswith("/"):
                continue
            if os.path.basename(path) in {"x.py", "y.py", "example.py"}:
                continue
            full = resolve(path)
            if full is None:
                broken.append(f"{os.path.basename(src)}:{lineno} cites {path}:{spec} -- no such tracked path")
                continue
            full = os.path.join(repo, full)
            total = lines_in(full)
            for token in spec.split(","):
                fields = token.split("-", 1)
                if len(fields) == 2 and int(fields[1]) < int(fields[0]):
                    broken.append(f"{os.path.basename(src)}:{lineno} cites {path}:{spec} -- reversed range")
                    continue
                if int(fields[-1]) > total:
                    broken.append(
                        f"{os.path.basename(src)}:{lineno} cites {path}:{spec} -- "
                        f"line {fields[-1]} beyond end of file ({total} lines)"
                    )
    broken.extend(stale_content_anchors(os.path.basename(src), text))
    broken.extend(phantom_claims(os.path.basename(src), text))

if broken:
    for b in broken:
        print(f"{ERROR} {b}")
    print(f"{ERROR} {len(broken)} citation problem(s): broken anchors, stale-content anchors, phantom claims")
    sys.exit(1)
print(f"{OK} citations: every file:line anchor in SKILL.md and profile.md resolves")
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

if want_list:
    print(f"{OK} manifest rows: {len(cov_rows)} tracked rows, {len(git_rows)} gitignored rows")
    print(f"{OK} tracked files: {len(tracked)}")
    print(f"{OK} personas reachable from the manifest: {sorted(used)}")
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

if failures:
    for f in failures:
        print(f"{ERROR} {f}")
    sys.exit(1)

print(f"{OK} coverage: all {len(tracked)} tracked files claimed by {len(cov_rows)} manifest rows")
print(f"{OK} coverage denominator: profile.md states {denominator} tracked files, matches git ls-files")
print(f"{OK} gitignored surfaces: {len(present_surfaces)} present, all claimed in profile.md")
print(f"{OK} personas: all 12 reachable from the manifest")
sys.exit(0)
PY
