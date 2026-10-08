---
name: distribution-target-and-credential
description: "Establish where an artifact is distributed to and what authenticates the move, before either is wired. Use when about to create or change anything that publishes, releases, pushes or deploys an artifact out of the repository, when choosing a registry, endpoint, namespace or store, or when about to conclude that a human must create a credential for a pipeline."
---

# Establish the distribution target and the credential before wiring either

Two questions, in this order, before you create or change anything that
moves an artifact out of this repository: **where does it go**, and **what
authenticates the move**. Both are answers you look up. Neither is a
default you inherit from the artifact's file format.

## Why this exists

Recorded 2026-10-03 from a real session. A publish job was written for an
npm package, shipped with 21 passing tests, and gated against
`registry.npmjs.org`. Three things were wrong and only the first was
visible:

1. **The destination was never decided by anyone.** The artifact was an
   npm package, so npmjs was treated as the address rather than as one
   candidate. The founder rejected it outright. Nothing had been
   published, and a measurement then showed **nothing consumed it from any
   registry** -- so the channel had no recipient at all.
2. **A secret was escalated before the platform's own credential was
   checked.** The job needed an automation token, which was reported to
   the founder as unavoidable human-only blocker work across an entire
   session. The destination's platform authenticates CI publishes with a
   **predefined job token** -- so the blocker did not exist and had never
   needed to.
3. **A safety property was silently tied to the wrong platform.** The
   registry-liveness probe was `npm view npm version`, chosen because npm
   returned an empty answer for both "not published" and "network down",
   which had to be told apart. The new platform does not proxy the old
   one, so that probe could not run there at all. The property was real
   and the implementation was platform-specific, and nothing said so.

Any one of these is a normal mistake. Together they are one mistake: the
platform was inherited rather than chosen, and everything downstream
inherited it too.

## Procedure

### 1. Find out whether anything consumes the artifact

Before designing a distribution channel, measure its demand. Search the
whole tree for `npx <name>`, `npm install <name>`, the registry host, and
the configured client block (`mcpServers`, `plugins`, `pip index-url`,
`go get`). Then read what the project's own records claim about
distribution and check whether the claim was a *registry* or a *local
tarball*.

If nothing consumes it, that is the first thing to say out loud. A
channel with no recipient is not a smaller task, it is a question for the
person who owns the decision.

### 2. Establish the destination from the platform, not the file extension

Enumerate the candidate registries the destination platform actually
offers, and record for each: the endpoint shape, the authentication
options, whether the package name must be scoped, and what the access
model is. Read the platform's own documentation. Do not carry an endpoint
across from another platform.

Then ask the one question that is not yours: **is this destination
acceptable to the person who owns the decision?** Where an artifact
leaves a boundary is a decision about blast radius and about who can read
it afterwards. It is not an implementation detail you can settle by
picking the endpoint that matches the file extension.

### 3. Prefer a credential the platform already issues

Before writing any secret into a pipeline, a job, or a human's todo list,
enumerate what the platform issues on its own:

- a per-job or per-run identity token (`CI_JOB_TOKEN` and equivalents)
- a workload identity or OIDC federation, with no stored secret at all
- a short-lived signed credential
- a project or deploy-scoped token narrower than a personal one

A design that stores no long-lived secret is strictly better than one that
does: nothing to mint, nothing to rotate, nothing to leak, and no human
blocked on your inability to create a credential. If you concluded a human
had to create a credential, the question to ask first is *whether the
platform issues one per job*.

If a stored secret really is required, say so with the scope, the
rotation path, and who holds it -- and prefer the narrowest scope that
works.

### 4. Make the destination a control, not a promise

Documentation saying "we publish to X" is a claim. Two things make it a
control, and they are cheap:

- **Pin the destination in the artifact's own metadata**, in the field
  the publishing tool resolves its target from, so the wrong destination
  is unreachable rather than merely unintended.
- **Re-derive the destination at run time from platform-provided
  identifiers** and **fail** when the artifact's pinned value disagrees.
  Deriving it means a fork, a mirror, or a different project cannot
  silently point the publish somewhere else.

### 5. Re-check every platform-specific mechanism

Go back through the design and name, for each mechanism, which platform it
belongs to. Mechanisms that belonged to the old destination -- an error
code, a probe, a flag, an identity block, a naming convention -- get
deleted or rewritten. A safety property is only real on the platform where
its implementation can actually run.

Absence checks deserve particular care. An empty answer usually means two
different things -- "not there" and "could not ask" -- and the old
platform's way of telling them apart does not exist on the new one. Read
the authoritative list and decide membership in structured data rather
than reading an exit code as absence.

### 6. Verify the consequence, not the tool's claim

After the write, read the destination back and confirm the artifact is
there. A publishing tool exiting zero is the tool's claim about itself;
the destination holding the artifact is the fact. One read before the
write cannot also establish the state after it, so there are two reads.

### 7. Declare the install-side cost

A private destination makes every consumer need a credential. State that
where the project's own bindings live, with the scope required, so it is
a declared per-host cost rather than a surprise on first install.

## Edge cases worth naming

- **A package you cannot scope.** Some registries require
  `@scope/name` at the instance level and relax it at the group or
  project level. Renaming an artifact to satisfy a registry is a breaking
  change; pick the endpoint that does not require the rename.
- **A registry that does not proxy the public one.** Verification,
  audit, and dependency-resolution commands that "just worked" against a
  public registry can return nothing useful here. Check whether the
  feature is off by default and who turns it on.
- **A credential-free path that still needs a person.** Platform-issued
  per-job tokens solve the *publish* side. Installs by a third party still
  need a token, and that is a real cost with a real owner -- do not
  report the blocker as gone when only half of it is.
- **A destination that is already governed.** If the project already ships
  a container, a release tag, or an artifact store with a release policy,
  the consistent choice is usually that store, and its existing policy is
  an argument you can make rather than a preference you assert.
- **Ownership of a destination you did not choose.** A public registry
  under someone else's namespace is not yours to publish into. If the
  artifact's metadata names an upstream owner, that is a fact about the
  artifact, not permission.

## Composes with

- `measure-before-asserting-environment` -- supplies the "measure demand"
  and "read the documentation" discipline this skill applies.
- `vet-third-party-tool` -- governs the dependency itself; this skill
  governs where the output goes and who may read it.
- `hyer-operations` -- where a credential lives once one genuinely exists.

## Verification

You have done this correctly when you can name, in one sentence each:

- who decided the destination, and where that decision is recorded;
- the measured evidence that something consumes the artifact, or an
  explicit statement to the owner that nothing does;
- the exact mechanism that authenticates the move, and why it is not a
  stored secret -- or, if it is one, its scope, its rotation path, and its
  holder;
- the mechanism that makes the wrong destination fail rather than
  succeed;
- the read that confirms the artifact arrived, as distinct from the
  command that claims it did.

If any of those five is missing, you have written a job, not a control.
