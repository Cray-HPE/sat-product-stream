#!/usr/bin/env bash
#
# Install the SAT product. This loads the cray/cray-sat docker image into nexus
# so that it can be pulled down by podman and sets up RPM repositories in nexus
# and uploads SAT rpms to those repos. It also uploads the
# cray/cray-product-catalog-update docker image to Nexus, and then uses it to
# add an entry to the cray-product-catalog Kubernetes configuration map.
#
# Copyright 2020-2021 Hewlett Packard Enterprise Development LP

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

# Add SAT to cray-product-catalog
product_catalog_image=${CRAY_PRODUCT_CATALOG_UPDATE_IMAGE:-registry.local/cray/cray-product-catalog-update:0.0.4}
podman run --rm --name sat-cpc \
    -e PRODUCT="sat" \
    -e PRODUCT_VERSION=$RELEASE_VERSION \
    -e KUBECONFIG="/.kube/admin.conf" \
    -e YAML_CONTENT="/cray-product-catalog/sat.yaml" \
    -v "/etc/kubernetes:/.kube:ro" \
    -v "${ROOTDIR}/cray-product-catalog:/cray-product-catalog:ro" \
    $product_catalog_image

clean-install-deps
