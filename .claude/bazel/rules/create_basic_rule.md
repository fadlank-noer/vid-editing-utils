---
name: Creating Basic Bazel Rules
description: Step-by-step guide to writing custom Bazel rules in Starlark — empty rules, evaluation model, output files, attributes, dependencies, and templates
type: reference
source: https://bazel.build/rules/creating
---

# Creating Basic Bazel Rules

## 1. Empty Rule

```python
# foo.bzl
def _foo_binary_impl(ctx):
    pass

foo_binary = rule(
    implementation = _foo_binary_impl,
)
```
```python
# BUILD
load(":foo.bzl", "foo_binary")
foo_binary(name = "bin")
```
Build with `bazel build bin`. Even an empty rule has mandatory `name` and supports common attrs (`visibility`, `testonly`, `tags`).

## 2. Evaluation Model

| Phase | What runs | Triggered by |
|---|---|---|
| `.bzl` loading | File-level code, `print()` statements | `bazel query`, `bazel build`, `bazel cquery` |
| `BUILD` loading | BUILD file after all `.bzl` loads | `bazel query`, `bazel build`, `bazel cquery` |
| Analysis | `_impl` callback functions | `bazel build`, `bazel cquery` only |

Key facts:
- `.bzl` files are evaluated **before** BUILD files
- `.bzl` evaluation is **cached** — loaded once even if multiple BUILDs import it
- `_impl` callbacks do NOT run during `bazel query` (loading phase only)
- Use `bazel build` or `bazel cquery` to trigger analysis + `_impl` execution

## 3. Creating Output Files

```python
def _foo_binary_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.write(
        output = out,
        content = "Hello!\n",
    )
    return [DefaultInfo(files = depset([out]))]
```

Three steps:
1. **Declare** — `ctx.actions.declare_file(name)` registers the output
2. **Define action** — `ctx.actions.write` tells Bazel how to create it
3. **Return** — `DefaultInfo(files = depset([out]))` makes it a rule output

Result: `bazel build bin` → `bazel-bin/bin` containing "Hello!"

## 4. Adding Attributes

```python
foo_binary = rule(
    implementation = _foo_binary_impl,
    attrs = {
        "username": attr.string(),
    },
)
```
```python
# BUILD
foo_binary(name = "bin", username = "Alice")
```

Access in impl: `ctx.attr.username`. Supports types: `string`, `bool`, `int`, `string_list`, etc. Can be `mandatory = True` or have a `default`.

## 5. Dependencies

### Rule-to-Rule Dependencies
```python
"deps": attr.label_list(),
```
Access in impl: `ctx.attr.deps` → list of `Target` objects. Get files via `target.files`.

### Source File Dependencies
```python
# Multiple files
"srcs": attr.label_list(allow_files = [".java"])

# Single file
"src": attr.label(allow_single_file = [".java"])
```
Access in impl: `ctx.files.srcs` (list) or `ctx.file.src` (single File).

## 6. Templates

### Explicit Template Attribute
```python
def _hello_world_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".cc")
    ctx.actions.expand_template(
        output = out,
        template = ctx.file.template,
        substitutions = {"{NAME}": ctx.attr.username},
    )
    return [DefaultInfo(files = depset([out]))]

hello_world = rule(
    implementation = _hello_world_impl,
    attrs = {
        "username": attr.string(default = "unknown person"),
        "template": attr.label(
            allow_single_file = [".cc.tpl"],
            mandatory = True,
        ),
    },
)
```
```python
# BUILD
hello_world(name = "hello", username = "Alice", template = "file.cc.tpl")
cc_binary(name = "hello_bin", srcs = [":hello"])
```

### Implicit (Private) Template
Attributes prefixed with `_` are private — not settable in BUILD files:
```python
"_template": attr.label(
    allow_single_file = True,
    default = "file.cc.tpl",
),
```
Export the template file in BUILD: `exports_files(["file.cc.tpl"])`
