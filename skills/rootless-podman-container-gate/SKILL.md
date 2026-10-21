---
name: rootless-podman-container-gate
description: "Use when a build, test suite, or toolchain script is going to run inside a rootless podman or docker container, or when something that passes on the host fails inside one with a message that points somewhere other than the cause. Five container procedures that fail silently, plus the rule that decides whether they are done."
---

# Rootless Container Build Gate

Procedural knowledge for the class of failure where a build works on the
host and fails inside a container, with an error message that names
something other than the cause. Learned shipping a hermetic workspace on
rootless podman 5.8.2 on an SELinux-enforcing host, verified by a
343-passed test stage matching the host baseline (issue #157). The
durable record with the same substance is the container-procedures
section of `methodology/tooling.md`.

The five procedures below are not a style guide; each one is a defect
that shipped once. Apply them when the container is rootless, when the
host enforces SELinux, or when the container reaches a private registry.
Skip the ones whose precondition is false -- but check the precondition
rather than assuming it.

## 1. SELinux host binds need `:z`

On an SELinux-enforcing host, a rootless host bind mount fails with an
opaque `Permission denied`. Append `:z` to every host bind:

    -v /host/path:/container/path:ro,z

Container volumes inherit the relabel state; host binds do not. A wrapper
that may run on either kind of host should detect `getenforce` returning
`Enforcing` and apply `:z` only there, so the same invocation still works
on a host without SELinux.

## 2. `--userns=keep-id` for any container that writes to a mount

`-u $(id -u):$(id -g)` maps the container uid into the caller's
*subordinate* uid range, so writes to a mounted volume fail `EACCES` even
though the ids look correct from the command line. `--userns=keep-id`
maps the named uid to the same host uid and is the podman analogue of
docker's plain `-u`. If the container writes anywhere the caller can see,
this flag is the difference between passing and failing.

## 3. Multi-stage `USER` ordering

A later build stage that inherits the runtime `USER` from its parent
cannot install packages: `E: List directory ... missing ... Permission
denied`. If a stage needs root, switch to `USER root`, do the install,
then restore the runtime `USER` again before `ENTRYPOINT`, so the final
image still runs as the unprivileged runtime user. Setting the user once
at the end of the final stage is not enough; the install step is what
fails, and it fails in the stage that inherited the wrong user.

## 4. A private package registry 401s for anonymous fetch

A build stage that downloads from a private generic package registry
fails anonymously with a 401. The build must mount the token as a
BuildKit secret -- `RUN --mount=type=secret,id=<name>`, read from
`/run/secrets/<name>`; on podman, `--secret id=<name>,src=<file>` -- and
keep a public fallback (a release tarball from wherever the project
already publishes one), asserting the expected SHA256 on both paths.
Also: the registry URL needs the *numeric* project id; the URL-encoded
path form 404s, which reads like a permissions problem and is not.

## 5. The base image ships no `python3`

`debian:12-slim` has no `python3`. A Python test leaf must
`apt-get install python3 python3-venv python3-pip`; `jq` and
`openssh-client` are likewise absent, and a toolchain script that calls
them fails mid-suite with `ssh not found` or `jq required` long after the
image built cleanly. Install what the suite actually invokes, not what
the image "should" have.

## Done means the real suite ran

None of the five is verified by reading the containerfile, and none is
verified by a build that merely succeeds. Run the suite that the host
baseline runs, inside the container, and compare the result to the host
result. A passing container build with an unrun or partially-skipped
suite is the failure mode this gate exists to catch: the five defects
above all present as a build that looks fine.
