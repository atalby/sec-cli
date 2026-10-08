# Skill Registry

Tool-agnostic index of every skill/procedure in this repo. Any agent
tool — not only Claude Code — should check this table's Trigger
column against the current task during the Boot Sequence (`AGENTS.md`
§2) and open the matching skill's file before proceeding.

`adopter` skills live under `skills/` and are meant to be copied into
adopting projects (see `AGENTS.md` §0). `hub-internal` skills live
under `.hyer/skills/` and cover this hub's own release engineering —
never copy these files into an adopting project. That is a
distribution rule, not an access rule: `AGENTS.md` itself references
several hub-internal skills by name in normative prose, and an
adopting project's own agent can still fetch a hub-internal skill's
full body — without ever getting a local copy of the file — via the
`hyer` MCP server's `list_skills` tool (`skill: "<name>"`
argument), the same server used for `get_methodology`/`sync_status`.
Confirmed 2026-08-26: `list_skills` applies no distribution-based
filtering — it was simply never documented as the retrieval path for
these until now. Requires that server actually be wired in your
project's `ADAPTERS.md`; if it isn't, that's the gap to fix, not a
reason to skip the skill.

| Skill | Path | Trigger | Distribution |
|---|---|---|---|
| engineering-loop | `skills/engineering-loop/SKILL.md` | any non-trivial implementation task | adopter |
| fleet-agent-coordination | `skills/fleet-agent-coordination/SKILL.md` | multiple concurrent agent sessions need to coordinate | adopter |
| hyer-session-currency | `skills/hyer-session-currency/SKILL.md` | session start | adopter |
| reuse-before-build | `skills/reuse-before-build/SKILL.md` | before implementing new tooling from scratch | adopter |
| roadmap-reconciliation | `skills/roadmap-reconciliation/SKILL.md` | auditing docs/history for ideas never filed as issues | adopter |
| self-diagnose-and-plan | `skills/self-diagnose-and-plan/SKILL.md` | session start, or "what's next" | adopter |
| adopt-persona | `skills/adopt-persona/SKILL.md` | dividing cross-domain work across an opted-in persona taxonomy | adopter |
| targeted-code-reading | `skills/targeted-code-reading/SKILL.md` | reading a file over ~200 lines | adopter |
| session-restart-handoff | `skills/session-restart-handoff/SKILL.md` | a session has sprawled, hit a clean boundary, or needs to hand off to another session/repo | adopter |
| stale-branch-merge-audit | `skills/stale-branch-merge-audit/SKILL.md` | rebasing/merging a branch that sat unmerged while main kept moving | adopter |
| adopter-drift-self-check | `.hyer/skills/adopter-drift-self-check/SKILL.md` | wiring drift-check CI into an adopting repo | hub-internal |
| diagnosing-hook-context-corruption | `.hyer/skills/diagnosing-hook-context-corruption/SKILL.md` | a git hook's test/build step behaves differently than running it directly, or unstaged content shows up committed | hub-internal |
| moving-stable-tag | `.hyer/skills/moving-stable-tag/SKILL.md` | cutting a new methodology release | hub-internal |
| self-learning-skill-synthesis | `.hyer/skills/self-learning-skill-synthesis/SKILL.md` | after a non-trivial bug fix or correction | hub-internal |
| self-refreshing-pre-commit-hook | `.hyer/skills/self-refreshing-pre-commit-hook/SKILL.md` | onboarding, or a hook's version banner looks stale | hub-internal |
| testing-skills-with-evals | `.hyer/skills/testing-skills-with-evals/SKILL.md` | creating or materially editing a skill | hub-internal |
| vet-third-party-tool | `.hyer/skills/vet-third-party-tool/SKILL.md` | before wiring a new external CLI/library/service into the project | hub-internal |
| verifying-negative-existence-claims | `.hyer/skills/verifying-negative-existence-claims/SKILL.md` | about to assert something doesn't exist | hub-internal |
