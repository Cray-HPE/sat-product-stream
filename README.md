# SAT Product Stream
This repository defines the product stream for the System Admin Toolkit.

## Packaging
The `release.sh` script in this repository generates a release distribution
for the SAT product stream. This script will download the Docker images defined
in `docker/index.yaml` (currently just cray/cray-sat) and the RPM repositories
defined in our bloblet at dst.us.cray.com. It will package these along with the
install script, `install.sh`, and other install libraries and dependencies, into
a release distribution as a gzipped tar file.

The following environment variables can be used to control packaging of the
release distribution:

| Variable          | Description                                 | Default Value                                             |
| ----------------- | ------------------------------------------- | --------------------------------------------------------- |
| `BLOBLET_URL`     | Bloblet URL from which to download SAT rpms | `http://dst.us.cray.com/dstrepo/bloblets/sat/dev/master/` |
| `RELEASE_VERSION` | The release version of the SAT distribution | `1.0.0`                                                   |

The default `BLOBLET_URL` will pull RPM artifacts built from the master branch.
This will need to be updated for each Shasta release branch. For example, to
pull from the v1.4 release bloblet, set the `BLOBLET_URL` to:
`http://dst.us.cray.com/dstrepo/bloblets/sat/release/1.4/`

To create a release distribution, run `release.sh`:

```sh
$ ./release.sh
```

This can be run from any system which has access to the `BLOBLET_URL` and to
dtr.dev.cray.com. It also requires certain tools to exist on your system like
`rsync`, `sed`, and `realpath`. If those utilities do not exist, the script
will fail. Install them on your system.

This script will result in a release distribution directory and a gzipped tar
version of that directory being created in `dist/sat-${RELEASE_VERSION}`. For
example:

```sh
$ ls dist
sat-1.0.0  sat-1.0.0.tar.gz
```

## Installing

The `install.sh` script in this repository installs the release distribution on
a system. It syncs the Docker images and RPM repositories included in the
release distribution to Nexus.

These are the steps to install the System Admin Toolkit (SAT) product stream
from the release distribution gzipped tar file.

1. Copy the release distribution gzipped tar file, e.g. `sat-1.0.0.tar.gz`, to
   the node running the Pre-install Toolkit (PIT) OS on the Shasta system.
2. Unzip and extract the release distribution. For example:
```sh
ncn-m001-pit# tar -xvzf sat-1.0.0.tar.gz
```
3. Change directory to the extracted release distribution directory. For
   example:
```sh
ncn-m001-pit# cd sat-1.0.0
```
4. Run the installer, `install.sh`:
```sh
ncn-m001-pit# ./install.sh
```

## Manually testing a release on a system
Create the release distribution as described in "Packaging" above. Install the
release as described in "Installing" above.

## Branching the SAT product stream for a Shasta release

When branching this repository for a new Shasta release `X.Y`, the following
must be done:

1. The `sat.bloblet` file needs to be updated to pull from the
   `release/shasta-X.Y` location.
2. The `BLOBLET_URL` default value must be updated to the location of the
   release branch bloblet, i.e. replace `/dev/master` with `/release/X.Y`.
