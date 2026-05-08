---
name: Bazel Package Resolution
description: Common error "not a package" and how to fix it — every directory referenced with // must contain a BUILD file
type: reference
---

# Bazel Package Resolution

## Error: "X is not a package"

```
Label '//rules_custom/rules_client:php.bzl' is invalid because
'rules_custom/rules_client' is not a package; perhaps you meant to
put the colon here: '//rules_custom:rules_client/php.bzl'?
```

### Cause
A Bazel **package** is any directory containing a `BUILD` or `BUILD.bazel` file. If a directory has no BUILD file, it is NOT a package — even if it contains `.bzl` files or other sources.

### Fix
Create a `BUILD` file in the directory. For packages that only export `.bzl` files:

```python
# rules_custom/rules_client/BUILD
exports_files(["php.bzl"])
```

### Package Rules

| Scenario | Valid? | Label syntax |
|---|---|---|
| `dir/BUILD` exists, load `.bzl` from it | Yes | `//dir:file.bzl` |
| `dir/` has no BUILD, load `.bzl` from it | **No** | Error: "not a package" |
| Parent `BUILD` exists, child dir has no BUILD | Parent owns child | `//parent:child/file.bzl` |

### Key Points
- A BUILD file (even empty) makes a directory a package
- `exports_files()` is required to make `.bzl` files loadable from other packages
- Subdirectories without BUILD files belong to their nearest ancestor package
- `visibility` in `exports_files` defaults to the package — use `visibility = ["//visibility:public"]` if needed from other packages
