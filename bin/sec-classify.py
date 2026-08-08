#!/usr/bin/env python3
"""
bin/sec-classify.py: Zero-Dependency ML Classification & Intelligent Disambiguating Renamer Engine.
Classifies vault items and infers specific, disambiguated item names based on username, URI, notes, and custom fields.
"""

import sys
import json
import re

GENERIC_NAMES = {
    "gmail", "google", "aws", "postgres", "mysql", "login", "password", 
    "account", "database", "key", "api_key", "token", "secret", "credentials"
}

CATEGORY_WEIGHTS = {
    "cloud/aws": {
        "tokens": ["aws", "s3", "ec2", "eks", "iam", "dynamodb", "sqs", "sns", "arn", "amazon", "cloudfront", "route53"],
        "regex": [r"AKIA[0-9A-Z]{16}", r"aws[_\-]?access", r"s3[_\-]?bucket"]
    },
    "cloud/gcp": {
        "tokens": ["gcp", "gcloud", "google", "bigquery", "firebase", "pubsub", "gke"],
        "regex": [r"google[_\-]?cloud", r"gcp[_\-]?key"]
    },
    "cloud/cloudflare": {
        "tokens": ["cloudflare", "cf", "dns", "zone", "workers", "r2"],
        "regex": [r"cf[_\-]?api", r"cloudflare[_\-]?token"]
    },
    "cloud/azure": {
        "tokens": ["azure", "az", "blob", "cosmos", "entra", "active_directory"],
        "regex": [r"azure[_\-]?key", r"az[_\-]?secret"]
    },
    "database": {
        "tokens": ["db", "database", "postgres", "postgresql", "mysql", "redis", "mongodb", "mongo", "sqlite", "supabase", "cockroach", "planetscale"],
        "regex": [r"postgres://", r"mysql://", r"mongodb://", r"redis://", r"db[_\-]?password", r"db[_\-]?url"]
    },
    "integrations": {
        "tokens": ["github", "gitlab", "stripe", "slack", "discord", "twilio", "sendgrid", "linear", "jira", "datadog"],
        "regex": [r"ghp_[a-zA-Z0-9]{36}", r"glpat-[a-zA-Z0-9_\-]{20}", r"sk_live_[a-zA-Z0-9]+"]
    },
    "infrastructure/ssh": {
        "tokens": ["ssh", "rsa", "ed25519", "pubkey", "private_key", "authorized_keys"],
        "regex": [r"BEGIN (OPENSSH|RSA|EC|DSA) PRIVATE KEY", r"ssh-rsa", r"ssh-ed25519"]
    },
    "infrastructure/certificates": {
        "tokens": ["cert", "certificate", "tls", "ssl", "crt", "pem", "pfx", "keystore"],
        "regex": [r"BEGIN CERTIFICATE", r"\.crt$", r"\.pem$"]
    },
    "authentication": {
        "tokens": ["jwt", "oauth", "auth", "bearer", "session", "passphrase", "totp", "2fa"],
        "regex": [r"bearer\s+[a-zA-Z0-9_\-\.]+", r"jwt[_\-]?secret"]
    }
}

def tokenize(text: str) -> list[str]:
    return [t.lower() for t in re.split(r'[^a-zA-Z0-9]+', text) if len(t) >= 2]

def infer_suggested_name(item: dict) -> tuple[str, bool]:
    name = item.get("name", "").strip()
    name_clean = name.lower()
    username = item.get("login", {}).get("username", "") if isinstance(item.get("login"), dict) else ""
    if not username:
        username = item.get("username", "")

    notes = item.get("notes", "")

    # Check if current name is generic or if username is available to make it specific
    is_generic = name_clean in GENERIC_NAMES or any(g in name_clean for g in GENERIC_NAMES)

    if username and username not in name:
        suggested = f"{name} ({username})"
        return suggested, True

    # Try extracting environment / project tag from notes if generic
    env_match = re.search(r"(env|environment|stage|project)[:=]\s*([a-zA-Z0-9_\-]+)", notes, re.IGNORECASE)
    if env_match and is_generic:
        tag = env_match.group(2)
        suggested = f"{name} ({tag})"
        return suggested, True

    return name, False

def classify_item(item: dict) -> dict:
    name = item.get("name", "")
    notes = item.get("notes", "")
    uris = [u.get("uri", "") for u in item.get("login", {}).get("uris", []) if isinstance(u, dict)]
    full_text = f"{name} {notes} {' '.join(uris)}"
    tokens = tokenize(full_text)

    scores = {}
    matched_reasons = {}

    for cat, rules in CATEGORY_WEIGHTS.items():
        score = 0.0
        reasons = []

        for pattern in rules["regex"]:
            if re.search(pattern, full_text, re.IGNORECASE):
                score += 5.0
                reasons.append(f"regex:{pattern}")

        cat_tokens = set(rules["tokens"])
        for token in tokens:
            if token in cat_tokens:
                score += 2.0
                reasons.append(f"token:{token}")

        if score > 0:
            scores[cat] = score
            matched_reasons[cat] = reasons

    suggested_name, needs_rename = infer_suggested_name(item)

    if not scores:
        return {
            "category": "general",
            "confidence": 50,
            "reasons": ["fallback:no_matching_signals"],
            "suggested_name": suggested_name,
            "needs_rename": needs_rename
        }

    best_cat = max(scores, key=scores.get)
    max_score = scores[best_cat]
    confidence = min(99, int((max_score / (max_score + 2.0)) * 100))

    return {
        "category": best_cat,
        "confidence": confidence,
        "reasons": matched_reasons.get(best_cat, []),
        "suggested_name": suggested_name,
        "needs_rename": needs_rename
    }

if __name__ == "__main__":
    try:
        data = json.load(sys.stdin)
        result = classify_item(data)
        print(json.dumps(result))
    except Exception as e:
        print(json.dumps({"category": "general", "confidence": 0, "reasons": [str(e)], "suggested_name": "", "needs_rename": False}))
