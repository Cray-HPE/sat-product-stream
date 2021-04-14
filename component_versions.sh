# Use a master version if on master branch; use a released version if on release branch
SAT_VERSION=3.5.0-20210325004035_c48be28
# Always just use a stable release of this since it's an external dependency.
CPCU_VERSION=0.0.4
# FIXME: this revision of sat-cfs-install is not the latest master or release version, because it has not been merged yet.
SAT_CFS_DOCKER_VERSION=1.0.0-20210415205831_9828e74
SAT_CFS_HELM_VERSION=${SAT_CFS_DOCKER_VERSION/_/+}
