# ray_base

_Docker build for a base image for running Ray on K8s on Azure_


## Overview

Our team has used the Ray base images on DockerHub to build container
images deployed to Microsoft Azure, to run Ray on Kubernetes on AKS:

  * <https://hub.docker.com/r/rayproject/ray/tags>
  * <https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal>

However, our enterprise customer's independent security audits have
identified multiple high-severity security vulnerabilities in the Ray
base images on DockerHub. Moreover, our attempts to patch these
pre-built images with security updates have not succeeded.

Consequently we tried to rebuild containers to deploy to AKS, so that
we could manage the dependencies better with regards to these security
concerns. The Ray public source repo on GitHub unfortunately doesn't
provide `Dockerfile` descriptions for the containers:

  * <https://github.com/ray-project/ray>

Instead there is a cascade of shell scripts used to push image layers
to DockerHub, which becomes difficult to reverse-engineer effectively.
Working through both "decompiled" container images and the build
scripts for Ray, we've created this repo to re-build a Ray base image.

Our specific targets are:

  * Python 3.8.3
  * Ubuntu 20.04 LTS
  * Ray release 1.9.2 through 1.11.0

Unfortunately -- **and this is a critical blocker** -- the process of
building a Ray base image is based on using Ray wheels. While there is
documentation for accessing and building Ray wheels, we've identified
errors in both.

  * <https://docs.ray.io/en/latest/ray-contribute/development.html#building-ray-on-linux-macos-full>
  * <https://discuss.ray.io/t/trying-to-build-containers-from-ray-wheels/5618>

There availability of pre-built wheels for Ray appears to be limited
to only two releases:

  * [`1.7.0`](https://s3-us-west-2.amazonaws.com/ray-wheels/latest/ray-1.7.0-cp38-cp38-manylinux2014_x86_64.whl)
    which has the `log4j` vulnerability and other issues

  * [`2.0.0.dev0`](https://s3-us-west-2.amazonaws.com/ray-wheels/latest/ray-2.0.0.dev0-cp38-cp38-manylinux2014_x86_64.whl)

Considering how the latest release of Ray is `1.11.0` (as of the date
of this writing: 2022-03-21) this latter wheel's "release" number is
problematic.  When runnning Ray on K8s, it's important for different
system components to use the same Ray release.  No one seems to be
able to explain the mysterious `2.0.0.dev0` or its provenance.


## Concerns

Frankly, this a red-flag for enterprise customers who must work within
regulated enviornments whcih are accountable to independent security
audits. We also cannot run crucial system components from `head`
commits and must be able to tie our builds to specific point releases.


## Usage

To build a Ray base image for a specific release, edit the parameters
in the following script then run it:

```
./build-ray.sh
```

To build a Ray wheel for a specific release, edit the parameters in
the following script then run it:

```
./build-wheel.sh
```

Currently this build fails.


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
for the container. The reported vulnerabilities will be constrained to
those for which known fixes are available.