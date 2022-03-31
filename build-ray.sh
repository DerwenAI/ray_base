#!/usr/bin/env bash -x

# per:
# https://docs.ray.io/en/latest/ray-overview/installation.html#installing-from-a-specific-commit
#
# we'd like to access a public Ray wheel for:
#  * Ubuntu 20.04 LTS
#  * 64-bit architecture
#  * Python 3.8.3
#  * Ray release 1.11.0 commit fec30a25dbb5f3fa81d2bf419f75f5d40bc9fc39
#
# although use of commit hashes in wheel URLs clearly fails,
# so we revert to a "known good" example:

COMMIT_HASH="latest"
RAY_VERSION="1.7.0"
PYTHON_VERSION="cp38" 
OS_VERSION="anylinux2014_x86_64"
AWS_BUCKET="https://s3-us-west-2.amazonaws.com/ray-wheels"

# then use:
WHEEL_URL=$AWS_BUCKET/$COMMIT_HASH/ray-$RAY_VERSION-$PYTHON_VERSION-$PYTHON_VERSION-m$OS_VERSION.whl

# except that this "known good" example is the one riddled with security vulnerabilities
# instead, let's simply use another available Ray wheel:

WHEEL_URL="https://s3-us-west-2.amazonaws.com/ray-wheels/latest/ray-2.0.0.dev0-cp38-cp38-manylinux2014_x86_64.whl"
WHEEL=$(basename $WHEEL_URL)

K8S=$(wget --no-check-certificate https://dl.k8s.io/release/stable.txt -O /dev/stdout)

docker build \
	--build-arg WHEEL_URL="$WHEEL_URL" --build-arg WHEEL="$WHEEL" --build-arg K8S="$K8S" \
	--pull --rm -f "docker/Dockerfile.ray-base" \
	-t ray-base:latest .

# one snag: no one seems able to say which version of Ray this `2.0.0.dev0` actually is?!?
