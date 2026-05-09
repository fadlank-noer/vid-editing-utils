def _docker_pull_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".txt")
    bat = ctx.actions.declare_file(ctx.label.name + ".bat")
    image_ref = ctx.attr.image + ":" + ctx.attr.tag
    docker_path = ctx.configuration.default_shell_env.get("DOCKER_PATH", "docker")
    ctx.actions.write(
        output = bat,
        content = '"%DOCKER_PATH%" pull ' + image_ref + ' --platform ' + ctx.attr.platform + ' && "%DOCKER_PATH%" images --format {{.Repository}}:{{.Tag}} {{.ID}} ' + image_ref + ' > %1',
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

docker_pull = rule(
    implementation = _docker_pull_impl,
    attrs = {
        "image": attr.string(mandatory = True),
        "tag": attr.string(default = "latest"),
        "platform": attr.string(default = "linux/amd64"),
    },
    doc = "Pulls a Docker image via `docker pull`. Set DOCKER_PATH via --action_env in .bazelrc.",
)
