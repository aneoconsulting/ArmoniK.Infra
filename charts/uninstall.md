# Uninstalling

`helm uninstall` does not fully undo `helm install` for these charts. What it leaves behind depends
on **who installed the operators** and **whether the release is still there**.

Two upstream Helm behaviours, both by design, cause all of it:

- **Helm never removes CRDs from a chart's `crds/` directory**
  ([Helm docs](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/)).
- **Hook resources are not part of the release**, so `helm uninstall` does not remove them
  ([Helm docs](https://helm.sh/docs/topics/charts_hooks/#hook-resources-are-not-managed-with-corresponding-releases)).

## Why the operator layout changes the procedure

A custom resource is a `post-install,post-upgrade` hook **only when the same release installs its
operator** (`global.armonik.operators.<op>.deploy=true`): its CRD does not exist yet when the main
manifest is applied. Those CRs are then invisible to `helm uninstall`.

| Emitter | Resource | Hooked when |
|---------|----------|-------------|
| `armonik-compute-plane/templates/scaledobject.yaml` | `ScaledObject` (one per partition) | `keda.deploy` |
| `armonik/templates/secrets/conf-secrets.yaml` | `ExternalSecret` (one per conf layer) | `externalSecrets.deploy` |
| `armonik/templates/secrets/conf-mounts.yaml` | `ExternalSecret` (mount aggregates) | `externalSecrets.deploy` |
| `armonik/templates/secrets/mongodb-exporter-secret.yaml` | `ExternalSecret` (mongodb-exporter URI) | `externalSecrets.deploy` |
| `armonik/templates/secrets/secret-store.yaml` | `SecretStore` | `externalSecrets.deploy` |
| `armonik-ingress/templates/armonik-nginx-conf.yaml` | `ExternalSecret` (nginx conf, when rendered through ESO) | `externalSecrets.deploy` |
| `armonik-ingress/templates/secrets/secret-store.yaml` | `SecretStore` | `externalSecrets.deploy` |
| `armonik-ingress/templates/certificate.yaml`, `secrets/mtls-ca.yaml` | `Certificate` (server TLS, mTLS CA) | `certManager.deploy` |
| `armonik/templates/certificate/{redis,mongodb}-certificate.yaml` | `Certificate` | `certManager.deploy` |
| `activemq/templates/certificate.yaml` | `Certificate` | `certManager.deploy` |
| `armonik.certManager.issuerManifest` (`armonik-common/templates/_certmanager.tpl`) | every `Issuer` the charts create, shared or local | `certManager.deploy` |
| same helper, `provider: googleCas` | `GoogleCASIssuer` / `GoogleCASClusterIssuer` | `googleCasIssuer.deploy` |

`PodMonitor`, `ServiceMonitor` and `PerconaServerMongoDB` are never hooked: kube-prometheus-stack
and psmdb-operator ship their CRDs in an untemplated `crds/` directory, which Helm applies before
the templates. `helm uninstall` deletes them normally.

For the same reason `helm upgrade` never prunes hook resources: with release-managed operators, a
partition removed from `compute-plane.partitions` leaves its `ScaledObject` behind. That is why the
sweeps below select by label.

## Which case are you in

| | Release still installed | Release already uninstalled |
|---|---|---|
| **Operators installed beforehand** (`deploy=false`, `available=true`) | [Case A](#case-a): plain `helm uninstall` | [Case C](#case-c): nothing wedged, check leftovers |
| **Operators installed by this release** (`deploy=true`) | [Case B](#case-b): drain the CRs, then uninstall | [Case D](#case-d): recover the wedged CRDs by hand |

Variables used throughout:

```sh
RELEASE=armonik
NS=default
```

<a id="case-a"></a>
## Case A: operators pre-deployed, release still installed

No CR is hooked, so Helm deletes them all, and the operators (alive in their own release) clear the
finalizers:

```sh
helm uninstall "$RELEASE" -n "$NS"
```

The operator CRDs belong to the `armonik-operators` release and stay, as other ArmoniK releases may
still use them. Then check the [non-CRD leftovers](#non-crd-leftovers).

To remove the operators too, uninstall that release **last**, see
[Ordering across releases](#ordering-across-releases).

<a id="case-b"></a>
## Case B: operators managed by the same release, release still installed

A bare `helm uninstall` orphans every hooked CR, then deletes the templated CRDs, KEDA's and
External Secrets' among them. The apiserver cascade-deletes the orphans, which wedge: `ScaledObject` holds
`finalizer.keda.sh`, `ExternalSecret` holds
`externalsecrets.external-secrets.io/externalsecret-cleanup`, and their controllers died in the same
uninstall. The CRDs stay `Terminating` forever.

Delete the CRs first, **while the operators still run**:

```sh
for t in scaledobjects.keda.sh \
         externalsecrets.external-secrets.io secretstores.external-secrets.io \
         certificates.cert-manager.io issuers.cert-manager.io; do
  kubectl get "$t" -n "$NS" >/dev/null 2>&1 || continue   # skip types this cluster does not have
  kubectl delete "$t" -n "$NS" -l app.kubernetes.io/instance="$RELEASE" --ignore-not-found
done
```

`kubectl delete` waits for finalizers, so it returns once the operators are done. Deleting the
`ExternalSecret`s also deletes the Secrets they own (`target.creationPolicy: Owner`); deleting the
`Certificate`s deletes their TLS Secrets.

Then:

```sh
helm uninstall "$RELEASE" -n "$NS"
```

`helm upgrade --set global.armonik.operators.<op>.available=false` is **not** a drain step: the
umbrella guard (`armonik/templates/operators-guard.yaml`) rejects `deploy=true` with
`available=false`. Setting both to false in one upgrade deletes the CRs and the operator in the same
operation, unordered, and can wedge like a bare uninstall. Use `kubectl` first.

<a id="ordering-across-releases"></a>
### Ordering across releases

CRDs are cluster-scoped. Uninstalling the release that owns the KEDA or External Secrets CRDs
cascade-deletes **every** `ScaledObject` and `ExternalSecret` in the cluster, other ArmoniK
releases' included. Uninstall the application releases first, `armonik-operators` last.

<a id="case-c"></a>
## Case C: operators pre-deployed, release already uninstalled

Nothing is wedged: the CRs were release resources, deleted while their operators ran. Confirm, then
handle the [non-CRD leftovers](#non-crd-leftovers):

```sh
kubectl get scaledobjects.keda.sh,externalsecrets.external-secrets.io,certificates.cert-manager.io \
  -n "$NS" -l app.kubernetes.io/instance="$RELEASE" 2>/dev/null
```

<a id="case-d"></a>
## Case D: operators managed by the release, release already uninstalled

Recovery from the Case B wedge.

1. Find the CRDs stuck in `Terminating`:

```sh
kubectl get crd -o json \
  | jq -r '.items[] | select(.metadata.deletionTimestamp != null) | .metadata.name'
```

2. For each one, strip the finalizers of the CRs still under it (they stay readable and patchable
   while the CRD terminates):

```sh
CRD=scaledobjects.keda.sh   # repeat per stuck CRD
kubectl get "$CRD" -A -o json \
  | jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"' \
  | while read -r ns name; do
      kubectl patch "$CRD" "$name" -n "$ns" --type=merge -p '{"metadata":{"finalizers":null}}'
    done
```

The apiserver then finishes deleting the CRD, usually within seconds.

**Do not** remove the `customresourcecleanup.apiextensions.k8s.io` finalizer from the CRD itself:
it is the apiserver's own bookkeeping, and forcing it off leaves orphaned custom resource data in
etcd.

3. Optionally delete the CRDs that survive an uninstall by design
   (see [what always survives](#what-always-survives)):

```sh
kubectl get crd -o name | grep -E '\.(keda\.sh|eventing\.keda\.sh|external-secrets\.io|generators\.external-secrets\.io|cert-manager\.io|acme\.cert-manager\.io|psmdb\.percona\.com|monitoring\.coreos\.com)$'
# review that list, then:
# kubectl delete crd <names>
```

Deleting a CRD deletes every resource of that type cluster-wide. Review the list first, especially
`monitoring.coreos.com` (shared cluster monitoring) and `cert-manager.io` (other workloads'
certificates).

4. Finish with the [non-CRD leftovers](#non-crd-leftovers).

<a id="what-always-survives"></a>
## What always survives an uninstall

CRD delivery per operator chart, at the versions pinned in `armonik-operators/Chart.lock`:

| Operator chart | CRD delivery | Removed by `helm uninstall`? |
|----------------|--------------|------------------------------|
| keda 2.21.0 | `templates/crds/`, gated by `crds.install` | yes |
| external-secrets 2.11.0 | `templates/crds/`, gated by its own `installCRDs` (unrelated to cert-manager's deprecated key of the same name) | yes |
| cert-manager v1.21.2 | `templates/crd-*.yaml`, gated by `crds.enabled` | yes, because `armonik-operators` sets `cert-manager.crds.keep: false`. With the upstream default (`true`) they carry `helm.sh/resource-policy: keep` and survive |
| cert-manager-google-cas-issuer v0.13.0 (off by default) | `templates/crd-*.yaml`, gated by `crds.enabled` | yes, `armonik-operators` sets `google-cas-issuer.crds.keep: false` (upstream default `true`) |
| psmdb-operator 1.23.1 | `crds/crd.yaml`, untemplated | never |
| kube-prometheus-stack 91.5.1 | `charts/crds/crds/*`, untemplated, gated by the `crds.enabled` subchart condition | never |

`templates/crds/` is an ordinary templates subdirectory, not the special `crds/` directory, which is
why the templated rows behave like normal resources.

The cert-manager row deliberately departs from upstream so the install-once operators release
undoes itself. The cost: uninstalling it deletes every `Certificate` and `Issuer` in the cluster,
ArmoniK's or not. On a shared cluster, set `cert-manager.crds.keep=true` or leave cert-manager to
another release (`global.armonik.operators.certManager.deploy=false`). Do not use the deprecated
`installCRDs: true`, defined as `crds.enabled=true` plus `crds.keep=true`.

<a id="non-crd-leftovers"></a>
### Non-CRD leftovers

These outlive every uninstall path, and a reinstall silently reuses them.

**PersistentVolumeClaims.** Helm does not manage StatefulSet `volumeClaimTemplates` PVCs, and the
umbrella sets `dependencies.mongodb.finalizers: []` (no `percona.com/delete-psmdb-pvc`), so psmdb
keeps its volumes. A reinstall binds the old MongoDB data, which is why a submission can be accepted
for a partition the new release no longer has:

```sh
kubectl get pvc -n "$NS"
# kubectl delete pvc -n "$NS" -l app.kubernetes.io/instance=<mongodb-instance>
```

**Operator-generated Secrets**, which no release owns: `<cluster>-secrets`,
`internal-<cluster>-users`, `<cluster>-mongodb-encryption-key` (psmdb), `cert-manager-webhook-ca`,
`kedaorg-certs`, `prometheus-admission`. Keep or delete the psmdb ones together with the PVCs; one
without the other gives a database whose credentials no longer match:

```sh
kubectl get secret -n "$NS" -o json \
  | jq -r '.items[] | select((.metadata.labels["app.kubernetes.io/managed-by"] // "") != "Helm") | .metadata.name'
```

**Orphaned hook resources** (Cases B and D only): the Secrets owned by an orphaned `ExternalSecret`
or `Certificate`. Deleting the owning CR garbage-collects them.

## Clean slate for a test loop

Full teardown of one application release plus the operators, in wedge-free order. This destroys all
ArmoniK data in the namespace.

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

Step 3 is cluster-wide. On a shared cluster, restrict it to the CRDs you own.

## Making uninstall symmetric

Knobs that reduce manual cleanup for repeated install/uninstall. Paths are from the umbrella, where
`armonik-operators` is aliased `operators`; drop the `operators.` prefix when installing
`armonik-operators` directly.

| Knob | Effect |
|------|--------|
| `operators.cert-manager.crds.keep` | Already `false` in `armonik-operators/values.yaml`: the six `cert-manager.io` CRDs go with the release. Set `true` on a shared cluster, where deleting them takes other workloads' `Certificate`s along. |
| `operators.kube-prometheus.crds.enabled=false` | Stops shipping the `monitoring.coreos.com` CRDs. Only useful when something else provides them; it does not help teardown, since Helm never removes installed CRDs. |
| psmdb-operator | No knob: its `crds/crd.yaml` is always installed and never removed. |
| `dependencies.mongodb.finalizers: ["percona.com/delete-psmdb-pvc"]` | psmdb deletes the database PVCs with the `PerconaServerMongoDB` CR. Throwaway environments only. It needs the operator alive at deletion time, so a bare uninstall in Case B defeats it. |

Nothing makes hooked CRs go away with the release: a `helm.sh/hook-delete-policy` would delete them
right after they are applied. Pre-installing the operators (Case A) is the configuration with a
clean teardown.
