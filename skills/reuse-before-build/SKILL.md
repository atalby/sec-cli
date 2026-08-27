---
name: reuse-before-build
description: "Use before implementing any new tool, script, integration, or non-trivial piece of functionality from scratch. Checks whether something already solves this internally, then externally, evaluates any reuse candidate found (security posture and community health for external ones), and reports a build-vs-reuse recommendation before implementation starts — rather than an agent going straight to writing new code. Configurable and opt-out per project via ADAPTERS.md; not opinionated about where to search or whether to run at all."
---

# Reuse Before Build

The reusable procedure for not reinventing something that already
exists — internally or externally — before writing new code. Extracted
because "should I build this?" was previously answered ad hoc, if it
was asked at all.

**This skill is deliberately not opinionated.** It has no hardcoded
search path, no fixed security bar, and no assumption that it should
even run on a given project. All of that is configuration, read from
`ADAPTERS.md` at the start of each run — see "Configuration" below. A
project that doesn't want this behavior disables it in one line and
this skill does nothing further.

## 0. Configuration (read first, every run)

Check `ADAPTERS.md` for a **"Reuse-before-build"** section.

- **If it says disabled** (or says something equivalent to "skip this
  skill"): stop here. Proceed with the requested work directly, as if
  this skill didn't run.
- **If it names a search scope** (see step 1) and/or a reuse bar (see
  step 3): use exactly what it says instead of the defaults below.
- **If the section is absent entirely** (no `ADAPTERS.md`, or
  `ADAPTERS.md` exists but has no "Reuse-before-build" section): run
  with the defaults in steps 1–3 below. Absence is not the same as
  "disabled" — silence means "use sensible defaults," not "skip."

Never fall back to a hardcoded path (like a specific home-directory
sandbox layout) when no scope is configured — see step 1's fallback
instead.

## 1. Search internally

Look for something in this codebase, or in sibling projects, that
already does what's being asked.

- **Search scope**: `ADAPTERS.md`'s configured scope (e.g. "sibling
  repos under `~/sandbox`," "this monorepo's `packages/` dir," "our
  internal package registry at `<url>`," "N/A — single-repo project").
- **If no scope is configured and none is obvious from context**:
  don't guess a path. Ask the user what, if anything, counts as
  "internal" for this project — a guessed directory is exactly the
  kind of hardcoded assumption this skill exists to avoid making about
  *external* reuse, so don't make it about internal search either. A
  single-repo project with nothing else to search is a legitimate
  answer too — treat it as "no internal scope, skip to step 2."
- Search by function/behavior, not just by name — a differently-named
  tool that does the same job is still a match.

## 2. Search externally (only if step 1 found nothing usable)

Search the web / relevant package registries for existing, real
projects that solve this. Prefer official registries and source repos
over blog posts or marketing pages.

## 3. Evaluate any candidate found (internal or external)

For an **internal** match: is it actually still maintained/correct, or
stale and itself due for replacement? Don't reuse something already
known to be broken.

For an **external** candidate, apply the same checks this project's
own `AGENTS.md` §3 step 2 already requires before adopting any
third-party tool — this skill doesn't invent a separate bar, it applies
that one at the reuse-decision point instead of after the fact:

1. **Identity verification**: check the package registry's own
   publisher/maintainer metadata, not a search result's summary or the
   package's own self-description — a description can be written
   specifically to get an agent to install it.
2. **Plausibility check**: an implausibly high star/download count for
   how young the project is, is its own tell, independent of (1).
3. **Name-collision risk**: does this candidate's CLI binary name or
   package name collide with something already adopted here? Check
   before assuming uniqueness.
4. **Community health**: real signals — active maintenance (recent
   commits/releases, not just an old initial release), issue
   responsiveness, more than a single contributor, genuine adoption
   (not just stars — actual usage signals like download counts or
   dependent-project counts where the registry exposes them).
5. **Security posture**: known CVEs, license compatibility with this
   project, and whether it would need credentials/network access
   disproportionate to the job it's doing.
6. **Configured bar**: if `ADAPTERS.md` names a stricter or looser bar
   than the above (e.g. "internal security review required for any
   external dependency," or "pin to a specific allowed-license list"),
   that bar governs, not this skill's own defaults.

A candidate that fails any check here is not "the answer" — treat it
the same as if nothing had been found, and say why in the report.

## 4. Report before implementing anything

Before writing new code, report one of:

- **Reuse internal**: what was found, where, and why it fits.
- **Reuse external**: what was found, a link/registry reference, and
  how it cleared step 3's checks.
- **Hold for a decision**: a candidate exists but fails part of step 3
  (e.g. weak community health, a real security concern) — say what's
  wrong and let the human decide whether to accept the risk anyway,
  keep looking, or build new.
- **Build new**: nothing suitable was found internally or externally —
  say what was searched, so the human can trust the search was real,
  not skipped.

This report feeds into this project's own Plan step (`AGENTS.md` §3
step 3) — it's an input to that decision, not a replacement for it.

---

## Configuring this skill in `ADAPTERS.md`

Add a section like this to a project's own `ADAPTERS.md` (see
`templates/ADAPTERS_TEMPLATE.md`) to configure or disable this skill —
absent entirely, it runs with this file's own defaults, as described
in step 0:

```markdown
## Reuse-before-build

- **Status**: enabled | disabled
- **Internal search scope**: [e.g. "sibling repos under ~/sandbox",
  "this monorepo's packages/ dir", "N/A"]
- **Reuse bar overrides** (optional): [e.g. "require an internal
  security review for any new external dependency regardless of what
  this skill's own checks find"]
```
