---
name: codebase-onboarding
description: "Use when a session first joins a repository it has not worked in, or is asked to onboard/understand a codebase. Systematically analyze the unfamiliar codebase and produce the durable project-addendum content — architecture map, entry points, conventions — that a fresh session's boot sequence will later query."
---

# Codebase Onboarding

Opening a repository cold and producing a usable map of it. The outcome
is one durable artifact: the project-addendum content for the repo's
`AGENTS.md` — the architecture map, entry points, and conventions a
newcomer needs — not a separate onboarding document that nothing else
reads. Once written, it becomes part of what a fresh session's boot
sequence queries for orientation instead of re-deriving from zero.

This boundary is deliberate: **this skill produces the artifact;
`AGENTS.md` §2 / `methodology/boot-sequence.md` governs what a session
does at start.** Nothing here re-implements the boot sequence — reading
`ADAPTERS.md`, checking the skill registry, querying the durable-knowledge
doc, checking the tracker, confirming a known-good test baseline. If this
run happens to be a repo's very first session, do those lookups first
(§2), then come back here. And note the placement rule from `AGENTS.md`
§0: the detected facts are project-aware fact, not process, so they sit
in a clearly-marked project addendum — never woven into the process
contract in a way that forks the contract per repo.

## Phase 1: Reconnaissance

Gather raw signals without reading the repo end-to-end. These checks run
in parallel; none is a full-file read:

1. Package manifests — package.json, go.mod, Cargo.toml, pyproject.toml,
   pom.xml, build.gradle, Gemfile, composer.json, mix.exs, pubspec.yaml.
   The fastest single source of language and dependency truth; worth a
   full read each.
2. Framework fingerprints — config keys and entry conventions specific to
   a framework: next.config.*, nuxt.config.*, angular.json,
   vite.config.*, Django settings, Flask app factory, a FastAPI app entry,
   Rails config.
3. Entry points — main.*, index.*, app.*, server.*, cmd/, src/main/.
4. Directory snapshot — the top two levels of the tree, ignoring what is
   never read anyway: node_modules, vendor, .git, dist, build,
   __pycache__, .next.
5. Config and tooling — lint/format/typecheck configs, Makefile,
   Dockerfile, compose files, CI workflow definitions, .env.example.
6. Test structure — test directories, *_test.go, *.spec.ts, *.test.js,
   test-runner config.

Read selectively. A package manifest is a full read; a framework config,
only the relevant keys; a source file, only when an earlier signal is
ambiguous. Prefer the structured query tools `ADAPTERS.md` wires in over
directory dumps for steps 4 and 6 when they exist — one graph query beats
a raw dump and is what `AGENTS.md` §2 step 3 already directs.

## Phase 2: Architecture Mapping

From the recon signals, establish:

- Tech stack — language(s) and version constraints; the frameworks and
  libraries that shape how code is written; database and ORM; build
  tooling; CI/CD platform.
- Architecture pattern — monolith, monorepo, multi-service, serverless;
  frontend/backend split or full-stack; and the API style as the code
  actually does it (REST, GraphQL, gRPC, or none).
- Key directories — top-level directories mapped to a one-line purpose
  each, and only the ones a newcomer genuinely needs. `src/` does not
  earn an entry that says "source code."
- Work lifecycle — trace one unit of work through the project, entry to
  response: where it enters, where and how it is validated, where the
  business logic lives, how it reaches storage. For a project that is not
  request-shaped — a CLI, a library, a pipeline — trace one unit of work
  in the shape it actually has.

Verify, don't guess. Where a config file claims one thing and the code
does another, trust the code and record the divergence.

## Phase 3: Convention Detection

Identify the patterns the codebase already follows, because these are the
patterns a session is expected to keep following:

- Naming — file naming (kebab-case, camelCase, PascalCase, snake_case),
  component/class conventions, test-file naming.
- Code patterns — error-handling style, dependency injection versus
  direct imports, async style, state management where one exists.
- Git workflow — branch naming from recent branches, commit-message style
  from recent history, PR/merge workflow. If history is shallow or empty
  (`git clone --depth 1`, first commit), skip and record that it was
  unavailable — do not invent a convention the repo never exercised.

## Phase 4: Produce the Artifact

The single output is the project-addendum content, encoding the four
sections above in this shape:

    ## Project Notes

    Overview: two or three sentences — what this project does, who it is for.

    Tech stack: language and version constraints, framework, database and
    ORM, build tooling, CI/CD.

    Architecture: how the pieces connect — a few lines of prose, not a
    diagram.

    Key entry points: the paths a newcomer will repeatedly touch, with one
    line each on what lives there. Cap at roughly six.

    Directory map: one-line-per-directory from Phase 2.
    Work lifecycle: the Phase 2 trace, compressed to a short chain.
    Conventions: Phase 3 findings phrased as "keep doing this."
    Commands: test, lint, build, migrate, serve — what was actually
    detected, not a README's wishful section.

Placement depends on the repo:

- `AGENTS.md` does not exist — create it with the process contract this
  project's adopting payload supplies, then attach this addendum as its
  project-specific section. The contract body comes from the payload, not
  from this skill's detection; this skill contributes the addendum only.
- `AGENTS.md` exists and has a project section — read that section first,
  then merge. Preserve project-specific instructions that are still true,
  and clearly call out what was added or changed.
- `AGENTS.md` is contract-only (`AGENTS.md` §0's strictest reading) —
  the addendum lands in the durable-knowledge doc §2 step 3 already
  queries, as a section of an existing addressing surface, not as a new
  standalone onboarding file.

Restraint rules, all non-optional:

- Stay scannable in about two minutes. That is what keeps the addendum
  cheap to load at boot and therefore trusted enough to be read.
- Detail belongs in the code, not in the addendum. This is a map, not an
  explanation of the territory.
- Record only the dependencies that shape how code gets written. A
  dependency list is what the manifest is for.
- If a convention cannot be confidently detected, say so. "Could not
  determine the test runner" is honest; a wrong guess is worse, because
  the next session will trust it and act on it.
- Do not reproduce the README. The addendum adds structural insight;
  duplicating the README just adds load cost.

## When this fires mid-session, not only on first contact

Joining conditions are not limited to opening a fresh repo. When a task
spans an unfamiliar area of a known repo, run Phase 1 and Phase 2 scoped
to that subsystem only and update the addendum's relevant lines in the
same unit of work — do not re-run the whole map and do not inflate the
addendum every task.

## What done looks like

The addendum is committed in the same unit of work as the onboarding. It
is small enough to scan in two minutes. Every claim a fresh session will
act on was verified against the code, or is explicitly marked
undetermined. And it is findable by `AGENTS.md` §2 step 3: a section of
`AGENTS.md` itself, or a section of the durable-knowledge doc that step
already addresses.
