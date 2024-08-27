# Dockerfile for the GAP system

The [Dockerfile](/Dockerfile) specifies a Docker image that contains the core GAP binaries, all packages that come in the main release tarball, and the runtime dependencies.

The image is significantly smaller than the [official image](https://hub.docker.com/r/gapsystem/gap-docker), as the build happens in a separate intermediate stage and the toolchain and development libraries are not shipped with the image.

This means it is not possible to compile further GAP packages in the container without installing the toolchain and development libraries.

Inspiration has been taken from the Dockerfile for the [official GAP base image](https://github.com/gap-system/gap-docker-base) and an [open pull request](https://github.com/gap-system/gap-docker-base/pull/32).
