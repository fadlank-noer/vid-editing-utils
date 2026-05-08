---
name: Bazel OCI/Docker Integration
description: How to build OCI-compliant container images with Bazel using rules_oci, rules_pkg, and aspect_rules_py, then load/run them via Docker.
type: reference
---

# Combining Bazel with Docker (OCI Images)

## Overview

Bazel supports building OCI-compliant images which are independent from a specific tool like Docker. The final step uses Docker to run the container, but no Dockerfile is needed — everything is defined in BUILD files.

## Project Structure

```
project/
├── app1/
│   ├── BUILD
│   ├── main.py
│   ├── run_container.sh
│   ├── some_config.json
├── app2/
│   ├── BUILD
│   ├── main.py
│   ├── run_container.sh
│   ├── some_config.json
├── MODULE.bazel
└── WORKSPACE
```

## MODULE.bazel Dependencies

```starlark
bazel_dep(name = "aspect_rules_py", version = "1.4.0")   # python binary + app layer
bazel_dep(name = "rules_oci", version = "2.2.6")         # OCI image building
bazel_dep(name = "rules_pkg", version = "1.1.0")         # pkg_tar for additional layers
```

## WORKSPACE Setup

Certain operations (like pulling a base image) execute only at workspace loading stage:

```starlark
load("@rules_oci//oci:dependencies.bzl", "rules_oci_dependencies")
rules_oci_dependencies()

load("@rules_oci//oci:repositories.bzl", "oci_register_toolchains")
oci_register_toolchains(name = "oci")

load("@rules_oci//oci:pull.bzl", "oci_pull")
oci_pull(
    name = "python_base",
    image = "python",
    tag = "3.9-slim",
    platforms = ["linux/amd64"],
)
```

## BUILD File Pattern

```starlark
load("@aspect_rules_py//py:defs.bzl", "py_binary", "py_image_layer")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_load")
load("@rules_pkg//:pkg.bzl", "pkg_tar")

# 1. Create a Python application binary
py_binary(
    name = "main",
    srcs = ["main.py"],
)

# 2. Create a Python application layer in the image
py_image_layer(
    name = "application_layer",
    binary = ":main",
)

# 3. Create an additional layer (e.g. config files)
pkg_tar(
    name = "configuration_layer",
    srcs = ["some_config.json"],
)

# 4. Define the OCI image
oci_image(
    name = "image_definition",
    base = "@python_base",
    entrypoint = ["/app1/main"],
    tars = [":configuration_layer", ":application_layer"],
)

# 5. Load image into local runtime (Docker)
oci_load(
    name = "image",
    image = ":image_definition",
    repo_tags = ["image_app_1:latest"],
)
```

## Key Rules Reference

| Rule | Purpose | Notes |
|------|---------|-------|
| `py_binary` | Compile Python into a standalone binary | Works with other language rules too |
| `py_image_layer` | Create an application layer from a binary | Language-specific layer rule |
| `pkg_tar` | Create a tar archive as an image layer | Used for config files, assets, etc. |
| `oci_image` | Assemble OCI image from base + layers | Composable, no Dockerfile needed |
| `oci_load` | Load OCI image into local Docker daemon | Must use `bazel run`, not `bazel build` |
| `oci_pull` | Pull a base image from a registry | Goes in WORKSPACE, not BUILD |

## Building & Running

### Build and load image into Docker
```bash
bazel run //app1:image
```

### Verify images exist
```bash
docker images
```

### Run container directly
```bash
docker run --rm --name container_app_1 image_app_1
```

## Running Container via Bazel Target

Create a wrapper script `run_container.sh`:
```bash
#!/bin/bash
docker run --rm --name container_app_1 image_app_1
```

Add to BUILD file:
```starlark
sh_binary(
    name = "container",
    srcs = ["run_container.sh"],
    data = [":image"],
)
```

Run with:
```bash
bazel run //app1:container
```

## Important Notes

- **`oci_load` requires `bazel run`** — calling `bazel build` will NOT load the image into the local runtime.
- **Container target won't detect image changes** — if you modify app code, you must rebuild the image target (`//app1:image`) before running the container target (`//app1:container`).
- **OCI vs Docker** — Bazel builds OCI-compliant images; Docker is used only at the final step to run them.
- **Multi-language** — swap `aspect_rules_py` for your language's equivalent (Go, Java, etc.) and adjust the base image accordingly.
