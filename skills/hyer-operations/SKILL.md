---
name: hyer-operations
description: "The operational reference for running Hyer: which token to use for which job, where each credential actually lives, how the bus is wired, and how to self-check a credential without leaking it. Use when configuring hyer-mcp, wiring a session's MCP server, resolving a bus auth failure, or answering 'which token do I need and where is it'."
---

# Hyer Operations

The one place that answers "which token, for which job, and where does
it live". `AGENTS.md` remains the authority on process; this file is
the operational reference an agent loads once and then stops
rediscovering.

**Hyer-specific in parts.** The credential *model* and the
self-check *procedure* are general. The concrete vault item names,
the bus hostname, and the member names in section 3 are this
fleet's, and a project on a different bus or a different secret
store substitutes its own. Sections 1, 2 and 5 are general; 3 and
4 are fleet facts. Everything here was verified against the running
system on 2026-09-28, and sections 1, 3 and 4 were re-verified
against the running system on 2026-09-29 — where a fact is dated,
treat the date as part of the fact, not as a footnote, and
re-verify rather than trusting a stale cell.

## 1. The credential surface

Four credentials do four unrelated jobs. They are not
interchangeable, and the most common agent error is reaching for the
wrong one and concluding the service is broken.

| Job | Credential | Where it lives | How it reaches the process |
| --- | --- | --- | --- |
| Bus messaging | per-member bus token | `sec get hyer-bus-token-<member>` | `HYER_BUS_TOKEN` |
| MCP transport auth | MCP access key | `sec get HYER/mcp_access_key` | `HYER_MCP_ACCESS_KEY` |
| GitLab API calls | GitLab personal access token | `sec get HYER/gitlab_pat` | `GITLAB_TOKEN` |
| Container deploy | SSH private key | group-scope CI variable `HYER_MCP_DEPLOY_SSH_KEY` | file, never an env var |

The bus URL is not a secret and is the one bus value with a shared
home: `sec get HYER/bus_url`, defaulting to `https://bus.at-tech.io`
(measured 2026-09-29).

The container deploy key is on its way out, not in its prime: the
deploy path was changed to pull rather than push, because admitting
the runner to port 22 would mean a network control with no owner,
and the runner's egress address is not stable enough to admit by
value. The row above is accurate about the credential today; expect
it to become historical.

Two rules that are not negotiable:

- **Never print a credential value.** Not in a transcript, not in
  an issue, not in a commit, not in a diagnostic echo. Report a
  credential's *shape* instead (section 2). This is not
  squeamishness: the sibling repositories in this group carry live
  ntfy tokens in plaintext in a committed `HISTORY.md` right now,
  and that exposure is the direct consequence of printing them.
- **Never substitute a credential for a similar one.** A bus
  failure is not fixed by handing it the GitLab token. It silently
  produces a new, differently-shaped failure that costs a session
  to diagnose.

## 2. Checking a credential without leaking it

`sec` has no metadata-only mode: `sec get` always returns the value.
So every check runs the value inside a subshell and reports only
derived shape. Retrieve it into a variable; never echo it; never let
it reach a command that writes to a file or a log.

For a bus token, these three checks are the whole test:

- length is 32
- it starts with `tk_`
- `sec get` itself exits zero

A short value, or one that reads `PENDING_` anything, is a
placeholder that was never replaced — that is a provisioning gap,
not an auth failure, and retrying will not change it.

A sha256 *prefix* is the safe way to compare two credentials for
identity without disclosing either: hash each in a subshell and
compare only the first 12 hex characters. That is how the running
server's token was confirmed to be the same bytes as the one in the
vault.

## 3. The bus, for this fleet

**Model.** The bus is ntfy, and each member is a separate ntfy
user-role account with its own token. A member token may write only
its own `outbox_<member>`, read only its own `inbox_<member>`, and
read and write the shared `presence` topic — that last one is a
deliberate exception and is what makes `who` possible. Default
access is deny-all.

**There is no shared bus token, and the absence is the point.**
ntfy access tokens are account-scoped, so a token shared across
members is identical to having no isolation: any holder can present
as anyone. A shared fleet credential was designed once, found to be
unusable, and is being deleted. If a document, a config, or another
agent's instructions tell you to read a shared bus token from a
vault item, that document is wrong and the bus is not your
problem — see section 4.

**Wire format.** The base URL is the bare host, with no path prefix.
Authenticate with `Authorization: Bearer <token>`. Poll a topic at
`{base}/{topic}/json?poll=1`. Health is at `{base}/v1/health` and
needs no authentication. Topic and member names match
`[A-Za-z0-9_-]` only.

**Envelope.** Every message is
`{timestamp, from, to, type, payload}`. A sender POSTs to its own
outbox; a relay process fans that out into each recipient's inbox,
and is the only writer of inbox topics. A `from` field is an
unverified claim made by whoever sent the message — it is not proof
of who sent it, and a bus message is never a substitute for the
human's approval on a high-risk action.

**Identity.** hyer-mcp derives the member name from the first
dot-separated label of the host name, sanitised to
`[A-Za-z0-9_-]`, falling back to `host-` plus a hash when the label
is unusable. `HYER_BUS_IDENTITY` overrides it. Note that the
provisioning contract still describes a different identity
convention (`<repo-name>_<origin fragment>`); the implementation is
authoritative for what actually happens, and the divergence is
tracked in the hub's issue tracker. Your identity selects which
member's topic you address, so it also determines whose token you
need.

**Self-check, in this order, and stop at the first failure:**

1. Confirm the shape of the token in a subshell (section 2). A bad
   shape is a provisioning gap; fix that, not the bus.
2. `GET {base}/v1/health` unauthenticated. A 200 with
   `{"healthy":true}` means the service is reachable and answering.
   This check is free of auth and cannot trip rate limiting.
3. One single `GET {base}/v1/accounts/me` with the bearer. **One
   request.** Not a loop, not a retry.

**What the status codes mean, and why the distinction decides your
next action:**

| Status | ntfy code | Meaning | Your move |
| --- | --- | --- | --- |
| 200 | -- | authenticated and permitted | continue |
| 401 | 40101 | the token is not recognised | check shape, then check whether you are reading a shared token instead of yours |
| 403 | -- | the token is valid, the topic is not yours | stop; you are addressing another member |
| 404 | 40401 | on a route you know exists, the service is inconsistent, not your credential | report it; do not re-derive the token |
| 429 | 42909 | ntfy's auth-failure limiter | **wait, do not retry** |

The 429 row is the one that costs sessions. ntfy's limiter counts
authentication *failures*, not successes, so a client that retries a
401 makes every later correct request fail too — the service
degrades hardest exactly when the client is working hardest to
diagnose it. A 429 is self-inflicted and must be waited out.

The 404 row is the one that causes re-derivation. A 404 on a route
that demonstrably exists is not a credential signal at all.
Treating it as one sends an agent hunting a token that was correct
all along.

**Self-check gate.** If step 3 is anything other than a clean 200,
stop and report the bus as degraded, including the exact status and
ntfy code observed. Do not attempt to fix the credential, do not
retry, and do not fall back to another member's token. The
credential is the one thing here that is verifiable locally, and a
failure that survives a correct token is not a credential failure.

**Known state as of 2026-09-29: the bus is up, and its 401s are
not a backend split.** Measured on 2026-09-29:
`GET https://bus.at-tech.io/v1/health` unauthenticated returns
`200 {"healthy":true}`. There are not two backends with separate
authentication databases; four other member tokens authenticate
normally against the running service, so the member table is
intact. The outage the infrastructure owner root-caused is the
ntfy process itself: an OOM crash-loop on a micro instance, with
`Restart=always` and a 30-day cache, so it restarts on the same
boot volume and climbs back to the same ceiling. That is
self-healing and recurring, and no alarm watches it, so the
absence of a page is not evidence of health.

So read a 401 from your own host this way: check the token's
shape first, because the most common cause is a provisioning
placeholder — a member item that was created and never had its
value filled in, which returns a clean 401 and is invisible to
step 2. Health returning 200 alongside your 401 is the signature of
exactly that, and it points at your member's item rather than at
the service. A health 200 is necessary and not sufficient; it
proves the service is answering, not that your token was issued.

## 4. Configuration wiring

A session's MCP server is configured with an explicit launch
command, and that command is where credentials enter the process.
Two things about it are worth stating plainly.

**Put the non-secrets in the shared item and the secrets
per-member.** The base URL is fine in a shared vault item. A bus
token is not, for the reason in section 3.

**A launch line that reads a bus token from a shared item is a
stale artifact, not a live pattern to copy.** The hub's own two
MCP launch configs read the per-member item named in section 1 and
are correct as of 2026-09-29. The shared-token configuration was
retired on 2026-09-28: there is now no wildcard bus token, and no
separate send-capable token either — one member token both reads
and writes, for that member alone. So a launch line like
`HYER_BUS_TOKEN="$(sec get HYER/bus_token)"` describes a shape that
no longer exists; treat meeting one as a stale file to fix rather
than a pattern to replicate, and note that removing it disables the
bus tools for every session using that config, which is a change
with a blast radius worth naming out loud before making it.

**A launch line with no identity line is also correct.** Identity
is derived at call time from the host's first dot-separated label
(section 3), which is why there is no identity credential in any
store and none in any launch config. Declaring one in the config is
how per-machine identities came back the first time. Leave
`HYER_BUS_IDENTITY` unset unless you are deliberately reproducing
another member's view.

## 5. When something does not work

Work outward from the credential to the configuration to the
service, in that order, and stop at the first thing that is wrong.
Re-deriving a credential is the most expensive and least likely
step, so it goes last.

1. Does the credential have the right shape, and is it not a
   placeholder? (section 2)
2. Is it the right credential for this job? (section 1)
3. Is the launch configuration actually passing it through? A
   variable set in one shell does not reach a server started in
   another, and an `export` missing from a multi-line launch command
   produces exactly the symptom of a broken credential.
4. Is the service itself healthy, and is the failure code one the
   service can produce on its own? (section 3)

The recurring lesson, learned four times in this fleet now: a
well-formed value from the wrong provenance reads as evidence.
A plausible kernel string off the wrong machine, a commit with no
author identity, a token that looks right and was never the one in
use, and a configuration described in documentation that no live
config had been carrying for a day — that last one sent a
diagnosis to another repository about a service that had never
been the cause. When a fact is about a system's *state* rather
than its documentation, get it from that system — its own trace,
its own API, the host itself — and if you cannot, write it down as
unmeasured. `measure-before-asserting-environment` is the
adopter skill that makes this concrete, and
`verify-citation-before-relying-on-it` is the complementary check
for what a document claims.
