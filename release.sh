#!/usr/bin/env bash
#
# Package the the SAT release distribution and generate a gzipped tar file that
# contains everything needed to install SAT on a system.
# 
# Copyright 2020-2021 Hewlett Packard Enterprise Development LP

set -ex

: "${BLOBLET_URL:="http://dst.us.cray.com/dstrepo/bloblets/sat/dev/master/"}"

# This is the version of the SAT product, which includes the sat python package
# and CLI as well as the sat podman wrapper script. As such, the version number
# differs from each of those version numbers, and its major, minor, or patch
# versions should be updated if either of the underlying packages change their
# corresponding versions.
: "${RELEASE:="${RELEASE_NAME:="sat"}-${RELEASE_VERSION:=$(cat .version)}"}"

ROOTDIR="$(dirname "${BASH_SOURCE[0]}")"
source "${ROOTDIR}/vendor/stash.us.cray.com/scm/shastarelm/release/lib/release.sh"

# Determine whether to pull sat container image from stable or master repository
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" == release/* ]]; then
    SAT_REPO_TYPE=stable
else
    SAT_REPO_TYPE=master
fi

# Substitute SAT version
source "${ROOTDIR}/component_versions.sh"
for f in "${ROOTDIR}/docker/index.yaml" "${ROOTDIR}/cray-product-catalog/sat.yaml" "${ROOTDIR}/install.sh" \
    "${ROOTDIR}/helm/index.yaml" "${ROOTDIR}/manifests/sat.yaml"
do
    sed -e "s/@SAT_REPO_TYPE@/${SAT_REPO_TYPE}/" \
        -e "s/@SAT_VERSION@/${SAT_VERSION}/" \
        -e "s/@CPCU_VERSION@/${CPCU_VERSION}/" \
        -e "s/@SAT_CFS_DOCKER_VERSION@/${SAT_CFS_DOCKER_VERSION}/" \
        -e "s/@SAT_CFS_HELM_VERSION@/${SAT_CFS_HELM_VERSION}/" $f.in > $f
done

requires rsync sed realpath

BUILDDIR="${1:-"$(realpath -m "$ROOTDIR/dist/${RELEASE}")"}"

# initialize build directory
[[ -d "$BUILDDIR" ]] && rm -fr "$BUILDDIR"
mkdir -p "$BUILDDIR"

# copy install scripts
mkdir -p "${BUILDDIR}/lib"
rsync -aq "${ROOTDIR}/vendor/stash.us.cray.com/scm/shastarelm/release/lib/install.sh" "${BUILDDIR}/lib/install.sh"
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

# Move the container images into the cray repository for consistency with old DTR layout
REGISTRY_DIR="${BUILDDIR}/docker/arti.dev.cray.com"
CRAY_REPO_DIR="${REGISTRY_DIR}/cray"
mkdir -p "${CRAY_REPO_DIR}"
for repo in "${REGISTRY_DIR}"/*-local; do
    mv "${repo}"/* "${CRAY_REPO_DIR}"
    rmdir "${repo}"
done

# sync sat repo from bloblet
reposync "${BLOBLET_URL}/rpms/cray-sles15-sp2-ncn/" "${BUILDDIR}/rpms/${RELEASE_NAME}-sle-15sp2"

# copy manifests
rsync -aq "${ROOTDIR}/manifests/sat.yaml" "${BUILDDIR}/manifests/"

# sync helm charts
helm-sync "${ROOTDIR}/helm/index.yaml" "${BUILDDIR}/helm"

# save cray/nexus-setup and quay.io/skopeo/stable images for use in install.sh
vendor-install-deps "$(basename "$BUILDDIR")" "${BUILDDIR}/vendor"

# Package the distribution into an archive
tar -C $(realpath -m "${ROOTDIR}/dist") -zcvf $(dirname "$BUILDDIR")/${RELEASE_NAME}-${RELEASE_VERSION}.tar.gz $(basename $BUILDDIR)
