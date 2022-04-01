# ray_base

_Docker build for a base image for running Ray on K8s on Azure_


## Problem statement

Our team has used the Ray base images on DockerHub to build container
images deployed to Microsoft Azure, to run Ray on Kubernetes on AKS.
These were based on:

  * <https://hub.docker.com/r/rayproject/ray/tags>
  * <https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal>

However, our enterprise customer's independent security audits have
identified multiple high-severity security vulnerabilities in the Ray
base images available on DockerHub. Our attempts to patch pre-built
images with security updates proved to be problematic. Consequently we
must build containers to deploy to AKS, so that we can manage
dependencies better with regards to security concerns.

Our targets are:

  * Ubuntu 20.04 LTS
  * 64-bit architecture
  * Python 3.8.3
  * Ray release 1.11.0, or possibly back as far as 1.9.2


## Blockers

The public source repo on GitHub for Ray unfortunately doesn't provide
`Dockerfile` descriptions for the containers it builds:

  * <https://github.com/ray-project/ray>

Instead there's a cascade of shell scripts which push image layers to
DockerHub. This is difficult to reverse-engineer in detail.

Based on working through both "decompiled" container images and
line-by-line runs of `build-docker.sh` and other scripts, this repo
here provides a Ray base image based on a specific Ray release.

Unfortunately -- **and this is a critical blocker** -- Ray's process
for building a base image depends on using Ray wheels. While there is
documentation for accessing pre-built Ray wheels, we've identified
multiple errors:

  * <https://docs.ray.io/en/latest/ray-contribute/development.html#building-ray-on-linux-macos-full>
  * <https://discuss.ray.io/t/trying-to-build-containers-from-ray-wheels/5618>

While there is documentation for
["Installing from a specific commit"](https://docs.ray.io/en/latest/ray-overview/installation.html#installing-from-a-specific-commit),
**those instructions do not work**.

In brief, the availability of pre-built wheels for Ray appears to be
limited to only two releases:

  * `1.7.0`
  <https://s3-us-west-2.amazonaws.com/ray-wheels/latest/ray-1.7.0-cp38-cp38-manylinux2014_x86_64.whl>  
  which has the `log4j` vulnerability and other security issues

  * `2.0.0.dev0`
  <https://s3-us-west-2.amazonaws.com/ray-wheels/latest/ray-2.0.0.dev0-cp38-cp38-manylinux2014_x86_64.whl>

The latter wheel `2.0.0.dev0` is for a nightly build of the "head"
commit in the Ray `master` branch. Considering how the latest release
of Ray is `1.11.0` (as of the date of this writing: 2022-03-21) that
did seem incongruous. Also, good luck trying to determine that fact
from the documentation!

If you look closely through notes from Ray committers on the GitHub
issues for Ray, only the nightly builds from "head" are made available.

This is unacceptable due to:

  * When runnning Ray on K8s, different system components need to use the same Ray release.
  * We cannot run crucial system components from "head" commits and must tie our builds to specific point releases.
  * The Ray project has a long and coloful history of unexpected or undocumented breaking changes.

Overall, these blockers pose red-flags for enterprise customers who
work within regulated enviornments accountable to independent security
audits.


## Step 1: build a Ray wheel for a specific release and platform

Clone the Ray repo from GitHub, then checkout for a specific tag. In
our case we want Ray release `1.11.0` so `tags/ray-1.11.0` is the
corresponding tag for its `fec30a25dbb5f3fa81d2bf419f75f5d40bc9fc39`
commit.

```
git clone https://github.com/ray-project/ray.git
cd ray
git checkout tags/ray-1.11.0
```

Next, follow the set up instructions in
["Building Ray on Linux & MacOS"](https://docs.ray.io/en/latest/ray-contribute/development.html#building-ray-on-linux-macos-full).
In our case, we're building on Ubuntu Linux.

Then see the file
[`python/README-building-wheels.md`](https://github.com/ray-project/ray/blob/master/python/README-building-wheels.md)
which describes running the following command from the root directory
of the repo:

```
docker run \
    -e TRAVIS_COMMIT=<commit_number_to_use> \
    --rm -w /ray -v `pwd`:/ray \
    -ti quay.io/pypa/manylinux2014_x86_64 \
    /ray/python/build-wheel-manylinux2014.sh
```

After this completes successful, the newly built wheels will be
located in the `.whl` directory.


## Step 2: build a Ray base image

To build a Ray base image, first copy the appropriate wheel file from
the previous step into this directory.

Then edit parameters in the following script and run it:

```
./build-ray.sh
```

This will build the image `ray-base` locally.


## Security scans

We use [`grype`](https://github.com/anchore/grype) for security scans
of container images. To install:

```
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
```

Then run `grype` for security vulnerability analysis of a specific
container image:

```
grype -o json --only-fixed ray-base:latest > cve.json
```

This will produce a JSON file `cve.json` with vulnerabilities listed
for the container, where the reported vulnerabilities are limited to
those for which known fixes are available.
