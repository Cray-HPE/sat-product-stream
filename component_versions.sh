# Use a master version if on master branch; use a released version if on release branch
SAT_VERSION=3.7.5
SAT_PODMAN_VERSION=1.4.11-20211215161649_00374c4
# Always just use a stable release of this since it's an external dependency.
CPCU_VERSION=0.1.3
SAT_CFS_DOCKER_VERSION=1.0.4
SAT_CFS_HELM_VERSION=${SAT_CFS_DOCKER_VERSION/_/+}
