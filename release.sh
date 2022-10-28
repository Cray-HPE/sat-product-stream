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

requires rsync sed realpath rpm2cpio

. "${ROOTDIR}/render_templates.sh"

BUILDDIR="${1:-"$(realpath -m "$ROOTDIR/dist/${RELEASE}")"}"
SNYK_SCAN_DIR="${BUILDDIR}/scans"

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

# validate IUF Product Manifest file against schema
iuf-validate "${ROOTDIR}/iuf-product-manifest.yaml"

# copy IUF Product Manifest file
rsync -aq "${ROOTDIR}/iuf-product-manifest.yaml" "${BUILDDIR}/"

# copy SAT data for cray-product-catalog
mkdir -p "${BUILDDIR}/cray-product-catalog"
rsync -aq "${ROOTDIR}/cray-product-catalog/sat-component-versions.yaml" "${BUILDDIR}/cray-product-catalog/sat-component-versions.yaml"

# copy Ansible plays, exclude roles/sat-ncn/defaults/main.yml.in
rsync --exclude "*.in" -aq "${ROOTDIR}/ansible" "${BUILDDIR}"

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

# scan container images
if [[ -z "$NO_SKYK_SCAN" ]]; then
    mkdir -p "$SNYK_SCAN_DIR"
    all_images=$(list-images "${ROOTDIR}/docker/index.yaml")
    cd "$SNYK_SCAN_DIR"
    for image in $all_images; do
        snyk-scan "$image"
    done
    snyk_results=$(find "$SNYK_SCAN_DIR" -name "snyk.json")
    snyk-aggregate-results "$snyk_results"
    for result in $snyk_results; do
        snyk-to-html "$result"
    done
    cd -
fi

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

# save nexus-setup, skopeo, and cfs-config-util images for use in install.sh
vendor-install-deps --include-cfs-config-util "$(basename "$BUILDDIR")" "${BUILDDIR}/vendor"

if [[ -z "$NO_SNYK_SCAN" ]]; then
    # Save snyk results spreadsheet as a separate asset.
    mv "$SNYK_SCAN_DIR/snyk.xlsx" "${ROOTDIR}/dist/${RELEASE}-snyk-results.xlsx"
    # Package scans as an independent archive.
    snyk_archive_name="${RELEASE}-snyk-results.tar.gz"
    tar -C $(realpath -m "$BUILDDIR") -zcvf "$(dirname "$BUILDDIR")/$snyk_archive_name" "$(basename "$SNYK_SCAN_DIR")"
    # Remove scans from release distribution
    rm -rf "${BUILDDIR}/scans"
fi

# Package the distribution into an archive
tar -C $(realpath -m "${ROOTDIR}/dist") -zcvf $(dirname "$BUILDDIR")/${RELEASE_NAME}-${RELEASE_VERSION}.tar.gz $(basename $BUILDDIR)
