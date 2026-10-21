# Adoption Model — Hyer Is the Central Hub

> Detail module for `AGENTS.md` §0. Loaded on demand — see the Module
> Table at the top of `AGENTS.md`. This file is part of the adopter
> payload -- this file defines the full-payload rule itself, below --
> copied alongside `AGENTS.md` and `skills/`.

**Hyer** (this repo's current name — see
`docs/archive/hub-roster-log-2026-08-to-09.md` for its naming/rename
history, per this file's own project-aware-facts rule below) is the one
central, versioned hub for this contract across every project — current
and future — that adopts it. That only works because this repo owns
*process only*.

## Onboarding a project (current or future)

Copy `AGENTS.md` verbatim into the project root, plus whatever thin
bridge file the harness you are working in needs in order to discover
it (the mechanism and its name are that harness's own convention — an
`@AGENTS.md` include, a settings entry pointing at the file, or similar;
never a model- or harness-branded path written into this contract). No
edits to `AGENTS.md` needed, since it has no project-specific facts to
adapt. Editing it to describe a specific project is the signal that
content belongs in that project's own docs instead.

**On a machine where Hyer is installed, `/adopt-hyer` runs this section.**
`scripts/install-hyer.sh` writes one global slash command per agent harness
it finds on the machine, so the whole procedure — enumerate, read, place at
the commit `stable` peels to, prove every byte — is one invocation, in any
of them, without reading this hub's checkout. It then loads
`skills/360-audit-skill-forge/SKILL.md`, so adopting Hyer adopts the 360
audit instrument in the same pass rather than leaving a second thing to
remember. The command carries no payload text: it points at the contract
below, and the payload is what it points at. Everything that follows is
what it runs, and what to do by hand where no installer has run.

Copying it in also means copying `skills/`, `skills/REGISTRY.md`, and
`methodology/` (the modules the Module Table points at) — adopting Hyer
means the full payload, not a hand-picked subset; `.hyer/skills/`
stays hub-internal. A version bump into an existing adopter follows the
same rule — don't leave `skills/` or `methodology/` behind at an older
state (see
`METHODOLOGY.md#corrected-2026-08-25-skills-registry-elective-drift`).

**`skills/REGISTRY.md` is merged, never overwritten.** It is the one
payload file guaranteed to diverge, because an adopter with its own
locally-authored skills adds rows the hub cannot have. Take every row
the incoming file carries, add or update the rows the adopter's own
skills own, and keep the rest — a verbatim overwrite deletes the
adopter's own rows, which the rule that adoption is additive forbids
just as surely as deleting a payload skill would. The result is a
superset of the hub's file, not a byte-exact copy of it, and that
divergence is correct: the byte claim below binds the *contract*, and
the registry is one line per skill the adopting project actually has.

**"Verbatim" is a byte claim, and a read path cannot satisfy it.** What
the methodology MCP returns *is* byte-faithful to the file at the ref
asked for — a missing trailing newline stays missing, an interior blank
line stays, CRLF is not folded. But a file read through a session has
passed through a session, and text is re-emitted rather than preserved:
writing that copy back out adds a trailing newline to a file that had
none, loses an interior blank line, re-wraps a paragraph. So a payload
file has to be *placed* by a path whose bytes never become text. Use the
MCP to enumerate what to copy and to read the contract; use a byte path
to put it on disk.

**Resolve the hub before you address it.** Nothing in this payload names
a GitLab host or a project id, because the same bytes have to remain
adoptable from a mirror or from a public snapshot of this hub. Ask the
methodology MCP: `locate_hub` returns the API base to address, the
project id and git remote that reach it, and the commit `stable`
currently resolves to, all for whichever hub that server is bound to.
Take `api_base` as the base of every URL below, `git_remote` as the
hub's git URL, and its resolved commit as `<sha>`. A bound server with
no `locate_hub` predates this contract: upgrade the methodology MCP
rather than reconstructing the hub's address by hand, because a guessed
project id is not a wrong answer that fails — it is payload written into
whichever project happens to answer to it.

**The byte path is a direct HTTP GET written straight to disk.** One
request per file, response body to `<dest>` with nothing in between:

```
curl --fail --silent --show-error --location \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "<api-base>/repository/files/<url-encoded-path>/raw?ref=<sha>" \
  --output <dest>
```

A project that already holds a clone of this hub may instead use
`git show <sha>:<path> > <dest>` there — at the SHA, never at the
floating tag, because a fetch does not refresh a local tag and that
clone's `stable` may be any release it last saw — but it must not
*create* one to do this: reading the payload through a clone is the
thing the new-release rule below forbids, so a clone is admissible only
as something already present, never as a step this adoption adds.

**A local tag is not evidence that a fetch kept you current.** `git fetch
--tags`, a bare `git fetch`, and `git fetch origin` all add tags that are
absent and update nothing already present, so an existing local `stable`
stays on whatever release that clone last saw and "I fetched" is not
evidence the ref moved. Before trusting a clone's local tag, resolve the
authoritative ref and compare the two: `git ls-remote <git-remote>
'refs/tags/stable^{}'` (or the methodology MCP's version list) names the
commit `stable` peels to now, and `git rev-parse 'stable^{}'` names the one
the clone holds. If they differ the local tag is stale — re-point it
(`git tag -f stable <that-commit>`) or, better, place at the resolved SHA
and never consult the local tag at all. Do not assume a forced fetch can
recover it: both `git fetch origin '+refs/tags/stable:refs/tags/stable'`
and `git fetch origin tag stable --force` failed with `couldn't find remote
ref refs/tags/stable` against this hub's mirror during the v5.35.0 sync,
which may be a mirror or permission artifact rather than Git behaviour —
which is the point: "re-fetch and check" is only sound if re-fetching can
work, so the comparison above, never the fetch itself, is the verification
step.

**The credential is the one the MCP already required.** This hub is
private, so the byte path needs read access to it. It is the same
GitLab read token the adopter has already supplied to the methodology
MCP — the `X-Gitlab-Token` request header, or the `GITLAB_TOKEN`
environment variable — carrying `read_api` (or `read_repository`).
Handle it under §6 (`methodology/credentials.md`): it goes in the
secret store, never in a committed file, a shell history, or an
announcement. An adopter that has no such token, or whose token lacks
the scope, **stops and asks the hub owner for read access** — it does
not fall back to an unauthenticated request, and it does not treat the
resulting 401 or 403 as a reason to accept a copy assembled any other
way. That fallback is exactly the silent substitution §6 forbids, and
a partial adoption is worse than none: a repo stamped to a version whose
payload it does not hold asserts a contract it cannot satisfy.

**Tell a refusal apart from a local fault before reporting one.** A fetch
that returns nothing is not yet a refusal, and the three failure modes must
not be collapsed into one report. A batch that fails identically across
several unrelated binaries is a local environment fault — the fetch loop is
broken, not the hub — so fix the command and re-run; neither the payload nor
the credential is in question. Only per-URL failures consistent with an HTTP
status from the API are remote (401/403: stop and escalate the credential;
404: a file absent at that SHA). Before diagnosing a batch, run
`command -v <tool>` and print `$PATH`: a tool that resolved nothing means no
HTTP status exists to inspect, so any status-code reading is evidence never
collected. Never report a mode you cannot evidence.

**Prove each file without a clone, and pin what you proved.** `stable`
is a floating tag, so a per-file proof has to name something that cannot
move under it. Peel the tag to a commit SHA **once**, before placing
anything:

```
curl --fail --silent --show-error --location \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "<api-base>/repository/commits/stable"
```

The `id` in that response must be a 40-character lowercase hexadecimal
commit id. If the request fails, returns nothing, or returns an `id` that
is anything else — an annotated tag's own object id, a branch name — then
this reference did not resolve to a commit: **stop and report it**, and
place nothing. Reading through the tag instead is the failure this step
exists to prevent, and a payload stamped with a provenance id that names
no commit asserts a provenance that cannot be checked.

Naming an explicit version through the methodology MCP is ref-proof in the
same way: `list_payload({version: "vX.Y.Z"})` and `get_methodology({path,
version: "vX.Y.Z"})` resolve that version server-side, so no local tag is
involved and a stale clone cannot serve the previous release. The explicit
version is what makes the MCP immune; `version: "stable"` still works but
re-derives the floating ref on every call, so name the released version
whenever one exists to name.

The same peel over git, from the git remote `locate_hub` returned, needs
no clone and no checkout:

```
git ls-remote <git-remote> 'refs/tags/stable^{}'
```

One line is printed, and its first column is the commit the annotated
tag points at. Ask for `stable` alone, or with `--tags` but no `^{}`, and
the first column is the *tag object's* own id instead: also forty hex
characters, but naming no commit, so every later `git show <that>:<path>`
fails or, worse, resolves against nothing you can audit.

Record that SHA as the provenance of this adoption, then fetch every
file at **that SHA rather than at the tag**. Two independent GETs of the
same `SHA:<path>` agree by construction, while a re-emitted MCP copy
differs from both — which is the point of comparing them. Record the
hash each placement wrote next to the SHA. A tag that moves afterwards
can no longer change what you hold, and the SHA is the one value that
survives the history rewrite described in `CHANGELOG.md`. Name the
immutable tag in any announcement: the tag is the provenance, and the
SHA beside it is the value to check that tag against.

**Install the gate before reporting the adoption done.** Placing files is
not adoption. Until the project runs the pre-commit gate, every rule above
is a document nothing enforces, and a green report says only that the
document is present. Install the wrapper with
`scripts/install-hooks.sh <repo>`: it writes a thin hook that execs the hub
script rather than a copy of it, backs up whatever hook was there to
`<hook>.hyer-backup-<UTC timestamp>`, and refuses to overwrite a hook it
does not recognise -- folding the gate into a framework's own hook config
is that project's separate decision.

Then verify the wiring instead of assuming it, because the hook lives
outside version control and a project can otherwise adopt completely and
still run no gate at all. The hub's sync check reports the wiring for every
discovered project as `hook wiring=hyer-live`, `hyer-broken`, `hyer-fork` or
`none`, and the project's own `scripts/adopter_drift_check.py` reports its
hook and fails its build for a broken or a frozen one. A hook that is
simply absent is deliberately informational in that check -- a missing hook
is not the drift check's to judge -- which is exactly why this step, and
not that check, is what catches it.

## Where a fact belongs

- **A project's own facts** — its tier (§1.0), its persona-to-repo
  mapping, its brand name if it has one, any product-specific pipeline
  — live in that project's own durable docs
  (`STATE.md`/`docs/ARCHITECTURE.md`), never in `AGENTS.md`.
- **Cross-project facts** (which repos exist across the whole ecosystem,
  which tier each is, a central rollup like a Confluence mirror) live in
  this hub's own `WIKI.md` — project-*aware*, but still a separate file
  from the project-*agnostic* `AGENTS.md`.

## The declared stack (`ADAPTERS.md`)

A repo declares the languages and toolchains it actually builds and ships
with one `stack:` line in the required `## Declared stack` section of its
`ADAPTERS.md` (the template ships the section; `check_adapters_completeness`
blocks a hub whose file omits it, issue #265). One line, comma-separated.
The gate reads three capabilities from the declared tokens and their
synonyms:

- `python` (python, python3, py): the Python format check (Step 19).
- `node` (node, nodejs, typescript, ts, javascript, js, npm, deno, bun):
  the hyer-mcp type check (Step 20) and the container-image build gate.
- `oci` (oci, container, docker, podman, buildah): the container-image
  pin assertions in the CI arch-sensitive test.

A toolchain-coupled check whose capability the declared stack does not
include exits NOT APPLICABLE and is skipped; that outcome is honest and
informational, never a WARNING, and never blocks. **Absent a `stack:`
line the checks fall back to probing the tree** (the pre-#265 behaviour),
so an adopting repo that has not yet declared a stack behaves as before.
A repo may declare stacks beyond these three; only the three above are
read by the hub's own gate.

## The gates binding (`ADAPTERS.md`)

A repo names the Hyer hub its gates come from with one
`hyer-gates-source:` line in the required `## Hyer gates binding`
section of its `ADAPTERS.md` (the template ships the section;
`check_adapters_completeness` blocks a hub whose file omits it). Give
the clone URL of the hub the runner would fetch `stable` from. The gates
runner resolves the binding on every run in this order: the
`HYER_GATES_SOURCE_URL` environment override, then this line, then the
`source_url` already recorded in the machine cache
(`~/.hyer/gates/state.json`), then a hard error that names both ways to
set one and writes nothing.

**A repo's own `origin` remote is never a candidate** (issue #261): for
an adopter that remote is the adopter's repository, not the hub, so
reading it binds the one-per-machine cache to the wrong repository and
then reports that binding as the binding. The layer that answered is
persisted as `source_binding` and printed on the first line of every run
as `binding=<env|adapters|state|working-tree>`, so a declaration that
disagrees with what the cache is serving prints a WARNING naming both
sides rather than running the wrong bundle silently. This hub declares
its own clone URL in the same line, so the named declaration is the same
in every repo; in hub mode the gates run against the working tree, so
the line is inert for execution there and tracked anyway.

## Versioning and the `stable` tag

- **Versioning**: a new version of `AGENTS.md` is a deliberate, reviewed
  release (`CHANGELOG.md`), never auto-synced into a project that
  adopted an earlier version. Adopting a new version into a given
  project is that project's own explicit act (§7's Definition of Done
  still applies to *that* change).
- **The `stable` git tag**: a floating pointer to the newest reviewed
  release commit, moved (not recreated) on every release — see the
  `moving-stable-tag` skill (hub-internal — §2 step 2 for how to fetch
  its content from outside this repo) for the exact command and why
  manual-copy adopters must fetch at `stable`, never a hardcoded
  version.
- **Staying in sync**: this hub detects adopter drift from its own side
  (`scripts/check_methodology_sync.py`), but that only helps if someone
  reads its output — an adopter's own CI can gate on its own drift
  instead; see the `adopter-drift-self-check` skill (hub-internal — §2
  step 2 for how to fetch its content from outside this repo).
- **On a new-release announcement**: wherever an announcement of a new
  `stable` release arrives (the auto-opened `adopt Hyer vX.Y.Z` issue,
  a fleet broadcast, or any other channel), adopting it is that
  session's *first* action in every adopting project — before the task
  itself. Fetch the payload through the methodology MCP server this
  project has bound in `ADAPTERS.md` (`list_payload` with
  `version: "stable"` to enumerate it, then `get_methodology` with
  `path` + `version: "stable"` per file) — never by reading or cloning
  this hub's repository. The MCP is the sanctioned read path for this
  content; reading the hub repo instead skips the tool built precisely
  to be consulted, and costs the whole payload in tokens besides.
  Placing the files on disk is the separate rule above, and the handoff
  between the two is explicit rather than implied: enumerate with
  `list_payload`, read any file whose *text* you need with
  `get_methodology`, and then place **every** file in the enumeration —
  the ones you read and the ones you did not — with the byte path,
  fetched at the SHA you peeled. Re-emitting the text `get_methodology`
  returned is never the placement step, however few bytes that text is.
  An announcement names the immutable tag for the release: that tag is
  the provenance. A bare commit SHA is not, because this hub's history
  is rewritten on a release and the tag re-cut (see `CHANGELOG.md`), so
  a SHA published alone in a durable channel names something that no
  longer exists. A SHA quoted beside the tag is a verification value,
  not a claim: it is what the adopter peels that tag to and compares,
  and it is expected to disagree once the tag is moved.
  `skills/hyer-session-currency` carries out this rule in steps.

## Boundaries this hub does not cross

- **The contract names no model- or harness-branded paths or bindings.**
  No bridge-file, storage-location, or tools-binding example in the
  payload surfaces a model- or harness-specific name, a device- or
  vendor-branded memory store, or a vendor's own config-file
  convention — a bridge file's name is the active harness's own
  convention (which its config surfaces), so the shared text stays
  harness-agnostic and any harness can adopt it unchanged. The rule
  binds this hub's own tracked layout too, not only the payload: no
  directory or file under version control is named after a vendor or
  harness. The one deliberate exception is hub adapter code, which
  discovers and writes into a real harness's own config on disk and so
  cannot name that target abstractly; such a path is an interop target
  rather than a binding the contract imposes on anyone, and it stays
  out of the shared text (issue #158).
- **The boundary line**: this repo stops at *how work gets done*; it
  never grows into *what exists*. A change that would only make sense
  for one specific project is out of scope for `AGENTS.md`.
