# Use a master version if on master branch; use a released version if on release branch
SAT_VERSION=3.6.0-20210416195541_db59b55
# Always just use a stable release of this since it's an external dependency.
CPCU_VERSION=0.0.4
SAT_CFS_DOCKER_VERSION=1.0.0-20210416195535_b4db651
SAT_CFS_HELM_VERSION=${SAT_CFS_DOCKER_VERSION/_/+}
