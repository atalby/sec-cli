---
name: measure-before-asserting-environment
description: Use before writing a factual claim about a host, runner, container, service, or other environment into a durable file, especially when the claim contradicts what the repo already documents or is about to be written into more than one file. Get the value from that environment's own authoritative source, or mark it unmeasured.
---

# Measure Before Asserting an Environment

A claim about an environment is a measurement, and a measurement has a
source. If you cannot name the command, file, line or URL the value came
from, you have not measured it. You have guessed something that looks like
a measurement, and the two are not the same kind of object.

**Empirical origin (2026-09-28, issue #201, commits `55e7265` then
`b4aaacc`).** An OCI deploy plan had carried, for a week, the premise
that the shared GitLab CI runner is aarch64 with no x86 emulation, and
four documents repeated it. Reasoning that the premise looked wrong, I
"corrected" all four: the runner is x86_64, the repo was wrong, and the
correction was committed across seven files. The `kernel=6.18.48-109.150`
string behind it had come from some machine that was not the CI runner at
all. Reading the pipeline's own job trace -- the one authoritative source
for a CI runner -- gave `arch=aarch64 kernel=6.12.0-206.104.4.4.el9uek.aarch64`.
The repo had been right the entire time, and the cost was seven files,
two commits, and an on-the-record retraction in narrative history.

The failure was not carelessness about a detail. It was three separate
mistakes, each of which is individually easy to make.

## The three mistakes

1. **A value of the right shape, from the wrong source.** A plausible
   kernel string is exactly as plausible whether or not it came from the
   runner. Nothing in the value distinguished the two. Only its provenance
   did, and provenance was never checked.
2. **Treating a mismatch as evidence that the repo is wrong.** The repo
   said aarch64; I had x86_64 in hand; I concluded the repo was in error.
   But a mismatch between a durable doc and an unsourced value is a
   signal to find the authoritative source, not a finding. Every claim in
   the repo was backed by somebody's measurement. My value was backed by
   nothing.
3. **Amplifying before verifying.** The claim entered seven files in one
   commit. Correcting it took another commit across the same seven files,
   plus a paragraph of public retraction. Blast radius of a measurement
   scales with how many files consume it, so the cheapest moment to verify
   is before the second file, not after the seventh.

## When this triggers

- You are about to write a measured-looking value into a durable file:
  a version, a kernel, an architecture, a quota, a default, a capacity,
  a latency, a count of open issues, a token prefix.
- You are about to correct a statement the repo already makes. Existing
  documentation is evidence that a measurement happened, not evidence
  that it is stale.
- The same fact is about to be written into more than one file.
- You are writing the word "measured", "confirmed", "verified" or
  "actually" into a document.

## The procedure

1. **Name the authoritative source for that class of fact, before
   looking.** The authority is whatever the subject itself reports:
   - a CI runner, image, or job: its own log or trace
     (`glab api projects/<p>/jobs/<id>/trace`), or a job that prints the
     value you are about to assert
   - a running service: its own API, health or version endpoint
   - a remote host: output from that host, over the connection to it
   - a third-party limit or default: the vendor's current documentation
2. **Fetch it, and keep the output.** Save the trace or response to a
   scratch path and quote the line you are relying on. A fact you cannot
   point at is a fact you cannot defend later, and you will be asked.
3. **If the authoritative source is unreachable, write the claim as
   unmeasured.** "Unverified: the runner's architecture is not recorded
   in any pipeline trace yet" is useful, honest, and costs nothing to fix
   later. "Measured x86_64" when you read it off an unrelated host is
   neither.
4. **Verify the first file before writing the second.** One file, one
   retrieval from the authoritative source. Then the rest.
5. **If you have already written it, retract it in place and in the
   narrative history.** Do not quietly fix the docs. The fact that a
   wrong measurement was committed and retracted is itself a durable
   finding, and it is what stops the next agent from re-deriving the same
   plausible-looking value.

## Edge cases worth knowing

- **Local is not remote.** Running `uname -m` tells you about your shell.
  It is evidence about a CI runner only if you ran it inside the CI
  runner. These are different claims, and the second one is the one that
  gets written down.
- **"Measured" is a claim about provenance, not about confidence.** You
  may be quite sure of a value and still have no source for it. Both can
  be true at once, and the second one is what disqualifies the first.
- **A corrected fact and a retracted fact look identical in the diff.**
  Anyone auditing will assume your current text is right. That is why
  step 5 exists: the difference has to be recorded somewhere a reader
  will find it, not left for git blame.
- **Absence of a measurement is not a measurement.** Not finding evidence
  for the repo's claim is not evidence against it.
- **This composes with `verify-citation-before-relying-on-it`.** That
  skill catches a claim about what a *document* says. This one catches a
  claim about what a *system* is. A grep can only ever check the first.

## Verification

You have done this correctly when, for every measured value you wrote
into a durable file, you can name the exact source it came from, the
command or request that retrieved it, and the line you read. If any
value in the diff fails that test, either retrieve it now or change the
wording so it no longer claims to be measured.
