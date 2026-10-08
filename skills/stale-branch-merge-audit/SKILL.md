---
name: stale-branch-merge-audit
description: "Use before rebasing or merging any branch that has sat unmerged while main kept moving — a stale feature branch, an old worktree branch, a parked proposal. Covers how to see the branch's real unique contribution (not main's unrelated churn), how to tell a genuine content collision from drift, how to check whether either side is resurrecting content the project's own history already rejected, and which personas to dispatch automatically instead of re-deciding each time."
---

# Stale Branch Merge Audit

Grounded in a real case (2026-09-06): two branches forked before this
repo's Phase 2 methodology-storage-restructure were both resolved. A
naive `git diff main <branch>` made both look like they were reverting
the restructure and colliding on ~28 files. Neither was true — both
artifacts came from comparing against main's *current tip* instead of
each branch's actual fork point.

## 1. Diff against merge-base, never against main's tip

`git diff main <branch> --stat` conflates two unrelated things: what
main did *after* the branch forked (which the branch is simply missing,
and which shows up as the branch "deleting" or "reverting" it), and
what the branch's own commits actually changed. Only the second thing
matters for merge-readiness.

Always compute the branch's real footprint like this instead:

```
base=$(git merge-base main <branch>)
git log main..<branch> --oneline # the branch's own unique commits
git diff --stat "$base" <branch> # what those commits actually touch
git diff --stat "$base" main # what main gained that the branch is missing
```

Two branches can look like they collide on dozens of files by the
naive diff and share zero files in their real, `merge-base`-relative
footprint. Don't report "these conflict" from the naive diff alone.

## 2. A conflict marker is not proof of a genuine collision

Once real conflicting files are identified (a real rebase attempt, not
just file-list overlap), read the actual conflicting hunks before
deciding whether it's trivial drift (safe to auto-resolve by taking the
rebased content) or a genuine collision. Before resolving either way,
check whether one side is resurrecting content the project's own
durable history (`HISTORY.md`, `CHANGELOG.md`, `git log --all | grep
-i revert`) already documents as rejected, reverted, or superseded —
in that case the correct resolution is usually "drop the commit
entirely," not a textual merge of both sides. Concretely, in the case
this skill is grounded in: a branch's tip commit fixed a one-line bug
inside a pack that had since been proposed, benchmarked twice, found
to overstate its results both times, and formally removed from main
through a documented process — the fix was moot, not a bug to
resolve. Verify this against the actual commits (`git show`, `git log
-p -- HISTORY.md`), not by trusting a subagent's or your own paraphrase
of what happened — see step 4.

Also check whether a stale branch's own commit duplicates policy
content main has since added independently, just in a different (and
by the project's own current rules, more correct) location — e.g. a
mandate written inline in `AGENTS.md` before a thin-core restructure
moved that class of content into `methodology/*.md`. Merging the
duplicate back in verbatim would reintroduce bloat a size gate
(`scripts/check_core_size.py`) exists specifically to prevent. Diff the
substance, not just the section title, before concluding it's genuinely
new content worth keeping.

## 3. Dispatch personas by domain, without re-asking each time

This is cross-domain work under `AGENTS.md` §1.1 whenever the branch
touches both docs/process *and* application code: dispatch a
**Codebase Hygiene Specialist** (reproduces the conflict, classifies
each conflicting file as drift vs. collision, sweeps for other
stray/duplicated work across sibling branches) and, whenever a
conflict touches actual application code (not just docs), a
**Multi-Project Product & Security Auditor** in parallel (traces the
specific commit's logic change against what current `main` actually
does, renders a go/no-go on whether the fix is still needed). Copy
each persona's system prompt verbatim from
`packs/solo-founder-governance/PACK.md` per the `adopt-persona` skill —
don't paraphrase, and don't ask the human which persona to use each
time this shape of task comes up; the domain split above is now the
default.

**Give each dispatched persona its own git worktree, never the shared
main checkout.** Confirmed live in the case this skill is grounded in:
two persona subagents both ran `git checkout <branch> && git rebase
main` against the same shared working directory concurrently — one
observed the other's rebase mid-flight as if it were the ambient repo
state, and correctly refused to touch it, but only because it happened
to check first. This is exactly the collision class
`methodology/tiers.md`'s Parallel Execution & Worktree Lifecycle
Mandate (v5.22.0) already exists to prevent for human-visible parallel
branches — it applies identically to agent-dispatched subagents doing
git operations, not just to top-level sessions, and isolation should
be set up before dispatch, not discovered as a race after the fact.

## 4. Don't amplify a subagent's dramatic framing without checking the primary source

A dispatched persona's report characterized rejected content as
"fabricated" and pushed by a "rogue agent session." Checking `git log
-p -- HISTORY.md` directly showed the real story was more mundane: a
real experimental pack, benchmarked twice, both times found to reuse a
previously-rejected proxy metric under a new label instead of the
requested real result, and closed through this project's own
documented process (`AGENTS.md` §3 step 1's empirical verification
working as intended) — not malice. Before repeating an alarming
characterization from a subagent to the human, verify it against the
actual commits/`HISTORY.md` yourself; report the corrected, sourced
version, not the paraphrase, especially when the paraphrase implies a
security incident the sourced version doesn't support.

## 5. What still needs a human decision vs. what doesn't

Process-level calls (is this drift or a collision, should this commit
be dropped as moot, does merging need worktree isolation) are this
skill's default answer — don't re-ask for these. Content/product calls
(should a roster entry for a real sibling service be documented in the
wiki even though the pack tying it to this repo was rejected) are not
process questions and still need the human's call — surface them
distinctly from the process verdict, not bundled into "conflicts
found."
