#!/usr/bin/env python3
"""
Central Secret Sync Controller (sec sync)
Single Source of Truth: Bitwarden Vault / bws
Targets: GCP Secret Manager, GitLab Group Variables, Vercel Projects
"""

import os
import sys
import json
import subprocess
import urllib.request

GCP_PROJECT = os.environ.get("GCP_PROJECT_ID", "sublime-flux-504502-k3")
GITLAB_GROUP_ID = os.environ.get("GITLAB_GROUP_ID", "at-tech-io")
GITLAB_TOKEN = os.environ.get("GITLAB_TOKEN", "")
BACKEND_TIMEOUT = float(os.environ.get("SEC_SYNC_TIMEOUT", "60"))

SYNC_KEYS = [
    "GEMINI_API_KEY",
    "OPENAI_API_KEY",
    "ANTHROPIC_API_KEY",
    "DEEPSEEK_API_KEY",
    "ATLASSIAN_API_TOKEN",
    "STRIPE_SECRET_KEY",
]

USAGE = """sec sync — push present env secrets to production backends (issue #3 guarded)

Usage:
  sec sync --dry-run | -n     Preview: list present key names and targets, write nothing
  sec sync --yes | -y         Push without an interactive prompt (scripts/CI)
  sec sync                    Interactive: prompt y/N before any write (TTY only;
                              non-interactive runs MUST pass --yes or are refused)
  sec sync -h | --help        Show this help

Exit codes:
  0  success (dry-run completed, every attempted write succeeded)
  1  no syncable keys present in the environment
  2  confirmation required but not given (or bad usage)
  3  one or more backend writes failed (values NOT stored there)

Targets (values are never printed):
  GCP Secret Manager project  %s
  GitLab group variables      %s

Safety: --dry-run performs zero backend calls; a real push needs an
explicit --yes or an interactive y confirmation. Never pipe this
command's output anywhere expecting secret values — only key names
are shown.""" % (GCP_PROJECT, GITLAB_GROUP_ID)


def parse_args(argv):
    want_dry = False
    want_yes = False
    for arg in argv:
        if arg in ("--dry-run", "-n"):
            want_dry = True
        elif arg in ("--yes", "-y"):
            want_yes = True
        elif arg in ("--help", "-h"):
            return "help", None
        else:
            return "usage-error", arg
    if want_dry:
        return "dry-run", None
    if want_yes:
        return "yes", None
    return "run", None


def sync_to_gcp_secret_manager(secret_name, secret_value):
    print(f"  🔒 Syncing to GCP Secret Manager: {secret_name}...")
    try:
        check_cmd = [
            "gcloud",
            "secrets",
            "describe",
            secret_name,
            f"--project={GCP_PROJECT}",
        ]
        res = subprocess.run(
            check_cmd, capture_output=True, text=True, timeout=BACKEND_TIMEOUT
        )
        if res.returncode != 0:
            create_cmd = [
                "gcloud",
                "secrets",
                "create",
                secret_name,
                f"--project={GCP_PROJECT}",
                "--replication-policy=automatic",
            ]
            subprocess.run(
                create_cmd,
                check=True,
                capture_output=True,
                text=True,
                timeout=BACKEND_TIMEOUT,
            )

        add_version_cmd = [
            "gcloud",
            "secrets",
            "versions",
            "add",
            secret_name,
            f"--project={GCP_PROJECT}",
            "--data-file=-",
        ]
        p = subprocess.Popen(
            add_version_cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        try:
            _out, err = p.communicate(
                input=secret_value.encode("utf-8"), timeout=BACKEND_TIMEOUT
            )
        except subprocess.TimeoutExpired:
            p.kill()
            p.communicate()
            print(
                f"    ❌ GCP Secret Manager sync FAILED for {secret_name}: "
                f"timed out after {BACKEND_TIMEOUT:.0f}s."
            )
            return False
        if p.returncode != 0:
            detail = (err or b"").decode("utf-8", "replace").strip()
            print(
                f"    ❌ GCP Secret Manager sync FAILED for {secret_name}: "
                f"exit {p.returncode}. {detail}"
            )
            return False
        print(f"    ✅ GCP Secret Manager: {secret_name} updated successfully.")
        return True
    except subprocess.TimeoutExpired:
        print(
            f"    ❌ GCP Secret Manager sync FAILED for {secret_name}: "
            f"timed out after {BACKEND_TIMEOUT:.0f}s."
        )
        return False
    except Exception as e:
        detail = getattr(e, "stderr", None) or ""
        if isinstance(detail, bytes):
            detail = detail.decode("utf-8", "replace")
        detail = str(detail).strip()
        print(
            f"    ❌ GCP Secret Manager sync FAILED for {secret_name}: {e}"
            + (f" {detail}" if detail else "")
        )
        return False


def sync_to_gitlab_group(secret_name, secret_value):
    if not GITLAB_TOKEN:
        print(
            f"    ℹ️ GITLAB_TOKEN not set; skipping GitLab group sync for {secret_name}."
        )
        return True
    print(f"  🦊 Syncing to GitLab Group Variables: {secret_name}...")
    url = f"https://gitlab.com/api/v4/groups/{GITLAB_GROUP_ID}/variables/{secret_name}"
    headers = {"PRIVATE-TOKEN": GITLAB_TOKEN, "Content-Type": "application/json"}
    data = json.dumps(
        {"value": secret_value, "masked": True, "protected": True}
    ).encode("utf-8")
    try:
        req = urllib.request.Request(url, data=data, headers=headers, method="PUT")
        with urllib.request.urlopen(req, timeout=BACKEND_TIMEOUT) as resp:
            print(
                f"    ✅ GitLab Group Variable {secret_name}: Updated (HTTP {resp.status})"
            )
        return True
    except Exception as e:
        print(f"    ❌ GitLab sync FAILED for {secret_name}: {e}")
        return False


def describe_targets():
    print("Targets:")
    print(f"  • GCP Secret Manager — project {GCP_PROJECT}")
    if GITLAB_TOKEN:
        print(f"  • GitLab group variables — group {GITLAB_GROUP_ID}")
    else:
        print(
            f"  • GitLab group variables — group {GITLAB_GROUP_ID} (skipped: GITLAB_TOKEN not set)"
        )


def main():
    mode, bad_arg = parse_args(sys.argv[1:])
    if mode == "help":
        print(USAGE)
        return 0
    if mode == "usage-error":
        print(f"sec sync: unknown argument: {bad_arg}", file=sys.stderr)
        print(USAGE, file=sys.stderr)
        return 2

    present = []
    for key in SYNC_KEYS:
        val = os.environ.get(key)
        if val:
            present.append((key, val))

    if not present:
        print("❌ No active keys found in environment — nothing to sync.")
        print(f"   Keys checked: {', '.join(SYNC_KEYS)}")
        return 1

    if mode == "dry-run":
        print(
            "================================================================================"
        )
        print(
            "🔐 SEC CENTRAL SECRET SYNC CONTROLLER — DRY RUN (no writes, no backend calls)"
        )
        print(
            "================================================================================"
        )
        describe_targets()
        print("\nPlan (key names only, values never shown):")
        for key, _val in present:
            gcp_name = key.lower().replace("_", "-")
            line = f"  🔑 {key} → GCP:{gcp_name}"
            line += (
                f" | GitLab:{key}" if GITLAB_TOKEN else " | GitLab:skipped(no token)"
            )
            print(line)
        absent = [k for k in SYNC_KEYS if k not in {pk for pk, _ in present}]
        if absent:
            print(f"  ℹ️ Not present in env: {', '.join(absent)}")
        print(
            f"\n🎉 DRY RUN COMPLETE: {len(present)} key(s) would be written, 0 written."
        )
        return 0

    print(
        "================================================================================"
    )
    print("🔐 SEC CENTRAL SECRET SYNC CONTROLLER (Single Source of Truth: Bitwarden)")
    print(
        "================================================================================"
    )
    describe_targets()

    if mode == "run":
        if not (sys.stdin.isatty() and sys.stdout.isatty()):
            print("❌ Confirmation required: non-interactive run without --yes.")
            print(
                "   Nothing pushed. Re-run with --yes to push, or --dry-run to preview."
            )
            return 2
        reply = input(f"\nPush {len(present)} secret(s) to the targets above? [y/N] ")
        if reply.strip().lower() not in ("y", "yes"):
            print("❌ Aborted by user; nothing pushed.")
            return 2
    else:
        print(f"\nProceeding with push (--yes): {len(present)} key(s) queued.")

    synced_count = 0
    failed_count = 0
    for key, val in present:
        print(f"\n🔑 Pushing active secret: {key}")
        if not sync_to_gcp_secret_manager(key.lower().replace("_", "-"), val):
            failed_count += 1
        if not sync_to_gitlab_group(key, val):
            failed_count += 1
        synced_count += 1

    print(
        "\n================================================================================"
    )
    if failed_count:
        print(
            f"❌ CENTRAL SECRET SYNC FAILED: {failed_count} backend write(s) "
            f"failed across {synced_count} key(s)."
        )
        print(
            "================================================================================"
        )
        return 3
    print(f"🎉 CENTRAL SECRET SYNC COMPLETED: {synced_count} keys processed.")
    print(
        "================================================================================"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
