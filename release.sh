#!/usr/bin/env bash
#
# MIT License
#
# (C) Copyright 2020-2022 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
#
# Package the the SAT release distribution and generate a gzipped tar file that
# contains everything needed to install SAT on a system.
# 
set -ex

# This is the version of the SAT product, which includes the sat python package
# and CLI as well as the sat podman wrapper script. As such, the version number
# differs from each of those version numbers, and its major, minor, or patch
# versions should be updated if either of the underlying packages change their
# corresponding versions.
: "${RELEASE:="${RELEASE_NAME:="sat"}-${RELEASE_VERSION:=$(./version.sh)}"}"

ROOTDIR="$(dirname "${BASH_SOURCE[0]}")"
source "${ROOTDIR}/vendor/github.hpe.com/hpe/hpc-shastarelm-release/lib/release.sh"

# Set to "unstable" for artifacts from main branch, "stable" for artifacts from
# release branch.
SAT_REPO_TYPE="unstable"
SEMANTIC_VERSION_ONLY=${RELEASE_VERSION%%-*}
MAJOR_MINOR_VERSION=${SEMANTIC_VERSION_ONLY%.*}

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
        -e "s/@DOCS_SAT_VERSION@/${DOCS_SAT_VERSION}/" \
        $f.in > $f
done

requires rsync sed realpath rpm2cpio

BUILDDIR="${1:-"$(realpath -m "$ROOTDIR/dist/${RELEASE}")"}"

# initialize build directory
[[ -d "$BUILDDIR" ]] && rm -fr "$BUILDDIR"
mkdir -p "$BUILDDIR"

# copy install scripts
mkdir -p "${BUILDDIR}/lib"
rsync -aq "${ROOTDIR}/vendor/github.hpe.com/hpe/hpc-shastarelm-release/lib/install.sh" "${BUILDDIR}/lib/install.sh"
rsync -aq "${ROOTDIR}/install-utils.sh" "${BUILDDIR}/"
rsync -aq "${ROOTDIR}/install.sh" "${BUILDDIR}/"
chmod 755 "${BUILDDIR}/install.sh"
rsync -aq "${ROOTDIR}/update-mgmt-ncn-cfs-config.sh" "${BUILDDIR}/"
chmod 755 "${BUILDDIR}/update-mgmt-ncn-cfs-config.sh"

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
ARTI_DIR="${BUILDDIR}/docker/artifactory.algol60.net"
CRAY_DIR="${BUILDDIR}/docker/cray"
mkdir -p "$CRAY_DIR"
# Any directory containing "manifest.json" is assumed to be an image.
image_dirs=$(find "$ARTI_DIR" -name manifest.json -exec dirname {} \;)
for image_dir in $image_dirs; do
    mv "$image_dir" "$CRAY_DIR"
done
rm -r "$ARTI_DIR"

# Sync RPMs using manifest file
rpm-sync "${ROOTDIR}/rpm/sle-15sp2/index.yaml" "${BUILDDIR}/rpms/${RELEASE_NAME}-sle-15sp2"

# Create SAT repositories
createrepo "${BUILDDIR}/rpms/${RELEASE_NAME}-sle-15sp2"

# Extract docs RPM into release
# Copied from: https://github.com/Cray-HPE/csm/blob/main/release.sh
mkdir -p "${BUILDDIR}/tmp/docs"
(
    cd "${BUILDDIR}/tmp/docs"
    find "${BUILDDIR}/rpms/${RELEASE_NAME}-sle-15sp2" -type f -name docs-sat-\*.rpm | head -n 1 | xargs -n 1 rpm2cpio | cpio -idvm ./usr/share/doc/sat/*
)
mv "${BUILDDIR}/tmp/docs/usr/share/doc/sat" "${BUILDDIR}/docs"

# Clean up temp space
rm -fr "${BUILDDIR}/tmp"

# copy manifests
rsync -aq "${ROOTDIR}/manifests/sat.yaml" "${BUILDDIR}/manifests/"

# sync helm charts
helm-sync "${ROOTDIR}/helm/index.yaml" "${BUILDDIR}/helm"

# save nexus-setup, skopeo, and cfs-config-util images for use in install.sh
vendor-install-deps --include-cfs-config-util "$(basename "$BUILDDIR")" "${BUILDDIR}/vendor"

# Package the distribution into an archive
tar -C $(realpath -m "${ROOTDIR}/dist") -zcvf $(dirname "$BUILDDIR")/${RELEASE_NAME}-${RELEASE_VERSION}.tar.gz $(basename $BUILDDIR)
