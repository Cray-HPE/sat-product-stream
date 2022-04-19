#!/usr/bin/env bash
#
# Package the the SAT release distribution and generate a gzipped tar file that
# contains everything needed to install SAT on a system.
# 
# Copyright 2020-2021 Hewlett Packard Enterprise Development LP
set -ex

# This is the version of the SAT product, which includes the sat python package
# and CLI as well as the sat podman wrapper script. As such, the version number
# differs from each of those version numbers, and its major, minor, or patch
# versions should be updated if either of the underlying packages change their
# corresponding versions.
: "${RELEASE:="${RELEASE_NAME:="sat"}-${RELEASE_VERSION:=$(./version.sh)}"}"

ROOTDIR="$(dirname "${BASH_SOURCE[0]}")"
source "${ROOTDIR}/vendor/github.hpe.com/hpe/hpc-shastarelm-release/lib/release.sh"

# Set to "master" for artifacts from master branch, "stable" for artifacts from
# release branch.
SAT_REPO_TYPE="stable"
SEMANTIC_VERSION_ONLY=${RELEASE_VERSION%%-*}
MAJOR_MINOR_VERSION=${SEMANTIC_VERSION_ONLY%.*}
if [[ $SAT_REPO_TYPE == "master" ]]; then
    ARTI_RPM_SUBDIR=dev/master
else
    ARTI_RPM_SUBDIR="release/${RELEASE_NAME}-${MAJOR_MINOR_VERSION}"
fi

# Substitute SAT version
source "${ROOTDIR}/component_versions.sh"
for f in "${ROOTDIR}/docker/index.yaml" "${ROOTDIR}/cray-product-catalog/sat.yaml" "${ROOTDIR}/install.sh" \
    "${ROOTDIR}/rpm/sle-15sp2/index.yaml" "${ROOTDIR}/helm/index.yaml" "${ROOTDIR}/manifests/sat.yaml"
do
    sed -e "s/@SAT_REPO_TYPE@/${SAT_REPO_TYPE}/" \
        -e "s%@ARTI_RPM_SUBDIR@%${ARTI_RPM_SUBDIR}%" \
        -e "s/@SAT_VERSION@/${SAT_VERSION}/" \
        -e "s/@SAT_PODMAN_VERSION@/${SAT_PODMAN_VERSION}/" \
        -e "s/@RELEASE_VERSION@/${RELEASE_VERSION}/" \
        -e "s/@CPCU_VERSION@/${CPCU_VERSION}/" \
        -e "s/@SAT_INSTALL_UTILITY_VERSION@/${SAT_INSTALL_UTILITY_VERSION}/" \
        -e "s/@SAT_CFS_DOCKER_VERSION@/${SAT_CFS_DOCKER_VERSION}/" \
        -e "s/@SAT_CFS_HELM_VERSION@/${SAT_CFS_HELM_VERSION}/" \
        -e "s/@CFS_CONFIG_UTIL_VERSION@/${CFS_CONFIG_UTIL_VERSION}/" \
        $f.in > $f
done

requires rsync sed realpath

BUILDDIR="${1:-"$(realpath -m "$ROOTDIR/dist/${RELEASE}")"}"

# initialize build directory
[[ -d "$BUILDDIR" ]] && rm -fr "$BUILDDIR"
mkdir -p "$BUILDDIR"

# copy install scripts
mkdir -p "${BUILDDIR}/lib"
rsync -aq "${ROOTDIR}/vendor/github.hpe.com/hpe/hpc-shastarelm-release/lib/install.sh" "${BUILDDIR}/lib/install.sh"
rsync -aq "${ROOTDIR}/install.sh" "${BUILDDIR}/"
chmod 755 "${BUILDDIR}/install.sh"

# copy SAT data for cray-product-catalog
mkdir -p "${BUILDDIR}/cray-product-catalog"
rsync -aq "${ROOTDIR}/cray-product-catalog/sat.yaml" "${BUILDDIR}/cray-product-catalog/sat.yaml"

# generate a script that can be sourced to set RELEASE, RELEASE_NAME, and
# RELEASE_VERSION at install time
gen-version-sh "$RELEASE_NAME" "$RELEASE_VERSION" >"${BUILDDIR}/lib/version.sh"
chmod +x "${BUILDDIR}/lib/version.sh"

# generate Nexus blob store configuration
generate-nexus-config blobstore <"${ROOTDIR}/nexus-blobstores.yaml" >"${BUILDDIR}/nexus-blobstores.yaml"

# generate Nexus repositories configuration
# update repository names based on the release version
sed -e "s/@RELEASE@/${RELEASE}/g" "${ROOTDIR}/nexus-repositories.yaml" | generate-nexus-config repository >"${BUILDDIR}/nexus-repositories.yaml"

# sync container images
skopeo-sync "${ROOTDIR}/docker/index.yaml" "${BUILDDIR}/docker"

# Re-organize the docker directory so all docker images are uploaded to a repo
# prefixed with "cray/" in the Nexus container image registry
ARTI_DIR="${BUILDDIR}/docker/arti.dev.cray.com"
CRAY_DIR="${BUILDDIR}/docker/cray"
mkdir -p "${CRAY_DIR}"
for repo in "${ARTI_DIR}"/*-local "${ARTI_DIR}/csm-docker-remote/stable"; do
    mv "${repo}"/* "${CRAY_DIR}"
    rmdir "${repo}"
done
rmdir "${ARTI_DIR}/csm-docker-remote"
rmdir "${ARTI_DIR}"

# Sync RPMs using manifest file
rpm-sync "${ROOTDIR}/rpm/sle-15sp2/index.yaml" "${BUILDDIR}/rpms/${RELEASE_NAME}-sle-15sp2"

# Flatten directory structure and remove "x86_64" directories
{
    find "${BUILDDIR}/rpms/" -name 'x86_64' -type d
} | while read path; do
    mv "$path"/* "$(dirname "$path")/"
    rmdir "$path"
done

# Create SAT repositories
createrepo "${BUILDDIR}/rpms/${RELEASE_NAME}-sle-15sp2"

# copy manifests
rsync -aq "${ROOTDIR}/manifests/sat.yaml" "${BUILDDIR}/manifests/"

# sync helm charts
helm-sync "${ROOTDIR}/helm/index.yaml" "${BUILDDIR}/helm"

# save cray/nexus-setup and quay.io/skopeo/stable images for use in install.sh
vendor-install-deps "$(basename "$BUILDDIR")" "${BUILDDIR}/vendor"

# Package the distribution into an archive
tar -C $(realpath -m "${ROOTDIR}/dist") -zcvf $(dirname "$BUILDDIR")/${RELEASE_NAME}-${RELEASE_VERSION}.tar.gz $(basename $BUILDDIR)
