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
- **This is a principle to apply going forward and when a script is next
  touched, not a mandate to mass-rewrite existing scripts today** — per
  §1.2's Laser Task Focus, don't open unrelated refactors as a side
  effect of an unrelated change. Existing over-scoped shell scripts are a
  known gap, tracked as backlog (§4), not silently fixed in passing.

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
