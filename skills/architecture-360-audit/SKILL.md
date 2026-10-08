---
name: architecture-360-audit
description: "Forensic twelve-dimension audit of the sec-cli repository. Use when asked for a '360 check', '360 review', '360 audit', 'full audit', 'deep audit', 'comprehensive review', 'architecture audit', 'secret-management audit', 'CLI audit', or any plain-language variant asking for an exhaustive end-to-end sweep. Binds to this repo's real hotspots: the bin/sec multi-backend dispatcher, the sec sync production-push guards, the piped-install bootstrap, the zero-plaintext claims in docs/ARCHITECTURE.md, and the GitHub backlog. Cross-validates every finding by disproof. Always confirms before starting and records wall-clock duration."
---

# Architecture 360 Audit

An exhaustive, evidence-bound audit of this repository. It exists to find the
gap between what the repo *claims* and what it *does*: a zero-plaintext
security architecture documented in `docs/ARCHITECTURE.md` while the sync
controller's targets drift from the documented ones, install instructions
that claim a one-liner and cannot survive a piped shell, tests that pass
because they assert against the same hardcoded tenant list the dispatcher
uses, issues marked closed whose implementing code never landed, and a
pre-commit gate whose test step silently skips this repository's only test
suites.

The procedure is fixed. `profile.md` beside this file holds every
repository-specific binding: the commands, the maturity tier, the twelve
personas with their `file:line` anchors, the coverage manifest, the external
integration list, and the gitignored surfaces. Read `profile.md`; do not
re-derive what it already states.

## Modes

Exactly two. They are not the same activity.

**Audit mode** (this file, all eleven steps). Run it only after Step 1's
confirmation gate. It reads the tree, applies the twelve personas,
cross-validates by disproof, and writes `report.md`, `findings.json`, and
`timing.json` into a timestamped run directory.

**Refresh mode** (Step 11 and the `## Regenerating this skill` section).
Bounded, local, and needs no internet. It re-derives `profile.md` against the
current tree, re-runs the coverage sentinel, records its own duration, and
rewrites only this skill's own surface: `SKILL.md`, `profile.md`,
`sentinel.sh`, and the harness bridges. It does not edit the audited
repository's source, tests, fixtures, or documentation. It does not run the
audit. It does not commit.

Reach refresh through the `360-check-update` command in any harness, never
by typing the audit command and improvising. Diffing `findings.json` across
runs is supported, and is not a third mode.

## Non-negotiables

Bind these into every run. They are not style preferences.

1. Every finding cites `file:line` **and quotes that line**. A finding
   without both is dropped, not softened.
2. Every finding states the **concrete consequence**, never the rule it
   violates. "Should validate" is not a finding. "`eval $(op signin)` at
   `bin/sec:118` executes whatever text the 1Password CLI prints on stdout
   as shell code in the user's session" is.
3. Severity is one of three values only: `blocking`, `important`, `nit`.
   Formatting taste and "I would have written it differently" are not
   findings at any severity.
4. **The audit never edits source, tests, fixtures, or docs.** It proposes
   changes in its report. An audit that edits its own evidence cannot be
   cross-validated against it.
5. **The audit detects its own drift.** Every `file:line` cited in
   `profile.md` is re-verified by reading it at the start of every run. A
   citation that has moved is corrected in `profile.md` *and* listed in that
   run's report. A persona auditing a stale line number produces a confident
   wrong finding, which is worse than no finding.
6. **No scope drift.** No unrequested refactors, no opportunistic cleanups,
   no fixing an audit finding in passing.
7. **Emit a scratchpad** of what was read and what was concluded from it,
   before the final report. Show the reasoning, not just the artifact.
8. **Root-cause, never symptom-mask.** Do not propose disabling a failing
   check, widening a tolerance, adding `|| true`, or hardcoding an override
   to reach a passing state. Name the cause and the fix for the cause. This
   repository's dispatcher is dense with existing `|| true` fallbacks — a
   proposed fix that adds one is a regression.
9. **Preserve contracts.** This repository's external contracts are the
   `sec` subcommand surface and its usage text, the `sec.conf` file format
   and its mode-600 location at `$HOME/.sec/sec.conf`, the `sec sync`
   confirmation behavior (`--dry-run` preview, TTY `y/N` or `--yes`,
   exit codes 0/1/2), the `install.sh` bootstrap environment variables
   (`SEC_REPO_URL`, `SEC_BOOTSTRAP_DIR`), and the `completions/_sec`
   completion surface. Any proposed change must state explicitly whether it
   alters one. An alteration is a breaking change requiring a decision, not
   a finding to apply silently.
10. **The audit works on this repository as it is.** A red checker, a test
    suite that no automation ever runs, an absence of manifests, and a
    tracked file with no test are all fully auditable. Never report "cannot
    audit". If the audit produces nothing, the audit failed, not the
    repository.

Prior art imported into this instrument, by name:

- **Adversarial validation** (prior art A). Fresh agents try to *disprove*
  each finding rather than reviewing it. This replaces the older simulated
  panel pattern, which is weaker: a simulated panel shares the author's
  context and tends to agree.
- **The finder-to-judgment trust boundary** (prior art B). The validation
  layer receives only the finding's file path and its quoted evidence, never
  the finder's reasoning. This is what stops a persuasive-but-wrong finding
  from surviving review.
- **Deterministic scanners for mechanical dimensions** (prior art C).
  Secrets, known CVEs, and license compatibility must be decided by a real
  scanner reading the real inputs, never by a model reading source and
  forming an impression. Use this repository's own tooling where it exists:
  `tests/test_install.sh`, `tests/test_sync_guard.sh`, and the hub checkers
  this repo runs from `~/sandbox/hyer/scripts/` (`check_version_banners.py`,
  `check_skill_registry.py`, `check_adapters_completeness.py`). Where no
  scanner exists for a mechanical question, that absence is itself a
  supply-chain finding.
- **Timestamped run directories plus a resumable checkpoint** (prior art D).
  Consecutive runs accumulate a duration history and an interrupted run
  resumes rather than restarts.
- **Schema-validated structured findings** (prior art E). `findings.json`
  exists so a later run can diff against this one and skip what is already
  known.

Prior art refused, with reasons:

- **No confirm-before-a-long-run gate** (prior art F) is refused: none of the
  surveyed projects implemented one. The gate is a deliberate
  differentiator. Keep it.
- **No run-duration recording** (prior art G) is refused: same result. Keep
  it. An audit whose cost is unknown is an audit nobody schedules.
- **Judging mechanical dimensions by inspection** (prior art H) is refused: a
  model's opinion about whether a dependency has a CVE is worse than no
  answer, because it is confidently wrong.
- **Per-repository reshaping of the procedure** (prior art I) is refused:
  reshaping sounds like adaptation and is actually drift. It makes two skills
  incomparable, breaks every bridge that names a section, and means a fix to
  one cannot be copied to another. Bind deeper; never reshape.

## Step 1: Confirm before starting

Before any file is read, state the scope in terms the user can judge: how
many personas, roughly how many files, roughly how much reading. Quote the
numbers from `profile.md`'s coverage manifest rather than estimating.

Offer exactly two scopes and nothing else:

- **Full sweep.** All twelve personas across the whole manifest. The default.
- **Scoped sweep.** A named subset of personas, drawn from the ranked order in
  `profile.md`. Personas are ranked highest-value-first, so dropping the
  lowest first is the cheap path. Name every dropped persona in the run
  header. A scoped run must never present itself as a full one.

Approval must be explicit and affirmative: "yes", "run it", "go ahead", "run
the 360", "do the 360 check", "start the audit", or an explicitly named
subset. Ambiguity does not count. Silence does not count. A question about
what the audit would check is not approval — answer the question, then ask
again. If the user asks what the audit covers, read `profile.md`'s persona
list aloud and re-ask.

Do not create the run directory, do not start the clock, and do not read a
repository file before this gate is passed.

## Step 2: Record the start time

Timing starts when the audit begins real work — after approval, not when the
user asked for it.

Record the wall-clock start. Track per-persona start and end, the finish
time, and total duration. A run without durations is incomplete.

Write `timing.json` into the run directory with `started_at`, `finished_at`,
`duration_seconds`, and the per-persona breakdown, and state the total in the
final reply alongside the previous run's duration if one exists, so the cost
of an audit is a known quantity rather than a surprise.

The run directory is `docs/360/runs/<YYYY-MM-DD-HHMMSS>/`, created on this
repository's default branch checkout. One directory per run; two runs on the
same day must not collide. Do not add it to `.gitignore` unless asked.

## Step 3: Load the profile and re-derive the hotspots

Read `profile.md`. It is the binding layer and it is the only file that
changes when this repository changes.

Then re-verify, by opening each cited location, every `file:line` anchor in
its `## Personas` section. Record each as resolved or moved. A moved citation
is corrected in `profile.md` in the same run and listed in the report's
re-derivation section — never silently. Also re-derive, from the repository
rather than from `profile.md`'s prose:

- the maturity tier's factual claims (does the test command still pass, does
  CI still absent or present, are the manifests still absent);
- the external integration list (does each named provider still appear in
  the code);
- the coverage manifest against the current `git ls-files`.

This step is what makes the skill future-proof: a persona bound to a line that
has since moved produces a confident wrong finding.

## Step 4: Forensic scan

Run the scan and record its raw results; they are the material for Step 6.

**Smoke and mirrors.** Functions, subcommands, or backends documented as
complete that are empty shells, missing their logic pipeline, or return
static placeholders. For each claim in `README.md`, `docs/ARCHITECTURE.md`,
`docs/SECURITY.md`, `docs/MULTI_TENANCY.md`, and `docs/OPERATOR_MANUAL.md`,
find the code that implements it. The documented `sec sync` target list
(GCP Secret Manager, GitLab group variables, Vercel projects) versus the
controller's actual call sites is the standing example — verify it against
the current tree, do not trust this sentence. A claim with no implementing
code is a finding.

**Hardcoded illusion.** Behaviour resting on hardcoded strings, magic
numbers, static return values, fixture data, or mocks on a live path rather
than behind a test seam. This repository legitimately hardcodes backend
vocabularies (the tenant list recurs in `bin/sec` at several call sites) and
illegitimately hardcodes others; the distinction is whether the value is a
declared, single-sourced constant or a literal duplicated across dispatch,
completion, and docs that nobody keeps in step. Name the `file:line` either
way.

**Intent versus reality.** Compare header comments, docstrings, and stated
requirements against what the code path actually computes. A comment
asserting a use where no such use exists is a finding, not a nit, because it
misleads the next reader. Where a comment explains a *past incident*,
verify the mitigation is still present in the code — `HISTORY.md` records
the piped-install `BASH_SOURCE` incident and the sync-guard work; both are
claims to be re-executed, not facts.

**Historical ghosts.** Reconcile `git log` and `HISTORY.md` against the code
on disk. Find features claimed done that are absent, and defects patched at
the call site while the root cause remains. This repository has a dense
`HISTORY.md` and a 35-commit log; use both as the intent record, and treat
them as claims to be re-executed, not as facts.

**Dead surface.** Named symbols with no reachable caller. Verify each with a
whole-repo search before claiming it is dead; a symbol used only by tests is
not dead, it is test-only, which is a different and smaller finding. **The
visibility rule applied here is Python's** (module-level names are public by
convention, a leading underscore marks privacy) for `.py` files; for the
shell dispatchers there is no language-level privacy, so **every function in
`bin/sec` and the other `bin/` scripts is public surface** — including
`sec.ps1` and `completions/_sec`, whose existence implies a contract even if
nothing here invokes them. State which rule you applied, because the same
scan yields different results under each.

## Step 5: Coverage sentinel

Run `sentinel.sh` from beside this file. It enumerates every tracked file and
compares it against the manifest in `profile.md`, and it additionally
enumerates the gitignored dependency surfaces listed in `profile.md`'s
`## Gitignored surfaces` section, which a tracked-file enumeration cannot see.

It must exit zero. A non-zero exit means either a tracked file no persona
accounts for, or a manifest row that no longer matches anything. Both are
blocking findings, reported as **unaudited surface**, with the file listed.
An unaudited file is not a silent omission; it is the finding.

A sentinel that has never been run is an unverified claim about a checker. Run
it, and quote its output in the report.

## Step 6: Apply the twelve personas

Apply each persona in `profile.md`, in the ranked order given there. Each is
bound to concrete `file:line` anchors in this repository; read those anchors,
then follow the call graph outward to whatever they actually reach.

A persona that could be pasted into an audit of an unrelated repository is
not bound. If a persona cannot be bound to anything real in the current tree,
narrow it until it is, or replace it with a dimension this repository
actually has — keeping the count at twelve, so the replacement takes the same
number. Never renumber, never merge two dimensions into one, never drop one
because it feels thin. If a dimension genuinely has nothing, it is marked N/A
in `profile.md` with its reason and is reported as such.

Mechanical dimensions are decided by scanner, not by reading. Use this
repository's own scanners where they exist — the two `tests/*.sh` suites and
the hub checkers — and say which one you ran; where none exists, say that the
verdict is a reading and not a scan.

## Step 7: Cross-validate by disproof

Do not re-read your own findings and agree with them. For each candidate
finding, try to break it:

- Open the cited line. Does it say what you claimed?
- Construct the failing case. Name the input, the code path, and the wrong
  output. If you cannot write the input down, you do not have a finding.
- Search for an existing test that already prevents it. A finding a passing
  test already covers is not a finding. Check `tests/test_install.sh` and
  `tests/test_sync_guard.sh` before claiming a gap in install or sync
  behavior.
- Search for a guard elsewhere: a caller that validates, a constant that
  makes the case impossible, a configuration default, the `-x` executable
  guards in `bin/sec`, an exit code checked upstream, a constraint you
  missed.

Dispatch the disproof to a fresh agent that receives **only** the file path
and the quoted evidence, never your reasoning.

Record a verdict per finding: `CONFIRMED`, `REJECTED`, or `MODIFIED`, with
the reason. Rejections are part of the deliverable, not failures; they are
what makes the confirmations trustworthy. A run that rejects nothing should
be treated as a sign the verification was superficial, not as evidence of a
clean repository. Only confirmed and modified findings reach the report.

## Step 8: Reconcile against the tracker

This repository's tracker is GitHub issues on `atalby/sec-cli`. Read live
state; never assume it from memory or from `HISTORY.md`:

    gh issue list --repo atalby/sec-cli --state all --limit 100

Reconcile each confirmed finding against it: which findings are already
filed, with issue numbers. Propose new issues; **do not file them unless
instructed**.

Also reconcile the reverse direction, which is where this repository leaks:
open issues whose implementing code is absent, partial, or wrong, and closed
issues whose closing commit did not actually land the described change. A
commit message that says `closes #N` is not a closed loop when the change
reverted or never shipped.

Sequence the result into phases ordered by risk reduction, so the order is a
recommendation rather than a list. State what depends on what.

## Step 9: Propose documentation alignment

Propose documentation corrections **separately** from code findings, each
with replacement text. They are cheaper and safer than correctness work and
must not compete with it for attention.

Verify every `file:line` the documentation cites still resolves to what it
names. A confidently-wrong document is worse than a vague one. Pay particular
attention to the version banner convention: the hub's banner checker reads
the **first** regex match in each file, so a load-bearing banner line and a
prose history entry that legitimately lists many versions must not be
confused for each other.

## Step 10: Effort

Estimate each finding with a Fibonacci effort using only 1, 2, 3, 5, 8, and
13. No intermediate values; false precision is noise.

Add a dependencies column wherever a finding cannot proceed alone. In this
repository that column is load-bearing: a large share of open work is blocked
not on code but on a decision that alters a preserved contract, on a hub-side
fix in another repository, or on approval to touch an external service.

## Step 11: Write the report

Write all three artifacts into `docs/360/runs/<YYYY-MM-DD-HHMMSS>/`.

`report.md`, containing, in this order:

1. Scope: full or scoped, and exactly what was dropped if scoped.
2. The re-derivation corrections from Step 3.
3. The forensic-scan results from Step 4.
4. Unaudited surface from Step 5, including anything gitignored.
5. The confirmation table from Step 7, with every rejection and its reason.
6. Confirmed and modified findings, each with severity, consequence, evidence,
   and effort.
7. The sequenced backlog with issue numbers where they exist.
8. Documentation proposals with replacement text.
9. The stated limits.
10. The timing block.

`findings.json`: one object per confirmed finding with `id`, `severity`,
`persona`, `file`, `line`, `claim`, `consequence`, `evidence`, `effort`,
`verdict`. Plus a `rejected` array of the same shape minus `effort`. Validate
against that shape before writing; structured output exists so a later run can
diff against this one and skip what is already known.

`timing.json`: `started_at`, `finished_at`, `duration_seconds`, and the
per-persona breakdown.

Maintain a resumable checkpoint beside them so an interrupted run continues
rather than restarts.

## Regenerating this skill

This section is the entry point for the `360-check-update` bridge in every
harness. Loading the skill in refresh mode means executing this section, not
the eleven steps above.

Refresh is bounded, local, and needs no internet — this repository learns it
has changed from itself. In order:

1. Diff this skill against the current tree and re-execute every sentence
   that describes the repository. A skill from a previous run is a hypothesis
   about the current tree, not a record of it. This includes numbers and it
   includes claims the skill makes about its own status, such as whether it
   is registered and whether that registration passes its checker.
2. Re-run the baseline commands in `profile.md`'s `## Commands (executed)` and
   replace the recorded output with the new output. Never carry a number
   forward. If a command no longer exists, record that it does not exist and
   search the four sources again (manifest, `Makefile`, CI configuration,
   contributor documentation) before recording an absence.
3. Re-derive the external integration list, the maturity tier, and the twelve
   persona anchors from the tree.
4. Regenerate the coverage manifest from `git ls-files`. Assert the manifest
   covers every tracked file rather than eyeballing the diff: a partial edit
   that drops rows is invisible in the diff and obvious to the sentinel. A
   renamed file is a new row; a deleted file is a deleted row.
5. Re-enumerate the gitignored surfaces on disk and reconcile them with the
   manifest. A live dependency surface that appears and is unclaimed is an
   unaudited surface, not a non-event.
6. Re-run `sentinel.sh` and record its output. Refresh still runs the sentinel.
7. Record this refresh's own duration. Refresh is a measured activity too.
8. Re-check every harness bridge against the canonical section headings, by
   name. A bridge naming a section that does not exist is a broken entry point
   that looks finished.
9. Re-run `python3 ~/sandbox/hyer/scripts/check_skill_registry.py` and confirm
   the registry row for this skill still passes.
10. Report what changed. **Do not commit.** Committing is the operator's
    decision, not the refresh's.

Refresh edits only `SKILL.md`, `profile.md`, `sentinel.sh`, and the bridges.
It never edits this repository's source, tests, fixtures, or documentation.
The skill is the instrument, and the instrument re-tunes itself; the subject
under audit does not.

## Known limits of this audit

Stated so a reader can calibrate the findings rather than over-trust them.

- Cross-validation by disproof reduces false positives; it cannot catch a
  false negative. A real defect nobody thought to look for is invisible to
  this instrument.
- Coverage numbers are a floor, not a proof. `sentinel.sh` proves every
  tracked file is *accounted for* by some persona. It does not prove any
  persona read it.
- Any finding about a provider CLI, a cloud account, or the production sync
  path is a code-and-configuration reading, not observed behavior. This audit
  never executes `sec sync` for real, never authenticates to a live vault,
  and never calls GCP or GitLab write APIs; the sync guard suite itself runs
  against a shimmed `gcloud` with `GITLAB_TOKEN` unset.
- Two runs over identical code will differ in duration and may differ in
  findings. Treat a changed verdict on unchanged code as a signal to re-derive,
  not as noise.
- Where a mechanical dimension had no scanner available, the verdict is a
  reading, not a scan, and must be labelled as one. A model reading source is
  not `pip-audit` — and this repository has no manifest for `pip-audit` to
  read, which is itself a persona 8 finding rather than a clean bill.
- Persona anchors are only as current as the last refresh. Step 3 exists to
  catch drift, but a run that skips Step 3 has no drift detection at all.
- This repository's open backlog is small but its gate is partially blind
  (the hook's test step does not recognize `tests/*.sh`, issue #2). An audit
  that treats "the hook is green" as "the suite ran" will systematically
  over-report the testing state.
