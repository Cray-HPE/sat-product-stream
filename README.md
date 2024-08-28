# SAT Product Stream
This repository defines the product stream for the System Admin Toolkit.

## Packaging
The `release.sh` script in this repository generates a release distribution
for the SAT product stream. This script downloads artifacts as follows:

* Docker images listed in `docker/index.yaml`.
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

This can be run from any system which has access to artifactory.algol60.net. It also
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

### Note

Starting in CSM 1.6.0, SAT is fully included in CSM. There is no longer a
separate SAT product stream to install.
SAT 2.6 releases, which accompanied CSM 1.5, are the last releases of SAT as a
separate product.
