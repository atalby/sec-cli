# Changelog — solo-founder-governance pack

Note: the `docs/superpowers/…` path referenced below moved to
`docs/hyer/…` on 2026-08-31 (HIAE Protocol §0 tool-neutral-structure
rule); the history line is left unedited on purpose.

## v1.4.0 (2026-09-18, issue #151)

**Adds Persona 9: UI/UX Design Reviewer** (found as missing after a real
review of two product surfaces with drifting visual identity): reviews
design-token/theme coherence, typography, layout, accessibility, and
visual professionalism; proposes ONE consolidated semantic token
architecture; produces a sober, domain-appropriate design direction for
the designated approver; never owns implementation or merges. Distinct
from both the Multi-Project Product & Security Auditor (correctness,
not pixels) and the Codebase Hygiene Specialist (code entropy, not
theme coherence). ADAPTERS.md's opted-in pack pin follows in the same
release so the hub's own drift gate stays green.

## v1.3.0 (2026-08-31)

**InfraAgent gains an explicit `Traits` field** (founder request):
automation-first as InfraAgent's default stance, not a preference —
every repeatable action is expressed as IaC/scripted tooling before
it's ever run by hand; manually running commands on a live box or
manually configuring something through a console UI is the last
resort, never a shortcut, and any unavoidable manual step is codified
back into tooling immediately afterward. Mirrored into InfraAgent's
"Persona system prompts" entry (§3) in the same sentence style as its
existing Focus line. No other persona changed.

## v1.0.0 (2026-08-22)

Initial extraction from `AGENTS.md` v4.10.0 §1.1 (persona taxonomy),
§1 (Breach Protocol escalation target), and §6 (deployment sign-off
authority) as part of the v5.0.0 opinionated-content extraction (see
root `CHANGELOG.md` and
`docs/superpowers/specs/2026-08-22-opinionated-content-extraction-design.md`).
Also absorbs the persona system prompts from the now-retired
`skills/prompt-suite/SKILL.md`, correcting a stale `$50/day` cost
figure and a `DevFleetAgent` naming drift against the actual persona
taxonomy in the process.
