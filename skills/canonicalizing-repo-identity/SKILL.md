---
name: canonicalizing-repo-identity
description: Use when any tool writes or aggregates per-repository state keyed by a directory or repo name — a cache, metric log, denial meter, drift record, or per-repo counter — and the repo is accessed through more than one path. Symptoms: one repository appears as several rows, records written from a worktree never reach the main repo, or a per-repo total reads zero while the raw log has entries.
---

# Canonicalize repo identity before keying state to a repo

`basename("$REPO_ROOT")` looks like a repo's identity but it is a path
segment, not an identity. Every git worktree and every additional clone
of the same repository presents a different directory name for the same
object store. Key per-repo state by the directory name and the repo
splits into as many rows as there are paths to it. The writes succeed;
the reader just never sees the records.

## Derive the key from the git common dir, shared by every worktree

Gate-time and pre-commit-time state is written from wherever the hook or
tool runs, often inside a worktree. `git rev-parse --show-toplevel`
returns the worktree path, which fragments. The git common dir is the
one thing every worktree shares instead:

    git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir

Take the canonical absolute common-dir path as the key. It is identical
from the main checkout and every worktree, survives the GIT_DIR /
GIT_COMMON_DIR env vars git exports to hooks, and names one object store
regardless of where each worktree is checked out. A bare `basename`
falls apart for bare repos and collides when two checkouts share a name;
symlink-resolve (realpath) so writer and reader are byte-identical even
when one side reaches the repo through a symlink. Fall back to git's
toplevel only when git cannot answer, and keep the recorder fail-open: a
silencing bug in the recorder is worse than the thing it records.

## Make reader and writer derive the IDENTICAL key

A canonical key is worthless if the reader joins on a different
spelling. Have both sides compute the same key function, then verify
with a real worktree: write a record from a linked worktree and assert
it lands on the main repo's row. Assert, do not eyeball.

## Two adjacent traps that inflate the same meter

- **Retry bursts.** A command a gate blocks is usually retried seconds
  later, so a retried-until-success event writes the same record twice
  while the committed counter advances once. Coalesce identical
  (repo, step) records within a short window, or give each logical
  event a stable id and upsert it in place under a lock.
- **Tiny denominators.** One denial in a three-commit window reads a
  huge percentage and false-flags. Floor on total attempts (committed
  plus denied), not committed alone, and print small-sample rows without
  judging them.

## Empirical origin, 2026-09-16

A denial meter recorded `basename("$REPO_ROOT")` while its reporter
aggregated under the canonical repo name. Every worktree-written denial
landed on the worktree's row, so the canonical row printed 0/N while the
raw log carried the denials. Two independent review agents found the
split only because the raw log was read next to the reporter's output;
no automated suite caught it.
