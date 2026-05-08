# Client — Bazel Build Summary

## Complete Element Checklist

| Section | File | Required Elements |
|---|---|---|
| Package PHP source | `BUILD` | `pkg_tar(name, srcs, package_dir)` |
| Build OCI image | `BUILD` | `oci_image(name, base, tars, entrypoint, ports)` |
| Create Docker tarball | `BUILD` | `oci_tarball(name, image, repo_tags)` |
| Version check rule | `.bzl` | `impl` function: declare output, compose command (load + run + `php -v`), `run_shell`, `DefaultInfo` |
| Rule definition | `.bzl` | `rule(implementation, attrs)` with `image` (label) and `image_name` (string) attributes |
| Invoke rule | `BUILD` | `load(...)`, `php_version_check(name, image, image_name)` |
