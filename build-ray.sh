#!/usr/bin/env bash
set -eux

# per:
# https://docs.ray.io/en/latest/ray-overview/installation.html#installing-from-a-specific-commit
#
# we'd like to download a public Ray wheel for:
#  * Ubuntu 20.04 LTS
#  * 64-bit architecture
#  * Python 3.8.3
#  * Ray release 1.11.0 commit fec30a25dbb5f3fa81d2bf419f75f5d40bc9fc39
#

# however, since use of commit hashes in URLs for accessing Ray wheels
# in general fails, we revert to using the only "known good" example:

OS_VERSION="anylinux2014_x86_64"
PY_ABBR="cp38"
RAY_VERSION="1.7.0"
COMMIT_HASH="latest"
AWS_BUCKET="https://s3-us-west-2.amazonaws.com/ray-wheels"

# then use:
WHEEL_URL="$AWS_BUCKET/$COMMIT_HASH/ray-$RAY_VERSION-$PY_ABBR-$PY_ABBR-m$OS_VERSION.whl"

# however, this "known good" example has security vulnerabilities,
# although other Ray wheels are not available for later point
# releases – except the nightly `master` "head" builds!

# instead, we have built a Ray wheel locally for our specific targets
# and copied it manually into this directory:

OS_VERSION="anylinux2014_x86_64"
PY_ABBR="cp38" 
PY_VERS="3.8.3"
RAY_VERSION="1.11.0"
WHEEL="ray-$RAY_VERSION-$PY_ABBR-$PY_ABBR-m$OS_VERSION.whl"

CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
K8S=$(wget --no-check-certificate https://dl.k8s.io/release/stable.txt -O /dev/stdout)

HUB_USER="derwenai"
REPO_NAME="ray_base"
TAG="$RAY_VERSION-$PY_ABBR-$OS_VERSION"
BUILD_URL="$HUB_USER/$REPO_NAME:$TAG"

docker build \
    --build-arg CONDA_URL="$CONDA_URL" \
    --build-arg K8S="$K8S" \
    --build-arg PY_VERS="$PY_VERS"\
    --build-arg WHEEL="$WHEEL" \
    --pull --rm -f "Dockerfile.ray-base" \
    -t $BUILD_URL .
