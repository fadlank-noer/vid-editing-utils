---
name: Bazel Best Practices and .bazelrc Usage
description: Project structure guidelines and .bazelrc configuration strategy — commit vs ignore, user.bazelrc, package structure, third-party deps
type: reference
source: https://bazel.build/configure/best-practices
---

# Bazel Best Practices

## Overall Goals
- Fine-grained dependencies for parallelism and incrementality
- Well-encapsulated dependencies
- Well-structured, testable code
- Build configuration that is easy to understand and maintain

## Running Builds and Tests
`bazel build //...` and `bazel test //...` should always succeed on the stable branch. Tag targets that need special conditions (specific platform, flags, licenses) with descriptive tags instead of just `"manual"`.

## Third-Party Dependencies
- Declare as remote repos in `MODULE.bazel`
- Or place in `third_party/` directory

## Build from Source
Always build from source when possible (instead of depending on prebuilt `.so` / binaries). Ensures compatible flags/architecture and enables coverage, static analysis, dynamic analysis.

## Versioning
- Prefer building all code from head
- Avoid version numbers in target names (`//guava`, not `//guava-20.0`)
- Makes updates easier and reduces diamond dependency issues

## Packages
Every directory with buildable files should be a package. If a BUILD file references files in subdirectories (`srcs = ["a/b/C.java"]`), add a BUILD file to that subdirectory. Long-lived cross-directory references lead to:
- Inadvertent circular dependencies
- Scope creep
- Excessive reverse dependency updates

---

# .bazelrc Configuration Strategy

## Two-File Approach

### 1. `.bazelrc` — Commit to Git
Project-wide config shared by the entire team. Contains flags ensuring build consistency.

```python
# .bazelrc (committed)
build --action_env=PHP_PATH=C:/tools/php85/php.exe
common --enable_bzlmod

# Import personal config at the bottom (so it can override)
try-import %workspace%/user.bazelrc
```

### 2. `user.bazelrc` — Add to .gitignore
Per-user config for local paths, credentials, personal preferences.

```python
# user.bazelrc (gitignored)
build --disk_cache=/path/to/local/cache
build --remote_cache=grpc://my-cache.example.com
```

Add to `.gitignore`:
```
user.bazelrc
```

## Why Separate?
- **Prevents Git conflicts** — personal settings never enter version control
- **Team consistency** — everyone shares the same base config
- **Security** — prevents accidental commits of API keys, credentials, or local paths

## Key Points
- `try-import` (not `import`) — won't error if `user.bazelrc` doesn't exist
- Place `try-import` at the **bottom** of `.bazelrc` so user config can override project config
- Use `try-import %workspace%/user.bazelrc` (workspace-relative path)
