#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
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
# Render templates from component_versions.sh

ROOTDIR="$(dirname "${BASH_SOURCE[0]}")"

# Set to "unstable" for artifacts from main branch, "stable" for artifacts from
# release branch.
SAT_REPO_TYPE="stable"

DISABLE_GPG_CHECK=yes
if [[ "${SAT_REPO_TYPE}" == "stable" ]]; then
    DISABLE_GPG_CHECK=no
fi

# Substitute SAT variables
source "${ROOTDIR}/component_versions.sh"
for f in "${ROOTDIR}/docker/index.yaml" "${ROOTDIR}/cray-product-catalog/sat-component-versions.yaml" \
    "${ROOTDIR}/install.sh" "${ROOTDIR}/rpm/sle-15sp2/index.yaml" "${ROOTDIR}/ansible/roles/sat-ncn/defaults/main.yml"
do
    sed -e "s/@SAT_REPO_TYPE@/${SAT_REPO_TYPE}/" \
        -e "s%@ARTI_RPM_SUBDIR@%${ARTI_RPM_SUBDIR}%" \
        -e "s/@SAT_VERSION@/${SAT_VERSION}/" \
        -e "s/@SAT_PODMAN_VERSION@/${SAT_PODMAN_VERSION}/" \
        -e "s/@RELEASE_VERSION@/${RELEASE_VERSION}/" \
        -e "s/@CPCU_VERSION@/${CPCU_VERSION}/" \
        -e "s/@CF_GITEA_IMPORT_VERSION@/${CF_GITEA_IMPORT_VERSION}/" \
        -e "s/@DISABLE_GPG_CHECK@/${DISABLE_GPG_CHECK}/" \
        -e "s/@SAT_INSTALL_UTILITY_VERSION@/${SAT_INSTALL_UTILITY_VERSION}/" \
        -e "s/@CFS_CONFIG_UTIL_VERSION@/${CFS_CONFIG_UTIL_VERSION}/" \
        -e "s/@DOCS_SAT_VERSION@/${DOCS_SAT_VERSION}/" \
        $f.in > $f
done
