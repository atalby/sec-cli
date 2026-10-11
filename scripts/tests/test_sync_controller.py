import email.message
import importlib.util
import json
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
