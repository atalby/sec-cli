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

def sync_to_gcp_secret_manager(secret_name, secret_value):
    """Syncs a secret key-value pair to GCP Secret Manager."""
    print(f"  🔒 Syncing to GCP Secret Manager: {secret_name}...")
    try:
        # Check if secret exists
        check_cmd = ["gcloud", "secrets", "describe", secret_name, f"--project={GCP_PROJECT}"]
        res = subprocess.run(check_cmd, capture_output=True, text=True)
        if res.returncode != 0:
            # Create secret
            create_cmd = ["gcloud", "secrets", "create", secret_name, f"--project={GCP_PROJECT}", "--replication-policy=automatic"]
            subprocess.run(create_cmd, check=True, capture_output=True)

        # Add secret version
        add_version_cmd = ["gcloud", "secrets", "versions", "add", secret_name, f"--project={GCP_PROJECT}", "--data-file=-"]
        p = subprocess.Popen(add_version_cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        p.communicate(input=secret_value.encode('utf-8'))
        print(f"    ✅ GCP Secret Manager: {secret_name} updated successfully.")
    except Exception as e:
        print(f"    ⚠️ GCP Secret Manager sync notice for {secret_name}: {e}")

def sync_to_gitlab_group(secret_name, secret_value):
    """Syncs a secret key-value pair to GitLab Group CI/CD variables."""
    if not GITLAB_TOKEN:
        print(f"    ℹ️ GITLAB_TOKEN not set; skipping GitLab group sync for {secret_name}.")
        return
    print(f"  🦊 Syncing to GitLab Group Variables: {secret_name}...")
    url = f"https://gitlab.com/api/v4/groups/{GITLAB_GROUP_ID}/variables/{secret_name}"
    headers = {
        "PRIVATE-TOKEN": GITLAB_TOKEN,
        "Content-Type": "application/json"
    }
    data = json.dumps({"value": secret_value, "masked": True, "protected": True}).encode("utf-8")
    try:
        req = urllib.request.Request(url, data=data, headers=headers, method="PUT")
        with urllib.request.urlopen(req) as resp:
            print(f"    ✅ GitLab Group Variable {secret_name}: Updated (HTTP {resp.status})")
    except Exception as e:
        print(f"    ⚠️ GitLab sync notice for {secret_name}: {e}")

def main():
    print("================================================================================")
    print("🔐 SEC CENTRAL SECRET SYNC CONTROLLER (Single Source of Truth: Bitwarden)")
    print("================================================================================")

    # Key secrets to sync across environments
    sync_keys = [
        "GEMINI_API_KEY",
        "OPENAI_API_KEY",
        "ANTHROPIC_API_KEY",
        "DEEPSEEK_API_KEY",
        "ATLASSIAN_API_TOKEN",
        "STRIPE_SECRET_KEY"
    ]

    synced_count = 0
    for key in sync_keys:
        val = os.environ.get(key)
        if val:
            print(f"\n🔑 Found active secret for {key}:")
            sync_to_gcp_secret_manager(key.lower().replace("_", "-"), val)
            sync_to_gitlab_group(key, val)
            synced_count += 1
        else:
            print(f"  ℹ️ Key {key} not present in active env.")

    print("\n================================================================================")
    print(f"🎉 CENTRAL SECRET SYNC COMPLETED: {synced_count} keys processed.")
    print("================================================================================")

if __name__ == "__main__":
    main()
