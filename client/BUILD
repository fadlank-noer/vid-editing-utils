load("//rules_custom/rules_client:php.bzl", "php_version")
load("//rules_custom/rules_client:container.bzl", "docker_pull")

php_version(
    name = "php_version",
)

docker_pull(
    name = "php_fpm",
    image = "php",
    tag = "8.5.6-zts-alpine3.22",
    platform = "linux/amd64",
)
