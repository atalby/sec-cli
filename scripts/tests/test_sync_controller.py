import email.message
import importlib.util
import json
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

import pytest

CONTROLLER_PATH = Path(__file__).resolve().parents[2] / "bin" / "sec-sync-controller.py"


def _load_module():
    spec = importlib.util.spec_from_file_location(
        "sec_sync_controller", CONTROLLER_PATH
    )
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


@pytest.fixture(scope="module")
def ctrl():
    return _load_module()


class _FakeResponse:
    def __init__(self, status):
        self.status = status

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False


def _install(monkeypatch, responses):
    calls = []

    def fake_urlopen(req, timeout=None):
        calls.append(
            {
                "method": req.get_method(),
                "url": req.full_url,
                "headers": {k.lower(): v for k, v in req.header_items()},
                "body": req.data,
                "timeout": timeout,
            }
        )
        result = responses.pop(0)
        if isinstance(result, Exception):
            raise result
        return _FakeResponse(result)

    monkeypatch.setattr(urllib.request, "urlopen", fake_urlopen)
    return calls


def test_gitlab_token_missing_skips_without_calling(ctrl, monkeypatch, capsys):
    monkeypatch.setattr(ctrl, "GITLAB_TOKEN", "")
    calls = _install(monkeypatch, [])
    assert ctrl.sync_to_gitlab_group("MY_KEY", "v") is True
    assert calls == []
    assert "[WARN] GITLAB_TOKEN not set" in capsys.readouterr().out


def test_gitlab_update_uses_put_with_private_token(ctrl, monkeypatch, capsys):
    monkeypatch.setattr(ctrl, "GITLAB_TOKEN", "tok-123")
    monkeypatch.setattr(ctrl, "GITLAB_GROUP_ID", "grp")
    calls = _install(monkeypatch, [200])
    assert ctrl.sync_to_gitlab_group("MY_KEY", "topsecret") is True
    assert len(calls) == 1
    call = calls[0]
    assert call["method"] == "PUT"
    assert call["url"] == "https://gitlab.com/api/v4/groups/grp/variables/MY_KEY"
    assert call["headers"]["private-token"] == "tok-123"
    assert json.loads(call["body"])["value"] == "topsecret"
    out = capsys.readouterr().out
    assert "Updated (HTTP 200)" in out
    assert "topsecret" not in out


def test_gitlab_missing_variable_is_created_on_404(ctrl, monkeypatch, capsys):
    monkeypatch.setattr(ctrl, "GITLAB_TOKEN", "tok-123")
    monkeypatch.setattr(ctrl, "GITLAB_GROUP_ID", "grp")
    url = "https://gitlab.com/api/v4/groups/grp/variables/MY_KEY"
    notfound = urllib.error.HTTPError(
        url, 404, "Not Found", email.message.Message(), None
    )
    calls = _install(monkeypatch, [notfound, 201])
    assert ctrl.sync_to_gitlab_group("MY_KEY", "topsecret") is True
    assert [c["method"] for c in calls] == ["PUT", "POST"]
    assert calls[1]["url"] == "https://gitlab.com/api/v4/groups/grp/variables"
    body = json.loads(calls[1]["body"])
    assert body["key"] == "MY_KEY"
    assert body["value"] == "topsecret"
    out = capsys.readouterr().out
    assert "Created (HTTP 201)" in out
    assert "topsecret" not in out


def test_gitlab_non_404_update_error_fails_loudly(ctrl, monkeypatch, capsys):
    monkeypatch.setattr(ctrl, "GITLAB_TOKEN", "tok-123")
    monkeypatch.setattr(ctrl, "GITLAB_GROUP_ID", "grp")
    url = "https://gitlab.com/api/v4/groups/grp/variables/MY_KEY"
    forbidden = urllib.error.HTTPError(
        url, 403, "Forbidden", email.message.Message(), None
    )
    calls = _install(monkeypatch, [forbidden])
    assert ctrl.sync_to_gitlab_group("MY_KEY", "topsecret") is False
    assert [c["method"] for c in calls] == ["PUT"]
    out = capsys.readouterr().out
    assert "[ERROR] GitLab sync FAILED" in out
    assert "topsecret" not in out


def test_gitlab_network_error_returns_false(ctrl, monkeypatch, capsys):
    monkeypatch.setattr(ctrl, "GITLAB_TOKEN", "tok-123")
    monkeypatch.setattr(ctrl, "GITLAB_GROUP_ID", "grp")
    _install(monkeypatch, [OSError("connection refused")])
    assert ctrl.sync_to_gitlab_group("MY_KEY", "topsecret") is False
    out = capsys.readouterr().out
    assert "[ERROR] GitLab sync FAILED" in out
    assert "topsecret" not in out


def test_parse_args_unknown_arg_is_usage_error(ctrl):
    assert ctrl.parse_args(["bogus"]) == ("usage-error", "bogus")
    assert ctrl.parse_args(["--dry-run", "EXTRA"]) == ("usage-error", "EXTRA")


def test_parse_args_help(ctrl):
    assert ctrl.parse_args(["--help"]) == ("help", None)
    assert ctrl.parse_args(["-h"]) == ("help", None)


def test_parse_args_mode_selection(ctrl):
    assert ctrl.parse_args(["--dry-run"]) == ("dry-run", None)
    assert ctrl.parse_args(["-n"]) == ("dry-run", None)
    assert ctrl.parse_args(["--yes"]) == ("yes", None)
    assert ctrl.parse_args(["-y"]) == ("yes", None)
    assert ctrl.parse_args([]) == ("run", None)


class _FakeCompleted:
    def __init__(self, returncode=0):
        self.returncode = returncode


class _FakePopen:
    def __init__(self, returncode=0):
        self.returncode = returncode

    def communicate(self, input=None, timeout=None):
        return (b"", b"")


class _TimeoutPopen:
    def __init__(self):
        self.returncode = 0
        self.killed = False
        self._calls = 0

    def communicate(self, input=None, timeout=None):
        self._calls += 1
        if self._calls == 1:
            raise subprocess.TimeoutExpired(cmd="gcloud", timeout=60)
        return (b"", b"")

    def kill(self):
        self.killed = True


def _install_gcp(
    monkeypatch,
    describe_rc=0,
    add_rc=0,
    popen_raises=None,
    run_raises=None,
    popen_factory=None,
):
    calls = {"describe": [], "create": [], "add": []}

    def fake_run(cmd, **kwargs):
        if "describe" in cmd:
            calls["describe"].append(cmd)
            if run_raises is not None:
                raise run_raises
            return _FakeCompleted(describe_rc)
        if "create" in cmd:
            calls["create"].append(cmd)
            return _FakeCompleted(0)
        return _FakeCompleted(0)

    def fake_popen(cmd, **kwargs):
        calls["add"].append((cmd, kwargs))
        if popen_raises:
            raise popen_raises
        if popen_factory is not None:
            return popen_factory()
        return _FakePopen(add_rc)

    monkeypatch.setattr(subprocess, "run", fake_run)
    monkeypatch.setattr(subprocess, "Popen", fake_popen)
    return calls


def test_gcp_happy_path_describe_then_add_version(ctrl, monkeypatch, capsys):
    calls = _install_gcp(monkeypatch)
    assert ctrl.sync_to_gcp_secret_manager("my-key", "topsecret") is True
    assert len(calls["describe"]) == 1 and not calls["create"]
    cmd, kwargs = calls["add"][0]
    assert cmd[:4] == ["gcloud", "secrets", "versions", "add"]
    assert kwargs.get("stdin") == subprocess.PIPE
    out = capsys.readouterr().out
    assert "[ OK ] GCP Secret Manager: my-key updated successfully." in out
    assert "topsecret" not in out


def test_gcp_creates_secret_when_describe_fails(ctrl, monkeypatch, capsys):
    calls = _install_gcp(monkeypatch, describe_rc=1)
    assert ctrl.sync_to_gcp_secret_manager("my-key", "topsecret") is True
    assert calls["create"]
    assert calls["create"][0][1:4] == ["secrets", "create", "my-key"]
    assert calls["add"]
    out = capsys.readouterr().out
    assert "topsecret" not in out


def test_gcp_add_version_failure_returns_false(ctrl, monkeypatch, capsys):
    _install_gcp(monkeypatch, add_rc=7)
    assert ctrl.sync_to_gcp_secret_manager("my-key", "topsecret") is False
    out = capsys.readouterr().out
    assert "[ERROR] GCP Secret Manager sync FAILED" in out
    assert "topsecret" not in out


def test_gcp_communicate_timeout_returns_false(ctrl, monkeypatch, capsys):
    _install_gcp(
        monkeypatch, popen_raises=subprocess.TimeoutExpired(cmd="gcloud", timeout=60)
    )
    assert ctrl.sync_to_gcp_secret_manager("my-key", "topsecret") is False
    out = capsys.readouterr().out
    assert "[ERROR] GCP Secret Manager sync FAILED" in out
    assert "timed out" in out
    assert "topsecret" not in out


def test_gcp_add_version_call_timeout_returns_false(ctrl, monkeypatch, capsys):
    _install_gcp(monkeypatch, popen_factory=_TimeoutPopen)
    assert ctrl.sync_to_gcp_secret_manager("my-key", "topsecret") is False
    out = capsys.readouterr().out
    assert "[ERROR] GCP Secret Manager sync FAILED" in out
    assert "timed out" in out
    assert "topsecret" not in out


def test_gcp_missing_binary_is_reported(ctrl, monkeypatch, capsys):
    _install_gcp(monkeypatch, run_raises=FileNotFoundError("gcloud"))
    assert ctrl.sync_to_gcp_secret_manager("my-key", "topsecret") is False
    out = capsys.readouterr().out
    assert "[ERROR] GCP Secret Manager sync FAILED" in out
    assert "topsecret" not in out


def test_gcp_error_includes_stderr_detail(ctrl, monkeypatch, capsys):
    err = subprocess.CalledProcessError(1, "gcloud", stderr=b"permission denied")
    _install_gcp(monkeypatch, run_raises=err)
    assert ctrl.sync_to_gcp_secret_manager("my-key", "topsecret") is False
    out = capsys.readouterr().out
    assert "permission denied" in out
    assert "topsecret" not in out


def _run_main(ctrl, monkeypatch, argv, env):
    monkeypatch.setattr(sys, "argv", argv)
    for key in list(ctrl.SYNC_KEYS) + ["GITLAB_TOKEN"]:
        monkeypatch.delenv(key, raising=False)
    for key, val in env.items():
        monkeypatch.setenv(key, val)
    return ctrl.main()


def test_main_no_active_keys_returns_1(ctrl, monkeypatch, capsys):
    assert _run_main(ctrl, monkeypatch, ["sec"], {}) == 1
    out = capsys.readouterr().out
    assert "No active keys found" in out


def test_main_non_interactive_without_yes_returns_2(ctrl, monkeypatch, capsys):
    assert _run_main(ctrl, monkeypatch, ["sec"], {"OPENAI_API_KEY": "sk-1"}) == 2
    out = capsys.readouterr().out
    assert "Confirmation required" in out


def test_main_dry_run_returns_0(ctrl, monkeypatch, capsys):
    assert (
        _run_main(ctrl, monkeypatch, ["sec", "--dry-run"], {"OPENAI_API_KEY": "sk-1"})
        == 0
    )
    out = capsys.readouterr().out
    assert "DRY RUN COMPLETE" in out
    assert "sk-1" not in out


def test_main_push_success_returns_0(ctrl, monkeypatch, capsys):
    monkeypatch.setattr(ctrl, "GITLAB_TOKEN", "")
    monkeypatch.setattr(ctrl, "sync_to_gcp_secret_manager", lambda name, val: True)
    assert (
        _run_main(ctrl, monkeypatch, ["sec", "--yes"], {"OPENAI_API_KEY": "sk-1"}) == 0
    )
    out = capsys.readouterr().out
    assert "COMPLETED" in out
    assert "sk-1" not in out


def test_main_push_failure_returns_3(ctrl, monkeypatch, capsys):
    monkeypatch.setattr(ctrl, "GITLAB_TOKEN", "")
    monkeypatch.setattr(ctrl, "sync_to_gcp_secret_manager", lambda name, val: False)
    assert (
        _run_main(ctrl, monkeypatch, ["sec", "--yes"], {"OPENAI_API_KEY": "sk-1"}) == 3
    )
    out = capsys.readouterr().out
    assert "SYNC FAILED" in out


def test_main_help_returns_0(ctrl, monkeypatch, capsys):
    assert _run_main(ctrl, monkeypatch, ["sec", "--help"], {}) == 0
    out = capsys.readouterr().out
    assert "Usage:" in out


def test_main_usage_error_returns_2(ctrl, monkeypatch, capsys):
    assert _run_main(ctrl, monkeypatch, ["sec", "bogus"], {}) == 2
    err = capsys.readouterr().err
    assert "unknown argument: bogus" in err


def test_main_push_gitlab_failure_returns_3(ctrl, monkeypatch, capsys):
    monkeypatch.setattr(ctrl, "sync_to_gcp_secret_manager", lambda *a: True)
    monkeypatch.setattr(ctrl, "sync_to_gitlab_group", lambda *a: False)
    assert (
        _run_main(ctrl, monkeypatch, ["sec", "--yes"], {"OPENAI_API_KEY": "sk-1"}) == 3
    )
    out = capsys.readouterr().out
    assert "backend write(s) failed" in out
    assert "sk-1" not in out


def test_main_interactive_abort_returns_2(ctrl, monkeypatch, capsys):
    monkeypatch.setattr(sys.stdin, "isatty", lambda: True)
    monkeypatch.setattr(sys.stdout, "isatty", lambda: True)
    monkeypatch.setattr("builtins.input", lambda *a: "n")
    assert _run_main(ctrl, monkeypatch, ["sec"], {"OPENAI_API_KEY": "sk-1"}) == 2
    out = capsys.readouterr().out
    assert "Aborted by user" in out


def test_main_interactive_confirm_pushes(ctrl, monkeypatch, capsys):
    monkeypatch.setattr(sys.stdin, "isatty", lambda: True)
    monkeypatch.setattr(sys.stdout, "isatty", lambda: True)
    monkeypatch.setattr("builtins.input", lambda *a: "y")
    monkeypatch.setattr(ctrl, "sync_to_gcp_secret_manager", lambda *a: True)
    monkeypatch.setattr(ctrl, "sync_to_gitlab_group", lambda *a: True)
    assert _run_main(ctrl, monkeypatch, ["sec"], {"OPENAI_API_KEY": "sk-1"}) == 0
    out = capsys.readouterr().out
    assert "COMPLETED" in out


def test_cli_entrypoint_help_exits_0():
    proc = subprocess.run(
        [sys.executable, str(CONTROLLER_PATH), "--help"],
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0
    assert "Usage:" in proc.stdout
