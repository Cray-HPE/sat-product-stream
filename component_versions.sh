# Use a master version if on master branch; use a released version if on release branch
SAT_VERSION=3.11.0-20211029193657_c204587
SAT_PODMAN_VERSION=1.5.2-20211029152029_7922a91
# Always just use a stable release of this since it's an external dependency.
CPCU_VERSION=0.1.3
SAT_CFS_DOCKER_VERSION=1.0.3-20210907184559_253262a
SAT_CFS_HELM_VERSION=${SAT_CFS_DOCKER_VERSION/_/+}
SAT_INSTALL_UTILITY_VERSION=1.3.2-20211029193701_be8a4f3
