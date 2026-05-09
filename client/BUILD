load("//rules_custom/rules_client:container.bzl", "docker_reload")

docker_reload(
    name = "reload",
    dockerfile = "Dockerfile",
    srcs = [
        "composer.json",
        "composer.lock",
        "src/index.php",
    ],
    tag = "video-editor-client",
    container_name = "video-editor-client",
    ports = ["8080:8080"],
)
