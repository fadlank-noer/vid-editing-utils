# Starlark Language Reference
**Source:** [Bazel Starlark Language](https://bazel.build/versions/9.1.0/rules/language) (v9.1.0)

## Overview
Starlark (formerly Skylark) is the language used in Bazel for `.bzl`, `BUILD`, and `WORKSPACE` files. It is a dialect of Python 3.

## Syntax
Valid Starlark resembles Python 3:
```python
def fizz_buzz(n):
  """Print Fizz Buzz numbers from 1 to n."""
  for i in range(1, n + 1):
    s = ""
    if i % 3 == 0:
      s += "Fizz"
    if i % 5 == 0:
      s += "Buzz"
    print(s if s else i)

fizz_buzz(20)
```

## Type Annotations (Experimental)
- Enabled via `--experimental_starlark_types`
- Syntax inspired by PEP 484
- Tracked in issue #22935

## Immutability
- Only **list** and **dict** are mutable
- Mutations only apply within the current context; values become **frozen** once the context ends
- Each `.bzl` and `BUILD` file has its own execution context
- A list created in `foo.bzl` and mutated by an internal function will be frozen after file evaluation — other files loading it cannot modify it (runtime error)

## BUILD vs .bzl Files
| Feature | BUILD | .bzl |
|---------|-------|------|
| Purpose | Register targets by calling rules | Define constants, rules, macros, functions |
| Function declarations | Not allowed | Allowed |
| `*args` / `**kwargs` | Not allowed | Allowed |
| Native functions/rules | Global symbols | Must load via `native` module |

## Differences from Python
- **Global variables** are immutable
- **`for` and `if`** not allowed at top-level (use inside functions, or use `if` expressions and list comprehensions)
- **Dict iteration order** is deterministic
- **Recursion** not allowed
- **`int` type** limited to signed 32-bit; overflow raises error
- **Comparison operators** (`<`, `<=`, `>=`, `>`) undefined between different types
- **Trailing comma** in tuples only valid inside parentheses
- **Dict literals** cannot have duplicate keys
- **Strings** use double quotes and are not iterable

## Unsupported Python Features
Implicit string concatenation, chained comparisons, `class`, `import`, `while`, `yield`, `float`, `set`, generators, `is`, `try`/`raise`/`except`, `global`/`nonlocal`, and most built-in functions/methods.

## Rule Conventions

### Naming Conventions
- Use **snake_case** names (lowercase with underscores).
- Rule names should be **nouns** describing the primary artifact they produce.

Common rule name patterns:

| Suffix | Purpose |
|--------|---------|
| `*_library` | Compilation unit or module |
| `*_binary` | Executable or deployable target |
| `*_test` | Test target |
| `*_import` | Wraps pre-compiled artifacts (e.g., `.jar`) |

### Common Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `srcs` | `label_list`, files allowed | Source files, typically hand-written |
| `deps` | `label_list`, files usually not allowed | Compilation dependencies |
| `data` | `label_list`, files allowed | Data files such as test data |
| `runtime_deps` | `label_list` | Runtime dependencies not needed for compilation |

### Implementation Guidelines

- **Documentation:** Use the `doc` keyword argument on attribute declarations to document non-obvious behavior.
- **Implementation functions:** Almost always private functions (prefixed with underscore). Common style: `_myrule_impl` for rule `myrule`.
- **Providers:** Use well-defined provider interfaces to pass information between rules. Declare and document provider fields.
- **Extensibility:** Design rules with potential interactions from other rules in mind.
- **Performance:** Follow [performance guidelines](https://bazel.build/rules/performance).
