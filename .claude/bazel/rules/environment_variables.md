---
name: Bazel Environment Variables
description: How to pass and access environment variables in Bazel — repository rules, build rules, test rules, and Starlark actions
type: reference
---

# Environment Variables in Bazel

Bazel does NOT use `.env` files. All config must be declared explicitly via `.bazelrc`, CLI flags, or Starlark code to ensure hermetic builds.

## 1. Repository Rules (Fetch Phase)

| Method | Description |
|---|---|
| `environ` attribute | Declares env var dependencies upfront on `repository_rule`. Triggers re-fetch when values change. |
| `repository_ctx.getenv()` | Reads env vars lazily without declaring them upfront. Useful when var names are unknown at definition time. |
| `--repo_env` flag | CLI flag to set/override values for vars declared via `environ` or `getenv()`. |

## 2. Build Rules (Execution Phase)

| Method | Description |
|---|---|
| `--action_env` | CLI / `.bazelrc` flag that passes env vars to **all** build actions. Use sparingly — changes invalidate the entire analysis cache. |
| `ctx.configuration.default_shell_env` | Property in rule implementation. Contains Bazel-filtered shell environment (e.g. `PATH`). |
| `use_default_shell_env` (bool) | Parameter in `ctx.actions.run()`. Tells Bazel to inherit the default shell env. |
| `env` (dict) | Parameter in `ctx.actions.run()`. Sets fixed env vars for that specific action. Overrides values from default shell env. |

## 3. Test Rules (`testing` Module)

| Method | Description |
|---|---|
| `testing.TestEnvironment` | Provider returned by test rules. Has `environment` (fixed dict) and `inherited_environment` (list of var names to inherit from shell). |

## 4. Execution Rules (`RunEnvironmentInfo`)

| Method | Description |
|---|---|
| `RunEnvironmentInfo` | Generic provider for executable rules (including tests). Specifies args and env for `bazel run` / `bazel test`. |

## Configuration Flow

### `.bazelrc` file
```python
# Pass vars to build actions
build --action_env=APP_ENV=Development
build --action_env=POSTGRES_USER

# Pass vars to repository rules (dependency fetching)
build --repo_env=CC=clang
build --repo_env=CXX=clang++
```

### Command line (inline, temporary)
```bash
bazel test --test_env=EMAIL=a@example.com --test_env=MODE=dev //...
bazel build --action_env=APP_ENV=Development //...
```

### Inside Starlark rules
```python
# Repository rule — read env var
def _my_repo_impl(rctx):
    value = rctx.getenv("MY_VAR", default="fallback")

# Build rule — use env in action
def _my_rule_impl(ctx):
    ctx.actions.run(
        executable = tool,
        use_default_shell_env = True,  # inherit filtered shell env
        env = {"MY_OUTPUT": output.path},  # fixed vars, override defaults
        ...
    )

# Test rule — declare test environment
def _my_test_impl(ctx):
    return [
        testing.TestEnvironment(
            environment = {"FIXED_VAR": "value"},
            inherited_environment = ["PATH", "HOME"],
        ),
    ]
```
