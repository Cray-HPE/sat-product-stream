#!/usr/bin/env bash
#
# Version script required by the build pipeline.
# Copyright 2021 Hewlett Packard Enterprise Development LP
#
# This script outputs the version of the sat product stream as follows:
#
# - If on a release branch, i.e. a branch prefixed by release/, output the
#   version exactly as defined in the file .version
# - Otherwise, if on any other branch, output the version defined in the file
#   .version appended with the timestamp and a short git commit hash in the
#   form VERSION-TIMESTAMP-GITHASH.
#
# In addition, if there are local, uncommitted changes, "-dirty" is appended to
# the version as determined by the rules above.

# Exits successfully if on a release branch, unsuccessfully otherwise.
function is_release_branch() {
    local git_branch=$(git rev-parse --abbrev-ref HEAD)
    case "$git_branch" in
        release/*)
            true
            ;;
        *)
            false
            ;;
    esac
}

# Gets the timestamp and git commit hash suffix to append to a version string
function get_version_suffix() {
    local short_git_hash=$(git rev-parse --short HEAD)
    local timestamp=$(date +%Y%m%d%H%M%S)
    echo "-${timestamp}-${short_git_hash}"
}

# Exits successfully if uncommitted changes exist, unsuccessfully if clean.
function uncommitted_changes_exist() {
    status_lines=$(git status --porcelain=v1 2>/dev/null | wc -l)
    if [[ $status_lines -gt 0 ]]; then
        true
    else
        false
    fi
}

full_version=""

dot_file_version="$(cat .version)"

if is_release_branch; then
    full_version="${dot_file_version}"
else
    full_version="${dot_file_version}$(get_version_suffix)"
fi

# Using the presence of the GIT_BRANCH environment variable to determine if we
# are running in a Jenkins pipeline. The pipeline puts files in place that look
# like uncommitted changes, but they are not.
if uncommitted_changes_exist && [[ -z $GIT_BRANCH ]]; then
    full_version="${full_version}-dirty"
fi

echo $full_version
