# Automated Tooling & Token Efficiency Directives

> Detail module for `AGENTS.md` §8. Loaded on demand — see the Module
> Table at the top of `AGENTS.md`. This file is part of the adopter payload
> (`methodology/adoption.md`: "adopting Hyer means the full payload, not
> a hand-picked subset"), copied alongside `AGENTS.md` and `skills/`.

To keep sessions fast and cheap:

1. **Subagent delegation**: any multi-file investigation, web-search
   sweep, or log analysis spanning >3 files or >2 web pages goes to a
   subagent -- isolated context, and a report at the level this repo
   declares (see `ADAPTERS.md`, "Output verbosity"). "Concise" was
   undefined for a year and every agent guessed; the levels are
   `outcomes`, `reasons` and `full`, and the floor is identical at every
   one: the outcome first, then every failed, blocked, skipped or
   unverified item by name, then any decision the reader owes, then where
   the work is. A report that drops a floor item is non-compliant, not
   terse. It ends with a terminator line, `END OF REPORT`; without it the
   report was truncated and every floor item is unknown rather than
   clean.
   The same level governs every reply an agent makes, not only a delegated
   report: the top-level operator session replies at the declared level too,
   and the floor is never traded for brevity. It also rules out filler --
   no restating the request, no narrating tool calls, no preamble about what
   the reply is going to say.
2. **Targeted editing**: use AST tools or line-range edits, not full
   rewrites or reading whole large files into context.
3. **Prompt caching**: system prompts, skills, and static contract text
   MUST sit at the top of context in unvarying order for cache hits.
4. **Structured queries over raw dumps**: prefer a typed MCP call to
   reading a raw DB dump, DOM HTML, or a full screenshot.
5. **Issue tracker sync**: query task status at Boot (§2), update
   tickets at Document (§3 step 6), no manual prompting needed.
6. **Per-project token/efficiency reporting** (roadmap, adopt only once
   implemented): a reasonable target for Product-tier repos once real;
   don't claim it as a current MUST before then.

## Context Management & Token Optimization

> Mandatory in every session, in every repo that adopts this contract.
> The directives above keep a session cheap; this one says when the
> accumulated context is itself the cost.

### Triggers

Manage context the moment one of these becomes true, not at the end of the turn:

1. **Proactive Management.** The history holds massive terminal output,
   repetitive error logs, or the contents of many files spread across
   more than three consecutive turns.
2. **Milestone Summarization.** A subsystem has been refactored, an
   architectural migration has settled, or a comprehensive test block
   has finished. That is a chapter boundary; close it there.
3. **Redundant State Elimination.** A file already read is being read
   again, or a command already run is being run again.

### Guardrails

1. **Use the harness's native mechanism.** Replace raw background dumps
   with tight one- or two-sentence technical summaries, using the
   summarization, message-trimming or context-cleaning facility the host
   harness provides. Name the facility by its role, never by a product
   or plugin name; this contract stays portable across harnesses.
2. **Protect what is load-bearing.** Active architectural
   specifications, the current system instructions and pending task
   payloads stay intact at all times. A summary that loses a live
   requirement has cost more than it saved.
3. **Do not stall to ask.** Managing token boundaries is a runtime
   requirement, not a decision to escalate. Compress and carry on.

The triggers are habits; the guardrails are what make them safe.

> Enforced by a content test, so the policy cannot be silently dropped:
> `scripts/tests/test_context_management_policy.py`. It cannot be
> enforced behaviourally inside the hub, because the hub's checks are
> static -- they read repository files and commits, never a session's
> context behaviour -- and any proxy predicate for "summarized too
> little" would fire on every commit and have to be muted.

## Dispatching a test author: the frozen-target protocol

> Detail for the `AGENTS.md` §8 subagent-delegation directive, for the case
> where the delegate is an independent test author — the #89 separation,
> where the implementer does not write the tests that grade their own
> work. Every rule below was paid for by a real failure; issue #112 is the
> record of the four that produced them.

An audit's value is that it is independent. An audit of a moving target is
not independent, it is a race, and it can be wrong in the dangerous
direction: a defect that exists at read time and not at run time is
reported closed, and one that appears between them is never seen. The
dispatcher's job is to make the target stop moving before the author
starts.

1. **Name the target.** When dispatching, name the commit under test *and*
   its tree fingerprint. The author grades that commit, never `HEAD`.
2. **Precondition the freeze.** An empty `git diff --stat <commit> --
   <files under test>` and a clean tree are explicit preconditions. If
   they do not hold, grade a scratch checkout of the named commit — never
   the working tree.
3. **Fingerprint everything the run executes.** A full-suite grade
   executes the whole tree, so the freeze covers the whole tracked tree
   plus untracked test files, or names explicitly what it leaves out.
   While any author's suite is running, no one changes a file that suite
   can reach — not only the files named in the brief.
4. **State the base.** An isolated worktree is only as good as the commit
   it was created from; one frozen too early hides the very spec the
   author needs. The freeze names the base commit, and the dispatcher
   confirms every document the brief cites exists at that commit.
5. **Sending a fingerprint does not freeze anything.** Messages are
   asynchronous and the dispatcher cannot know whether grading has begun.
   Once a fingerprint is sent, touch no file under test until the author
   reports or acknowledges a stop. If a change is needed after sending,
   send a stop request first, wait for the acknowledgement, then change,
   then send a new fingerprint. The author treats any fingerprint mismatch
   as void-and-report.
6. **A spec that omits its data shapes is not dispatch-ready.** Name the
   contract's keys before dispatching; a grade that fails on vocabulary
   rather than behaviour is the dispatcher's defect, not the author's.

## Dispatch input cost: quote the evidence, continue the agent

> Detail for the `AGENTS.md` §8 delegation directive. Complements #93's
> declared verbosity, which governs output only; this governs what a
> dispatched agent has to READ. Issue #110 is the measurement.

Measured (issue #110, 2026-09-11): a dispatch prompt averages about 930
tokens and is under 2 percent of an agent's bill — an agent consumes
60k-103k tokens, almost all of it re-reading files it opened to orient
itself. Report length, which #93 governs, is the small half of the cost;
input is the large half. Three levers, ordered by measured size:

1. **Quote the evidence into the prompt** (largest). Put the line ranges,
   the exact file paths, and the pre-verified facts into the dispatch
   prompt so the agent does not spend a grep and several full reads to
   rediscover them. More prompt is cheaper than one more discovery, which
   runs against the intuition that shorter prompts are cheaper. The
   pre-verified fact block is mandatory, not optional. Do not, however,
   cut the anti-fabrication and write-early-and-save rules to save prompt
   tokens: they cost little and prevent a known-expensive failure.
2. **Continue a running agent instead of dispatching a fresh one.** A
   running agent has already paid for its reading; a cold start pays
   again. Related follow-up work continues the existing agent; genuinely
   independent work starts cold. State it as a property of the work, not
   a preference, so the choice is made by cost and not by habit.
3. **Narrow the task so fewer files are in scope** (smallest, and the one
   most likely to damage the work). Use last.

Open: the split between file reading and report writing inside that
60k-103k is unmeasured; distinguishing them needs per-agent tool-call
accounting that the transcript does not carry in a totalable form. Until
that is measured, lever 1 is the one with proof behind it.

## Right Tool for the Right Job

> Detail for `AGENTS.md` §1.3, folded in here since both concern
> practical tooling discipline. §1.3 keeps the short rule in core;
> this module carries the reasoning.

Choosing a language/tool should be a deliberate decision, not a default:

- **Shell scripting (`bash`/`zsh` on POSIX, PowerShell on Windows) is for
  thin orchestration only**: stringing together a handful of existing CLI
  calls, simple conditionals, file/path glue. If a script needs structured
  data parsing (JSON/YAML beyond a one-line `jq`), retries with backoff,
  non-trivial branching, or anything the TDD gate (§7) should cover with
  real unit tests, it does not belong in shell.
- **Reach for a real language (Python, Go, etc.) once a script needs
  tests.** A script that can't practically be unit-tested is a script
  that can't practically satisfy §7 — that's the concrete signal to
  rewrite it, not a style preference.
- **Shell orchestration hazards.** In zsh a whole class of parameters is
  bound to shell behaviour, so binding one as a loop variable or temporary
  silently changes it: `read -r path` resets `PATH` to that one value, and
  every external command after it becomes unreachable while builtins keep
  working — a batch that fails identically across several unrelated binaries
  is this, not a refused fetch. Never bind `path`, `status`, `argv`,
  `cdpath`, `fpath`, `mailpath`, `manpath`, `module_path`, `prompt`,
  `psvar`, `signals`, `options`, `commands`, `functions`, `dirstack`, or
  `watch` (use `f`, `line`, `item`, `p`); where a script must not depend on
  `PATH` at all, invoke the binary by absolute path (`/usr/bin/curl`).
- **This is a principle to apply going forward and when a script is next
  touched, not a mandate to mass-rewrite existing scripts today** — per
  §1.2's Laser Task Focus, don't open unrelated refactors as a side
  effect of an unrelated change. Existing over-scoped shell scripts are a
  known gap, tracked as backlog (§4), not silently fixed in passing.

## Contract Plus an Adapter

> Detail for `AGENTS.md` §1.3. The hub forbids harness-branded paths and
> bindings in the payload and in its own layout; this is the same rule for
> the tooling an adopting project writes to operate its own agents.

A tool that operates agents is usually written against whichever harness
happened to be in front of it. That works until the harness changes, and
then the tool's vocabulary — pane names, session ids, CLI flags, HTTP
paths — is spread across every function rather than confined to one file.
The rule is the same shape as the language rule above: decide the boundary
deliberately, at the moment the tool is written.

- **A tool that operates agents is built as a contract plus an adapter,
  even when only one adapter exists.** The contract names what the tool
  needs in verbs and data; the adapter is the only place a harness's own
  vocabulary appears (`tmux`, `pane`, `capture-pane`, `send-keys`, an
  HTTP path, a session or form id, a CLI flag).
- **The core does not import an adapter.** Adapters are selected at the
  edge by configuration, so a second harness is an addition rather than a
  rewrite.
- **Where the core has tests, they run against the normalised shape**, not
  against the adapter's output; the adapter keeps at most a thin
  integration test.
- **Where drawing the boundary would cost more than the unit is worth**,
  ship the working version and file the abstraction in the same commit,
  naming what the interface would have been. Silent coupling is the only
  outcome that is never allowed.
- **This applies when a tool is written and when one is next touched**, not
  as a mandate to rewrite existing tooling today — the same wording §1.3
  uses for the shell-to-language rule.

A worked shape: four verbs (`state`, `deliver`, `asks`, `watch`) with one
adapter that is the only file naming a pane, session, or CLI flag. A second
harness is then a sibling adapter behind the same four verbs, and the core's
tests never learn which one is running.

## Moving work between hosts, lanes, or agents: prove capability, not reachability

> Detail for `AGENTS.md` §1.3, alongside the right-tool rule: both concern
> choosing where and how work actually runs.

A destination can answer and still be unable to do the work. Reachable
means the process runs, the repository clones, the agent replies.
Capable means the credential is live and non-interactive, the toolchain
is the right version, the state backend is writable, and the egress the
work needs exists. Reachable is easy to mistake for ready, and the
mistake is expensive: work that looks underway and dies at its first
real call. A destination was never moved to; it was reached, and it
could not do the work.

Before planning dependent work at a destination -- another host, another
lane, another agent -- verify each capability with a cheap read-only
probe. Never assume it carried across.

1. Identity and credentials: which store, which principal, and is it
   non-interactive? Prove it with the tool's own identity or listing
   call, not by reasoning that it probably works.
2. Toolchain and versions: install the same tools and pin the versions.
   Version skew between two hosts is a silent hazard -- the same command
   produces different results.
3. Repository state: clone or fetch to the exact commit. Do not carry a
   hand-copied working tree; a copied tree desyncs caches and lock files
   from the repository it came from.
4. Remote state and data: know where state and backends live, and prove
   the destination can reach and write them.
5. Network egress: confirm the endpoints the work needs are reachable
   from the destination, not only from where you are.
6. Record the capability matrix: per destination, what works where, with
   which principal or version. Keep it as durable knowledge -- a fleet
   registry or the destination's own profile -- never in a person's head,
   which is exactly where the next agent cannot read it.
7. Verify after the move: run the cheapest end-to-end proof at the
   destination before assuming parity with the source.

The routine is the point. The recorded matrix is what stops the next
agent rediscovering the same wall the hard way.

## CLI Output Convention

> Detail for the `AGENTS.md` §8 CLI output convention.

The normative rule lives in `AGENTS.md` §8 — where one tool-machine's
stdout is consumed as a parse target by another (CI, hooks, gates, a
harness, another script), the producer MUST emit one `[ TAG ]` line
per event (`[ OK ]`, `[WARN]`, `[INFO]`, `[ERROR]`), never reworded
or re-spaced when checked; tabular or prose blocks are never a parse
target. This section is the reasoning, not a
second edition of the rule. The tag format exists because consumers
actually parse this repo's stdout as a machine contract: a doctor-style
consumer in dev-infra-fleet greps sub-check output with
`if "[ OK ]" in line`, so a tool that emits prose where a tag is
expected, or quietly rewords a checked tag, silently breaks that
consumer. The byte-stable form is the contract; prose is only ever an
optional human suffix. What counts as a parse target is decided by
the consumer, not the producer — this repo's own test suite pins the
pre-commit station strings exactly, and those stations are the
contract. Stdout addressed to a human or an agent reading a live
terminal is prose, never a parse target; the convention binds the
producer only where a machine re-parses the bytes. Tabular or prose
blocks are reserved for documents rendered for a person to read,
never a parse target.

## The "never comment code" rule and where it is enforced

> Detail for the `AGENTS.md` §8 rule "Never comment code, docstrings
> included." Stated here because the rule is enforced mechanically and
> the enforcement has a language-dependent edge.

`scripts/check_no_comments.py`, run as Step 16 of
`scripts/pre-commit-hiae.sh`, is where the rule is enforced. Its coverage
is complete for Python: comments are found through the tokenizer and
docstrings through the syntax tree, so both an inline comment and a
docstring count. For every other language in its code-suffix set
(`.sh .ts .tsx .js .jsx .go .rs .java .c .cpp .tf`) the checker catches
**whole-line comments only** — a line whose first non-whitespace
characters are the language's comment marker (`#`, `//`, `/*`). An inline
comment after code on the same line is a known gap in those languages
(issue #265), stated here explicitly so the rule is not silently weaker
than a reader of `AGENTS.md` §8 assumes. Closing the gap means adding a
parser for that language, not loosening the rule.

**The rule is absolute for code, and it is not scoped to new code.** A
file that predates the rule is not exempt; it is simply not re-examined,
because Step 16 judges added lines and newly added files. Read §8 as "do
not add one", never as "only new files are covered". An adopting project
that cannot follow this for a specific file carries a recorded exception
in its own `ADAPTERS.md`, as it would for any other rule; a local
exception is a declared divergence, not a narrower reading of the hub
rule.

**Configuration is out of scope.** The checker's suffix set names source
files; YAML, TOML, JSON and Markdown are not in it, so a comment beside a
pipeline job or a manifest value may explain that value to whoever edits
it next, and this hub's own `.gitlab-ci.yml` depends on that. The boundary
is about what a file is, not about the file's name: a pipeline step that
has become program logic is code by behaviour and takes the rule, and the
why for anything a maintainer changes as logic still belongs in the commit
and the spec.

## A commit runs the repo's own test suite, so budget the command timeout

> Detail for the `AGENTS.md` §3 step 7 (Commit) rule, for any agent that
> invokes `git commit` under a per-command timeout.

`scripts/pre-commit-hiae.sh` runs its unit-test step (Step 5) inside the
hook, against whatever suite the repo declares — for a hub-shaped repo
that is the full `pytest` run (minutes), and for any adopter it is that
repo's own suite, which can be longer. The commit therefore blocks for
the suite's duration, not for a fast local write, and the hook gives no
early signal before the test step starts. A command timeout shorter than
the suite turns a real commit into an ssh/agent-side timeout that looks
like a hang and leaves the invoking shell unsure whether the commit
landed. Budget at least the repo's full suite duration with headroom, and
remember the hook re-runs on every commit attempt, so a retried commit
pays the same cost again. When the timeout cannot be raised, run the gate
by hand once (`bash scripts/pre-commit-hiae.sh` after `git add`) and then
commit with the result already known.

## MCP keep-list and the per-session tool-schema cost

> Detail for the `AGENTS.md` §8 token-efficiency directives and the §9
> MCP/Skills/Plugins triad, for repos that load a large MCP set.

Every enabled MCP server contributes its full tool schemas to the session
system prompt. On a hosted model with prompt caching that cost is often
amortized; on a local model with no cross-restart cache it is paid again
on every cold start -- a fresh or resumed session rebuilds the whole
tool-schema prompt, so a large enabled set is a per-session cost, not a
one-time one.

The pattern that survives a cold restart, a crash, and a first run:

- **The committed project config is the fail-closed floor.** Disable the
  servers the project does not use, by name, in the committed config, so
  a session that reads only committed files starts with the keep-list and
  nothing else. Do not rely on a runtime or plugin default to hold the
  boundary.
- **Enablement is additive within the floor, never above it.** A
  discovery layer that reads repo signals (dependency manifests,
  infrastructure provider blocks, CI config) may only flip an already
  declared server on. It must never synthesize a server definition, URL,
  header, or credential.
- **Keep-list before enable-list.** Choose the servers the project
  actually calls, disable the rest by name, and let signal-based
  enablement widen that set -- never start from everything on and prune
  later, which pays the whole schema cost before the first prune.

For a **personal-infra-tier** repo (`AGENTS.md` §1.0), where the model is
often local or cost-sensitive, a small keep-list is the default rather
than a tuning exercise: the knowledge-graph/memory server for the repo, a
code-graph server when one is indexed, the documentation-lookup server,
and the methodology server. Everything else stays disabled until a
concrete task names it. One project measured roughly 90k tokens of tool
schemas on a 30B local model and cut it to a four-server keep-list (issue
#160; durable home issue #313).

## GitLab API and glab: encode every slash, prefer the numeric project id

> Learned the hard way on a project rename (issue #142). These are
> footguns that fail silently, not loudly, so they cost a debugging
> session each time they are rediscovered.

- **A path-based project lookup needs EVERY slash `%2F`-encoded.** When
  you address a project by path (`glab api projects/<group>%2F<sub>%2F<repo>`),
  encoding only the first slash returns a body that silently lacks
  `path_with_namespace`, which turns what should be a clean 404 into a
  `KeyError` three lines later. Encode every separator, not just the
  first.
- **Prefer the numeric project id.** `glab api projects/<id>` is idempotent
  and stable across renames, and you should read `path_with_namespace`
  back to confirm you landed on the intended project — do not assume the
  id you have still points where you think.
- **Check reachability independently of the API.** The API saying a path
  resolves is not proof the git remote does; confirm with
  `git ls-remote git@gitlab.com:<ns>/<path>.git HEAD`.
- **`glab ci status` takes neither `-P` nor `-r`.** Read a specific
  pipeline through the API instead: `glab api projects/<id>/pipelines/<pid>`.
- **Job-token cross-project allowlists are keyed by PROJECT ID**, so an
  in-place rename leaves them intact even though the path changed. Verify
  with `glab api projects/<target>/job_token_scope/allowlist` rather than
  re-adding entries after a rename.
- **CLI flag shapes that differ from the obvious guess:** `glab issue note`
  takes the body via `-m`, and `glab issue list` takes `--per-page` (not
  `--per_page`).

## Rootless podman + SELinux: five container procedures that fail silently

> Learned shipping a hermetic workspace on podman 5.8.2 (Oracle Linux 9.8,
> aarch64, SELinux enforcing, rootless), verified 2026-09-23 (a 343-passed
> test stage matching the host baseline — issue #157). Upstream docs cover
> none of these; each one fails with a message that points somewhere other
> than the cause.

- **SELinux host binds need `:z`.** On an SELinux-enforcing host, a rootless
  host bind mount fails with an opaque `Permission denied`. Append `:z` to
  every host bind (`-v /host:/cont:ro,z`) so the label is relabeled for the
  container. Container volumes inherit the relabel state; host binds do not,
  so a wrapper should detect `getenforce == Enforcing` and apply it.
- **`--userns=keep-id` for any container that writes to a mount.** `-u
  $(id -u):$(id -g)` maps the container uid into the caller's *subordinate*
  uid range, so writes to a mounted volume fail `EACCES` even though the ids
  look correct. `--userns=keep-id` maps a named uid to the same host uid —
  it is the podman analogue of docker's plain `-u`.
- **Multi-stage `USER` ordering.** A test leaf that inherits the runtime
  `USER` from its parent cannot `apt-get` (`E: List directory ... missing
  ... Permission denied`). If a stage needs root, switch `USER root`, do the
  install, then restore the runtime `USER` again before `ENTRYPOINT []` so
  the leaf keeps the runtime user.
- **A private GitLab generic package 401s for anonymous fetch.** The build
  stage must mount the token as a BuildKit secret
  (`RUN --mount=type=secret,id=X`, read `/run/secrets/X`; podman:
  `--secret id=X,src=file`) and keep a public fallback (a GitHub-release
  tarball), with a hard SHA256 assert on both paths. The generic-package URL
  needs the *numeric* project id — the URL-encoded-path form 404s.
- **`debian:12-slim` ships no `python3`.** A Python test leaf must
  `apt-get install python3 python3-venv python3-pip`; `jq` and
  `openssh-client` are also absent, and a toolchain script that calls them
  fails mid-suite with `ssh not found` / `jq required`. Verify by running the
  real suite, not by installing what the leaf "should" need.
