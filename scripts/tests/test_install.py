"""Pytest-based regression tests for sec-cli (Issue #2: pre-commit Step 5 test detection)."""

import os
import re
import subprocess

import pytest

# Resolve repo root from test file: scripts/tests/test_install.py
# __file__ → scripts/tests/test_install.py
# three dirnames: scripts/tests → scripts → sec-cli root
_ABS_FILE = os.path.abspath(__file__)
_REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(_ABS_FILE)))

_FAST_SUITES = [
    "test_install.sh",
    "test_sync_guard.sh",
    "test_write_honesty.sh",
    "test_sentinel.sh",
]

_SUITE_TIMEOUT = int(os.environ.get("SEC_TEST_SUITE_TIMEOUT", "300"))


def _run_suite(name):
    return subprocess.run(
        ["bash", os.path.join(_REPO_ROOT, "tests", name)],
        cwd=_REPO_ROOT,
        capture_output=True,
        text=True,
        timeout=_SUITE_TIMEOUT,
    )


# Every tests/*.sh suite reports through the identical shape --
# `echo "[NN] section title"` then `fail() { echo "  FAIL: $1"; }` -- so one
# extractor covers all five. Issue #120: a suite failure reached the hook as a
# bare "1 failed, 52 passed" because the failing checks' names were only ever
# in the truncated sub-suite tail, so a recurrence could not be diagnosed.
_FAIL_RE = re.compile(r"^\s+FAIL:\s*(?P<name>.*)$")
_SECTION_RE = re.compile(r"^\[(?P<tag>\S+)\]\s*(?P<title>.*)$")


def _failing_checks(stdout):
    """Return [(section_label, check_name)] for each "  FAIL:" line in stdout.

    The section label is the enclosing "[NN] title" header, so a bare check name
    is attributable to the region of the suite that failed.
    """
    found = []
    section = "(before the first section header)"
    for line in stdout.splitlines():
        header = _SECTION_RE.match(line)
        if header is not None:
            section = f"[{header.group('tag')}] {header.group('title')}".rstrip()
            continue
        failure = _FAIL_RE.match(line)
        if failure is not None:
            found.append((section, failure.group("name").strip()))
    return found


def _suite_failure_detail(name, result):
    """Build the assertion body for a failed suite run.

    Names every failing check with its section header first, then keeps a short
    tail of the suite output for context. Falls back to the tail alone when the
    suite died without printing a "  FAIL:" line (a crash, or a non-zero exit
    from a path the suite does not report through fail()).
    """
    combined = result.stdout + result.stderr
    tail = combined.strip().splitlines()[-15:]
    failures = _failing_checks(result.stdout)
    if failures:
        named = "\n".join(f"  - {section} :: {check}" for section, check in failures)
        return (
            f"{name}: {len(failures)} failing check(s):\n{named}"
            f"\n  last {len(tail)} output line(s):\n" + "\n".join(tail)
        )
    return (
        f"{name}: no '  FAIL:' line in the suite output (it may have died before"
        f" reporting); last {len(tail)} output line(s):\n" + "\n".join(tail)
    )


def test_install_sh_exists():
    """Verify install.sh is executable and present at repo root."""
    install_path = os.path.join(_REPO_ROOT, "install.sh")
    assert os.path.isfile(install_path), "install.sh missing at repo root"
    assert os.access(install_path, os.X_OK), "install.sh not executable"


def test_bin_dir_has_required_binaries():
    """Verify every bin/ entry the dispatcher needs is present."""
    bin_files = [
        "sec",
        "bw-session-keeper",
        "sec-organizer",
        "sec-classify.py",
        "sec-migrator",
        "sec-sync-controller.py",
        "sec.ps1",
    ]
    for fname in bin_files:
        path = os.path.join(_REPO_ROOT, "bin", fname)
        assert os.path.isfile(path), f"Missing {fname} in bin/"


def test_help_output():
    """Verify sec --help lists expected subcommands."""
    bin_sec = os.path.join(_REPO_ROOT, "bin", "sec")
    result = subprocess.run(
        [bin_sec, "--help"], capture_output=True, text=True, timeout=30
    )
    assert result.returncode == 0, f"sec --help failed: {result.stderr}"
    help_text = result.stdout
    assert "sec sync" in help_text, "'sec sync' not in --help output"
    assert "completion" in help_text, "'completion' not in --help output"


def test_sec_ps1_set_honesty():
    """Verify sec.ps1 set command references exist."""
    ps1_path = os.path.join(_REPO_ROOT, "bin", "sec.ps1")
    assert os.path.isfile(ps1_path), "sec.ps1 missing"
    with open(ps1_path, "r") as f:
        content = f.read()
    assert "set" in content, "sec.ps1 set command not found"


def test_test_dispatch_suite_shell():
    """Verify the bash test dispatch suite is present and executable."""
    test_path = os.path.join(_REPO_ROOT, "tests", "test_dispatch.sh")
    assert os.path.isfile(test_path), "tests/test_dispatch.sh missing"
    assert os.access(test_path, os.X_OK), "tests/test_dispatch.sh not executable"


@pytest.mark.parametrize("suite_name", _FAST_SUITES)
def test_bash_suite_passes(suite_name):
    result = _run_suite(suite_name)
    assert result.returncode == 0, (
        f"{suite_name} exited {result.returncode}\n{_suite_failure_detail(suite_name, result)}"
    )


def test_dispatch_suite_passes():
    result = _run_suite("test_dispatch.sh")
    assert result.returncode == 0, (
        f"test_dispatch.sh exited {result.returncode}\n"
        f"{_suite_failure_detail('test_dispatch.sh', result)}"
    )


def test_failing_checks_names_each_failure_with_its_section():
    """A suite failure must be reportable by check name, not just by count (#120)."""
    stdout = (
        "[1] first section\n"
        "  ok: fine\n"
        "[32] bin/sec never expands a possibly-empty array bare\n"
        "  FAIL: bin/sec expands these possibly-empty arrays bare: SCOPE_ARGS\n"
        "[33] another section\n"
        "  FAIL: something else broke\n"
    )
    assert _failing_checks(stdout) == [
        (
            "[32] bin/sec never expands a possibly-empty array bare",
            "bin/sec expands these possibly-empty arrays bare: SCOPE_ARGS",
        ),
        ("[33] another section", "something else broke"),
    ]


def test_failing_checks_is_empty_when_every_check_passes():
    assert _failing_checks("[1] s\n  ok: a\n  ok: b\n\nALL TESTS PASSED\n") == []


def test_suite_failure_detail_surfaces_a_name_truncated_out_of_the_tail():
    """The name must survive when it sits far above the tail of a long run."""
    padding = "\n".join(f"  ok: check {i}" for i in range(400))
    stdout = (
        "[1] section one\n"
        "  FAIL: the check that flaked\n" + padding + "\nALL TESTS PASSED\n"
    )
    detail = _suite_failure_detail(
        "test_dispatch.sh", subprocess.CompletedProcess([], 1, stdout, "")
    )
    assert "1 failing check(s)" in detail
    assert "[1] section one :: the check that flaked" in detail
    assert "ALL TESTS PASSED" in detail


def test_suite_failure_detail_falls_back_to_the_tail_without_a_fail_line():
    detail = _suite_failure_detail(
        "test_install.sh", subprocess.CompletedProcess([], 2, "boom\n", "segfault\n")
    )
    assert "no '  FAIL:' line" in detail
    assert "boom" in detail
    assert "segfault" in detail


def test_suite_runners_report_through_the_named_failure_detail():
    """Pin the call shape: both suite runners must use the extractor.

    The helper's own tests would still pass if a runner went back to truncating
    raw stdout, which is the exact regression issue #120 hit.
    """
    with open(os.path.abspath(__file__), "r") as fh:
        source = fh.read()
    runners = re.findall(
        r"^def test_(?:bash_suite_passes|dispatch_suite_passes)\(.*?\n(?=\n\ndef |\Z)",
        source,
        re.S | re.M,
    )
    assert len(runners) == 2, "the suite-runner bodies were not found in this file"
    for body in runners:
        assert "_suite_failure_detail" in body, body.splitlines()[0]
        assert "result.stdout[" not in body, body.splitlines()[0]
