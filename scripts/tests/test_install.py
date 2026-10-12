"""Pytest-based regression tests for sec-cli (Issue #2: pre-commit Step 5 test detection)."""

import os
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
        f"{suite_name} exited {result.returncode}\n"
        f"stdout:\n{result.stdout[-2000:]}\nstderr:\n{result.stderr[-2000:]}"
    )


def test_dispatch_suite_passes():
    result = _run_suite("test_dispatch.sh")
    assert result.returncode == 0, (
        f"test_dispatch.sh exited {result.returncode}\n"
        f"stdout:\n{result.stdout[-2000:]}\nstderr:\n{result.stderr[-2000:]}"
    )
