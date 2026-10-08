# The MCP / Skills / Plugins Triad Architecture

> Detail module for `AGENTS.md` §9. Loaded on demand — see the Module
> Table at the top of `AGENTS.md`. This file is part of the adopter payload
> (`methodology/adoption.md`: "adopting Hyer means the full payload, not
> a hand-picked subset"), copied alongside `AGENTS.md` and `skills/`.

To standardize agent capabilities, knowledge organization, and tool
interoperability:

1. **Model Context Protocol (MCP) — The Hardware & API Bus Layer**:
   - Connects LLM agents to deterministic external systems via typed,
     sandboxed JSON-RPC interfaces.
2. **Skills (`SKILL.md`) — Procedural SOPs & Workflow Playbooks**:
   - Markdown instruction packages (`SKILL.md` with YAML metadata +
     helper scripts) loaded strictly on-demand when specific domain
     tasks trigger them, kept out of always-loaded context.
   - A skill is trusted prose by default — nothing verifies its
     instructions still produce the right behavior after an edit. For
     any skill where following it wrong would matter, add regression
     eval cases; see the `testing-skills-with-evals` skill (hub-internal
     — §2 step 2 for how to fetch its content from outside this repo).
3. **Plugins — Namespaced Capability Bundles**:
   - Higher-level self-contained packages that bundle MCP servers,
     Skills, Sidecars, and Hooks into namespaced, shareable units for
     single-command installation.

See `METHODOLOGY.md#why-mcp-skills-and-plugins-stay-three-separate-things`
for the reasoning behind keeping these three distinct, and this
project's own issue/merge-request templates for how this gets enforced
day to day.
