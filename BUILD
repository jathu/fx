load("//tools/runner:defs.bzl", "runner")
load("@rules_pkg//pkg:pkg.bzl", "pkg_tar")

exports_files([
    ".clang-tidy",
    ".clang-format",
    "fx.rb",
])

# Run fx in development mode.
# Usage:
#   bazel run //:fx -- <args...>
runner(
    name = "fx",
    envvars = {
        "SPDLOG_LEVEL": "trace",
    },
    tool = "//src:main",
)

# Release ----------------------------------------------------------------------

pkg_tar(
    name = "package",
    files = {
        "//src:main": "fx",
    },
    stamp = 1,
)

platform(
    name = "macos-x86",
    constraint_values = [
        "@bazel_tools//platforms:osx",
        "@bazel_tools//platforms:x86_64",
        "@bazel_tools//tools/cpp:clang",
    ],
)

platform(
    name = "linux-x86",
    constraint_values = [
        "@bazel_tools//platforms:linux",
        "@bazel_tools//platforms:x86_64",
        "@bazel_tools//tools/cpp:clang",
    ],
)
