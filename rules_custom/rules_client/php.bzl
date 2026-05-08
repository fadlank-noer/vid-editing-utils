def _php_version_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".txt")
    bat = ctx.actions.declare_file(ctx.label.name + ".bat")
    ctx.actions.write(
        output = bat,
        content = '"%PHP_PATH%" -v > %1',
        is_executable = True,
    )
    php_path = ctx.configuration.default_shell_env.get("PHP_PATH", "php")
    ctx.actions.run(
        executable = bat,
        arguments = [output.path],
        outputs = [output],
        inputs = [bat],
        env = {"PHP_PATH": php_path},
    )
    return [DefaultInfo(files = depset([output]))]

php_version = rule(
    implementation = _php_version_impl,
    doc = "Runs `php -v` and writes the output to a file. Set PHP_PATH via --action_env in .bazelrc.",
)
