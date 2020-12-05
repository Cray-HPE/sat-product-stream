#!/usr/bin/env bash
#
# Install the SAT product. This loads the cray/cray-sat docker image into nexus
# so that it can be pulled down by podman and sets up RPM repositories in nexus
# and uploads SAT rpms to those repos.
#
# Copyright 2020 Hewlett Packard Enterprise Development LP

set -ex

ROOTDIR="$(dirname "${BASH_SOURCE[0]}")"
source "${ROOTDIR}/lib/version.sh"
source "${ROOTDIR}/lib/install.sh"

load-install-deps

# Upload assets to existing repositories
skopeo-sync "${ROOTDIR}/docker" 

# Setup Nexus
nexus-setup blobstores   "${ROOTDIR}/nexus-blobstores.yaml"
nexus-setup repositories "${ROOTDIR}/nexus-repositories.yaml"

# Upload repository contents
nexus-upload raw "${ROOTDIR}/rpms/${RELEASE_NAME}-sle-15sp2" "${RELEASE}-sle-15sp2"

clean-install-deps
