---
name: Custom Docker Pull Rule (Windows)
description: Custom docker_pull Bazel rule for Windows replacing rules_oci
type: project
---

Replaced `rules_oci` with a custom `docker_pull` rule at `rules_custom/rules_client/container.bzl` because `rules_oci` is Unix-centric and does not work on Windows.

**Why:** rules_oci relies on bash/Unix tooling that fails on Windows. Rancher Desktop provides docker.exe natively.

**How to apply:** Use `docker_pull` rule in BUILD files instead of any oci-based targets. The rule generates a .bat script that calls `docker pull` via `DOCKER_PATH` env var set in `user.bazelrc`. Image config (image, tag, platform) is defined as rule attributes in the BUILD target, not in MODULE.bazel.

Key files:
- Rule definition: `rules_custom/rules_client/container.bzl`
- Usage: `client/BUILD` — `//client:php_fpm`
- Docker path: `user.bazelrc` — `DOCKER_PATH` action_env (Rancher Desktop)
