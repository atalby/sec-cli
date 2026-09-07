# Automated Tooling & Token Efficiency Directives

> Detail module for `AGENTS.md` §8. Loaded on demand — see the module
> table in `AGENTS.md` §0. This file is part of the adopter payload
> (§0: "adopting Hyer means the full payload, not a hand-picked
> subset"), copied alongside `AGENTS.md` and `skills/`.

To keep sessions fast and cheap:

1. **Subagent delegation**: any multi-file investigation, web-search
   sweep, or log analysis spanning >3 files or >2 web pages goes to a
   subagent — isolated context, concise summary back.
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

## Right Tool for the Right Job

> This subsection was `AGENTS.md` §1.3 before Phase 2; folded in here
> since both concern practical tooling discipline. `AGENTS.md` §8
> carries a short pointer.

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
- **This is a principle to apply going forward and when a script is next
  touched, not a mandate to mass-rewrite existing scripts today** — per
  §1.2's Laser Task Focus, don't open unrelated refactors as a side
  effect of an unrelated change. Existing over-scoped shell scripts are a
  known gap, tracked as backlog (§4), not silently fixed in passing.
