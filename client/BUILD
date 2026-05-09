load("//rules_custom/rules_client:container.bzl", "docker_reload")

docker_reload(
    name = "reload",
    dockerfile = "Dockerfile",
    srcs = [
        "composer.json",
        "composer.lock",
        "package.json",
        "package-lock.json",
        "src/index.php",
        "src/assets/css/input.css",
        "src/app/views/layout.latte",
        "src/app/views/pages/home.latte",
        "src/app/views/ui/button.latte",
        "src/app/views/ui/card.latte",
    ],
    tag = "video-editor-client",
    container_name = "video-editor-client",
    ports = ["8080:8080"],
)
