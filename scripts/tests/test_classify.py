import importlib.util
import json
from pathlib import Path

import pytest

CLASSIFY_PATH = Path(__file__).resolve().parents[2] / "bin" / "sec-classify.py"


def _load_module():
    spec = importlib.util.spec_from_file_location("sec_classify", CLASSIFY_PATH)
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


@pytest.fixture(scope="module")
def classify_mod():
    return _load_module()


def _item(**overrides):
    base = {
        "name": "item",
        "notes": "",
        "login": {"username": "", "password": "", "totp": "", "uris": []},
        "card": {},
        "identity": {},
        "fields": [],
    }
    base.update(overrides)
    return base


def test_classify_aws_key_password(classify_mod):
    item = _item(
        login={"username": "a@example.com", "password": "aws_access_key_placeholder"}
    )
    res = classify_mod.classify_item(item)
    assert res["category"] == "cloud/aws"


def test_classify_gcp_service_account_uri(classify_mod):
    item = _item(
        name="gcp-sa",
        login={
            "username": "a@example.com",
            "uris": [{"uri": "https://iam.gserviceaccount.com"}],
        },
    )
    res = classify_mod.classify_item(item)
    assert res["category"] == "cloud/gcp"


def test_classify_cloudflare_token(classify_mod):
    item = _item(
        name="cf-dns", login={"username": "", "password": "cf_api_abcdef123456"}
    )
    res = classify_mod.classify_item(item)
    assert res["category"] == "cloud/cloudflare"


def test_classify_azure_key(classify_mod):
    item = _item(name="az-blob", login={"username": "", "password": "azure_key_xyz"})
    res = classify_mod.classify_item(item)
    assert res["category"] == "cloud/azure"


def test_classify_database_postgres_uri(classify_mod):
    item = _item(
        name="db",
        login={"username": "a@example.com", "uris": [{"uri": "postgres://host/db"}]},
    )
    res = classify_mod.classify_item(item)
    assert res["category"] == "database"


def test_classify_integrations_github_token(classify_mod):
    item = _item(name="gh", login={"username": "", "password": "ghp_" + "a" * 36})
    res = classify_mod.classify_item(item)
    assert res["category"] == "integrations"


def test_classify_ssh_private_key(classify_mod):
    item = _item(
        name="id_rsa", login={"username": "", "password": "BEGIN RSA PRIVATE KEY"}
    )
    res = classify_mod.classify_item(item)
    assert res["category"] == "infrastructure/ssh"


def test_classify_certificate_pem(classify_mod):
    item = _item(name="tls", login={"username": "", "password": "BEGIN CERTIFICATE"})
    res = classify_mod.classify_item(item)
    assert res["category"] == "infrastructure/certificates"


def test_classify_authentication_jwt(classify_mod):
    item = _item(name="jwt", login={"username": "", "password": "jwt_secret_abc"})
    res = classify_mod.classify_item(item)
    assert res["category"] == "authentication"


def test_classify_fallback_general_when_no_signals(classify_mod):
    item = _item(name="misc", notes="nothing meaningful")
    res = classify_mod.classify_item(item)
    assert res["category"] == "general"
    assert res["confidence"] == 50
    assert res["reasons"] == ["fallback:no_matching_signals"]


def test_classify_confidence_is_bounded(classify_mod):
    item = _item(
        name="aws",
        login={"username": "a@example.com", "password": "aws_access_key_placeholder"},
    )
    res = classify_mod.classify_item(item)
    assert 0 < res["confidence"] <= 99


def test_classify_suggested_name_from_username(classify_mod):
    item = _item(name="login", login={"username": "alice@example.com", "password": "x"})
    res = classify_mod.classify_item(item)
    assert res["suggested_name"]
    assert res["needs_rename"] is True


def test_classify_suggested_name_from_env_tag_in_notes(classify_mod):
    item = _item(name="login", notes="env: prod")
    res = classify_mod.classify_item(item)
    assert res["suggested_name"] == "login (prod)"
    assert res["needs_rename"] is True


def test_classify_suggested_name_no_env_tag_when_name_specific(classify_mod):
    item = _item(name="my-credential", notes="env: prod")
    res = classify_mod.classify_item(item)
    assert res["suggested_name"] == "my-credential"
    assert res["needs_rename"] is False


def test_classify_custom_fields_contribute(classify_mod):
    item = _item(
        name="cfg",
        fields=[{"name": "endpoint", "value": "s3://my-bucket"}],
    )
    res = classify_mod.classify_item(item)
    assert res["category"] == "cloud/aws"


def test_cli_stdin_stdout_contract():
    import subprocess

    payload = json.dumps({"name": "db", "login": {"uris": [{"uri": "mysql://host"}]}})
    proc = subprocess.run(
        ["python3", str(CLASSIFY_PATH)],
        input=payload,
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0
    out = json.loads(proc.stdout)
    assert out["category"] == "database"


def test_cli_invalid_json_falls_back_not_crash():
    import subprocess

    proc = subprocess.run(
        ["python3", str(CLASSIFY_PATH)],
        input="this is not json",
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0
    out = json.loads(proc.stdout)
    assert out["category"] == "general"
    assert out["confidence"] == 0
    assert out["needs_rename"] is False
