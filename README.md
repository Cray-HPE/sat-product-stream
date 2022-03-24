# SAT Product Stream
This repository defines the product stream for the System Admin Toolkit.

## Packaging
The `release.sh` script in this repository generates a release distribution
for the SAT product stream. This script downloads artifacts as follows:

* Docker images listed in `docker/index.yaml`.
* Helm charts defined in `helm/index.yaml`.
* RPMs listed in `rpm/SLE_VERSION/index.yaml` where `SLE_VERSION` is the version
  of SUSE Linux Enterprise for which SAT is currently packaged.

It will package these along with the install script, `install.sh`, and other
install libraries and dependencies, into a release distribution as a gzipped
tar file.

The following environment variables can be used to control packaging of the
release distribution:

| Variable          | Description                                 | Default Value                                             |
| ----------------- | ------------------------------------------- | --------------------------------------------------------- |
| `RELEASE_VERSION` | The release version of the SAT distribution | Return value of `version.sh` script.                      |

To create a release distribution locally, run `release.sh`:

```sh
$ ./release.sh
```

This can be run from any system which has access to arti.dev.cray.com. It also
requires certain tools to exist on your system like `rsync`, `sed`, and
`realpath`. If those utilities do not exist, the script will fail. Install them
on your system.

This script will result in a release distribution directory and a gzipped tar
version of that directory being created in `dist/sat-${RELEASE_VERSION}`. For
example:

```sh
$ ls dist
sat-2.2.0  sat-2.2.0.tar.gz
```

## Installing

The `install.sh` script in this repository installs the release distribution on
a system. It syncs the Docker images and RPM repositories included in the
release distribution to Nexus.

For install instructions, see the [hpc-sat-docs git repository](https://github.hpe.com/hpe/hpc-sat-docs).
For HTML and PDF versions of that documentation see the appropriate directory of
the form `sat-x.y` in the [pubs-misc-stable-local Artifactory repository](https://arti.dev.cray.com/ui/native/pubs-misc-stable-local/release/).

## Manually testing a release on a system
Create the release distribution as described in "Packaging" above. Install the
release as described in "Installing" above.

## Branching the SAT product stream for a Shasta release

When branching this repository for a new release version `x.y` of the SAT
product stream, the following must be updated:

1. Pinned version of the "dst-shared" Jenkins shared library in `Jenkinsfile`.
2. Patch version in the `.version` file.
3. Values of `SAT_VERSION`, `SAT_PODMAN_VERSION`, and `SAT_CFS_DOCKER_VERSION`
   in `component_versions.sh`.
4. The value of `SAT_REPO_TYPE` in `release.sh` should be changed to `stable`.

See [this confluence page for more details](https://connect.us.cray.com/confluence/display/XCCS/SAT+Branching+Model#SATBranchingModel-Step3:Createandupdatereleasebranchofsat-product-stream).
