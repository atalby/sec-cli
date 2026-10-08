---
name: verify-citation-before-relying-on-it
description: Use before acting on a claim of the form "file X line N cites §Y" — from a subagent report, an audit, a grep result, or your own earlier note. Read the cited line and its surroundings first; a section number matched by grep is not evidence of what the line actually says. Especially before deleting, renumbering, or moving anything a citation addresses.
---

# Verify a Citation Before Relying On It

A grep for `§2` finds every line containing that string. It does not
tell you whether the line cites §2 as a whole, cites §2 *step 2*,
mentions §2 in passing, or belongs to a code comment quoting an older
version of §2. Those four cases license completely different actions,
and only reading the line distinguishes them.

**Empirical origin (2026-09-10, issue #75).** During an `AGENTS.md`
restructure, two separate constraint reports pointed at the wrong
section, both produced by grepping a section number without reading the
surrounding line. The second one nearly shipped real breakage: a report
said `scripts/check_skill_registry.py` cites §0, so §0 looked safe to
collapse. The line actually reads "§2 step 2 sends every agent looking."
Checking it surfaced 31 live citations addressing §2's steps *by number*
— including a template file shipped to adopters — plus a standing
decision in the repo's own plan documents refusing to renumber those
steps for exactly that reason. A ruling to collapse §2 to two lines was
overturned as a result. That ruling would have deleted the addressing
surface 31 citations depend on.

## When this triggers

- A subagent, audit, or review hands you "file X line N cites §Y."
- You are about to delete, renumber, stub, or move anything addressable
  by number: a section, a numbered step, a checklist item, an enum value.
- You are about to conclude something is *unreferenced* and therefore
  safe to remove.
- You wrote the citation yourself earlier in the session. Your own note
  is not exempt; it was produced by the same fallible method.

## The procedure

1. **Read the cited line at its cited number**, plus a line either side.
   `sed -n '<N-1>,<N+1>p' <file>`. Not the file, not a grep of the file.
2. **Check what is actually addressed.** A section number and a numbered
   sub-item within it are different addresses. `§2` surviving does not
   mean `§2 step 2` survived. This is the exact distinction both failures
   above collapsed.
3. **Re-grep for the real address once you know it.** The first grep was
   for the wrong string, so its count means nothing. Search for the
   sub-address (`§2 step`, not `§2`) and exclude history, changelogs and
   specs, which cite freely without depending on anything.
4. **Check for a standing decision.** If a numbering scheme is load-bearing,
   someone has usually already refused to change it. Search plans and
   specs for "renumber", "cites", "by number", "addressing".
5. **Only then act.** If the count changed by an order of magnitude
   between steps 1 and 3, treat any ruling made on the old count as
   provisionally void and say so.

## Edge cases worth knowing

- **A citation can depend on content rather than a number.** Stubbing a
  section keeps its number resolvable while emptying it of what the
  citer relied on. Both kinds break; only one is visible to a grep for
  the number.
- **Code comments quoting a document** drift silently, since nothing
  validates a quotation. Treat a quoted sentence in a comment as a claim
  to verify, not as evidence of what the document says.
- **A report being confident is not evidence.** Both wrong citations
  above arrived in careful, well-structured reports with line numbers
  attached. Precision of format is not accuracy of content.

## Verification

You have done this correctly when you can state, for each thing you are
about to change, the exact address that is cited, the real count of live
citations to *that* address, and where you looked to exclude a standing
decision against changing it. If any of those three is an inference
rather than something you read, you are not done.
