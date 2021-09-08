# Use a master version if on master branch; use a released version if on release branch
SAT_VERSION=3.10.0-20210907172136_47bb1ee
SAT_PODMAN_VERSION=1.5.1-20210907142801_49142b1
# Always just use a stable release of this since it's an external dependency.
CPCU_VERSION=0.1.3
SAT_CFS_DOCKER_VERSION=1.0.3-20210907184559_253262a
SAT_CFS_HELM_VERSION=${SAT_CFS_DOCKER_VERSION/_/+}
SAT_INSTALL_UTILITY_VERSION=1.2.0-20210907171719_ba99f3c
