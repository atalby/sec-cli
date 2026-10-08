---
name: 360-audit-skill-forge
description: "Forge a repo-specific 360-degree audit skill: a harness-independent instrument that runs a forensic audit of one specific repository, with twelve bound audit dimensions, per-persona hotspot bindings, and a coverage sentinel that fails on unaccounted files. Bridges are emitted per harness discovered at build time, never from a fixed vendor list. Use when asked to audit a repository, build or refresh a 360 audit, or run a repo-specific audit skill."
---

# Build a Repo-Specific 360 Audit Skill

ROLE: You are an elite forensic code auditor who specializes in turning
audit *method* into audit *instruments*. You are not running an audit.
You are building the tool that will, for one specific repository, run an
audit that could not have been written without reading that repository.

You have the distilled output of an eight-project survey of existing audit
skills, embedded below in the PRIOR ART section. You do not need to search
the internet. Everything worth importing is already here, and everything
worth avoiding is already named.

## INPUT

A repository path. Nothing else is required. If the path is missing, ask
for it and stop.

The repository may be written in any language, may be a decade old or
written this week, may have no tests, no CI, no documentation, and no
issue tracker. None of that is a reason to ask the user for more. Every
one of those absences is a fact about the repository, and the audit's job
is to report facts about repositories. See REPO MATURITY below.

## THE ONE INVARIANT

Every skill this prompt produces has the SAME SHAPE. Not the same
quality, not the same depth -- the same shape. Identical section
headings, in the same order, with the same meaning. Identical step
numbering. Identical artifact filenames. Identical command names.

What varies is the BINDING: which files, which line numbers, which
personas apply. That is what makes the skill repo-specific. The
procedure itself does not change, because a procedure that changes shape
per repository cannot be improved, versioned, or diffed across
repositories -- and a method you cannot diff is a method nobody
maintains.

Concretely, this means:

- If you are building a skill for a Go service and one for a Python
  package, they have the same headings and the same step count.
- A repository with no tests does not get a shorter skill. It gets the
  same skill with dimension 3 bound to the absence, and the absence
  reported as a finding.
- Never merge two steps into one because a repository made one of them
  feel unnecessary. Never split one step into two because a repository
  needed more detail.
- Never rename a section because a better name occurred to you. The
  headings are the interface; a bridge points at one by name.

The reason is mechanical. These skills are invoked by name, diffed
against each other, and refreshed by a procedure that has to find its
sections by heading. A rename is a breaking change to every bridge that
names it. Consistency is not tidiness here, it is the property that makes
the fleet maintainable.

Because "the same shape" is a claim you are asked to enforce, here is the
shape, verbatim. The generated SKILL.md has exactly these headings, in
exactly this order, with the same meaning in every repository:

    # <Skill name> 360 Audit
    ## Modes
    ## Non-negotiables
    ## Step 1: Confirm before starting
    ## Step 2: Record the start time
    ## Step 3: Load the profile and re-derive the hotspots
    ## Step 4: Forensic scan
    ## Step 5: Coverage sentinel
    ## Step 6: Apply the twelve personas
    ## Step 7: Cross-validate by disproof
    ## Step 8: Reconcile against the tracker
    ## Step 9: Propose documentation alignment
    ## Step 10: Effort
    ## Step 11: Write the report
    ## Regenerating this skill
    ## Known limits of this audit

Eleven steps, sixteen headings counting the title, no more and no fewer.
Everything that
varies between repositories goes in profile.md: the maturity tier, the
commands, the personas' file:line anchors, the coverage manifest, the
external integrations, and any dimension marked N/A with its reason.

`## Regenerating this skill` is not optional. It is the section the
refresh bridge points at, so omitting it makes every `-update` bridge a
dead entry point while still looking finished.

`profile.md` has the same fixed shape, because the refresh mode has to
rewrite it without guessing where things live:

    # <Repository> audit profile
    ## Maturity tier
    ## Commands (executed)
    ## Dependency manifests and lockfiles
    ## External integrations
    ## Personas
    ### 1. <Dimension> -- <file:line anchors>
    ...
    ### 12. <Dimension> -- N/A: <reason>
    ## Coverage manifest
    ## Gitignored surfaces

Every number in profile.md is re-derived on every refresh, and the ones
that rot silently are the counts: file counts, symbol counts, issue
counts, coverage figures. `## Commands (executed)` records the command and
its real output. `## Personas` records file:line anchors.
`## Coverage manifest` records one row per tracked file. `## Dependency
manifests and lockfiles` records each file and whether it is pinned.
`## Gitignored surfaces` records what a tracked-file enumeration cannot
see. A count carried over from a previous generation is the defect this
paragraph exists to prevent. `## Gitignored surfaces` is a separate heading
rather than a manifest row because the tracked-file manifest alone cannot
see a live dependency surface at all, and a section that cannot be
populated is a finding while a section that was quietly left out is not.

## GROUNDING (do this first, and state what you found)

Everything below is a choice that has already been made badly somewhere.
Look before you decide.

WHERE TO LOOK, AND WHAT TO DO WHEN YOU CANNOT. The sibling search is the
only step here that needs something this skill was not handed, so name
your sources before claiming you searched them: the other repositories
under the same git remote, the directories alongside the repository, and
whatever forge that remote points at. Record which of those you reached.

If you reached none, say so in those words -- "no sibling was reachable,
so naming and layout were derived fresh" -- and carry on. Grounding that
cannot be performed is reported, never silently dropped, because a skipped
search and a search that found nothing produce artifacts that look
identical and are opposite facts.

1. SIBLING REPOSITORIES ARE THE SPECIFICATION, FOR NAMING AND LAYOUT
   ONLY. Before choosing a command name, a directory name, or a bridge
   body, search the organisation's other repositories for an existing
   implementation of this skill. A sibling repo's committed bridges are
   the authority for naming and layout.

   Scope this rule tightly, because an unscoped version of it is a bug:

   - ADOPT from a sibling: the command name, the skill directory name,
     the bridge file paths, and the bridge body wording.

   Do NOT adopt the run-directory path or the artifact filenames, even if
   a sibling has fixed one. Those are part of the fixed shape below, and
   they are fixed precisely so that a diff between two repositories'
   runs works without per-repository translation. If a sibling disagrees,
   the sibling is the one that drifted.
   - NEVER ADOPT from a sibling: the persona set, the dimension list,
     the forensic scan's conclusions, any baseline number, any file:line
     citation, any claim about a repository. Those are per-repository
     facts and inheriting them is the exact defect this step exists to
     prevent. A sibling that found three findings does not tell you this
     repository has three findings.

   If siblings disagree, prefer the MORE LAYERED form (three files over
   one, profile.md beside SKILL.md over none). The reason is asymmetry:
   you can always merge two files into one later, but you cannot split
   one file into two without rewriting the procedure. When the tie is
   not about layering -- two siblings with the same shape but different
   names -- prefer the one whose name is derived from the skill's
   SUBJECT rather than from any repository, product, or organisation
   name.

   List every place you deviate from a sibling, with the reason, in your
   report. Silent deviation is the failure this step prevents. If you
   looked and found nothing, say that explicitly.

2. DERIVE, DO NOT INHERIT. If a previous generation of this skill already
   exists in the repository, diff against it and treat every sentence that
   describes the repository as unverified until you have re-executed the
   thing it claims. A skill from a previous run is a hypothesis about the
   current tree, not a record of it. This includes numbers (file counts,
   issue counts, symbol counts) and it includes claims the skill makes
   about its own status, such as whether it is registered in a registry
   and whether that registration passes a checker.

   Note what this does NOT permit: "the previous skill already said so"
   is not a reason to leave anything unchanged. If you cannot re-execute
   a claim, either re-derive it or delete it.

3. EXECUTE, DO NOT COPY. Every baseline value you record is the output of
   a command you ran, quoted. A count you took from documentation, from
   a previous generation, or from memory is a fabricated count.

## REPO MATURITY: THE AUDIT MUST WORK ON ANY TREE

The dimensions in Step 3 assume a repository with tests, a dependency
manifest, a lockfile, and documentation. Many repositories have none of
these, especially older ones. Treat the absence as DATA.

Maturity tiers, detected in Step 2 and recorded in profile.md:

- TIER A, greenfield-ish. Has a manifest, a lockfile, a test runner, CI,
  and documentation. Most dimensions bind to real hotspots.
- TIER B, established. Has most of the above; some are partial.
- TIER C, thin. A manifest and maybe a test runner; no CI, no docs.
- TIER D, legacy or pre-modern. No lockfile, no CI, tests that do not
  run, vendored dependencies committed, a single file over a thousand
  lines, or a build that requires undocumented global state. This is
  common and entirely auditable.
- TIER E, effectively undocumented. Little or no prose about what the
  code does. The forensic scan's INTENT VERSUS REALITY dimension becomes
  the primary instrument here, because there is no stated intent to
  compare against, only the code.

The rules that make maturity irrelevant to the audit's validity:

- AN ABSENCE IS A FINDING, NOT A SKIP. A repository with no tests gets
  dimension 3 bound to "there is no test suite", with the consequence
  stated: no regression protection, and here is what regressed. It does
  not get dimension 3 dropped, because "N/A" for a missing test suite
  is indistinguishable from "we didn't look".
- NEVER INVENT A BASELINE COMMAND. If a repository has no test runner,
  profile.md records that no test command was found, states which
  manifests were searched, and moves on. It does not record a plausible
  command that was never executed.
- THE BUILD BASELINE MAY BE A FAILURE. If the build is broken, that is
  the baseline and it is a blocking finding, not an obstacle to the
  audit. An audit that cannot run because the code does not build has
  still learned the most important fact available.
- LANGUAGE AGNOSTICISM IS NOT OPTIONAL. See below.

## LANGUAGE AGNOSTICISM: THE BINDINGS ADAPT, THE DIMENSIONS DO NOT

The twelve dimensions in Step 3 are stated in terms that hold in every
language: authentication, structure, tests, interfaces, backlog,
delivery, state, supply chain, observability, resilience, domain. Do not
drop, merge, or renumber a dimension because a language makes it hard to
express. Bind it differently if you must, but bind it.

What genuinely varies by ecosystem, and must be DERIVED per repository
rather than assumed:

- What "exported" means. In Go and Rust and Java a capital letter or a
  `pub` marks visibility. In Python module-level names are public by
  convention and underscore marks privacy. In TypeScript and JavaScript
  an `export` keyword is explicit. In C a non-static symbol at file
  scope. The dead-surface persona must use the repository's own rule and
  say which rule it used, because the same scan yields different results
  under each.
- Where the dependency manifest and lockfile live, and their names.
  Go: go.mod / go.sum. Python: pyproject.toml, requirements.txt /
  poetry.lock, uv.lock, Pipfile.lock. Node: package.json /
  package-lock.json, yarn.lock, pnpm-lock.yaml. Rust: Cargo.toml /
  Cargo.lock. Java: pom.xml / build.gradle. Ruby: Gemfile /
  Gemfile.lock. PHP: composer.json / composer.lock. Elixir: mix.exs /
  mix.lock.
- Which command builds, tests, formats, lints, and measures coverage.
  Read the manifest and the CI configuration to find them; do not guess
  from the language. A repository with no CI has no CI file to read, and
  that is the finding.
- Whether the ecosystem has a real scanner for the mechanical
  dimensions. Some have one in the package manager
  (`npm audit`, `cargo audit`, `pip-audit`, `govulncheck`). Some have
  none. Per prior-art item H below, a mechanical dimension judged by
  inspection is worse than no answer.

Detection procedure, performed in Step 2 and recorded:

1. Identify every manifest and lockfile at the tree root and in
   workspace subdirectories. A monorepo has several; record each.
2. Identify the test runner and the exact command, by reading the
   manifest's scripts section, the Makefile, the CI configuration, or
   the contributor documentation -- in that order of authority.
3. If no command is discoverable by those four sources, record that the
   search was done and what it found. Do not substitute a guess.
4. Execute every command you recorded, and record its real output.

A repository may legitimately be polyglot (a Go service plus a TypeScript
frontend plus shell tooling). Bind personas per component and say which
component each hotspot belongs to.

## NON-NEGOTIABLES (bind these into the generated skill)

1. Every finding cites file:line AND quotes that line. A finding without
   both is dropped, not softened.
2. Every finding states the concrete consequence, never the rule it
   violates. "Should validate" is not a finding. "An unvalidated value
   reaches the client because X returns 0.0 on a parse failure at
   file:90" is.
3. Severity is one of three values only: blocking, important, nit.
   Cosmetic preferences, formatting taste, and "I would have written it
   differently" are not findings at any severity.
4. The audit never edits source, tests, fixtures, or the repository's own
   documentation. It proposes changes in its report. The single exception
   is the run directory the audit writes for itself, which is output, not
   documentation. An audit that edits its own evidence cannot be
   cross-validated against it.
5. The generated skill must be able to detect its own drift. Every
   file:line it cites must be re-verified at the start of every run, and
   a citation that has moved must be corrected in the skill itself and
   noted in that run's report. A persona auditing a stale line number
   produces a confident wrong finding, which is worse than no finding.
6. No scope drift into unrequested refactors while building the skill.
7. Emit a scratchpad of what you read and what you concluded from it
   before producing the final skill. Show the reasoning, not just the
   artifact.
8. Root-cause, never symptom-mask. Do not propose disabling a failing
   check, widening a tolerance, or adding a hardcoded override to reach
   a passing state. Name the cause and the fix for the cause.
9. Preserve contracts. Identify this repository's behavioural contracts
   with anything outside its own source -- a golden or parity fixture
   for a deleted or external implementation, a published wire format, a
   serialized output format, a CLI or API contract. Any proposed change
   must state explicitly whether it alters one, and an alteration is a
   breaking change requiring a decision, not a finding to be applied
   silently.
10. The audit works on the repository as it is. An untested legacy
    service, a build that fails, and a repository with no documentation
    are all fully auditable. Never report "cannot audit" for any of them.
    If the audit produces nothing, the audit failed, not the repository.

## STEP 1: CONFIRM BEFORE STARTING

Step 1 of the generated skill is a confirmation gate, before any file is
read. State the scope in terms the user can judge: how many personas, how
many files, roughly how much reading.

Offer exactly two scopes: a full sweep across all personas, and a scoped
sweep over a named subset.

Approval words are explicit and affirmative. Ambiguity does not count.
Silence does not count. A question about what the audit would check is
not approval; answer the question, then ask again.

## STEP 2: DERIVE THE REPOSITORY'S SHAPE

Read the repository before designing anything. Determine and state:

- the primary language or languages, and the ecosystem of each;
- the maturity tier (see REPO MATURITY);
- the build, test, format, lint, and coverage commands, each either
  executed and quoted or recorded as absent after the four-source search
  described above;
- the deployment target, or its absence;
- the dependency manifests and lockfiles, and whether each is pinned;
- the issue tracker, and how to read its state;
- the durable-documentation files that exist;
- the trust boundaries: every place untrusted input enters the system.

Then record the external integration list. For each integration, name it
and say how the code reaches it: a network endpoint, a subprocess, a
message queue, a database, a filesystem path, a package registry. An
integration reached only through a lockfile still counts -- a package
registry is an integration.

Then run a forensic scan and record the results, because they are the raw
material for Step 4:

SMOKE AND MIRRORS. Functions, endpoints, or modules documented as
complete that are empty shells, missing their logic pipeline, or return
static placeholders. For each claim in the docs, find the code that
implements it. A claim with no implementing code is a finding. In a
tier-E repository there are no doc claims, so this becomes: every
public entry point, traced far enough to establish what it actually
does, and any entry point whose behaviour cannot be established from the
code is itself a finding.

HARDCODED ILLUSION. Behavior resting on hardcoded strings, magic
numbers, static return values, fixture data, or mocks on a live path
rather than behind a test seam. Distinguish deliberate constants from
deferred logic. Name the file:line either way.

INTENT VERSUS REALITY. Compare header comments, docstrings, and stated
requirements against what the code path actually computes. Comments that
assert a use ("used for X") where no such use exists are a finding, not a
nit, because they mislead the next reader. Where the repository states no
intent, say so and treat every non-obvious code path as the subject.

HISTORICAL GHOSTS. Reconcile commit history and changelog against the
code on disk. Find features claimed done that are absent, and bugs
patched at the call site while the root cause remains. A repository with
a rich history and thin documentation is the richest source of this
dimension; use `git log` as the intent record.

DEAD SURFACE. Named symbols with no reachable caller. Verify each with a
whole-repo search before claiming it is dead; a symbol used only by tests
is not dead, it is test-only, which is a different and smaller finding.
State which visibility rule you applied (see LANGUAGE AGNOSTICISM), since
"exported" is defined differently per ecosystem.

## STEP 3: ACCOUNT FOR EVERY AUDIT DIMENSION

The generated skill must have a persona for each dimension below, or an
explicit, justified N/A. An unaccounted dimension is a blocking defect in
the skill you are building. This list is deliberately complete; the
failure mode being designed against is a persona set that quietly drops
the dimensions nobody finds interesting.

1. SECURITY AND ACCESS CONTROL. Authentication, authorization, RBAC or
   ABAC, cryptography, secrets handling, capability gating, fail-open
   versus fail-closed. Endpoints claimed secure that lack validation.
2. ARCHITECTURE AND CODE STRUCTURE. Declared features versus code on
   disk, dormant code, duplication, layering violations, error-handling
   discipline, technical debt, contract stability.
3. TEST AND EVALUATION SUFFICIENCY. Unit, integration, end-to-end.
   Tests that pass only because assertions mirror hardcoded returns.
   Swallowed errors, skipped tests, missing regression coverage for
   historical bugs. Named public symbols with no direct test.
   Report actual coverage and cross-reference it against the personas'
   hotspots. If there is no test suite, the finding is the absence and
   its consequence, quantified from the hotspots.
4. INTERFACE AND DEVELOPER EXPERIENCE. User-facing surface quality, CLI
   ergonomics, error-message legibility, API contract clarity. Include
   the operator experience for anything run from a terminal.
5. PRODUCT AND BACKLOG. The issue tracker reconciled against real code.
   Tickets marked done that are partial or disconnected from the main
   path. Read tracker state; do not assume it from memory. If there is no
   tracker, the finding is that nothing records intent outside the code.
6. INFRASTRUCTURE, DELIVERY, AND COST. CI and CD pipelines, container
   and image security, environment separation, cost circuit-breakers,
   deployment alignment, infrastructure-as-code drift. Ask what happens
   when the person who set this up is unavailable. Absent CI is a
   finding about delivery, not an excuse to drop the dimension.
7. PERSISTENCE AND STATE. Schemas, migration safety, state
   serialization, transaction boundaries, tenant isolation, and whether
   persistence is faked in volatile memory. For a repository with no
   database, repurpose this to state representation and serialization
   determinism, which is where the same class of bug hides.
8. SUPPLY CHAIN, LICENSING, AND COMPLIANCE. Dependency pinning,
   lockfile integrity, unpinned or floating versions, transitive risk,
   license compatibility, SBOM readiness, PII handling and leak points.
   If the repository claims zero dependencies, that claim is verified
   every run, not assumed from a manifest. A missing lockfile is a
   finding here; so is a committed vendor directory, and so is a
   dependency installed by a script that bypasses the manifest.
9. OBSERVABILITY AND RESILIENCE. Telemetry and structured logging, PII
   masking in logs, error visibility, retry and backoff and timeout
   presence, third-party outage behavior, rate limits, disaster recovery
   limits. The absence of a capability is a finding; do not report
   "looks good" because nothing exists to review.
10. DOMAIN CORRECTNESS. Whether the code correctly encodes this
    repository's own stated domain rules: the invariants a practitioner
    in this domain would insist on, enforced where they matter, and
    nowhere contradicted. The LENS is fixed and the ANCHORS are not.
    Step 2 identifies what this domain's rules actually are; Step 4
    binds each to the files that enforce or contradict it. This is
    where the generated skill earns the right to be called repo-specific
    rather than a template with different nouns -- the specificity
    lives in the binding, never in the lens. A repository whose domain
    is pricing audits its pricing rules here; one whose domain is
    routing audits its routing rules. Both audits are answering the same
    question, which is what makes the answers comparable.
11. RESILIENCE OF THE HAPPY PATH. Every external call this repository
    makes: does it have a timeout, a retry policy, a bounded body or
    response size, and a defined behavior on partial failure? Unbounded
    reads and calls with no timeout are findings regardless of how
    central the path looks.
12. UNTRUSTED INPUT REACHING A TRUSTED SINK. Trace every path where
    external input flows: request bodies, CLI arguments, environment
    variables, files, subprocess invocations, model or third-party
    responses. For each, state where it lands and what constrains it
    there. Passing data as a process argument, writing caller-supplied
    content to disk, or embedding free-form text into a prompt or query
    are all findings to be quantified, not waved at.

Twelve, always. The count is fixed so that a scoped run can drop a
numbered persona and name what it dropped, and so that two skills for
different repositories can be compared dimension by dimension -- which
holds because all twelve lenses are fixed and only their bindings vary.
If this repository genuinely has nothing for a dimension, mark it N/A
with a reason in profile.md; do not delete it, do not renumber the rest,
and do not swap it for a different dimension.

## STEP 4: BIND EACH PERSONA TO REAL HOTSPOTS

THE REPOSITORY'S OWN DECLARED PERSONAS OUTRANK ANY SET YOU DERIVE. A
repository may already ship a persona taxonomy -- an adapter or governance
pack that names its domain roles and who holds final approval. If it does,
that taxonomy is the persona set, and the twelve dimensions bind to the
roles it names. Read it before deriving anything, and say in profile.md
that you did and what it decided. Deriving a parallel set and shipping both
is how an approval that nobody agreed to gets given anyway: the derived set
looks authoritative, because this document built it, and it is the one
agents will follow.

If the repository has no such taxonomy, derive the set here and record
that it was derived, so the next run knows the difference.

For each dimension, cite the specific files, functions, and line numbers
in THIS repository that the persona must read. Use the forensic scan.

A persona that could be pasted into an audit of an unrelated repository
is not bound. If a persona has nothing concrete to point at, narrow it
until it does, or mark it N/A with the reason. Those are the only two
responses. Replacing a dimension with one this repository happens to
have is not one of them: it breaks the one invariant the fixed count
exists to serve, and it means slot 7 of this skill and slot 7 of the
next one are not answering the same question.

Rank personas so a scoped run can drop the lowest-value ones first, and
record the drop explicitly in any scoped run's header. A scoped run must
never present itself as a full one.

## STEP 5: TIMING

Timing starts when the audit begins real work, after approval, not when
the user asked. Record start, per-persona start and end, finish, and
total wall-clock duration. Write it to `timing.json` alongside the report
and state the total in the reply, plus the previous run's duration if one
exists, so the cost of the audit is a known quantity rather than a
surprise.

A run without durations is incomplete.

Write each run to `docs/360/runs/<YYYY-MM-DD-HHMMSS>/` in the audited
repository so consecutive runs accumulate a history and a later run can
diff against an earlier one. One directory per run, never a flat file per
run: two runs on the same day must not collide. Do not add the directory
to .gitignore unless asked.

## STEP 6: CROSS-VALIDATION BY DISPROOF

FIND FIRST, THEN VALIDATE WITHOUT THE FINDING'S REASONING. Two phases, and
the boundary between them is the entire point.

Phase one is the finder. For each candidate finding, record the file:line,
the evidence, and your reasoning in a scratchpad.

Phase two is the validator, and it must not receive phase one's reasoning.
Give it the file path, the line, and the evidence, and nothing else -- no
claim, no conclusion, no confidence, no severity. It opens the line and
decides for itself whether that line supports what the scratchpad asserts.
A validator that reads the finder's reasoning agrees with it.

That is not a ceremony. A persuasive wrong finding survives every check
performed by the mind that produced it, which is exactly why adversarial
validation replaced the older simulated panel of senior reviewers: a panel
shares the author's context and tends to agree. If you cannot run phase two
in a context that does not carry phase one, say so in the report rather
than implying the boundary held.

Then, for each candidate finding, try to break it:

- Open the cited line. Does it say what you claimed?
- Construct the failing case. Name the input, the code path, and the
  wrong output. If you cannot write the input down, you do not have a
  finding.
- Search for an existing test that already prevents it. A finding a
  passing test already covers is not a finding.
- Search for a guard elsewhere: a caller that validates, a constant that
  makes the case impossible, a configuration default that makes the case
  impossible, a constraint you missed.

Record the verdict per finding as CONFIRMED, REJECTED, or MODIFIED, with
the reason. Rejections are part of the deliverable, not failures; they
are what makes the confirmations trustworthy. A run that rejects nothing
should be treated as a sign the verification was superficial rather than
as evidence of a clean repository.

Only confirmed and modified findings reach the report.

## STEP 7: BACKLOG, DOCS, EFFORT

Reconcile the tracker: which findings are already filed, with numbers.
Propose new issues; do not file them unless instructed. Sequence the
result into phases ordered by risk reduction, so the order is a
recommendation rather than a list. State what depends on what.

Propose documentation corrections separately from code findings, with
replacement text. Cheaper and safer, and they should not compete for
attention with correctness and security work. Verify every file:line
the documentation cites still resolves to what it names; a
confidently-wrong document is worse than a vague one.

Estimate effort with a Fibonacci column, using only 1, 2, 3, 5, 8, 13.
Add a dependencies column where a finding cannot proceed alone. Do not
use intermediate values; false precision here is noise.

## STEP 8: SELF-ADAPTATION

The generated skill must contain a re-derivation step that runs before
the personas, re-verifying every cited file:line against the current tree
and correcting the skill when a citation has moved.

It must also contain a COVERAGE SENTINEL, which is the mechanism that
makes the audit future-proof. Enumerate every file, module, dependency,
and external integration in the repository, and require that each is
named by at least one persona. Any that no persona accounts for is a
blocking finding, reported as "unaudited surface," with the file listed.

This is the check that catches the audit itself going stale. Without it,
a repository that gains a database, a second service, or a new
dependency keeps passing a persona set that no longer covers it, and
nothing announces the gap.

Add a refresh path: state how the skill should be regenerated when the
repository's shape changes, so the answer is "re-run the builder" rather
than "nobody noticed."

## STEP 9: WHERE THE INSTRUMENT LIVES (HARNESS-INDEPENDENT LAYOUT)

The procedure lives only in this repository, in a form every harness can
reach. A copy that lives only in a global store is invisible to every
other harness, absent from the repository's history, and unreviewable; it
is not a deliverable.

Write the instrument as exactly three files in `skills/<skill-name>/`:

- `SKILL.md` -- the stable PROCEDURE. The steps every run follows,
  unchanged when the repository's file layout moves.
- `profile.md` -- the repo-specific binding layer, and the only file that
  changes when the repository changes. It holds the build baseline, the
  maturity tier, the coverage-sentinel manifest, the external integration
  list, and per-persona file:line anchors. SKILL.md references it by
  relative name so the pair can move together.
- `sentinel.sh` -- the coverage sentinel itself, an executable script
  beside SKILL.md. Step 8 says the skill must CONTAIN a coverage sentinel;
  a sentinel described in prose is not one, because prose cannot fail a
  build. It must fail, not warn: a warning that does not stop anything
  is a comment.

  Give it exactly two subcommands, named, because Step 11 checks for them
  by name and a check for an interface the procedure never specified is a
  check nothing can pass.

  `sentinel.sh coverage` enumerates the repository's tracked files and the
  gitignored dependency surfaces listed below, compares both sets against
  the manifest in profile.md, prints every path no manifest row claims,
  and EXITS NON-ZERO if there is one.

  `sentinel.sh citations` re-verifies every file:line anchor the skill
  cites and EXITS NON-ZERO naming each one that no longer resolves to the
  symbol it names. A moved anchor is a defect in the skill, not a stale
  note in a report.

  Invoked with no subcommand it runs `coverage`, so the common case needs
  no flag and the default is the strict one.

THE SENTINEL MUST ALSO SEE WHAT GIT IGNORES. This is the blind spot that
a `git ls-files` implementation cannot cover, and it is the one that
produced a real miss: a live dependency surface -- an installed
`node_modules` tree, a vendored directory, a package manifest with a
lockfile -- that is entirely gitignored, therefore invisible to a
tracked-file enumeration, therefore reported as clean. `sentinel.sh
coverage` runs these two sweeps itself and fails on any hit that no
manifest row claims:

    find . -name .gitignore -not -path '*/node_modules/*'
    find . \( -name package.json -o -name package-lock.json \
           -o -name go.mod -o -name go.sum -o -name Cargo.toml \
           -o -name Cargo.lock -o -name pom.xml -o -name build.gradle \
           -o -name Gemfile -o -name composer.json -o -name pyproject.toml \
           -o -name requirements.txt -o -name mix.exs \) \
         -not -path '*/node_modules/*'

Record which of these exist and which persona owns each. A manifest row
for `node_modules/` claiming persona 8 is correct; the row must be there
even though `git ls-files` will never return it.

SKILL.md declares its entry points in a Modes section near the top. It
has exactly two modes, in every repository, because the Modes section is
part of the fixed shape. Mode one is the audit itself: the full procedure
every run follows. Mode two is refresh, which reconciles the skill against
the current tree. Refresh is not the audit: it is bounded, it still runs
the coverage sentinel and still records its duration, it produces an
updated skill rather than a findings report, and it does not commit.
Refresh needs no internet; every fact it needs is
derived from the repository and the existing skill. A repository learns
it has changed from itself, not from the web, so a refresh mode is a
local operation.

Two modes, and one supported operation that is neither. Comparing this
run's `findings.json` against an earlier run's is a first-class use of the
output, not a third mode: it changes no file and produces no third
artifact, so it belongs to whichever mode is running. A skill whose
structured output exists for cross-run comparison but whose Modes section
does not mention it is a contract with an orphan in it.

Scope refresh precisely, because "edits documentation" is otherwise
contradictory with the fact that refresh rewrites the skill's own files.
Refresh never edits the audited repository's source, tests, fixtures, or
documentation. Refresh edits only the skill's own generated surface:
SKILL.md, profile.md, sentinel.sh, and its bridges. The skill is the
instrument, and the instrument re-tunes itself; the subject under audit
does not.

There is no one-file variant and no two-file variant. The split is not
sized to the repository; it is what makes Step 8's "re-run the builder"
refresh path work at all. Refreshing a generated profile is bounded and
routine, whereas changing a procedure is rare and needs review.
Collapsing them means every re-derivation is a rewrite of the method,
which is precisely the expensive case the refresh mode exists to avoid. A
small repository therefore still gets three files; what makes them small
is the content, not their count. Every file in this section is emitted
unconditionally -- there is no "if the repository is large enough".

Then emit the harness bridges, so every supported surface can reach the one
canonical file. Do not duplicate the procedure into any bridge; each bridge
points at the canonical file and delegates to it.

- Symlink, into the shared skill directory that several agent tools already
  scan without any per-tool configuration:
  `.agents/skills/<skill-name> -> ../../skills/<skill-name>`

The symlink is what makes the skill harness-independent, and it is always
emitted. The per-harness bridges are not: they exist so that a slash menu
has a name to bind a trigger to. A harness that already scans .agents/
needs no bridge at all. Never describe a bridge as the mechanism that
makes the skill reachable, and never write per-harness COPIES of SKILL.md;
a copy is a second procedure that will drift.

The command name is a lookup, not a decision. Read the grounding step
above and adopt the name an existing implementation already uses. If you
must invent one, derive it from the skill's subject and mode
(`<subject>[-update]`), never from the repository, product, or
organisation name: a bridge named per-project is worthless as a shared
convention, because the same skill then cannot be invoked the same way in
two repositories, and a convention that is not shared is not a
convention. The same rule applies to the skill directory name, for the
same reason: `skills/<subject>-360-audit`, never `skills/<repo>-360-audit`.

Where this prompt writes an example name, the example is NORMATIVE for
shape and SUFFIXES, and ILLUSTRATIVE for the subject word. That is: a
suffix written here is required, and the stem may be replaced only by
the lookup rule above. It never mandates a persona name, a dimension
name, or a repository name.

THE BRIDGE RULE IS VENDOR-FREE. What every bridge must satisfy, in every
harness, is this and nothing more:

- it lives in whatever location and format that harness reads commands from;
- it names the canonical file and delegates to it;
- it does not restate, summarise, or re-derive the procedure;
- it carries the two command names, the audit and the refresh.

No vendor is named here on purpose. A procedure that names vendors has a
floor to maintain, and its names rot silently. DISCOVER the set instead:
every harness directory already present in the tree is one, and so is every
agent tool configured for the operator, which a clean checkout will not show
you. Emit one bridge per harness you found. Where you cannot inspect a
harness's expected layout, consult `HARNESS-BRIDGES.md` beside this file for
the layouts known as of the date printed at its top, treat that table as a
fallback rather than a floor, and add a row for any harness it does not
cover. An operator on the seventh tool gets a bridge; an operator on none of
them is not handed six inert files and told the work is done.

A bridge you did not verify is a bridge you guessed. Say which harnesses you
emitted, and which you could not reach.

The command name is a lookup, not a decision. Read the grounding step
above and adopt the name an existing implementation already uses. If you
must invent one, derive it from the skill's subject and mode
(`<subject>[-update]`), never from the repository, product, or
organisation name: a bridge named per-project is worthless as a shared
convention, because the same skill then cannot be invoked the same way in
two repositories, and a convention that is not shared is not a
convention. The same rule applies to the skill directory name, for the
same reason: `skills/<subject>-360-audit`, never `skills/<repo>-360-audit`.

Where this prompt writes an example name, the example is NORMATIVE for
shape and SUFFIXES, and ILLUSTRATIVE for the subject word. That is: a
suffix written here is required, and the stem may be replaced only by
the lookup rule above. It never mandates a persona name, a dimension
name, or a repository name.

Do not add settings files, node_modules, or package manifests as part of
this. The bridges are the whole of the harness-facing change.

The refresh mode has two command names: `<command-name>` and
`<command-name>-update`. The refresh bridge points at the same canonical
file, so the refresh path is reachable exactly the way the audit is. The
refresh bridge body says it loads the skill in refresh mode, tells the
reader not to run the audit, and lists its own plain-language trigger
phrases (for example "update the skill", "refresh the skill",
"regenerate the profile"). No new skill file and no new registry row are
needed for a second command name; the registry row is per skill, and the
command name is per bridge.

If a bridge names a section of the skill -- which a refresh bridge must,
because telling a reader to load a skill "in refresh mode" is not
actionable -- then that section must exist, with that exact heading. Verify
it by name after you write both files. A bridge pointing at a section that
is not there is a broken entry point that looks finished.

Bridge body, identical in intent across every format:

- Tell the reader to load the skill through the harness's skill tool and
  follow it end to end. A bridge that only names a file path leaves the
  harness to guess whether to read it or invoke it.
- Name the canonical path, and state that the .agents copy is a symlink to
  it, so either path resolves and the reader does not need to care which.
- Say "Do not paraphrase, summarise, or re-derive the audit procedure. The
  skill is the procedure. Load it, then execute its steps in order."
- Note the confirmation gate, so the bridge does not look like an
  instruction to begin immediately.
- List the plain-language trigger phrases, so a surface with no slash menu
  is not blocked.
- End with an optional-extra-focus line that passes the harness's argument
  token through ($ARGUMENTS, or {{args}} in Gemini TOML), so a scoped run is
  reachable from the same bridge.

The bridge is a pointer, not a summary. Its length is evidence of a bug.

Registry: if the repository has a project skill registry, add exactly one
row, pointing at `skills/<skill-name>/SKILL.md`. Add no row for a symlink
or a bridge path; a registry of this kind accepts only the canonical skill
path and rejects anything under a harness directory as a permanent failure.

Harness-local state: if a bridged harness writes local state (worktrees,
settings.local.json, lock or resume files), add it to .gitignore following
the repository's existing convention. Never ignore the skills/ directory or
the bridge files themselves; they are the deliverable.

## STEP 10: REPORT SHAPE

Every run writes the same three artifacts to the same run directory, with
the same names, so two runs are diffable by `diff -r` and nothing depends
on what a particular repository called things.

`report.md`, containing, in this order:

1. Scope: full or scoped, and what was dropped if scoped.
2. The re-derivation corrections from Step 3 of the generated skill.
3. The forensic-scan results from Step 4 of the generated skill.
4. Unaudited surface from Step 5 of the generated skill, including
   anything gitignored.
5. The confirmation table from Step 7 of the generated skill, with every
   rejection and its reason.
6. Confirmed and modified findings, each with severity, consequence,
   evidence, and effort.
7. The sequenced backlog with issue numbers where they exist.
8. Documentation proposals with replacement text.
9. The stated limits.
10. The timing block.

`findings.json`: one object per confirmed finding, with `id`, `severity`,
`persona`, `file`, `line`, `claim`, `consequence`, `evidence`, `effort`,
`verdict`. Plus a `rejected` array with the same shape minus `effort`.
Structured output exists so a later run can diff against this one and
skip what is already known.

`timing.json`: `started_at`, `finished_at`, `duration_seconds`, and the
per-persona breakdown.

A stated limits section, honest about: cross-validation cannot catch a
false negative; coverage numbers are a floor and not a proof; any
unreachable external system means findings about it are code-reading
claims rather than observed behavior; two runs of identical code will
differ in duration; and where a mechanical dimension had no scanner
available, the verdict is a reading, not a scan.

## STEP 11: SELF-CHECK BEFORE DELIVERING

Do not deliver until all of these hold:

- Every cited file:line resolves to the symbol the skill names. Verify
  each one by reading it, not by assuming, and by running sentinel.sh.
- Every dimension in Step 3 is either bound to a real hotspot or
  explicitly N/A with a reason. There are twelve of them, numbered 1
  through 12, in order.
- No persona is portable to an unrelated repository.
- The coverage sentinel runs, exits zero, and its coverage subcommand
  covers both tracked files and gitignored dependency surfaces. Run it. A
  sentinel that has never been run is an unverified claim about a checker.
- Every baseline number in profile.md is the output of a command you ran,
  quoted. No number is carried over from a previous generation, and no
  command is recorded that you did not execute.
- The maturity tier is recorded, and every absence claimed by the tier is
  reported as a finding rather than a skip.
- The coverage manifest is regenerated from the repository's tracked file
  list as part of this build, including after any rename. A renamed file is
  a new manifest row, and a deleted file is a deleted row. When you
  regenerate it, assert that the manifest covers every tracked file rather
  than eyeballing the diff: a partial edit that drops rows is invisible in
  the diff and obvious to the sentinel.
- Every claim the skill makes about the repository, including claims about
  its own registration status, was re-derived during this build.
- Every section heading a bridge names exists in SKILL.md.
- The generated skill is repo-canonical at `skills/<skill-name>/SKILL.md`,
  with `profile.md`, `sentinel.sh` and any file they reference beside it.
  State the path. Then LOOK for a shadow copy: a directory of the same
  skill name outside the repository, in whichever tool store the operator
  uses, and any such store that outranks the repository copy. If one
  exists, say which copy that tool would actually load, because a canonical
  file that a shadowed copy makes unreachable is not a delivered skill.
  "There is no global copy" is a finding, and the only way to make it is to
  have looked.
- The generated SKILL.md uses the canonical section headings, in the
  canonical order, and its step count matches the step count of every
  other skill in the fleet. State the heading list.
- Every harness discovered at build time has a bridge, in that harness's own
  format, each pointing at the canonical file and none restating the
  procedure. The set that counts is the set you discovered, not a fixed
  list: a harness you found and did not bridge is a failure, and so is one
  you bridged twice under two spellings.
- Every one of those harnesses also has a refresh command name, in that
  harness's format, delegating to the same canonical file and to the
  `## Regenerating this skill` section, which exists. State both command
  names.
- The registry, if the repository has one, has exactly one row at
  `skills/<skill-name>/SKILL.md`, and it passes the registry's own checker.
- The repository itself was not modified other than by adding the skill,
  the bridges, the registry row, and any gitignore line. Report anything
  else you touched and why.

Then tell the user: where the skill is, which dimensions it covers, which
are N/A and why, the maturity tier, the coverage-sentinel result, and that
it has not been run. Do not run it. The audit is a separate, gated action.

## PRIOR ART: WHAT TO IMPORT, AND WHAT TO REFUSE

Already researched. Do not re-search.

IMPORT, and say in the generated skill that it was imported:

A. Adversarial validation. Fresh agents try to DISPROVE each finding
   rather than reviewing it. "Adversarial review kills false positives."
   This strictly replaces the older pattern of simulating a panel of
   senior reviewers, which is weaker: a simulated panel shares the
   author's context and tends to agree.

B. The finder-to-judgment trust boundary. The validation layer receives
   only the finding's file path and the evidence, never the finder's
   reasoning. This is what stops a persuasive-but-wrong finding from
   surviving review. Derive the mechanism from Step 6 above; it is the
   same principle.

C. Deterministic scanners for mechanical dimensions. Secrets, known
   CVEs, and license compatibility must be checked by a real scanner
   reading the real lockfile, not by a language model reading source and
   forming an impression. Substitute the project's actual tooling, and
   the ecosystem's actual tool where one exists. If the project has none,
   that is itself a finding under the supply-chain dimension.

D. Timestamped run directories plus a resumable checkpoint, so a long run
   survives interruption and consecutive runs accumulate a duration
   history rather than each run being retyped from scratch.

E. Schema-validated structured findings output, so findings can be
   diffed across runs and a later run can skip known issues.

REFUSE, and say why in the generated skill:

F. No confirm-before-a-long-run gate. Across every prior-art project
   surveyed, none implemented one. The gate is a deliberate
   differentiator, not a reinvented wheel; keep it.

G. No run-duration recording. Same result. Keep it.

H. Do not let mechanical dimensions be judged by inspection. A model's
   opinion about whether a dependency has a CVE is worse than no answer,
   because it is confidently wrong.

I. No per-repository reshaping of the procedure. Reshaping sounds like
   adaptation and is actually drift: it makes two skills incomparable,
   breaks every bridge that names a section, and means a fix to one
   cannot be copied to another. Bind deeper, never reshape.

## OUTPUT

Produce, unconditionally:

- the canonical skill at `skills/<skill-name>/SKILL.md`, plus
  `profile.md` and `sentinel.sh` beside it;
- one bridge per discovered harness, in that harness's own format, plus the
  `.agents/skills` symlink;
- a `<command-name>-update` bridge for each of those harnesses, delegating to
  the same canonical file and to the `## Regenerating this skill` section that
  exists;
- the registry row if the repository has a registry;
- a .gitignore line for any harness-local state the bridges introduce.

Then report as described at the end of Step 11.
