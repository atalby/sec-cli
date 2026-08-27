# History — sec-cli

## Current state
**2026-08-27**: `AGENTS.md` resynced v5.1.0 → **v5.21.2** ("Hyer" is now this methodology's working name); `skills/` created (didn't exist before) with the 9 adopter-distributable skills + `REGISTRY.md`; `.mcp.json` added for the first time (`hyer` server); `ADAPTERS.md` reconciled — secrets binding corrected (this repo IS `sec-cli`, not a consumer of a different tool), `solo-founder-governance` bumped to v1.2.0, the legacy `$50/day` block dropped, Git host (GitHub, not GitLab — the outlier in the `at-tech-io` fleet) / Issue tracker / Hyer sync / Skills registry / Pre-commit hook / Test suite sections added. 3 pre-existing unpushed local commits (v4.2.0 → v4.3.0 → v5.1.0 syncs, dated 2026-08-12 → 2026-08-22, never pushed) went out together with this sync's commit. `sec-cli` zero-plaintext multi-tenant secret manager active across the fleet — integrates Bitwarden (`bw`), Bitwarden Secrets Manager (`bws`), 1Password (`op`), Infisical, and HashiCorp Vault.

### 2026-08-27 — Hyer sync v5.1.0 → v5.21.2, skills/ + .mcp.json created, ADAPTERS.md reconciled, 3 stale unpushed commits landed
- **Trigger**: founder asked to adopt latest stable Hyer fleet-wide, following the same pass already applied to `iac-infrastructure`, `talby-law-firm`, `axiom-mesh`, `llm-fallback-manager`, `documesh`, `at-tech-website`, and `whatsapp-messenger`.
- **Found 3 unpushed local commits** already sitting on `main` (v4.2.0 → v4.3.0 → v5.1.0 methodology syncs from 2026-08-12 through 2026-08-22, never pushed to `github.com:atalby/sec-cli`) — same pattern as `talby-law-firm` had. Pushed together with this session's own commit rather than rewriting history.
- `AGENTS.md` replaced byte-for-byte with `git show stable:AGENTS.md`.
- `skills/` created — 9 adopter-distributable skills + `REGISTRY.md` from `stable`.
- `.git/hooks/pre-commit` installed for the first time via the hub's `scripts/install-hooks.sh` (thin wrapper). Note: the hub's own shared script had a real bug (steps 2/3/5/6 silently no-op for any adopter using this exact wrapper, fixed same-day as v5.21.2/issue #39) — picked up automatically via the wrapper's always-exec-current-script design, no action needed here.
- `.mcp.json` added for the first time, wired at the correct current hub path (`hyer-mcp/`, server name `hyer`) from the start.
- `ADAPTERS.md`: corrected the Secrets section to reflect that this repo *is* the secrets tool, not a consumer of `bws`/`infisical`; bumped `solo-founder-governance` to v1.2.0; dropped the legacy `$50/day` block; added Git host (GitHub — this repo's real outlier vs. the rest of the GitLab-hosted fleet), Issue tracker, Hyer version sync, Skills registry, Local pre-commit hook, Test suite sections.
- **`stable` moved fast mid-sync**: this repo's sync resolved at `stable` = `cf7804c` (v5.21.2) — the hub shipped v5.21.0 → v5.21.1 → v5.21.2 within roughly an hour of this fleet-sync task starting. Per the hub's own `moving-stable-tag` skill, logged as the resolved point-in-time commit rather than chased further.
- Doc/tooling-only change; no test suite found in this repo to re-run (zero-dependency shell CLI).

---

### 2026-08-12 — Central Secret Sync Controller (`sec sync`)
- Implemented `sec sync` subcommand (`bin/sec-sync-controller.py`) in `sec-cli`.
- Automatically syncs Bitwarden canonical vault keys to GCP Secret Manager (`sublime-flux-504502-k3`) and GitLab Group CI/CD variables (`at-tech-io`).
- Eliminates secret drift and configuration fragmentation across multi-cloud environments.
