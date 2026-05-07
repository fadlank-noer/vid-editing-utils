load("@rules_php//php:php.bzl", "php_binary", "php_library")

php_library(
    name = "vendor",
    srcs = glob(["vendor/**/*.php"]),
    visibility = ["//client:__subpackages__"],
)

php_binary(
    name = "app",
    srcs = glob(["src/**/*.php"]) + glob(["vendor/**/*.php"]),
    main = "src/index.php",
    visibility = ["//:__subpackages__"],
)
