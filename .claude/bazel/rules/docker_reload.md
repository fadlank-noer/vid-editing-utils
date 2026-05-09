# Bazel — docker_reload Rule

## Overview

`docker_reload` is a custom Bazel rule that combines stop + remove + build + run into a single target. Defined in `rules_custom/rules_client/container.bzl`.

## What It Does (in order)

1. **Stop** the existing container by name (`docker stop <name>`)
2. **Remove** the container (`docker rm -f <name>`)
3. **Build** the image with `--no-cache` (force rebuild)
4. **Run** a fresh container with `--name <name>` and the specified ports

## Attributes

| Attribute        | Type           | Required | Description |
|-----------------|----------------|----------|-------------|
| `dockerfile`     | `label`        | Yes      | The Dockerfile to build |
| `srcs`           | `label_list`   | No       | Source files (sent to Bazel sandbox) |
| `tag`            | `string`       | Yes      | Docker image tag |
| `container_name` | `string`       | Yes      | Named container for easy stop/rm |
| `ports`          | `string_list`  | No       | Port mappings e.g. `["8080:8080"]` |
| `detach`         | `bool`         | No       | Run in detached mode (default: True) |
| `rm`             | `bool`         | No       | Auto-remove container on exit (default: True) |

## Usage in BUILD

```python
load("//rules_custom/rules_client:container.bzl", "docker_reload")

docker_reload(
    name = "reload",
    dockerfile = "Dockerfile",
    srcs = [
        "composer.json",
        "composer.lock",
        "src/index.php",
    ],
    tag = "video-editor-client",
    container_name = "video-editor-client",
    ports = ["8080:8080"],
)
```

Run with: `bazel build //client:reload`

## Related Rules

- `docker_build` — builds image only (see `container.bzl`)
- `docker_run` — runs an existing image (see `container.bzl`)
- `php_version` — prints PHP version (see `php.bzl`)
