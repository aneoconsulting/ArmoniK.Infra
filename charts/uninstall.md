# Uninstalling

`helm uninstall` does not fully undo `helm install` for these charts, and what it leaves behind
depends on **who installed the operators** and on **whether the release is still there**. This
document gives the procedure for each case.

Two upstream Helm behaviours cause all of it, and both are by design:

- **Helm never removes CRDs that ship in a chart's `crds/` directory.** "There is no support at this
  time for upgrading or deleting CRDs using Helm"
  ([Helm docs](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/)).
- **Resources created by a Helm hook are not part of the release.** "if you create resources in a
  hook, you cannot rely upon `helm uninstall` to remove the resources"
  ([Helm docs](https://helm.sh/docs/topics/charts_hooks/#hook-resources-are-not-managed-with-corresponding-releases)).

## Why the operator layout changes the procedure

The ArmoniK charts annotate a custom resource as a `post-install,post-upgrade` hook **only when the
same release installs that resource's operator** (`global.armonik.operators.<op>.deploy=true`). The
hook exists because the CRD does not yet exist when the main manifest is applied, so the CR has to be
applied in a later pass. The consequence at teardown time is that those CRs are invisible to
`helm uninstall`.

| Emitter | Resource | Hook applied when |
|---------|----------|-------------------|
| `armonik-compute-plane/templates/scaledobject.yaml:15` | `ScaledObject` (one per partition) | `keda.deploy` |
| `armonik/templates/secrets/conf-secrets.yaml:31` | `ExternalSecret` (one per conf layer) | `externalSecrets.deploy` |
| `armonik/templates/secrets/conf-mounts.yaml:44` | `ExternalSecret` (mount aggregation) | `externalSecrets.deploy` |
| `armonik/templates/secrets/secret-store.yaml:49` | `SecretStore` | `externalSecrets.deploy` |
| `armonik-ingress/templates/certificate.yaml:13,30` | `Issuer` + `Certificate` | `certManager.deploy` |
| `activemq/templates/certificate.yaml:22` | `Certificate` (the `Issuer` above it is **not** hooked) | `certManager.deploy` |

`PodMonitor`, `ServiceMonitor` and `PerconaServerMongoDB` are never hooked: kube-prometheus-stack and
psmdb-operator ship their CRDs in an untemplated `crds/` directory, which Helm applies ahead of the
templates, so no extra ordering pass is needed. They are ordinary release resources and
`helm uninstall` deletes them normally.

Second-order effect of the same mechanism: because hook resources are not in the release manifest,
`helm upgrade` never prunes them either. A partition removed from `compute-plane.partitions` leaves
its `ScaledObject` behind while the operators are release-managed. That is why the sweeps below select
by label instead of trusting Helm to know what it owns.

## Which case are you in

| | Release still installed | Release already uninstalled |
|---|---|---|
| **Operators installed beforehand** (`deploy=false`, `available=true`) | [Case A](#case-a) : plain `helm uninstall`, nothing else | [Case C](#case-c) : nothing wedged, only check leftovers |
| **Operators installed by this release** (`deploy=true`) | [Case B](#case-b) : drain the CRs first, then uninstall | [Case D](#case-d) : recover the wedged CRDs by hand |

Set the variables used throughout:

```sh
RELEASE=armonik
NS=default
```

<a id="case-a"></a>
## Case A: operators pre-deployed, release still installed

Nothing special. With `deploy=false` no CR carries a hook annotation, so every `ScaledObject`,
`ExternalSecret`, `SecretStore`, `Certificate` and `Issuer` is a normal release resource. Helm deletes
them, and the operators (alive in their own release) clear their finalizers as they go:

```sh
helm uninstall "$RELEASE" -n "$NS"
```

The operator CRDs belong to the `armonik-operators` release and are untouched, which is exactly what
you want when other ArmoniK releases still run in the cluster. Then check the
[non-CRD leftovers](#non-crd-leftovers), which no case avoids.

If you also want the operators gone, uninstall that release **last**, after every application release
(see [Case B on ordering](#ordering-across-releases)).

<a id="case-b"></a>
## Case B: operators managed by the same release, release still installed

`helm uninstall` alone leaves every hooked CR from the table above orphaned in the namespace, then
deletes the KEDA and External Secrets CRDs (those two charts render CRDs as templates). The apiserver
cascade-deletes the orphans, and they wedge: `ScaledObject` holds `finalizer.keda.sh` and
`ExternalSecret` holds `externalsecrets.external-secrets.io/externalsecret-cleanup`, and the
controllers that would clear them died in the same uninstall. The CRDs then sit in `Terminating`
forever. Avoid this by deleting the CRs **while the operators are still running**:

```sh
for t in scaledobjects.keda.sh \
         externalsecrets.external-secrets.io secretstores.external-secrets.io \
         certificates.cert-manager.io issuers.cert-manager.io; do
  kubectl get "$t" -n "$NS" >/dev/null 2>&1 || continue   # skip types this cluster does not have
  kubectl delete "$t" -n "$NS" -l app.kubernetes.io/instance="$RELEASE" --ignore-not-found
done
```

`kubectl delete` waits for finalizers by default, so it returns only once the operators have actually
finished. Deleting the `ExternalSecret`s also removes the conf Secrets they own
(`target.creationPolicy: Owner`, `armonik/templates/secrets/conf-secrets.yaml:45`), and deleting the
`Certificate`s removes the TLS Secrets they own.

Then uninstall:

```sh
helm uninstall "$RELEASE" -n "$NS"
```

Note that `helm upgrade --set global.armonik.operators.<op>.available=false` is **not** a valid drain
step: the umbrella guard rejects `deploy=true` with `available=false`
(`armonik/templates/operators-guard.yaml:9`). Setting both flags to false in one upgrade puts the CR
deletions and the operator deletion in the same operation with no ordering guarantee between them, so
it can wedge exactly like a bare uninstall. Delete the CRs with `kubectl` first.

<a id="ordering-across-releases"></a>
### Ordering across releases

CRDs are cluster-scoped and shared. Uninstalling a release that owns the KEDA or External Secrets
CRDs cascade-deletes **every** `ScaledObject` and `ExternalSecret` in the cluster, including those of
other ArmoniK releases. So: application releases first, `armonik-operators` last.

<a id="case-c"></a>
## Case C: operators pre-deployed, release already uninstalled

Nothing is wedged. The CRs were release-managed and were deleted while their operators were alive.
Confirm, then handle the [non-CRD leftovers](#non-crd-leftovers):

```sh
kubectl get scaledobjects.keda.sh,externalsecrets.external-secrets.io,certificates.cert-manager.io \
  -n "$NS" -l app.kubernetes.io/instance="$RELEASE" 2>/dev/null
```

<a id="case-d"></a>
## Case D: operators managed by the release, release already uninstalled

Recovery from the wedge described in Case B.

1. Find the CRDs stuck in `Terminating`:

```sh
kubectl get crd -o json \
  | jq -r '.items[] | select(.metadata.deletionTimestamp != null) | .metadata.name'
```

2. For each one, the blocker is the CRs that still exist under it. They are still readable and
   patchable while the CRD terminates. Strip their finalizers:

```sh
CRD=scaledobjects.keda.sh   # repeat per stuck CRD
kubectl get "$CRD" -A -o json \
  | jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"' \
  | while read -r ns name; do
      kubectl patch "$CRD" "$name" -n "$ns" --type=merge -p '{"metadata":{"finalizers":null}}'
    done
```

The apiserver's CRD cleanup controller then finishes the deletion and the CRD disappears on its own,
usually within a second or two. Nothing else is needed.

**Do not** remove the `customresourcecleanup.apiextensions.k8s.io` finalizer from the CRD itself. It
is the apiserver's own bookkeeping; forcing it off drops the CRD while leaving orphaned custom
resource data in etcd.

3. Delete the CRDs that survived the uninstall on purpose, if you want them gone
   (see [what always survives](#what-always-survives)):

```sh
kubectl get crd -o name | grep -E '\.(keda\.sh|eventing\.keda\.sh|external-secrets\.io|generators\.external-secrets\.io|cert-manager\.io|acme\.cert-manager\.io|psmdb\.percona\.com|monitoring\.coreos\.com)$'
# review that list, then:
# kubectl delete crd <names>
```

Deleting a CRD deletes every custom resource of that type cluster-wide. Check the list before
running the delete, especially for `monitoring.coreos.com` (shared cluster monitoring) and
`cert-manager.io` (certificates of unrelated workloads).

4. Finish with the [non-CRD leftovers](#non-crd-leftovers).

<a id="what-always-survives"></a>
## What always survives an uninstall

Per-operator CRD delivery, at the versions pinned in `armonik-operators/Chart.lock`:

| Operator chart | CRD delivery | Removed by `helm uninstall`? |
|----------------|--------------|------------------------------|
| keda 2.20.1 | `templates/crds/`, gated by `crds.install` | yes |
| external-secrets 2.8.0 | `templates/crds/`, gated by that chart's own `installCRDs` (unrelated to cert-manager's deprecated key of the same name) | yes |
| cert-manager v1.21.x | `templates/crd-*.yaml`, gated by `crds.enabled` | yes, because `armonik-operators` sets `cert-manager.crds.keep: false`. With the upstream default (`crds.keep: true`) they are annotated `helm.sh/resource-policy: keep` and survive |
| psmdb-operator 1.23.0 | `crds/crd.yaml`, untemplated | never |
| kube-prometheus-stack 82.18.0 | `charts/crds/crds/*`, untemplated, gated by the `crds.enabled` subchart condition | never |

`templates/crds/` is an ordinary templates subdirectory, not the special untemplated `crds/`
directory, which is why the first three rows behave like normal resources.

The cert-manager row is a deliberate deviation from that chart's default: an install-once operators
release should undo itself. The cost is that uninstalling it deletes every `Certificate` and `Issuer`
in the cluster, ArmoniK's or not, so on a shared cluster set `cert-manager.crds.keep=true` or leave
cert-manager to another release (`global.armonik.operators.certManager.deploy=false`). Do not use the
deprecated `installCRDs: true`, which is defined as `crds.enabled=true` plus `crds.keep=true`.

<a id="non-crd-leftovers"></a>
### Non-CRD leftovers

These outlive every uninstall path, and reusing them silently changes behaviour on the next install.

**PersistentVolumeClaims.** Helm does not manage StatefulSet `volumeClaimTemplates` PVCs, and the
umbrella sets `mongodb.finalizers: []` (`armonik/values.yaml:252`), so psmdb keeps its volumes (no
`percona.com/delete-psmdb-pvc`). A reinstall binds the old MongoDB data, which is why a submission can
be accepted for a partition that no longer exists in the new release (the partition rows are still in
the database):

```sh
kubectl get pvc -n "$NS"
# kubectl delete pvc -n "$NS" -l app.kubernetes.io/instance=<mongodb-instance>
```

**Operator-generated Secrets.** Created by the operators rather than by Helm, so no release owns them:
`<cluster>-secrets`, `internal-<cluster>-users`, `<cluster>-mongodb-encryption-key` (psmdb),
`cert-manager-webhook-ca`, `kedaorg-certs`, `prometheus-admission`. Keeping the psmdb ones together
with the PVC is consistent; keeping one without the other gives a database whose credentials no longer
match:

```sh
kubectl get secret -n "$NS" -o json \
  | jq -r '.items[] | select((.metadata.labels["app.kubernetes.io/managed-by"] // "") != "Helm") | .metadata.name'
```

**Orphaned hook resources**, in Case B and D only: the conf Secrets owned by an orphaned
`ExternalSecret`, and the TLS Secrets owned by an orphaned `Certificate`. Deleting the owning CR
garbage-collects them.

## Clean slate for a test loop

Full teardown of one application release plus the operators, in the order that avoids every wedge.
This destroys all ArmoniK data in the namespace.

```sh
RELEASE=armonik OPERATORS=armonik-operators NS=default

# 1. drain the operator-dependent CRs while the operators still run (no-op if not hooked)
for t in scaledobjects.keda.sh \
         externalsecrets.external-secrets.io secretstores.external-secrets.io \
         certificates.cert-manager.io issuers.cert-manager.io; do
  kubectl get "$t" -n "$NS" >/dev/null 2>&1 || continue
  kubectl delete "$t" -n "$NS" -l app.kubernetes.io/instance="$RELEASE" --ignore-not-found
done

# 2. application release, then the operators release
helm uninstall "$RELEASE" -n "$NS"
helm uninstall "$OPERATORS" -n "$NS" 2>/dev/null || true

# 3. CRDs that Helm keeps or never touches
kubectl get crd -o name \
  | grep -E '\.(keda\.sh|eventing\.keda\.sh|external-secrets\.io|generators\.external-secrets\.io|cert-manager\.io|acme\.cert-manager\.io|psmdb\.percona\.com|monitoring\.coreos\.com)$' \
  | xargs -r kubectl delete --ignore-not-found

# 4. state that no release owns (psmdb Secrets are named after the cluster, "<release>-mongodb")
kubectl delete pvc -n "$NS" --all
kubectl delete secret -n "$NS" \
  "$RELEASE-mongodb-secrets" "internal-$RELEASE-mongodb-users" \
  "$RELEASE-mongodb-mongodb-encryption-key" \
  cert-manager-webhook-ca kedaorg-certs prometheus-admission --ignore-not-found
```

Step 3 is cluster-wide. On a shared cluster, restrict it to the CRDs you actually own.

## Making uninstall symmetric

If you install and uninstall repeatedly, these knobs reduce the manual cleanup. Paths are given as
seen from the umbrella, where `armonik-operators` is aliased `operators`; drop the `operators.` prefix
when installing `armonik-operators` directly.

| Knob | Effect |
|------|--------|
| `operators.cert-manager.crds.keep` | Already `false` in `armonik-operators/values.yaml`, so the six `cert-manager.io` CRDs go with the release and need no manual cleanup. Set it back to `true` on a shared cluster, where deleting them would take unrelated workloads' `Certificate`s with them. |
| `operators.kube-prometheus.crds.enabled=false` | kube-prometheus-stack stops shipping the `monitoring.coreos.com` CRDs. Only useful when something else in the cluster already provides them, and it does not help teardown: CRDs already installed are still never removed by Helm. |
| psmdb-operator | No knob. Its single `crds/crd.yaml` is always installed and never removed. |
| `mongodb.finalizers: ["percona.com/delete-psmdb-pvc"]` (`armonik/values.yaml:252`) | psmdb deletes the database PVCs when the `PerconaServerMongoDB` CR goes away. Only for throwaway environments, and it needs the operator alive at deletion time, so it does not survive a bare uninstall in Case B. |

Nothing makes hooked CRs disappear with the release: a `helm.sh/hook-delete-policy` would delete them
right after they are applied, which is not what a long-lived resource wants. Pre-installing the
operators (Case A) is the configuration with a clean teardown.
