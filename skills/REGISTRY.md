# Skill Registry

Tool-agnostic index of every skill/procedure in this repo. Any agent
tool should check this table's Trigger
column against the current task during the Boot Sequence (`AGENTS.md`
§2) and open the matching skill's file before proceeding.

`adopter` skills live under `skills/` and are meant to be copied into
adopting projects (see `methodology/adoption.md`, `AGENTS.md` §0). `hub-internal` skills live
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

`project-specific` is the third value, and it is the one an **adopting
project writes for itself**: a skill that repo authored, living under
its own `skills/`, never part of the hub payload and never synced from
here. Use it for anything this hub will not ship you. It exists
because the vocabulary above was previously the whole vocabulary, so a
repo that wrote its own skill had to either mislabel it `adopter`
(claiming the hub owns it) or move the file somewhere `AGENTS.md` §2
step 2 never looks — added 2026-09-09 after an adopting project was
left unable to commit at all (issue #74). Rows carrying it are excluded
from every hub-drift comparison, so your own skills never read as
divergence from `stable`. It is valid under `skills/` only:
`.hyer/skills/` rows stay `hub-internal`, since a mislabelled row
there would drop a real hub skill out of that same comparison.

| Skill | Path | Trigger | Distribution |
|---|---|---|---|
| adr-capture | `skills/adr-capture/SKILL.md` | an architectural decision between alternatives is reached during planning | adopter |
| codebase-onboarding | `skills/codebase-onboarding/SKILL.md` | first session in an unfamiliar repo, or a request to onboard/understand a codebase | adopter |
| confirming-repo-ownership | `skills/confirming-repo-ownership/SKILL.md` | the task names or reaches a path outside this session's working directory | adopter |
| security-review | `skills/security-review/SKILL.md` | reviewing code, a merge request, or a dependency set for security | adopter |
| distribution-target-and-credential | `skills/distribution-target-and-credential/SKILL.md` | about to publish, release or deploy an artifact out of this repo, or to conclude a human must mint a credential | adopter |
| tdd-workflow | `skills/tdd-workflow/SKILL.md` | test-first implementation of any feature or bugfix | adopter |
| engineering-loop | `skills/engineering-loop/SKILL.md` | any non-trivial implementation task | adopter |
| fleet-agent-coordination | `skills/fleet-agent-coordination/SKILL.md` | multiple concurrent agent sessions need to coordinate | adopter |
| hyer-session-currency | `skills/hyer-session-currency/SKILL.md` | checking HIAE version currency against stable, or unread fleet-bus messages | adopter |
| hyer-operations | `skills/hyer-operations/SKILL.md` | which credential to use for which job, where each one lives, bus self-check, or an unexplained auth failure | adopter |
| reuse-before-build | `skills/reuse-before-build/SKILL.md` | before implementing new tooling from scratch | adopter |
| roadmap-reconciliation | `skills/roadmap-reconciliation/SKILL.md` | auditing docs/history for ideas never filed as issues | adopter |
| self-diagnose-and-plan | `skills/self-diagnose-and-plan/SKILL.md` | session start, or "what's next" | adopter |
| adopt-persona | `skills/adopt-persona/SKILL.md` | dividing cross-domain work across an opted-in persona taxonomy | adopter |
| targeted-code-reading | `skills/targeted-code-reading/SKILL.md` | reading a file over ~200 lines | adopter |
| session-restart-handoff | `skills/session-restart-handoff/SKILL.md` | a session has sprawled, hit a clean boundary, or needs to hand off to another session/repo | adopter |
| verify-citation-before-relying-on-it | `skills/verify-citation-before-relying-on-it/SKILL.md` | acting on "file X line N cites §Y", or deleting/renumbering anything addressable by number | adopter |
| measure-before-asserting-environment | `skills/measure-before-asserting-environment/SKILL.md` | writing a measured-looking claim about a runner, host, container or service into a durable file, especially when it contradicts what the repo already documents or lands in more than one file | adopter |
| diagnose-a-noisy-check | `skills/diagnose-a-noisy-check/SKILL.md` | a gate, lint or alert fires too often to read, and muting/thresholding/deleting it is on the table | adopter |
| stale-branch-merge-audit | `skills/stale-branch-merge-audit/SKILL.md` | rebasing/merging a branch that sat unmerged while main kept moving | adopter |
| canonicalizing-repo-identity | `skills/canonicalizing-repo-identity/SKILL.md` | writing or aggregating per-repo state keyed by a directory or repo name, where worktrees or clones fragment one repo into several rows | adopter |
| 360-audit-skill-forge | `skills/360-audit-skill-forge/SKILL.md` | forging a 360 audit instrument, or binding a twelve-dimension audit to a single tree | adopter |
| architecture-360-audit | `skills/architecture-360-audit/SKILL.md` | asking for an exhaustive end-to-end sweep of THIS repository's code, CLI surface, and secret-management claims: "run the 360 check", "do a 360 review", "360 audit", "full audit", "architecture audit", "secret-management audit", "CLI audit" (NOT for building or forging an audit skill -- that is 360-audit-skill-forge); `/360-check-update` refreshes this skill against the current tree | project-specific |
| adopter-drift-self-check | `.hyer/skills/adopter-drift-self-check/SKILL.md` | wiring drift-check CI into an adopting repo | hub-internal |
| adoption-self-service-drill | `.hyer/skills/adoption-self-service-drill/SKILL.md` | verifying the adoption/sync process is actually self-serviceable by a blind agent | hub-internal |
| diagnosing-hook-context-corruption | `.hyer/skills/diagnosing-hook-context-corruption/SKILL.md` | a git hook's test/build step behaves differently than running it directly, or unstaged content shows up committed | hub-internal |
| moving-stable-tag | `.hyer/skills/moving-stable-tag/SKILL.md` | cutting a new methodology release | hub-internal |
| parsing-markdown-tables-in-tests | `.hyer/skills/parsing-markdown-tables-in-tests/SKILL.md` | asserting the semantic content of a markdown table in a test, where a cell regex that fails to match skips the row silently | hub-internal |
| self-learning-skill-synthesis | `.hyer/skills/self-learning-skill-synthesis/SKILL.md` | after a non-trivial bug fix or correction | hub-internal |
| self-refreshing-pre-commit-hook | `.hyer/skills/self-refreshing-pre-commit-hook/SKILL.md` | onboarding, or a hook's version banner looks stale | hub-internal |
| testing-skills-with-evals | `.hyer/skills/testing-skills-with-evals/SKILL.md` | creating or materially editing a skill | hub-internal |
| vet-third-party-tool | `.hyer/skills/vet-third-party-tool/SKILL.md` | before wiring a new external CLI/library/service into the project | hub-internal |
| verifying-negative-existence-claims | `.hyer/skills/verifying-negative-existence-claims/SKILL.md` | about to assert something doesn't exist | hub-internal |
| verifying-a-guard-fails-closed | `.hyer/skills/verifying-a-guard-fails-closed/SKILL.md` | writing or reviewing a guard whose whole job is to stop early — a set -e credential loader, a preflight check, a required-value guard — or before claiming any check is fail-closed | hub-internal |
| verifying-which-mcp-build-is-running | `.hyer/skills/verifying-which-mcp-build-is-running/SKILL.md` | a tool's behaviour contradicts the source you are reading, or after editing a server's source without rebuilding | hub-internal |
