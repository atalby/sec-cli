@AGENTS.md

## Claude Code specifics

This file exists only because Claude Code does not yet auto-discover
`AGENTS.md` the way Gemini CLI, Cursor, and several other tools do (see
`docs/wiki` — "Tool Bridges" — for the current state of that). The
`@AGENTS.md` line above imports that file's full content into this
session exactly as if it were written here directly. Everything in
`AGENTS.md` applies; nothing below overrides it.

- **Plan Mode is this project's mechanism for step 3 of the core
  development loop** ("Plan" — write a design, get explicit approval
  before implementing). Use it for anything matching `AGENTS.md`'s own
  calibration guidance (risk, not line count).
- If a project-specific `CLAUDE.md` addendum is needed (secrets,
  sandbox URLs, anything that shouldn't be committed), put it in a
  gitignored `CLAUDE.local.md` alongside this file, not in this one.
