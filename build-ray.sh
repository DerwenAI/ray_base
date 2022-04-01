#!/usr/bin/env bash
set -eux

# per:
# https://docs.ray.io/en/latest/ray-overview/installation.html#installing-from-a-specific-commit
#
# we'd like to access a public Ray wheel for:
#  * Ubuntu 20.04 LTS
#  * 64-bit architecture
#  * Python 3.8.3
#  * Ray release 1.11.0 commit fec30a25dbb5f3fa81d2bf419f75f5d40bc9fc39
#
# since the use of commit hashes in wheel URLs fails,
# we revert to a "known good" example:

AWS_BUCKET="https://s3-us-west-2.amazonaws.com/ray-wheels"
COMMIT_HASH="latest"
RAY_VERSION="1.7.0"
PYTHON_VERSION="cp38" 
OS_VERSION="anylinux2014_x86_64"

# then use:
WHEEL_URL=$AWS_BUCKET/$COMMIT_HASH/ray-$RAY_VERSION-$PYTHON_VERSION-$PYTHON_VERSION-m$OS_VERSION.whl

# except that this "known good" example is riddled with security
# vulnerabilities and Ray wheels are not available for other point
# releases

# instead, we've built a wheel and moved it into this directory:
WHEEL_PATH="./ray-1.11.0-cp38-cp38-manylinux2014_x86_64.whl"
WHEEL=$(basename $WHEEL_PATH)

K8S=$(wget --no-check-certificate https://dl.k8s.io/release/stable.txt -O /dev/stdout)

docker build \
	--build-arg WHEEL_PATH="$WHEEL_PATH" --build-arg WHEEL="$WHEEL" --build-arg K8S="$K8S" \
	--pull --rm -f "Dockerfile.ray-base" \
	-t ray-base:latest .
