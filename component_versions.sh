# Use a master version if on master branch; use a released version if on release branch
SAT_VERSION=3.9.0-20210804200331_9f1a814
SAT_PODMAN_VERSION=1.5.0-20210804161344_d5c1435
# Always just use a stable release of this since it's an external dependency.
CPCU_VERSION=0.1.3
SAT_CFS_DOCKER_VERSION=1.0.2-20210514024411_4e375c4
SAT_CFS_HELM_VERSION=${SAT_CFS_DOCKER_VERSION/_/+}
SAT_INSTALL_UTILITY_VERSION=1.0.0-20210804200337_a4bc2c0
