---
name: Writing Rules on Windows
description: Bazel guide for writing Windows-compatible rules — paths, env vars, actions, and file handling quirks
type: reference
source: https://bazel.build/docs/windows
---

# Writing Rules on Windows

## Paths

**Problems:**

- **Length limit:** max path is 259 chars. Many programs enforce this even though Windows supports up to 32767.
- **Working directory:** also limited to 259 chars. Processes cannot `cd` into longer paths.
- **Case-sensitivity:** Windows paths are case-insensitive, Unix paths are case-sensitive.
- **Path separators:** Windows uses `\`, not `/`. Bazel stores paths Unix-style with `/`. Some Windows programs support `/`, others don't. Some `cmd.exe` builtins support them, some don't.
- **Absolute paths:** don't start with `/`. Windows absolute paths start with a drive letter (e.g. `C:\foo\bar.txt`). No single filesystem root.

**Solutions:**

- Keep paths short — avoid long directory names, deeply nested structures, long file/workspace/target names.
- Use a short output root via `--output_user_root=<path>`. Example `.bazelrc`:
  ```
  build --output_user_root=D:/
  # or
  build --output_user_root=C:/_bzl
  ```
- Use junctions (directory symlinks) for long paths:
  ```bat
  mklink /J c:\path\to\junction c:\path\to\very\long\target\path
  ```
- Replace `/` with `\` in paths in actions/envvars:
  ```python
  def as_path(p, is_windows):
      if is_windows:
          return p.replace("/", "\\")
      else:
          return p
  ```

## Environment Variables

**Problems:**

- **Case-sensitivity:** Windows env var names are case-insensitive. `System.getenv("SystemRoot")` == `System.getenv("SYSTEMROOT")`.
- **Hermeticity:** env vars are part of action cache key. Custom/user-specific vars make rules less cacheable.

**Solutions:**

- Only use upper-case env var names (works on all platforms).
- Minimize action environments. Use `ctx.configuration.default_shell_env` and add only what's needed:
  ```python
  load("@bazel_skylib//lib:dicts.bzl", "dicts")

  def _make_env(ctx, output_file, is_windows):
      out_path = output_file.path
      if is_windows:
          out_path = out_path.replace("/", "\\")
      return dicts.add(ctx.configuration.default_shell_env, {"MY_OUTPUT": out_path})
  ```

## Actions

**Problems:**

- **Executable outputs:** must have `.exe` or `.bat` extension. Shell scripts (`.sh`) are NOT executable on Windows. No `+x` permission.
- **Bash commands:** avoid running Bash directly — it's often unavailable on Windows. Bazel is moving away from MSYS2 dependency.
- **Line endings:** Windows uses CRLF (`\r\n`), Unix uses LF (`\n`). Be mindful when comparing text files and of Git's `core.autocrlf`.

**Solutions:**

- Use Bash-less purpose-made rules from `bazel-skylib`:
  - **Build rules:**
    - `copy_file()` — copies a file, optionally making it executable
    - `write_file()` — writes a text file with desired line endings (auto/unix/windows)
    - `run_binary()` — runs a binary with given inputs/outputs as a build action
    - `native_binary()` — wraps a native binary in a `*_binary` rule
  - **Test rules:**
    - `diff_test()` — compares contents of two files
    - `native_test()` — wraps a native binary in a `*_test` rule
- Use `.bat` scripts for trivial tasks on Windows. Extensions don't matter on macOS/Linux, so `.bat` works everywhere.
  - Empty `.bat` files cannot be executed — write one space if you need an empty script.
- Use Bash in a principled way:
  - In rules: `ctx.actions.run_shell`
  - In macros: `native.sh_binary()` or `native.genrule()`
  - In repository rules: avoid Bash altogether (Bazel offers no principled way to run it)

## Deleting Files

**Problems:**

- Files cannot be deleted while open — attempts result in "Access Denied" errors.
- Working directory of a running process cannot be deleted until the process terminates.

**Solutions:**

- Close files eagerly:
  - Java: `try-with-resources`
  - Python: `with open(...) as f:`
  - Close handles as soon as possible in general.
