# 360 audit scratchpad — run 2026-10-09-000410

Step-7 record of what was read and what was concluded from it, per SKILL.md
non-negotiable #7. Started 2026-10-09T00:04:10+00:00 (post Step-1 gate).

## What was read (sources)

- profile.md (477 lines) — all 62 file:line anchors re-verified by scripted
  extraction + sed: 62/62 OK, 0 moved, 0 out of range; content of each line
  matches the profile claim (spot-checked all load-bearing ones).
- Step 3 re-derivation: 3 suites ALL TESTS PASSED; .github/workflows absent;
  manifest census empty; git ls-files = 87; sentinel coverage OK
  (87/35 rows/12 personas/5 surfaces); integrations grepped (bw/bws/op/
  infisical/vault/keychain/gcloud/vercel/aws) — Vercel claim = docstring
  only (controller:5), AWS claim = docs only (no code anywhere).
- STALE profile records found: `git log --oneline | wc -l` recorded 35 →
  actual 40; `git log -1` recorded 6ff435d → actual 54146bc. Corrected in
  profile.md in-run; listed in report re-derivation.
- Step 4 forensic scan (dedicated agent): smoke/hardcoded/intent/ghost/dead
  categories — 10 candidates + category negatives (piped-install fix
  install.sh:17 present; sync guards :204/:209/:211/:213 present; hook thin
  wrapper .git/hooks/pre-commit:10 present; issue #4 templates present).
- Step 6: 7 parallel read-only agents (forensic; P1+P12; P2+P4; P3+P9;
  P5+P8; P6+P7; P10+P11). Findings consolidated below (dupes collapsed).
- Step 8 raw: gh issue list — #4/#3/#1 CLOSED, #2 OPEN (live).
- Side-effect check: persona-6 agent claimed its piped-install repro wrote
  ~/.local/bin/sec; stat shows mtime 2026-09-27 (untouched), ~/.sec-cli
  absent — claim did not materialize; verified no damage.

## Dedup method

Same file:line from two agents = one candidate (keep both personas).
Overlaps collapsed: master_pass plaintext (forensic/P1/P7/P10?) → C02;
Vercel (forensic/P2) → C04; tenant vocabulary (forensic/P2/P3) → C13;
returncode-never-read (P9-1/P11-3) → C22; synced_count (P9-2/P11-4) → C23;
migrator TX (P7/P10) → C44; LICENSE-notice, packs-declared etc. singletons.

## Consolidated candidate inventory (pre-disproof)

| id | file:line | severity | persona | effort |
|----|-----------|----------|---------|--------|
| C01 | bin/sec:558 | blocking | 2,4 | 8 |
| C02 | bin/bw-session-keeper:68 | blocking | 1,7 | 2 |
| C03 | bin/bw-session-keeper:127 | important | 1 | 2 |
| C04 | bin/sec-sync-controller.py:5 (docstring) + docs/ARCHITECTURE.md:14 | important | 1,2 | 2 |
| C05 | README.md:5 | important | 2,5 | 2 |
| C04b | docs/ARCHITECTURE.md:6 (AWS) | important | 1,2 | 2 |
| C06 | bin/sec-sync-controller.py:4 (SoT claim) | important | 2 | 8 |
| C07 | bin/sec-sync-controller.py:14-15 (prod defaults) | important | 1 | 1 |
| C08 | docs/ARCHITECTURE.md:10 (daemon claim) | important | 2 | 2 |
| C09 | bin/sec:563 (sync silent fallthrough) | important | 2 | 2 |
| C10 | bin/sec:118 (eval) | important | 1,12 | 2 |
| C11 | bin/sec:457/464 (set argv) | important | 1,5 | 1 |
| C12 | bin/sec-migrator:170 etc. (ungated writers) | important | 1 | 2 |
| C13 | bin/sec:65+151+178+238+295+465 (tenant vocab, 1password silent wrong-vault exit 0, keychain dead, infisical set silent success) | blocking | 2,3 | 5 |
| C14 | .gitignore:11 (literal ~/) | nit | 1,7 | 1 |
| C15 | bin/sec-sync-controller.py:120 (URL path inject) | important | 12 | 2 |
| C16 | install.sh:7 (SEC_REPO_URL) | important | 12 | 2 |
| C17 | .mcp.json:8 (PAT handoff) | important | 12 | 3 |
| C18 | bin/sec.ps1:129 (Invoke-Expression) | important | 12 | 1 |
| C19 | docs/ARCHITECTURE.md:9 (inject/audit phantom cmds; table incomplete) | important | 2 | 2 |
| C20 | completions/_sec + 4 heredocs: sync absent; fish absent from usage(:145)/_sec:46 | important | 2,4 | 2 |
| C21 | bin/sec.ps1:134 (5/15 cmds; sync exit 0) | important | 4 | 5 |
| C22 | bin/sec-sync-controller.py:107+108 (returncode unread, unconditional success) | blocking | 9,11 | 2 |
| C23 | bin/sec-sync-controller.py:222+231 (synced_count unconditional, exit 0 always) | blocking | 9,11 | 3 |
| C24 | bin/sec-sync-controller.py:90 (stderr lost) | important | 9 | 1 |
| C25 | bin/bw-session-keeper:143 (set -e silent abort) | blocking | 9 | 2 |
| C26 | bin/bw-session-keeper:122 (non-TTY silent exit 1; no runbook) | important | 9 | 2 |
| C27 | .gitignore:9 (no logger; *.log trap) | important | 9 | 3 |
| C28 | tests/test_install.sh:26 (791 lines untested) | blocking | 3 | 8 |
| C29 | tests/test_sync_guard.sh:78 (circular canary: destination unasserted) | blocking | 3 | 2 |
| C30 | bin/sec:65 (tenant literals untested → C13 test-gap aspect) | blocking | 3 | 2 |
| C31 | bin/sec (57/58 units unasserted; only --help executed) | blocking | 3 | 13 |
| C32 | ADAPTERS.md:32 (no CI, no coverage) | blocking | 3,5,6 | 3 |
| C33 | ADAPTERS.md:213-214 (#2 hook blind; ADAPTERS documents 1/3 suites) | important | 3,5,6 | 2 |
| C34 | HISTORY.md:14 (#1 closed though packs 7/9 differ; solo-founder v1.2.0 vs hub v1.4.0; changelog review undone) | important | 5 | 2 |
| C35 | README.md:86 (sync without flags) | important | 5 | 1 |
| C36 | README.md:5 zero-dependency false (jq/python3 unguarded, no prereqs) | important | 5 | 2 |
| C37 | README.md:147 (set argv contradicts line 11) | important | 5 | 1 |
| C38 | README.md:92 vs bin/sec:145 (fish divergence) | nit | 5 | 1 |
| C39 | install.sh:24 (unverified remote code, no pin/tag/checksum) | blocking | 6,8 | 5 |
| C40 | README.md:29 (unpinned curl|bash, no --max-time, no -f; bootstrap never refreshed → stale re-install) | important | 6,8,11 | 3 |
| C41 | install.sh:19 (piped mode trusts $PWD/bin/sec) | important | 6 | 2 |
| C42 | packs/zero-cost-infra-defaults/PACK.md:33 (broken cross-refs) | important | 6 | 1 |
| C43 | .gemini/settings.json:3 (GEMINI.md missing) | nit | 6 | 1 |
| C44 | bin/sec-migrator TX_FILE (no trap; SIGKILL orphans; undo refused; undo rm after swallowed deletes) | blocking | 7,10 | 3 |
| C45 | bin/sec-organizer:157/185 (apply bw|op only: bws et al zero mutations + rm plan + success) | blocking | 7 | 2 |
| C46 | bin/sec-organizer:154 (single-slot snapshot; non-atomic; same-second collision) | important | 7 | 2 |
| C47 | bin/sec-organizer:125 (plan 644 until apply; cache dir 755 vs SECURITY.md:24) | important | 7 | 1 |
| C48 | sec.conf.example:7 (cli×5 + global auto_rotate never read; parser honors commented keys) | important | 7 | 2 |
| C49 | bin/sec-classify.py:98 (login.password ignored → wrong class propagates to apply) | important | 10 | 3 |
| C50 | bin/sec-classify.py:18/23/51 (GCP SA→aws; JWT→general/azure) | important | 10 | 5 |
| C51 | bin/sec-organizer:60/63 (op/bws payload stripped before classify; apply replays stale) | important | 10 | 5 |
| C52 | bin/sec-organizer:246+250+251 (revert op: swallow+rm snapshot+success) | blocking | 10 | 5 |
| C53 | bin/sec:337/340/351 (cross-tenant get; MULTI_TENANCY routing claims; exit-0 usage) | blocking | 10 | 13 |
| C54 | bin/sec-sync-controller.py:127 (urlopen no timeout → infinite hang) | blocking | 11 | 3 |
| C55 | bin/sec-sync-controller.py:107 (communicate no timeout) | blocking | 11 | 3 |
| C56 | bin/sec (outage → "secret not found"; 0 timeouts/retries anywhere) | important | 11 | 5 |
| C57 | tests/test_sync_guard.sh:22 (no network-failure/hang coverage) | important | 11 | 3 |
| C58 | .git/hooks/pre-commit:10 (machine-local untracked gate; scan staged-only) | blocking | 6,8 | 2 |
| C59 | install.sh:1 (no version/deps checks; PATH toolchain unpinned) | important | 8 | 5 |
| C60 | ADAPTERS.md:43 (packs on disk not declared: compliance-baseline, human-team-coordination) | important | 8 | 1 |
| C61 | install.sh:29 (LICENSE never installed → MIT notice non-compliance) | important | 8 | 1 |
| C62 | install.sh:10 / bin output ([ TAG ] convention: 0 conforming lines in bin/) | important | 4 | 3 |
| C63 | docs/OPERATOR_MANUAL.md:35 (no sync/completion documented) | important | 4 | 1 |
| C64 | README.md:131 (vault example crashes: unbound item_name) | important | 4 | 2 |
| C65 | tests/test_sentinel.sh mode 100644 (non-executable vs siblings) | nit | 4 | 1 |

Mechanical verdicts (persona 8): no manifest → no scanner target exists
(census re-run, empty; pip-audit absent). Secrets-in-tree: hook's own
scan_secrets.py over all 87 tracked files PASS + positive control detected
a planted ghp_ token → clean, proven live.
Tracker reconciliation (live): #1 CLOSED but PARTIAL (C34); #3 LANDED
(guards :55/:57/:205 + suite present); #4 LANDED (templates + sections);
#2 OPEN = C33.

Category negatives (recorded, not findings): guards precede every write in
controller main(); no other network writer than controller+set+migrate;
no secret printed on any output path; argv→provider quoting safe (quoted
call sites); jq always via --arg with literal programs; sync-guard suite
already prevents naive "CI push" claims; piped-install BASH_SOURCE fix
present (install.sh:17); hook is thin wrapper not frozen fork.
