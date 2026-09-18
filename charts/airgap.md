# Air-gapped installs

A packaged chart carries its dependencies inside the archive, so installing one
needs neither the network nor a configured helm repository. That is what the
packaging pipeline produces: one `.tgz` per release-root chart, plus the
`index.yaml` that turns the directory into a helm repository.

Charts are only half of an air-gapped install; the container images they
reference are the other half, and this pipeline does not mirror them. See
[Images](#images).

## Getting the archives

- **Per commit**: the `Package charts` job of the `Publish Charts` workflow
  uploads them as the `packaged-charts` artifact (14 days). The chart version is
  the git-version snapshot of the branch, not the in-tree `0.1.0`, so archives
  from two builds never collide.
- **Per release**: the `Attach the packages to the release` job of the same
  workflow attaches them to the GitHub release, stamped with the tag.
- **From the registry**: `helm pull` returns the same archive, see [Installing
  from the registry](#installing-from-the-registry).
- **Locally**:

  ```sh
  ./test/vendor.sh              # once, with network: vendors every dependency
  ./charts/package-charts.sh    # writes dist/
  ```

  `package-charts.sh -v <semver>` stamps a version, `-o <dir>` picks another
  output directory. It packages the charts a user installs directly: `armonik`,
  `armonik-operators`, the three plane charts, `armonik-dependencies` and
  `activemq`. `armonik-common` is a library every consumer vendors, so it ships
  inside the others rather than on its own.

## Installing from an archive

Copy the files in and install by path. The umbrella archive is self-contained,
operators included, so the all-in-one shape is a single command:

```sh
helm install armonik ./armonik-<version>.tgz -n armonik --create-namespace
```

The layered shape, operators once per cluster and then the application, is two:

```sh
helm install armonik-operators ./armonik-operators-<version>.tgz -n operators --create-namespace
helm install armonik ./armonik-<version>.tgz -n armonik --create-namespace \
  --set global.armonik.operators.<op>.deploy=false \
  --set global.armonik.operators.<op>.namespace=operators
```

`charts/armonik/templates/NOTES.txt` renders the per-mode recipes, and
`uninstall.md` covers the teardown, which is not symmetric.

## Installing from the registry

The same archives are published as OCI artifacts on Docker Hub, so a cluster
with network access needs neither the release assets nor a served directory:

```sh
helm install armonik oci://registry-1.docker.io/dockerhubaneo/armonik \
  --version <version> -n armonik --create-namespace
helm show values oci://registry-1.docker.io/dockerhubaneo/armonik --version <version>
helm pull oci://registry-1.docker.io/dockerhubaneo/armonik --version <version>
```

One repository per chart, named after the chart: `armonik`,
`armonik-operators`, the three plane charts, `armonik-dependencies` and
`activemq`. Three things to know:

- `helm repo add` takes no OCI registry, so there is no `index.yaml` and no
  `helm search repo` here; the Docker Hub tag list is the catalogue.
- Always pass `--version`: without one helm resolves the highest semver tag, and
  these repositories also hold image tags.
- Branch and pull-request builds publish snapshots there too, pruned after two
  months, so only a released `X.Y.Z` is durable.

## Serving the directory as a repository

`helm repo add` has no `file://` handler, so a local directory cannot be added
as a repository directly. Serving it over plain HTTP works, and is what
`index.yaml` is for:

```sh
(cd dist && python3 -m http.server 8080) &
helm repo add armonik http://localhost:8080
helm install armonik armonik/armonik --version <version>
```

The index entries are bare file names, resolved against whatever base URL serves
them, so the directory can be moved or re-served anywhere.

## Images

Every workload still pulls its image from a registry. Take the inventory from
the render, with the values the target cluster will actually use:

```sh
helm template armonik ./armonik-<version>.tgz -f my-values.yaml \
  | grep -E '^ *image:' | tr -d '"' | awk '{print $2}' | sort -u
```

Mirror those into the internal registry, then point the charts at it. There is
no single knob: `global.imageRegistry` covers the ArmoniK and Bitnami images,
`global.image.registry` the KEDA ones, and each dependency chart keeps its own
`image.registry`, so check the inventory again after overriding.
