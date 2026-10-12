# Resume Point

## Live Resume Point (durable)
- **Status (2026-10-12, verified 2026-10-12):** Issues #78 and #79 closed —
  the completion-parity class is now complete. #78: `sec completion fish`
  omitted the tenant-prefix words (bitwarden/bw/1pass/op/bws/vault/infisical/
  keychain) that zsh/bash/ps1 offer; guard [22q] pins tenant parity. #79:
  fish offered no housekeep subcommands after the `organize` alias (bash/zsh/
  ps1 key on `housekeep|organize`); the fish condition now reads
  `__fish_seen_subcommand_from housekeep organize` and guard [22r] pins it.
  Also truth-up'd the stale `ADAPTERS.md` "Last updated" stamp and its suite
  snapshot (dispatch 64 / write-honesty 11 -> now 74 / 13).
  Five bash suites ALL TESTS PASSED (dispatch 74 / install 9 / sentinel 10
  / sync_guard 16 / write_honesty 13); pytest mirror 29 passed; sentinel
  citations + coverage green (suite counts match); HISTORY.md under budget.
- **Open issues:** #67 (fresh 360 audit — Step-1 gate needs explicit human
  scope approval, not autonomous), #51 (hub-side handoff items #2/#13,
  upstream), #80 (housekeep `undo`/`restore` accepted but not advertised in
  help/completions — held for a human decision).
- **Next action:** no autonomous in-repo work remains (no failing test, no
  untested path, no unmerged branch: only origin/main exists). The next run
  should re-check for new drift, take #67 once a human approves scope, or
  resolve #80 once a human decides.
- **Resume command:** `gh issue list --repo atalby/sec-cli --state open` then
  `bash tests/test_dispatch.sh` (expect ALL TESTS PASSED, 74 sections).
- **Verification:** `gh issue list --repo atalby/sec-cli --state open`
  (this repo tracks on GitHub, not GitLab — see `ADAPTERS.md` "Git
  host"/"Issue tracker"; `glab` has no sec-cli project among the fleet
  projects it can see). Operator prompt says GitLab/glab; ADAPTERS + prior
  RESUME runs document GitHub as the real tracker — use `gh`.

(End of file)
