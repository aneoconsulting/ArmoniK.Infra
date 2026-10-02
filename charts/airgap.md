# Air-gapped installs

A packaged chart carries its dependencies expanded inside the archive, so it installs with no
network and no helm repository. Packaging produces one `.tgz` per release-root chart plus an
`index.yaml`.

Container images are out of scope: this pipeline does not mirror them. See [Images](#images).

## Getting the archives

- **Per commit**: the `packaged-charts` artifact of the `Package charts` job (`Publish Charts`
  workflow), kept 14 days. Its version is the branch's git-version snapshot, not the in-tree `0.1.0`,
  so two builds never collide.
- **Per release**: attached to the GitHub release by the `Attach the packages to the release` job,
  stamped with the tag.
- **From the registry**: `helm pull`, see [Installing from the registry](#installing-from-the-registry).
- **Locally**:

  ```sh
  ./test/vendor.sh              # once, with network: vendors every dependency
  ./charts/package-charts.sh    # writes dist/
  ```

  `-v <semver>` stamps a version, `-o <dir>` changes the output directory.

The packaged charts are `armonik`, `armonik-operators`, `armonik-control-plane`,
`armonik-compute-plane`, `armonik-ingress`, `armonik-dependencies` and `activemq`. The
`armonik-common` library ships inside each of them.

## Installing from an archive

All-in-one (the umbrella archive includes the operators):

```sh
helm install armonik ./armonik-<version>.tgz -n armonik --create-namespace
```

Layered, operators once per cluster, then the application:

```sh
helm install armonik-operators ./armonik-operators-<version>.tgz -n operators --create-namespace
helm install armonik ./armonik-<version>.tgz -n armonik --create-namespace \
  --set global.armonik.operators.<op>.deploy=false \
  --set global.armonik.operators.<op>.namespace=operators
```

`charts/armonik/templates/NOTES.txt` renders the per-mode recipes. Teardown is not symmetric, see
`uninstall.md`.

## Installing from the registry

The same archives are OCI artifacts on Docker Hub, one repository per chart, named after it:

```sh
helm install armonik oci://registry-1.docker.io/dockerhubaneo/armonik \
  --version <version> -n armonik --create-namespace
helm show values oci://registry-1.docker.io/dockerhubaneo/armonik --version <version>
helm pull oci://registry-1.docker.io/dockerhubaneo/armonik --version <version>
```

- `helm repo add` does not take an OCI registry: no `index.yaml`, no `helm search repo`. The Docker
  Hub tag list is the catalogue.
- Always pass `--version`. Without it helm picks the highest semver tag, and these repositories also
  hold image tags.
- Branch and pull-request snapshots are published there too and pruned after two months. Released
  `X.Y.Z` tags and the `-SNAPSHOT` tags built from `main` are kept.

## Serving the directory as a repository

`helm repo add` has no `file://` handler, so serve the directory over HTTP to use `index.yaml`:

```sh
(cd dist && python3 -m http.server 8080) &
helm repo add armonik http://localhost:8080
helm install armonik armonik/armonik --version <version>
```

Index entries are bare file names, resolved against the serving URL, so the directory can be moved
and served from anywhere.

## Images

Every workload still pulls from a registry. List the images from a render with your actual values:

```sh
helm template armonik ./armonik-<version>.tgz -f my-values.yaml \
  | grep -E '^ *image:' | tr -d '"' | awk '{print $2}' | sort -u
```

Mirror them, then point the charts at the mirror. There is no single knob: `global.imageRegistry`
covers the ArmoniK and Bitnami images, `global.image.registry` the KEDA ones, and each other
dependency keeps its own `image.registry`. Re-run the inventory after overriding.
