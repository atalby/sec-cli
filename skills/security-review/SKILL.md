---
name: security-review
description: "Use when reviewing code, a merge request, or a dependency set that touches auth, secrets, user input, API endpoints, payments, or sensitive data — secrets hygiene, input validation, injection prevention, dependency audit."
---

# Security Review

Structured security checklist for non-trivial changes. Use this as a
gate before calling work done (see AGENTS.md section 7), not as a
separate approval cycle. If a section below does not apply to this
change, skip it — but skip it consciously, not by omission.

Cross-reference this skill's findings with `scripts/scan_secrets.py`,
which already recognises the secret formats listed below (private keys,
cloud provider tokens, JWTs, connection strings with embedded
passwords, and others). Running that scanner is a cheap automated
first pass; this skill covers the manual and design-level review it
cannot reach.

## 1. Secrets Hygiene

### What must never be committed

- Hardcoded API keys, tokens, passwords, or connection strings with
  embedded credentials in source code, config files, tests, or scripts.
- Secrets in environment variable definitions committed to version
  control (`.env`, `.env.local`, `.env.production`, and equivalents).
- Secrets in CI/CD logs, debug output, or error messages returned to
  clients.

### What to do instead

- Load secrets from the environment at runtime. Fail explicitly when a
  required secret is absent — never silently proceed with a fallback
  default.
- Store production secrets in the hosting platform's secret manager,
  not in files on disk.
- Add `.env*` patterns to `.gitignore` if the project does not already
  have them.

### Verification

- [ ] Zero hardcoded secrets in any committed file (AGENTS.md section 7
      DoD: "zero raw secrets, API keys, or plaintext passwords exist in
      committed files or logs").
- [ ] `scripts/scan_secrets.py` passes clean, or every flagged finding
      is a documented false positive.
- [ ] `.gitignore` excludes environment files.
- [ ] Git history contains no committed secrets (check with
      `git log -p | head -500` or a dedicated tool if the repo is
      large).

## 2. Input Validation

### Principle

Validate all external input at the boundary, before any processing.
Whitelist allowed values; reject everything else. Never trust the
client to send well-formed data.

### Checks

- Every API endpoint or handler that accepts user-supplied data has a
  schema or validator applied before use.
- File uploads are restricted by size, MIME type, and extension — all
  three, not just one.
- User input is never interpolated directly into database queries,
  shell commands, or HTML without sanitisation.
- Error responses to the client do not include internal details
  (stack traces, database errors, file paths).

## 3. Injection Prevention

### SQL / database injection

- All database queries use parameterised statements or a query builder
  that handles escaping. No string concatenation or template-literal
  interpolation of user input into queries.
- ORM query-builder methods are used correctly (`.eq()`, `.in()`, etc.)
  — verify that the ORM does not silently fall back to raw SQL for the
  query shape in question.

### Command injection

- No user input reaches `exec`, `spawn`, `system`, `os.popen`, or
  equivalent without shell-escaping or argument-list form.
- Template rendering (server-side or client-side) does not evaluate
  user input as code.

### LDAP / NoSQL / path traversal

- If the project uses LDAP, NoSQL document queries, or file-path
  construction from user input, apply the same parameterise-or-escape
  discipline.

## 4. Authentication and Authorization

### Token handling

- Authentication tokens are stored in `httpOnly`, `Secure`,
  `SameSite=Strict` cookies, not in `localStorage` or `sessionStorage`.
- Token expiry is enforced server-side; expired or revoked tokens are
  rejected with a clear error, not silently ignored.

### Authorization

- Every mutation endpoint checks that the authenticated principal has
  permission to perform the operation, not just that the principal is
  authenticated.
- Row-level or resource-level access control is enabled where the
  data store supports it.
- Role or permission checks appear before the operation, not after
  (no implicit "admin check happened somewhere upstream").

### Session management

- Sessions are invalidated on logout, password change, and account
  deactivation.
- Session tokens are sufficiently random and are not re-used across
  environments.

## 5. Cross-Site Request Forgery and Cross-Site Scripting

### CSRF

- State-changing endpoints require a CSRF token or equivalent
  double-submit pattern.
- Cookies carrying session state use `SameSite=Strict` or
  `SameSite=Lax` at minimum.

### XSS

- User-supplied HTML is sanitized with a well-maintained library
  before rendering. Do not roll your own HTML stripper.
- Content-Security-Policy headers are set. Start restrictive
  (`default-src 'self'`) and loosen only with a documented reason.
  Avoid `'unsafe-inline'` and `'unsafe-eval'` — they negate most of
  what CSP provides.
- Framework-provided output encoding (auto-escaping in template
  engines, React's JSX escaping) is used and not bypassed with
  `dangerouslySetInnerHTML` or equivalent without sanitisation.

## 6. Rate Limiting and Abuse Prevention

- All public API endpoints have rate limiting. Expensive operations
  (search, authentication attempts, file uploads) get stricter limits.
- Authentication endpoints have additional protections against brute
  force (account lockout, progressive delay, or CAPTCHA after
  repeated failure).
- Pagination or hard caps are enforced on list endpoints to prevent
  resource exhaustion.

## 7. Sensitive Data Exposure

### Logging

- Passwords, tokens, credit card numbers, and similar secrets are
  never written to log output. Log identifiers (user ID, request ID)
  instead of the secrets themselves.

### Error handling

- Client-facing error responses are generic ("An error occurred").
  Detailed error information goes to server-side logs only.
- No stack traces, internal file paths, or database error messages
  leak to the client.

### Data at rest and in transit

- Sensitive data is encrypted at rest where the storage layer supports
  it.
- All production traffic uses TLS. HTTP requests are redirected to
  HTTPS.

## 8. Dependency and Supply-Chain Security

- `npm audit`, `pip audit`, `cargo audit`, or the equivalent for this
  project's package manager runs clean, or every flagged advisory is
  triaged (accepted, mitigated, or patched).
- Lock files (`package-lock.json`, `poetry.lock`, `Cargo.lock`,
  `go.sum`) are committed and used for CI installs (`npm ci` /
  equivalent) to ensure reproducible builds.
- New dependencies are vetted before adoption: confirm the publisher's
  identity via the package registry metadata, check download counts
  and maintenance activity, and verify there are no binary-name
  collisions with existing tools.

## 9. Pre-Deployment Gate

Before any production deployment, all of these must be true:

- [ ] No hardcoded secrets anywhere in committed code or config
- [ ] All user inputs validated at the boundary
- [ ] All database queries parameterised
- [ ] Authentication tokens handled securely (httpOnly cookies)
- [ ] Authorization checked on every mutation endpoint
- [ ] CSRF protection enabled on state-changing endpoints
- [ ] User-supplied HTML sanitized; CSP headers configured
- [ ] Rate limiting active on public endpoints
- [ ] No sensitive data in logs or client-facing error messages
- [ ] TLS enforced; HTTP redirects to HTTPS
- [ ] Dependencies current; no unpatched known vulnerabilities
- [ ] Lock files committed; CI uses lock-file-based installs
- [ ] `scripts/scan_secrets.py` passes clean

## 10. Security Testing

Write and maintain automated tests for security-critical behaviour:

- Unauthenticated requests to protected endpoints return 401.
- Authenticated requests to endpoints requiring higher privilege
  return 403.
- Invalid or malformed input is rejected with 400, not passed
  through.
- Rate limiting returns 429 after the configured threshold.
- SQL injection payloads in input fields do not alter query behaviour.

These tests are not optional extras — they are part of the full test
suite and must pass for the change to be considered done.

## Reference

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- Project script: `scripts/scan_secrets.py` (recognises private keys,
  cloud provider API keys, GitHub/GitLab tokens, Slack tokens, JWTs,
  connection strings with embedded passwords, and secret-management
  service tokens)
