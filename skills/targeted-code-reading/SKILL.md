---
name: targeted-code-reading
description: "Use before reading any file over roughly 200 lines into context. Prefer symbol-level or line-range navigation over a full-file dump — cheaper, less context degradation, better cache behavior. Folds in Next-Era Feature 3 (AST-Aware Navigation Guard) as a tool-agnostic convention; any enforced version of this is a per-project, per-tool opt-in, not a core requirement."
---

# Targeted Code Reading

Loading an entire large file into context to look at one function
wastes tokens, degrades context, and hurts prompt-cache hit rates.
Before reading a file over ~200 lines in full:

1. **Locate the symbol first.** Use whatever your environment provides
   — a grep/ripgrep search for the function/class name, an AST-aware
   tool (`ast-grep`, tree-sitter-based search), or your tool's
   language-server "go to definition" — before opening the file.
2. **Read a line range, not the whole file.** Once you know roughly
   where the relevant code is, read a bounded slice around it rather
   than the full file. Widen the slice only if the surrounding context
   turns out to matter.
3. **Full-file reads are still fine when they're actually needed** —
   e.g. reviewing a file end-to-end for a self-review pass, or a file
   genuinely under ~200 lines. This is a default to prefer, not an
   absolute ban.

## Optional per-project enforcement

This skill documents the convention; it does not itself enforce it.
A project that wants this mechanically enforced for a specific tool
(e.g. a Claude Code `PreToolUse` hook rejecting an oversized full-file
read without a prior symbol search) should wire that in via its own
`ADAPTERS.md`, scoped to that tool — never assume every adopting
project's tool supports the same enforcement mechanism, and never bake
a single tool's hook mechanism into this skill or into core
`AGENTS.md`.
