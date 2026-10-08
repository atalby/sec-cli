---
description: Exhaustive twelve-dimension forensic audit of the sec-cli repository
agent: build
---

Load the `architecture-360-audit` skill via the `skill` tool and follow it
end to end. Its canonical file is `skills/architecture-360-audit/SKILL.md`; the
copy at `.agents/skills/architecture-360-audit` is a symlink to it, so read
whichever path resolves.

Do not paraphrase, summarise, or re-derive the audit procedure. The skill is
the procedure. Load it, then execute its steps in order.

It begins by asking the user to confirm before starting. Honour that gate.

This command is the same entry point as saying any of these in plain language:
"run the 360 check", "do a 360 review", "360 audit", "full audit", "deep
audit", "comprehensive review", "architecture audit", "secret-management
audit", "CLI audit", "audit the repository". Those phrases trigger the
skill directly, with or without this slash command, so a harness with no
slash-command support is not blocked.

Optional extra focus: $ARGUMENTS
