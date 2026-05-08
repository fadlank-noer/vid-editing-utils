---
name: Bazel Modules
description: Bazel module system — MODULE.bazel format, version format/selection (MVS), overrides, repo naming, and strict deps
type: reference
source: https://bazel.build/external/module
---

# Bazel Modules

A Bazel module is a versioned Bazel project with a `MODULE.bazel` manifest at its repo root.

```python
# MODULE.bazel
module(name = "my-module", version = "1.0")

bazel_dep(name = "rules_cc", version = "0.0.1")
bazel_dep(name = "protobuf", version = "3.19.0")
```

## Version Format

Relaxed SemVer:
- Any number of segments (not just MAJOR.MINOR.PATCH)
- Segments can contain letters, not just digits
- All valid SemVer versions are valid Bazel module versions
- Comparison semantics match SemVer prerelease identifier rules

## Version Selection — MVS (Minimal Version Selection)

Bazel uses Go's MVS algorithm:
- Picks the **highest version specified by any dependent** in the graph
- Called "minimal" because it's the earliest version satisfying all requirements
- Reproducible and deterministic

```
       A 1.0
      /     \
   B 1.0    C 1.1
     |        |
   D 1.0    D 1.1
   → D 1.1 is selected
```

### Yanked Versions
Registry can mark versions as yanked (security, bugs). Bazel errors on yanked versions.
Fix: upgrade to non-yanked version, or use `--allow_yanked_versions`.

## Overrides (Root Module Only)

### single_version_override
```python
single_version_override(
    module_name = "foo",
    version = "1.2.3",         # pin to specific version
    registry = "https://...",   # force specific registry
    patches = ["//:fix.patch"], # apply patches
    patch_strip = 1,
)
```

### multiple_version_override
Allows multiple versions of the same module to coexist:
```python
multiple_version_override(
    module_name = "foo",
    versions = ["1.3", "1.7", "2.0"],
    registry = "https://...",
)
```
Each dependent gets the nearest higher allowed version. Versions not in the allowed set are upgraded.

### Non-Registry Overrides
Skip registry entirely — source comes from elsewhere:

```python
archive_override(
    module_name = "foo",
    urls = ["https://example.com/foo.zip"],
    sha256 = "...",
)

git_override(
    module_name = "foo",
    remote = "https://github.com/org/foo.git",
    commit = "abc123",
)

local_path_override(
    module_name = "foo",
    path = "/path/to/local/foo",
)
```

## Non-Module Repos (use_repo_rule)

Define repos that don't represent Bazel modules (e.g. data files):
```python
http_file = use_repo_rule("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
http_file(name = "data_file", url = "http://example.com/file", sha256 = "...")
```

## Repository Names & Strict Deps

### Apparent Name
- Defaults to module name, or override via `bazel_dep(repo_name = ...)`
- Only **direct dependencies** are visible — prevents accidental transitive dep breakage

### Canonical Name
- Format: `module_name+version` (e.g. `bazel_skylib+1.0.3`) or `module_name+` for single-version
- Format is NOT a stable API — don't hardcode it

### Getting Canonical Name
```python
# In BUILD/.bzl files
Label("@bazel_skylib").repo_name

# For runfiles
$(rlocationpath ...)

# From external tools (IDE, language server)
bazel mod dump_repo_mapping
```
