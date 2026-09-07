# The Core Development Loop — full detail

> Detail module for `AGENTS.md` §3. Loaded on demand — see the module
> table in `AGENTS.md` §0. This file is part of the adopter payload
> (§0: "adopting Hyer means the full payload, not a hand-picked
> subset"), copied alongside `AGENTS.md` and `skills/`.
>
> `AGENTS.md` §3 itself keeps the one-line skeleton for all 7 steps
> **and** the full step-3 tripwire list verbatim (mechanical,
> safety-critical — read those in core, not here). This module carries
> the full reasoning and detail for steps 1, 2, 4, 5, 6, 7, plus the
> Auto-Moderation Protocol.

For any non-trivial change, in order:

1. **Ground.** Verify current-state facts with real citations — exact
   file and line, not memory, not assumption, not what a doc *claims* is
   true. If an investigation is large, delegate it, but insist on
   citations back. **A negative claim ("this doesn't exist," "this
   feature is fabricated") needs its own, different verification than a
   positive one** — see the `verifying-negative-existence-claims` skill
   (hub-internal — §2 step 2 for how to fetch its content from outside
   this repo) for why a filename/pattern grep finding nothing doesn't
   prove absence, and what a real check looks like, before writing the
   claim into a durable doc or filed issue.
2. **Research third-party tools before configuring them.** Before wiring
   an external CLI tool, library, or service into the project, read its
   actual source, CLI reference, or config schema for the exact surface
   being used — see the `vet-third-party-tool` skill (hub-internal —
   §2 step 2 for how to fetch its content from outside this repo) for
   the registry-identity and CLI-collision checks.
3. **Plan.** See `AGENTS.md` §3 core for the full tripwire list (kept
   there verbatim, not duplicated here) — this step's short version:
   for anything non-trivial, write a concrete design to a durable,
   reviewable location before implementing, and get explicit approval
   before proceeding. Calibrate the ceremony to the *risk*, not the
   line count — a one-line change to shared infrastructure deserves
   more care than a hundred-line change to an isolated module. These
   tripwires are also mechanically re-surfaced mid-session — not only
   readable once at session start — by the `~/.hyer/` hook layer
   (issue #26; see `docs/hyer/specs/2026-08-26-hyer-hook-layer-design.md`;
   see also `METHODOLOGY.md#prose-alone-already-failed-twice`).
4. **Implement** in small, independently coherent units — not one batch
   at the end.
5. **Verify.** In order of cost, cheapest first, but don't stop at the
   cheap ones:
   - Local tests passing is *necessary, not sufficient*.
   - Run the *full* test suite after any change to shared or global
     state, not just the tests you think are affected — cross-file and
     cross-session pollution from shared state is a real, recurring bug
     class, not a hypothetical one.
   - **If a trigger is supposed to cause a consequence** (a merge
     triggers a release, an approval triggers a resume, a webhook
     triggers a notification), **verify the consequence happened,
     independently.** Never let the trigger's own "succeeded" status
     stand in for proof that what it was supposed to cause actually did.
   - For infrastructure or integration work, verify against the real
     target system at least once — real CI, a real external API, a real
     deployed instance — before declaring it done. A local simulation
     passing is not the same claim.
6. **Document.** Update the durable-knowledge doc if system state
   changed. Record what was learned honestly, including what *didn't*
   work and wrong turns taken — a sanitized success narrative is worse
   than no narrative, because it's trusted and wrong. If this project's
   narrative-history doc has a current-state summary (see §5): overwrite
   its summary paragraph and next-step pointer — replace, don't append —
   and append one dated entry to the current period's archive file. Do
   this in the same unit of work as the change itself, not as a
   separate, skippable follow-up.
7. **Commit small, commit often, push immediately.** One commit per
   independently coherent unit of work, not a whole phase batched into
   one. Never `--amend` a previous commit for follow-up work — a new
   commit, always.
   - **"Push immediately" describes a trunk with no second human
     reviewing it** — the coherent default for a solo operator working
     through AI agents directly on trunk. **In a multi-contributor
     setting, gate merge on review before this step applies**: most
     real engineering teams require human (or required-bot) review,
     CODEOWNERS, or branch protection before a change lands on the
     shared trunk. This file does not prescribe a specific tool,
     reviewer count, or branch-protection config — calibrate the gate
     to this project's own rules (see `ADAPTERS.md` if the project has
     one). The broader mechanics of how a multi-human team coordinates
     with each other and with concurrent agent sessions — pairing,
     on-call, postmortems, resolving conflicting concurrent work — is
     a separate, opted-in concern (e.g. `packs/human-team-coordination`),
     not part of this step's own review-gate scope.

## Auto-Moderation Protocol (Claude Code Supervision) — Advisory, Not Binding

- **Advisory Supervision**: Major architectural plans, code refactors, or
  quality gate checks may be spot-audited by an agent CLI (e.g.
  `claude -p`) as an informal second reviewer.
- **Not Binding by default**: These audits are advisory input, not a
  binding gate, unless a real CI job exists in this repo that runs it and
  fails the pipeline on a negative finding — verify that before claiming
  "binding supervisory authority" (see
  `METHODOLOGY.md#why-unverified-binding-authority-claims-are-a-3-violation`).
