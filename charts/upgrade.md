# Upgrading

Helm installs the CRDs of a chart's `crds/` directory on the first install only and never upgrades
them ([Helm docs](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/)). An
operator bump whose CRDs change therefore needs them applied before `helm upgrade`, on the release
that installs that operator: `armonik-operators` in a layered install, the umbrella in an all-in-one
install (`global.armonik.operators.<op>.deploy=true`). A release consuming an operator installed
elsewhere has nothing to do.

One section per such bump, newest first. Skipping chart versions means applying the steps of every
section in between; the CRDs of the target version are enough, being cumulative.

## kube-prometheus-stack 92.x to 93.x

Upstream notes: [From 92.x to 93.x](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/UPGRADE.md#from-92x-to-93x).

- prometheus-operator moves to v0.95, with new versions of its ten `monitoring.coreos.com` CRDs.
- The operator's ClusterRole gains `alertmanagerconfigs/status` and loses `delete` on core `pods`.

Either way below applies the CRDs before the new operator starts.

### Apply the CRDs the chart ships (recommended)

The packaged charts carry their dependencies, so the CRDs of the version you upgrade to sit in the
archive itself, with no network access to GitHub. From the registry (see [`airgap.md`](airgap.md)
for a local archive):

```sh
helm pull oci://registry-1.docker.io/dockerhubaneo/armonik-operators --version "$VERSION" --untar -d crds-upgrade
kubectl apply --server-side -f crds-upgrade/armonik-operators/charts/kube-prometheus-stack/charts/crds/crds/
helm upgrade armonik-operators oci://registry-1.docker.io/dockerhubaneo/armonik-operators --version "$VERSION" -n operators
```

For an all-in-one install, pull `armonik` instead; the CRDs then sit under
`crds-upgrade/armonik/charts/armonik-operators/charts/kube-prometheus-stack/charts/crds/crds/`.

If `kubectl` reports conflicts with the `helm` field manager, which created the CRDs, add
`--force-conflicts`: the chart's own upgrade job (below) does the same.

Upstream also lists one `kubectl apply --server-side` command per CRD, against the
prometheus-operator repository; they target v0.95.1, while the chart pinned here ships v0.95.2.

### Let the chart apply them

kube-prometheus-stack can apply its CRDs from a `pre-install,pre-upgrade,pre-rollback` hook Job,
off by default and marked preview upstream:

```sh
# armonik-operators release
--set kube-prometheus.crds.upgradeJob.enabled=true
# all-in-one umbrella release
--set operators.kube-prometheus.crds.upgradeJob.enabled=true
```

The Job pulls two more images, `registry.k8s.io/kubectl` and `docker.io/busybox:latest` (an
air-gapped mirror needs them), and creates a ClusterRole, ClusterRoleBinding and ServiceAccount
of its own. Keep it on and every later upgrade applies the CRDs too.
