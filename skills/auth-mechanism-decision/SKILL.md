---
name: auth-mechanism-decision
description: "Use when choosing or reviewing the mechanism that authenticates a caller -- a browser session, a service-to-service call, a third-party SaaS integration, a CI job, a machine identity, or a multi-tenant inbound API. Names the mechanism to use per situation, the mechanisms not to use, and the single requirement each must satisfy."
---

# Auth Mechanism Decision Guide

Pick the mechanism from the situation, not from the library that happens
to be installed. Each row below names the mechanism to use, the ones not
to use, and the one property that decides whether the choice is safe at
all. Everything else -- logging, error shape, secret storage -- is
ordinary hygiene and is not what this guide is for.

## The situations

| Situation | Use | Do not use | The one requirement |
|---|---|---|---|
| Browser session: a human logged into a web app | A server-side session record, or a session token in an httpOnly cookie minted on login | A static API key shipped to the browser; a token in localStorage; a session token with no expiry | Expiry, with the session revocable server-side |
| Service-to-service: two services in the same fleet | A short-lived token minted per call and verified against the issuer's published keys | A static shared bearer key copied into both services' environments | Issuer and audience are both checked, not only the signature |
| Third-party SaaS: an outbound API we call, or a vendor calling us | A per-integration credential read from the vault, or the vendor's own signed-request scheme | One credential shared across integrations; a credential committed to the repo | Constant-time comparison on the receiving side |
| CI job: a pipeline acting on the fleet | Keyless federation -- the job's OIDC token exchanged for the target's short-lived credential | A long-lived cloud key or a personal token stored as a CI variable | No stored key: the credential must not exist before the job starts |
| Machine identity: a host or daemon authenticating to a peer | A per-host key or tunnel identity (SSH key, mTLS, network identity) plus a per-host token | A bearer token in a world-readable file; one identity shared by every host | Rotation, and the identity is scoped to that one host |
| Multi-tenant inbound: many customers, one endpoint | A per-tenant key resolved to a tenant and stored hashed | A plaintext registry of tenant keys; two tenants sharing a key; a tenant taken from a request field without proof | Constant-time comparison against the stored hash |

## Where the fleet's evidence lives

This guide is generic on purpose, so it cannot carry the examples: an
adopting project has no business seeing this fleet's inventory. The
verified per-repository inventory -- one row per repository, mechanism,
and citation -- is hub-only durable state at
`docs/AUTH_MECHANISM_REGISTRY.md`, and the payload rule that forces the
split is worth knowing: everything under `skills/` and `methodology/`
ships to every adopter, and a generic payload that named repositories
would be wrong. Step 11 enforces that mechanically. When a decision here
is genuinely close, read the registry row for a repository in the
matching situation and follow the shape that is already proven there;
when your own project keeps such a registry, keep it out of anything you
distribute.

## The duplication classes, and what to do about them

Three shapes repeat across the fleet, and they are not equally
justified. The distinction matters because the hub's non-goals forbid a
shared runtime library and an auth service, so every recommendation here
has to be a pattern rather than a dependency.

**Session JWTs signed with one shared secret, hand-rolled in each
product.** Four independent products mint their own session tokens this
way, each with its own secret and lifetime. This duplication is
deliberate and should stay: they are separate products with separate
session stores, no shared deployment, and a common library would couple
their release cadence to gain nothing. The requirement is what makes it
safe: a per-deployment secret, a real expiry, and no default secret that
survives into production. If two of them ever deploy together behind one
login, that is the moment to revisit it -- not before.

**JWKS fetch, cache, and verify loops.** Five implementations exist,
four using PyJWT's key client and one using a jose key cache in
JavaScript. This is the class worth converging, because it is the one
where a hand-rolled version quietly drops a check: the cache is easy to
get wrong, key rotation must be respected, and a verifier that checks
the signature but not the issuer or audience accepts tokens it must
reject. Keep the implementation local -- non-goals again -- but hold
every copy to the same three properties: issuer checked, audience
checked, cache re-read on rotation. New JavaScript work should follow
the jose cache shape rather than hand-rolling a fetch.

**Tenant keys sent in a header.** Two producers plus a consumer. The
same header carries a plaintext environment registry in one producer and
a hashed registry in the other, and only the hashed one survives a leak
of the registry. Treat the hashed form as the pattern: store the hash,
compare the presented key's hash in constant time, and never let the
plaintext list be the thing that ships. The end-to-end proof that this
shape works -- an unauthenticated request rejected and the header
accepted -- is itself part of the pattern; a verifier with no test that
exercises both directions is not yet proven.

## What this guide does not do

It does not propose a shared runtime library, an auth service, a forced
migration, or a security review of any single repository. It answers one
question -- which mechanism belongs to this situation, and what must be
true for it to be safe -- and points at the inventory when a real
example would settle the question faster than the reasoning.
