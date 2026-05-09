load("//rules_custom/rules_client:php.bzl", "php_version")
load("//rules_custom/rules_client:container.bzl", "docker_build", "docker_run")

php_version(
    name = "php_version",
)

docker_build(
    name = "build",
    dockerfile = "Dockerfile",
    srcs = [
        "composer.json",
        "composer.lock",
        "src/index.php",
    ],
    tag = "video-editor-client",
)

docker_run(
    name = "run",
    image = "video-editor-client",
    ports = ["8080:8080"],
)
