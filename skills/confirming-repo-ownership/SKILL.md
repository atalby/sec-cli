---
name: confirming-repo-ownership
description: "Establish who owns a repository before reading, editing, or committing anything in it, when the task at hand names or reaches a repository other than the one your session was opened for. Use when a task mentions a second repo, when another session's work is in view, when a fix seems to belong somewhere you were not asked to open, or before any file write whose path is outside your session's working directory."
---

# Confirm repo ownership before acting

A session has one repository. Anything outside it has an owner, and the
owner is not you until they say so. This applies to reads that look
harmless, to writes that look trivial, and to your own dispatched
subagents.

## Why this exists

Recorded 2026-10-03. Six agents holding write access to a second
repository were dispatched for work in this one. They edited that
repository: six files restored, nine untracked files removed, verified
clean, nothing committed. The founder's instruction was to file an issue
in the repository that owns the problem instead.

The rule that should have prevented it already existed, verbatim, since
v5.28.0 in `methodology/tiers.md` under **Cross-Repo Ownership &
Ask-Don't-Read Mandate**, and `AGENTS.md` routes "cross-repo ownership"
to that file. It names both exemptions that were reached for: *even "just
to check"*, and *a subagent given a task in another repo/domain is still
bound by this mandate, not exempted because a human didn't type the
request directly*. Neither exemption survived contact with the text. The
file was simply never opened.

The failure was therefore not a missing rule. It was a **missing hop**:
a file of binding mandates reachable only through a topic-indexed lookup
table, consulted for the subject of a task. Nobody thinks to look up
"ownership" while working on a publish job. The lookup happens when you
already suspect a boundary, which is after the boundary has been crossed.

## Procedure

### 1. Notice the moment a path leaves your working directory

This is the whole skill. The trigger is not "think about ownership" --
it is noticing that a path, a repo name, or a `workdir` argument is
outside the directory your session was opened in. That observation is the
checkpoint, and it happens *before* the read or the write, not after.

Common shapes that mean a second repo is in play:

- the task text names a repository, service, or directory you were not
  opened in;
- another session's work is visible -- a dirty worktree, an open branch,
  a file you did not create;
- a fix "obviously belongs" somewhere else, which is a feeling worth
  treating as a stop rather than as a direction;
- a dispatched subagent was handed a path outside this repo.

### 2. Establish the owner before you touch anything

Resolve it mechanically, not from memory and not from what the task
sounds like. One command answers the only question that can be got wrong
by reasoning:

    git -C <target-path> rev-parse --show-toplevel

Run it from inside the directory you are about to write to, and run your
own session's root the same way. If the two roots differ, the path is in
a second repository, and every remaining step of this skill applies. The
command exits non-zero outside any repository, which is the cheap case:
there is no owner to consult, so ask rather than assume. Run this
*before* the first write. Afterwards it only describes what you already
did.

Be honest about what this is: a comparison you are required to make, not a
sandbox. It does not intercept an edit you make without running it, and no
pre-commit hook can, because a write to another repository is invisible to
this repository's hooks. What it does give you is a named, checkable step
that a diff cannot quietly skip, and a fact you can state rather than
recall -- the root you resolved, and the fact that it matched or did not.

The owner's own repository declares ownership, and that declaration is
local to the repository it describes -- there is deliberately no central
roster to go stale. So read the target repository's own
`ADAPTERS.md` ownership field. If the project binds a live inter-session
bus, also check whether a session for that repository is online right
now.

Three outcomes, three different permissions:

- **Owned** -- you message the owner and let them act in their own
  repository, even for something that looks trivial or read-only-safe
  from outside. Their in-flight work and session state are things you
  cannot see from out here.
- **Unowned** -- read what you need to answer the question you were
  actually asked. That is all. Any change still gets surfaced to a human
  or the declared approver before you make it.
- **Ask-first-beyond-read** -- same as unowned: reading answers the
  question; changing is a separate, surfaced decision.

### 3. Reach the owner the way the fleet is wired, not the way that is nearest

Where a bus binding exists, the owner is reached on the bus. A host
tool's built-in direct-messaging feature is not a substitute: it is not
what the other session is reading, and a message delivered somewhere the
recipient never looks is indistinguishable from no message at all.

### 4. If the work really does belong there, put it where it can be decided

The correct output for out-of-scope work is not a local edit and not a
silent drop. It is a proposal raised **in the owning repository**, where
that repository's own owner can judge it against its own context. That
means an issue, not a patch. Write it so the receiving owner can act
without re-deriving what you already measured -- including the evidence,
and including anything that contradicts an earlier claim, because a
proposal that carries a false premise is worse than no proposal.

State plainly that you made no change there.

### 5. Treat your subagents as bound by the same rule

A dispatched subagent holding write access to a second repository is
still bound. So is a task handed to you by a human who typed it
directly. Authority to *ask* someone to work in another repository is not
authority to work there yourself, and it does not transfer to an agent you
spawn. If a task cannot be completed inside your own repository, that is
a fact to report, not a boundary to route around.

### 6. When you have already crossed, restore before you report

If files were changed in a repository you did not own, restore them to
the state you found -- including untracked files, which `restore` does
not touch -- and verify the result is clean at a known commit before you
say anything about it. Verify, do not assume: an untracked file left
behind is exactly the residue this rule exists to prevent.

## Edge cases worth naming

- **A repo you have standing access to.** Being able to write to a
  repository is not being able to decide in it. Access answers "can",
  never "should".
- **A genuinely trivial fix.** The mandate calls this out by name. Trivial
  is a judgement about size, and size is not the question; ownership is.
- **A one-line config in someone else's repo.** Same answer, and it is
  worse in one respect: a one-line change to another repository's config
  is invisible in review there, because nobody is reviewing it.
- **A read you already did.** Do not reframe it as harmless because it
  changed nothing. Ask-not-read exists precisely because reading can
  inform a write you should not make.
- **The work genuinely belongs to the other repo.** Then it is not
  blocked, it is misrouted. Raise it there.
- **An unowned repo with no bus binding.** "Unowned" authorises a read,
  not a change, and it does not create a queue. Someone has to be asked.

## Verification

You have done this correctly when, for every repository your task touched
other than your own, you can name: the moment you noticed the path left
your working directory, whose declaration told you who owned it, how you
reached that owner, and what you raised there instead of changing
anything. If a repository outside your session was modified and you cannot
produce all four, restore it and say so.

## Composes with

- `fleet-agent-coordination` -- the bus protocol for reaching the owner,
  once step 2 has established that there is one.
- `adr-capture` -- the other case where "obvious" and "decided" come
  apart.
