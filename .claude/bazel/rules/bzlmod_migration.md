---
name: Bzlmod Migration Guide
description: Migrating from WORKSPACE to Bzlmod (MODULE.bazel) — syntax mapping, module extensions, overrides, toolchains, and hybrid mode
type: reference
source: https://bazel.build/external/migration
---

# Bzlmod Migration Guide

WORKSPACE is **disabled in Bazel 8** (late 2024) and **removed in Bazel 9** (late 2025). Bzlmod is the replacement.

## Quick Migration Steps

1. Add `MODULE.bazel` at project root
2. Add empty `WORKSPACE.bzlmod` to override old WORKSPACE during migration
3. Enable Bzlmod in `.bazelrc`: `common --enable_bzlmod`
4. Build, check which repos are missing, migrate one at a time
5. Remove `WORKSPACE.bzlmod` when done

## WORKSPACE vs Bzlmod Syntax Mapping

### Workspace Name
```python
# WORKSPACE
workspace(name = "com_foo_bar")

# MODULE.bazel
module(name = "bar", repo_name = "com_foo_bar")
```

### Fetch Bazel Modules
```python
# WORKSPACE
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(name = "bazel_skylib", urls = [...], sha256 = "...")

# MODULE.bazel — just declare the dep
bazel_dep(name = "bazel_skylib", version = "1.4.2")
```

### Simple Repo Rule (use_repo_rule)
```python
# MODULE.bazel
http_file = use_repo_rule("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
http_file(
    name = "data_file",
    url = "http://example.com/file",
    sha256 = "e3b0c44298fc...",
)
```

### Module Extension (complex logic)
For deps that aren't Bazel modules or need custom resolution:

```python
# extensions.bzl
load("//:repositories.bzl", "my_data_dependency")

def _non_module_dependencies_impl(_ctx):
    my_data_dependency()

non_module_dependencies = module_extension(
    implementation = _non_module_dependencies_impl,
)
```
```python
# MODULE.bazel
non_module_dependencies = use_extension("//:extensions.bzl", "non_module_dependencies")
use_repo(non_module_dependencies, "data_file")
```

### Override a Module
```python
# MODULE.bazel — only available to root module
bazel_dep(name = "rules_java")
local_path_override(
    module_name = "rules_java",
    path = "/Users/bazel_user/workspace/rules_java",
)
```

### Register Toolchains
```python
# WORKSPACE
load("//:local_config_sh.bzl", "sh_configure")
sh_configure()  # calls native.register_toolchains(...)

# MODULE.bazel — register_toolchains only works here, NOT in module extensions
sh_config_ext = use_extension("//:local_config_sh_extension.bzl", "sh_config_extension")
use_repo(sh_config_ext, "local_config_sh")
register_toolchains("@local_config_sh//:local_sh_toolchain")
```

### Replace `bind()`
```python
# WORKSPACE (deprecated)
bind(name = "openssl", actual = "@my-ssl//src:openssl-lib")

# Bzlmod — use alias in a BUILD file
# third_party/BUILD
alias(name = "openssl", actual = "@my-ssl//src:openssl-lib")
```

## Conflict Resolution via Module Extension

Module extensions can collect info from the entire dep graph and resolve conflicts:

```python
# extensions.bzl
data = tag_class(attrs={"version": attr.string()})

def _data_deps_extension_impl(module_ctx):
    version = "1.0"
    for mod in module_ctx.modules:
        for d in mod.tags.data:
            version = max(version, d.version)
    data_deps(version)

data_deps_extension = module_extension(
    implementation = _data_deps_extension_impl,
    tag_classes = {"data": data},
)
```

## Dev Dependencies
```python
# MODULE.bazel
bazel_dep(name = "rules_java", version = "7.0", dev_dependency = True)
```
Use `--ignore_dev_dependency` to verify builds work without dev deps.

## Hybrid Mode (Gradual Migration)

| File | When Bzlmod OFF | When Bzlmod ON |
|---|---|---|
| `WORKSPACE` | Used | Ignored |
| `WORKSPACE.bzlmod` | Ignored | Used instead of WORKSPACE |

`WORKSPACE.bzlmod` has no prefixes/suffixes injected — easier to track what's left to migrate.

## Repository Visibility

| From \ To | Main repo | Bazel module repos | Extension repos | WORKSPACE repos |
|---|---|---|---|---|
| **Main repo** | Visible | If root module is direct dep | If root module is direct dep | Visible |
| **Bazel module repos** | Direct deps | Direct deps | Direct deps | Direct deps of root |
| **Extension repos** | Direct deps | Direct deps | Same extension + direct deps | Direct deps of root |
| **WORKSPACE repos** | All visible | Not visible | Not visible | All visible |

## Useful Commands

```bash
# Generate resolved lock file from WORKSPACE
bazel sync --experimental_repository_resolved_file=resolved.bzl

# Query external dependency info
bazel query --output=build //external:<repo_name>

# Fetch dependencies
bazel fetch //target          # fetch for a target
bazel fetch --force @repo     # force re-fetch
```

## Publishing to Bazel Central Registry (BCR)

1. Create a versioned, stable source archive URL (use GitHub release URLs, not auto-generated archives)
2. Include a test module in a subdirectory
3. Follow BCR contribution guidelines via PR
4. Automate with Publish to BCR GitHub App
