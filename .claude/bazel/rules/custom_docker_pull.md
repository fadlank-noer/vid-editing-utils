---
name: Custom Docker Rules (Windows)
description: Custom docker_build and docker_run Bazel rules for Windows, replacing rules_oci
type: project
---

Replaced `rules_oci` with custom Docker rules at `rules_custom/rules_client/container.bzl` because `rules_oci` is Unix-centric and does not work on Windows.

**Why:** rules_oci relies on bash/Unix tooling that fails on Windows. Rancher Desktop provides docker.exe natively.

**How to apply:** Use `docker_build` and `docker_run` rules in BUILD files. The rules generate .bat scripts that call Docker CLI via `DOCKER_PATH` env var set in `user.bazelrc`.

Available rules:
- `docker_build` — Builds a Docker image from a Dockerfile. Attributes: `dockerfile` (label), `srcs` (file list), `tag` (string).
- `docker_run` — Runs a Docker container. Attributes: `image` (string), `ports` (string list), `detach` (bool, default True), `rm` (bool, default True).
- `docker_pull` was removed — superseded by `docker_build` which builds the actual app container from the project Dockerfile.

Key files:
- Rule definitions: `rules_custom/rules_client/container.bzl`
- Usage: `client/BUILD` — `//client:build`, `//client:run`
- Docker path: `user.bazelrc` — `DOCKER_PATH` action_env (Rancher Desktop)
- Client Dockerfile: `client/Dockerfile` — PHP 8.5.6 ZTS Alpine, FlightPHP, Composer with hash verification, serves on port 8080
