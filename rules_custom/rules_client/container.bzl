def _docker_build_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".txt")
    bat = ctx.actions.declare_file(ctx.label.name + ".bat")
    dockerfile = ctx.file.dockerfile
    tag = ctx.attr.tag
    docker_path = ctx.configuration.default_shell_env.get("DOCKER_PATH", "docker")
    all_inputs = [dockerfile] + ctx.files.srcs
    ctx.actions.write(
        output = bat,
        content = '"%DOCKER_PATH%" build -t ' + tag + ' -f "' + dockerfile.path + '" "' + dockerfile.dirname + '" && "%DOCKER_PATH%" images --format {{.Repository}}:{{.Tag}} {{.ID}} ' + tag + ' > %1',
        is_executable = True,
    )
    ctx.actions.run(
        executable = bat,
        arguments = [output.path],
        outputs = [output],
        inputs = all_inputs,
        env = {"DOCKER_PATH": docker_path},
    )
    return [DefaultInfo(files = depset([output]))]

docker_build = rule(
    implementation = _docker_build_impl,
    attrs = {
        "dockerfile": attr.label(mandatory = True, allow_single_file = True),
        "srcs": attr.label_list(allow_files = True),
        "tag": attr.string(mandatory = True),
    },
    doc = "Builds a Docker image from a Dockerfile. Set DOCKER_PATH via --action_env in .bazelrc.",
)

def _docker_run_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".txt")
    bat = ctx.actions.declare_file(ctx.label.name + ".bat")
    image = ctx.attr.image
    docker_path = ctx.configuration.default_shell_env.get("DOCKER_PATH", "docker")
    flags = ""
    if ctx.attr.detach:
        flags += " -d"
    if ctx.attr.rm:
        flags += " --rm"
    for port in ctx.attr.ports:
        flags += " -p " + port
    ctx.actions.write(
        output = bat,
        content = '"%DOCKER_PATH%" run' + flags + " " + image + " > %1",
        is_executable = True,
    )
    ctx.actions.run(
        executable = bat,
        arguments = [output.path],
        outputs = [output],
        inputs = [bat],
        env = {"DOCKER_PATH": docker_path},
    )
    return [DefaultInfo(files = depset([output]))]

docker_run = rule(
    implementation = _docker_run_impl,
    attrs = {
        "image": attr.string(mandatory = True),
        "ports": attr.string_list(default = []),
        "detach": attr.bool(default = True),
        "rm": attr.bool(default = True),
    },
    doc = "Runs a Docker container. Set DOCKER_PATH via --action_env in .bazelrc.",
)

def _docker_reload_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".txt")
    bat = ctx.actions.declare_file(ctx.label.name + ".bat")
    dockerfile = ctx.file.dockerfile
    tag = ctx.attr.tag
    container_name = ctx.attr.container_name
    docker_path = ctx.configuration.default_shell_env.get("DOCKER_PATH", "docker")
    all_inputs = [dockerfile] + ctx.files.srcs

    run_flags = ' --name ' + container_name
    if ctx.attr.detach:
        run_flags += " -d"
    if ctx.attr.rm:
        run_flags += " --rm"
    for port in ctx.attr.ports:
        run_flags += " -p " + port

    ctx.actions.write(
        output = bat,
        content = (
            '"%DOCKER_PATH%" stop ' + container_name + ' 2>nul & ' +
            '"%DOCKER_PATH%" rm -f ' + container_name + ' 2>nul & ' +
            '"%DOCKER_PATH%" build --no-cache -t ' + tag + ' -f "' + dockerfile.path + '" "' + dockerfile.dirname + '" && ' +
            '"%DOCKER_PATH%" run' + run_flags + ' ' + tag + ' > %1'
        ),
        is_executable = True,
    )
    ctx.actions.run(
        executable = bat,
        arguments = [output.path],
        outputs = [output],
        inputs = all_inputs,
        env = {"DOCKER_PATH": docker_path},
    )
    return [DefaultInfo(files = depset([output]))]

docker_reload = rule(
    implementation = _docker_reload_impl,
    attrs = {
        "dockerfile": attr.label(mandatory = True, allow_single_file = True),
        "srcs": attr.label_list(allow_files = True),
        "tag": attr.string(mandatory = True),
        "container_name": attr.string(mandatory = True),
        "ports": attr.string_list(default = []),
        "detach": attr.bool(default = True),
        "rm": attr.bool(default = True),
    },
    doc = "Stops and removes the existing container, force-rebuilds the image, and runs a fresh container. Set DOCKER_PATH via --action_env in .bazelrc.",
)
