#!/usr/bin/env bash
#
# This updates the CFS configuration that applies to management NCNs.
#
# Copyright 2020-2021 Hewlett Packard Enterprise Development LP

[ -n "${SAT_INSTALL_DEBUG}" ] && set -x

ROOTDIR="$(dirname "${BASH_SOURCE[0]}")"
source "${ROOTDIR}/lib/version.sh"
source "${ROOTDIR}/lib/install.sh"
source "${ROOTDIR}/install-utils.sh"

load-cfs-config-util
trap "{ print_stage 'Cleaning up install dependencies'; clean-install-deps &>/dev/null; }" EXIT

function print_usage() {
    cat <<EOF
usage: ${BASH_SOURCE[0]} [options]

Update the CFS configuration for configuring management NCNs by adding or
updating the layer for ${RELEASE}.

Options:

  -h, --help              Print this usage information.

EOF

    cfs-config-util-options-help
}

if [[ $1 == "-h" || $1 == "--help" ]]; then
    print_usage
    exit 0
fi

print_stage "Updating CFS configuration(s)"

cfs-config-util --product "${RELEASE_NAME}:${RELEASE_VERSION}" --playbook sat-ncn.yml $@
rc=$?

if [[ $rc -eq 2 ]]; then
    print_usage
    exit_with_error "cfs-config-util received invalid arguments."
elif [[ $rc -ne 0 ]]; then
    exit_with_error "Failed to update CFS configurations. cfs-config-util exited with exit status $rc."
fi

print_stage "Completed CFS configuration(s)"
