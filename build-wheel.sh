#!/usr/bin/env bash -x

# target:
# Ray release 1.11.0 commit fec30a25dbb5f3fa81d2bf419f75f5d40bc9fc39
RAY_VERSION="1.11.0"
GIT_TAG="tags/ray-$RAY_VERSION"

docker build \
	--build-arg GIT_TAG="$GIT_TAG" \
	--pull --rm -f "docker/Dockerfile.ray-wheel" \
	-t ray-wheel:latest .

# TL;DR: fails after 59.5 minutes
# subprocess.CalledProcessError: Command '['/opt/ray/.bazel/bin/bazel', 'build', '--verbose_failures', '--', '//:ray_pkg', '//cpp:ray_cpp_pkg']' returned non-zero exit status 1.
