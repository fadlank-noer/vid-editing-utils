# Loading .bzl Files from Another Folder

To load a `.bzl` file from a different folder (e.g., `rules_custom` sibling to `app1`), use a **label** pointing to the package where the `.bzl` resides. The folder containing the `.bzl` **must** be a Bazel package — it needs a `BUILD` (or `BUILD.bazel`) file, even if empty.

## Directory Structure

```
workspace/
├── app1/
│   └── BUILD          # loads the .bzl here
├── rules_custom/
│   ├── BUILD          # REQUIRED — can be empty
│   └── my_rules.bzl   # rule/macro definitions
├── WORKSPACE          # if not using bzlmod (optional)
├── MODULE.bazel       # if using bzlmod (Bazel ≥ 6)
```

## Steps

### 1. Make `rules_custom` a Package

Create an empty `rules_custom/BUILD` (or `BUILD.bazel`). This tells Bazel the directory is a package, making it referenceable as `//rules_custom`.

```bash
touch rules_custom/BUILD
```

### 2. Define Rules in `rules_custom/my_rules.bzl`

```python
# rules_custom/my_rules.bzl
def _my_rule_impl(ctx):
    # ... implementation ...
    pass

my_rule = rule(implementation = _my_rule_impl)
```

### 3. Load in `app1/BUILD` Using Absolute Label

```python
# app1/BUILD
load("//rules_custom:my_rules.bzl", "my_rule")

my_rule(
    name = "example",
    ...
)
```

**Notes:**
- Label `//rules_custom:my_rules.bzl` refers to file `my_rules.bzl` inside package `//rules_custom`.
- No need for `exports_files` — `.bzl` files are loadable from any package in the same workspace by default.
- If using bzlmod (`MODULE.bazel`), the structure and load syntax are identical. For internal use, direct `load()` is sufficient.

## Summary

1. Create an empty `BUILD` file in the folder containing the `.bzl`.
2. Use `load("//folder_name:<file>.bzl", "<symbol>")` from any other package.
3. No special `visibility` settings needed — `.bzl` files are accessible workspace-wide by default.
