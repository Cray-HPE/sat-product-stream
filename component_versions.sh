# Use a master version if on master branch; use a released version if on release branch
SAT_VERSION=3.8.0-20210623191519_a80e627
SAT_PODMAN_VERSION=1.4.7-20210623155701_3f5d88b
# Always just use a stable release of this since it's an external dependency.
CPCU_VERSION=0.1.3
SAT_CFS_DOCKER_VERSION=1.0.2-20210514024411_4e375c4
SAT_CFS_HELM_VERSION=${SAT_CFS_DOCKER_VERSION/_/+}
