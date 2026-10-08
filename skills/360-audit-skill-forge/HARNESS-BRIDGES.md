# Harness bridge layouts: a dated fallback table

This is a data table, not a prescription. `SKILL.md` states what every
bridge must satisfy and names no vendor; this file records the layouts
known as of the date below so that a build with no reachable harness
reference still has something to verify against.

Precedence, and it is not close: what the harness itself reads beats this
table. Use this when you cannot inspect a harness, and expect it to be
wrong for a harness it has never seen.

If a harness you are bridging is not listed, add a row. If a row is wrong,
correct it and note what told you. A table that is never corrected is worse
than no table, because it is confidently wrong in the shape of a reference.

Known as of 2026-10-04. Treat anything older than the audit's own vintage
as suspect.

| Harness | Command location | Format notes |
|---|---|---|
| opencode | `.opencode/commands/<command-name>.md` | YAML frontmatter with `description` and `agent: build` |
| Claude Code | `.claude/commands/<command-name>.md` | YAML frontmatter with `description` and `argument-hint` |
| Cursor | `.cursor/commands/<command-name>.md` | plain markdown, no frontmatter; its skills directory is not covered by the shared symlink and needs its own bridge if the operator configures it |
| Gemini CLI | `.gemini/commands/<command-name>.toml` | required `prompt` key, optional `description`, `{{args}}` for arguments |
| Windsurf | `.windsurf/workflows/<command-name>.md` | invoked as `/<command-name>` |
| Kiro | `.kiro/steering/<command-name>.md` | frontmatter inclusion `manual`, which surfaces as a slash command |

## What every bridge must contain, whatever the harness

These four are the contract. The table above only decides where the file
goes and what wrapper syntax it needs.

1. Name the canonical path, and state that the shared-directory copy is a
   symlink to it, so either path resolves and the reader need not care
   which.
2. Say to load the skill through the harness's skill tool and follow it end
   to end. A bridge that only names a path leaves the harness to guess
   whether to read it or invoke it.
3. Say "Do not paraphrase, summarise, or re-derive the audit procedure. The
   skill is the procedure. Load it, then execute its steps in order."
4. Note the confirmation gate, and list plain-language trigger phrases, so
   a surface with no slash menu is not blocked. An optional-extra-focus
   line passes the harness's argument token through.

The bridge is a pointer, not a summary. Its length is evidence of a bug.

## Both command names

The refresh bridge points at the same canonical file and at the
`## Regenerating this skill` section, which must exist with that exact
heading. Its body says it loads the skill in refresh mode, tells the reader
not to run the audit, and lists its own trigger phrases. No second skill
file and no second registry row are needed: the registry row is per skill,
the command name is per bridge.

Verify by name, after you have written both files, that every section a
bridge names exists in `SKILL.md`. A bridge pointing at a heading that is
not there is a broken entry point that looks finished.
