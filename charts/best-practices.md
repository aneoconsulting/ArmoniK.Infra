# Best practices

Guidelines [Aneo](https://www.aneo.eu/) follows when writing the Helm charts of the
[ArmoniK platform](https://www.armonik.fr/). Most come from the [Helm docs](https://helm.sh/docs/);
others from [boxunix](https://boxunix.com/2022/02/05/developers-guide-to-writing-a-good-helm-chart/),
[Bitnami](https://docs.bitnami.com/tutorials/production-ready-charts/),
[Argonaut](https://www.argonaut.dev/blog/helm-best-practices),
[Codefresh](https://codefresh.io/docs/docs/ci-cd-guides/helm-best-practices/) and
[itnext](https://itnext.io/helm-3-umbrella-charts-standalone-chart-image-tags-an-alternative-approach-78a218d74e2d).

This document is a draft.

## Coding standard

### Conventions and constraints

From [Argonaut](https://www.argonaut.dev/blog/helm-best-practices) unless noted.

| Component | Convention / constraint |
|-----------|-------------------------|
| Chart names | Lowercase alphanumerics and dashes. No uppercase, underscores or dots. |
| Version numbers | SemVer 2, except image tags. In a label, replace `+` with `_` (labels reject `+`). |
| YAML indentation | Two spaces, no tabs. |
| Helm terminology | "Helm" is the project, "helm" the CLI. |
| Chart terminology | "chart" is not capitalized, except the case-sensitive `Chart.yaml`. |
| Variables | Start lowercase, camelCase. |
| YAML structure | Prefer flat values over nested ones. |
| Sharing templates | Every `define` is global: parent charts and subcharts share them. |
| Block vs. include | Use `include`, not `block`: several implementations of one block behave unpredictably. |
| Manifests | One resource per manifest file ([boxunix](https://boxunix.com/2022/02/05/developers-guide-to-writing-a-good-helm-chart/)). |
| Naming resources | Avoid stutter (`kind: Pod`, `name: armonik-pod`) ([boxunix](https://boxunix.com/2022/02/05/developers-guide-to-writing-a-good-helm-chart/)). |

Flat or nested values? Prefer flat: every nesting level needs an existence check in the templates.
Where nesting is kept, read it with `armonik.utils.index`
(`armonik-common/templates/_utils.tpl`), which tolerates a missing intermediate.

### Variables

```
{{- $relname := .Release.Name -}}
release: {{ $relname }}
```

### Using labels

Use the `app.kubernetes.io/*` labels, from one helper. The charts share `armonik.labels` and
`armonik.selectorLabels` (`armonik-common/templates/_helpers.tpl`):

```
metadata:
  labels:
    {{- include "armonik.labels" . | nindent 4 }}
```

### Documenting charts

- Comments
- README
- NOTES.txt

### Securing secrets

The helm-secrets plugin, backed by Mozilla SOPS (AWS KMS, Google Cloud KMS, Azure Key Vault, PGP).

### Reusable charts using template functions

- default
- required
- ...

### Resource policies to opt out of resource deletion

A `"helm.sh/resource-policy": keep` annotation (quotes required) keeps a resource on uninstall, so
important data survives it.

## Exposing arbitrary parameters

No chart enumerates every field its users need. Three mechanisms cover the gap:

> **`extra*` owns lists the chart builds. `*Patch` owns scalars and maps. Anything else is a
> post-renderer.**

### extra* (additive)

`extraEnv`, `extraEnvFrom`, `extraVolumes`, `extraVolumeMounts`, `extraContainers`,
`extraInitContainers`. Appended to the list the chart builds, never replacing it. Extras go last:
container 0 is what `kubectl logs` picks by default.

`extraEnv` exists because the name is universal, not because it is the preferred channel. A var
several workloads share belongs in a `conf` block (`conf.env` on a plane chart, `conf.<layer>.env`
on the umbrella), which reaches every workload consuming it; `extraEnv` is for a var local to one
container. Setting a name the conf already sets emits it twice: the API accepts that, but `name` is
the patchMergeKey, so later patches handle the pair badly.

### podSpecPatch and containerPatch (overriding)

A map merged over the rendered fragment, last and winning. The names mirror the API types: a
`PodSpec` and a `Container` (there is no `ContainerSpec`).

`podSpecPatch` targets `spec.template.spec`, never `spec.template`: pod labels must stay a superset
of the immutable `spec.selector.matchLabels`, so metadata stays owned by the chart's `labels` and
`annotations`.

Two limits follow from `armonik.utils.merge`:

- **A list replaces, it does not merge by key.** `armonik.utils.patch` lets a patch add a top-level
  list key the fragment does not build, but replacing one it does is a render error pointing to the
  `extra*` value. The check reads the fragment, not a hand-kept deny list, so a list is protected as
  soon as the chart builds it. `command` and `args` are exempt.
- **A patch cannot delete a key**: null and `""` count as absent.

### Post-renderer (everything else)

`helm --post-renderer` or ArgoCD's kustomize post-render give real strategic-merge semantics,
merge-by-key included. It does not compose with per-partition values, so it stays the last resort.

### Implementing a patch point

`armonik.utils.patch` parses what it patches, and printed text cannot be patched. The patchable
object therefore moves into a `define` of literal YAML, and the template keeps only the envelope
plus one bound variable per seam (`armonik-compute-plane/templates/_deployment.tpl`). Two
consequences:

- `toYaml` sorts keys, so rendered manifests are alphabetical rather than `name`-first. Cosmetic,
  and what `kubectl get -o yaml` shows anyway.
- A statement ending in `-}}` eats the newline before the next document. Where a `range` emits
  several, the last binding before the `---` keeps a plain `}}` or the documents merge.

## Umbrella charts

### Subcharts

Each subchart must work standalone: it cannot depend on its parent, which can only override its
values. `charts/armonik` is the umbrella, its subcharts aliased `operators`, `control-plane`,
`compute-plane`, `ingress` and `dependencies`.

### Using global values

`.Values.global` reaches every subchart. The ArmoniK cross-chart defaults live under
`global.armonik`, defined once in `armonik-common/values.yaml` and lifted by every chart that
depends on `armonik-common` with `import-values` (`child: global.armonik`, `parent: global.armonik`), so a subchart
installed alone still has them.

## Library charts

## Versioning

From [Codefresh](https://codefresh.io/docs/docs/ci-cd-guides/helm-best-practices/). A chart has two
unrelated versions in `Chart.yaml`: `version` (the chart) and `appVersion` (the application). Sync
them or not, but pick one strategy.
<!-- TODO: Define a strategy for version -->
1. Simple 1-1 versioning: the chart version follows the application (`appVersion` unused).
2. Chart versus application versioning: version each independently.
    - suits charts that change all the time
    - needs a chart versioning strategy
3. Umbrella charts: either of the above
    - the chart and the subcharts share one version
    - when is the parent chart version bumped?
        - only when a child chart changes?
        - only when an application changes?
        - both?

From [itnext](https://itnext.io/helm-3-umbrella-charts-standalone-chart-image-tags-an-alternative-approach-78a218d74e2d):
when the subcharts are rarely deployed standalone, maintain the image tags in the umbrella chart,
through `global`.

## Helm promotion strategies

Promotion between environments (testing, staging, production).

### Single repository with multiple environments

One chart, deployed to every target with a different set of values.

### Chart promotion between environments

The recommended deployment workflow.

## Chart repository

- [ArtifactHub](https://artifacthub.io/packages/search?kind=0)
- our own repository:

A chart repository is any HTTP server serving an `index.yaml` and, optionally, packaged charts
([Helm docs](https://helm.sh/docs/topics/chart_repository/)); GitHub Pages works.

```
charts/
  |- index.yaml
  |- alpine-0.1.2.tgz
  |- alpine-0.1.2.tgz.prov
```

## Abbreviation

Use abbreviations in manifest names:

| Abbreviation | Full name               |
| ------------ | ----------------------- |
| svc          | service                 |
| deploy       | deployment              |
| cm           | configmap               |
| secret       | secret                  |
| ds           | daemonset               |
| rc           | replicationcontroller   |
| petset       | petset                  |
| po           | pod                     |
| hpa          | horizontalpodautoscaler |
| ing          | ingress                 |
| job          | job                     |
| limit        | limitrange              |
| ns           | namespace               |
| pv           | persistentvolume        |
| pvc          | persistentvolumeclaim   |
| sa           | serviceaccount          |

## Security

From [Bitnami](https://docs.bitnami.com/tutorials/production-ready-charts/).

### Use non-root containers

```
spec:
  {{- if .Values.securityContext.enabled }}
  securityContext:
    fsGroup: {{ .Values.securityContext.fsGroup }}
    runAsUser: {{ .Values.securityContext.runAsUser }}
  {{- end }}
```

In values (see the
[Kubernetes security context docs](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)):

```
securityContext:
  enabled: true
  fsGroup: 1001
  runAsUser: 1001
```

### Do not persist the configuration

### Integrate charts with logging and monitoring tools

## Tests

## Questions

In Terraform (`control-plane.tf`), the service selects on the deployment's labels (`app`,
`service`). Does that mean the service is created after the deployment? Would a value shared by the
deployment and the service (for `app` and `service`) make more sense?

## TODO

- Use control-plane.labels of _helpers.tpl
    - add extraLabels
