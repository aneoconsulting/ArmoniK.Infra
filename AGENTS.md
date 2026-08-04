# AGENTS.md

This file provides guidance to coding agents working in this repository.

## What this repository is

ArmoniK.Infra deploys [ArmoniK](https://github.com/aneoconsulting/ArmoniK), a distributed compute orchestrator: one control plane, per-partition compute planes (polling agent + worker per pod), storage backends (MongoDB, a queue, an object cache), and monitoring. Two deployment stacks coexist:

- `charts/` : the Helm charts. **This is the target of the ongoing revamp; all new work happens here.**
- `armonik/`, `storage/`, `monitoring/`, `kubernetes/`, `networking/`, `security/`, `container-registry/`, `service-account/`, `utils/` : the legacy Terraform modules. Do not extend them. They are the feature-parity reference for the charts, chiefly the `armonik/` module and `monitoring/onpremise/{fluent-bit,keda,prometheus}`.

## Commands

The vendored dependency archives are NOT committed (`.gitignore` excludes `**.tgz`); the `Chart.lock` files are. So on a fresh clone nothing renders until you vendor them (network required):

```sh
cd charts && ./update-charts.sh   # every chart, in dependency order, one layer at a time, in parallel
                                  #      helm dependency build  --skip-refresh   (reproduce Chart.lock)
                                  # -r   helm dependency build                   (refresh)
                                  # -u   helm dependency update --skip-refresh   (re-resolve, rewrite Chart.lock)
                                  # -ur  helm dependency update                  (refresh)
```

Any run that refreshes rewrites every repository index in the shared cache, whatever the chart depends on, and concurrent rewrites corrupt it. So `-r` serializes the charts that pull a dependency from an http(s) repository and runs the rest in parallel with `--skip-refresh`. Until those repositories are added locally (`helm repo add`), `-u -r` is the only mode that resolves them: helm fetches a repository it does not know only through `dependency update` while refreshing.

Day-to-day, from `charts/`:

```sh
helm lint <chart-dir>                     # e.g. helm lint armonik-compute-plane
helm template <chart-dir> >/dev/null      # render with defaults; do this for EVERY chart you touch
helm template armonik                     # render the full umbrella
helm template armonik-compute-plane --set podDisruptionBudget.enabled=true   # exercise non-default paths too
```

From the repo root:

```sh
ct lint --config ct.yaml --all   # chart-testing; ct expects PARENT dirs (ct.yaml sets `charts`, never pass `charts/armonik`)
pre-commit run -a
bash .docs/generate-helm-docs.sh # helm-docs; the readthedocs pipeline runs this, see the note below
```

The chart test suite is template-only (no cluster; see `test/README.md`, and `.github/workflows/test-helm.yml` which runs it on every PR):

```sh
./test/vendor.sh        # repo add + vendor deps from Chart.lock; fails on Chart.yaml/lock drift (freshness check)
./test/unittest.sh      # helm-unittest suites: charts/<chart>/tests/*_test.yaml + test/harness/common-harness
./test/matrix.sh        # helm template matrix + unrendered-'{{' check + kubeconform (KUBECONFORM=0 skips schemas)
```

Valid render fixtures go in `charts/<name>/ci/*-values.yaml` (ct lint runs the chart once per fixture, instead of bare defaults); expected-failure and kube-version-variant fixtures go in `test/fixtures/<chart>/`. `armonik-common` is a library chart and cannot be unit-tested directly, so its contract is pinned by the never-deployed consumer chart `test/harness/common-harness`, which lives outside `charts/` so ct and helm-docs ignore it. Known-broken render paths keep disabled tests (`skip` with a reason naming the bug) that get enabled when the bug is fixed. When you fix or add a conditional path, extend the matching suite or fixture rather than probing by hand.

No reference outputs or snapshots are committed anywhere, deliberately: assertions target specific keys so the suite needs no re-recording on unrelated changes. Do not introduce helm-unittest snapshots. Every render is instead screened for unrendered `{{`, which usually means a `tpl` value that never got evaluated. `test/check-unrendered.awk` decides per document rather than exempting whole renders: third-party subchart documents are skipped by provenance, `ExternalSecret` documents may carry ESO's own `{{ .KEY }}` target-template references, and ArmoniK-owned dashboard ConfigMaps may carry Grafana's `{{label}}` legend syntax. Keep it that way; a blanket opt-out is how a real leak hides. `matrix.sh` must also keep helm's stderr out of the manifest stream, warnings otherwise corrupting the kubeconform parse.

helm-unittest (1.1.2) traps worth knowing: a render error is attributed to the FIRST template that raises it, so a guard can surface on an unrelated file; a per-test `template:` must also appear in the suite-level `templates:` list or `failedTemplate` reports "rendered manifest is empty"; `containsDocument` needs `any: true` to mean "some document matches"; umbrella suites address vendored subchart templates by ALIAS (`charts/control-plane/templates/...`).

## Chart architecture

```
charts/armonik (umbrella)
 |- armonik-common          (library: helpers, merge engine, conf schema and emitters, operator/monitoring resolvers)
 |- armonik-operators       (alias operators: install-once cluster operators, see below)
 |- armonik-control-plane   (alias control-plane: deployment + service, metrics-exporter, init Job, auth builtin roles)
 |- armonik-compute-plane   (alias compute-plane: one deployment + KEDA ScaledObject per partition, init Job, PDB)
 |- armonik-ingress         (alias ingress: nginx gRPC/HTTP entry, admin GUI, grafana/seq routes, certificates)
 |- armonik-dependencies    (alias dependencies: activemq [custom local chart], valkey, psmdb-db,
                             rabbitmq, grafana, fluent-bit, seq)
```

Target release layout: **operators release -> ArmoniK application release(s)**. Operators and their CRDs are installed once per cluster, never per application release. `charts/armonik` defaults to the all-in-one shape (it installs the operators itself through the `armonik-operators` subchart) so a plain `helm install` works; a layered install sets `global.armonik.operators.<op>.deploy=false` and states each operator's namespace.

`charts/eniconfig` and `charts/keda-hpa` are legacy standalone charts, not part of the umbrella.

### Configuration: the conf layers

Config crosses charts as **per-layer Secrets rendered by the umbrella**, consumed by name by the plane charts. There are eight layers: `core`, `log`, `control`, `compute`, `worker`, `polling`, `metrics`, `init`. Each gets two Secrets, both always rendered so pods can reference them with `optional: false`:

- `<source>-conf-<layer>` : environment (`charts/armonik/templates/secrets/conf-secrets.yaml`)
- `<source>-conf-<layer>-mount` : mounted files, TLS material (`charts/armonik/templates/secrets/conf-mounts.yaml`)

There is no materialized twin and no configuration subchart: both files range the layers and emit inline.

**Layer builders.** `armonik.conf.<layer>`, one file each in `charts/armonik/templates/conf/_<layer>.tpl`, plus an `armonik.conf.<layer>Helper` extension hook merged into every builder. `core` = the four storage fragments + `coreHelper` + `conf.core`; `log` = the validated Serilog env + `conf.log`; the six component layers = their helper + `conf.<layer>`, own content only. Layers deliberately do NOT compose one another: cross-layer composition is the pods' `conf.envSecret` / `conf.mountSecret` lists.

**Storage fragments.** `charts/armonik/templates/storage/_{mongodb,redis,activemq,rabbitmq}.tpl` define `armonik.<backend>.conf`. Each navigates the live subchart scope with a nameless `with`: `{{- with .Subcharts.dependencies.Subcharts.<alias> -}}`, then plain dot access. Consequences to respect:

- `.Subcharts` holds only ENABLED subcharts, so a disabled backend is a missing key, dot access returns nil, and `with` skips the fragment. That is the bring-your-own-backend path: set `dependencies.<backend>.enabled=false` and supply the connection through `conf.core.env` / `conf.core.envFromSecret`.
- Pass the LIVE subchart object, never a `toYaml | fromYaml` round trip: that lowercases `chart.Metadata`'s keys and breaks `.Chart.Name`.
- A hyphenated alias (`fluent-bit`, `cert-manager`, `kube-prometheus`) needs `index`, Go parsing `a-b` as subtraction. The storage four are all unhyphenated.
- Only the root chart sees `.Subcharts` and every dependency's fully-coalesced, override-aware values. That is why ALL cross-chart derivation lives in the umbrella and is recomputed every render. `import-values` must never carry a dependency's values upward: it copies chart-file defaults only and silently drops every `-f`/`--set` override, which would deploy a customized backend whose connection env ArmoniK never receives.

**Kind auto-detection** (`conf-secrets.yaml`): a layer whose built conf carries secret references (`envFromSecret` or `envSecret`) renders as an External Secrets Operator `ExternalSecret`, otherwise as a plain `Secret`. Mapping: `env` -> literal data (`stringData`, or `target.template.data` under ESO); `envFromSecret` -> `spec.data[]` remoteRefs into the operator-generated Secrets, surfaced through the template under the ArmoniK env name; `envSecret` -> `spec.dataFrom[].extract` whole-Secret import with `template.mergePolicy: Merge`, so imported keys pass through alongside the computed literals and the template wins on collision. With default values only `core` holds credentials, so only `core` is an ExternalSecret.

**Guards.** `envConfigmap`, `envFromConfigmap` and `mountConfigmap` always fail on a layer: a layer becomes a Secret and ESO imports only from Secrets. Without `externalSecrets.available`, `envSecret`, `envFromSecret` and `mountSecret` fail too, a plain Secret being unable to copy another Secret without `lookup`.

**Mounts have two sides; do not conflate them.**

- *Aggregation source* : an entry of the umbrella's `conf.<layer>.mountSecret`, shaped `{secret, prefix, items?}`. Without `items`, the whole Secret is imported (`dataFrom.extract` plus a `rewrite` applying `prefix`, which may be empty). With `items` (`{<dest>: {field: <source key>}}`), keys are selected and renamed individually into `<prefix><dest>` via `spec.data[]`. Aggregate keys are flat: a Secret key cannot contain `/`, so there are no subdirectories.
- *Consuming mount* : an entry of a plane's `conf.mountSecret`, rendered by `armonik.conf.generateVolumeMounts` / `generateVolumes`. Native `mountPath`, `subPath`, `items` and `mode` all apply here. A workload mounts the mount-aggregate of every layer it uses, listed explicitly, parallel to its `envSecret` but never derived from it (env Secrets are not mounted).
- Entries resolving to the same path merge into ONE projected volume with one volumeMount. Volume names are content-addressed, `conf-<sha256(path + specs) | trunc 16>`, so the compute agent (`core`+`polling`+`log`+`compute`) and the credential-free worker (`worker`+`log`+`compute`) get distinct volumes at the same path and the worker never receives `core`. `subpath` is rejected at a path shared by two or more entries, and conflicting `mode`s at a shared path fail.
- `mountPath` is a single knob: `armonik.conf.mountPath` reads `.Values.conf.mountPath`, else `global.armonik.mountPath`, else `/mounts`. Storage env strings derive their file paths through `armonik.conf.mountFilePath`, so the env value, the ESO rewrite prefix and the volumeMount stay in sync. An aggregation source may mirror the consuming fields; `conf-mounts.yaml` then validates its `path` against the umbrella `mountPath` (equal, or under it when a `subpath` is set).
- An umbrella-declared mount cannot render as a per-entry volumeMount in plane pods: the plane subchart cannot reconstruct the backend-dependent specs (they need `.Subcharts`, which only the umbrella has), subchart values are static, and `lookup` is banned. An aggregate is necessarily consumed whole.

**Naming and cross-release wiring.** Every conf Secret is `<source>-conf-<layer>[-mount]`, where `source` is `armonik.conf.source`: `.Values.conf.source` (tpl-rendered), defaulting to `.Release.Name`. Plane charts default `conf.source: armonik`; the umbrella overrides it at three sites (`conf.source`, `control-plane.conf.source`, `compute-plane.conf.source`) with `'{{ .Release.Name }}'`, so children reference the umbrella release under any name. Installing a plane as its own release is then one flag, `--set conf.source=<umbrella-release>`, in the SAME namespace; another namespace needs the Secrets mirrored there, for instance with an ESO `remoteNamespace` ExternalSecret. `charts/armonik/templates/NOTES.txt` renders the matching recipes. Never name a conf Secret with `armonik.fullname`: it embeds `.Chart.Name` and `fullnameOverride`, so it is caller-variant.

**Credentials.** ESO is the channel for credentials, references and content-derived values (assembling a `mongodb://user:pass@host` URI, for instance). It reads Secrets only, so credentials never land in a ConfigMap. Bring-your-own credentials means pre-creating the backend Secret; GitOps consumers get a deterministic, `lookup`-free render. `charts/armonik/templates/secrets/secret-store.yaml` renders the per-release `SecretStore` (Kubernetes provider) with a dedicated read-only ServiceAccount, Role and RoleBinding.

**Naming is a convention between the umbrella and our own charts, never imposed on external charts.** We do not shadow third-party naming helpers, nor tpl-inject names into dependency values. The umbrella reads whatever names the dependency charts produce (through `.Subcharts`) and wires them into the ESO `remoteRef`s. The only names we own are our own (conf Secrets, the SecretStore), all release-derived, so multi-release installs and non-`armonik` release names stay safe.

### armonik-common (library, renders nothing)

- `_conf.tpl` : the conf schema, documented at the top of the file (`env`, `envConfigmap`, `envSecret`, `envFrom*`, `mountConfigmap`, `mountSecret`), `armonik.conf.merge`, the name and path helpers, `armonik.conf.resolve` (tpl-renders the name-bearing fields, defaults `path` and `mode`), and the `generateEnv` / `generateEnvFrom` / `generateVolume*` emitters used by every deployment and Job.
- `_utils.tpl` : `armonik.utils.merge`, a recursive merge engine with tpl-render-on-merge and null-is-absent / empty-string-is-absent semantics. Load-bearing for every pod spec; treat changes here as high-risk. Also `armonik.utils.index` and `armonik.utils.imageConf`.
- `_helpers.tpl` : `armonik.{name,fullname,namespace,chart,labels,selectorLabels,serviceAccountName,clusterDomain,pdb.apiVersion}`.
- `_operators.tpl` and `_monitoring.tpl` : see below.
- Its `values.yaml` is the single definition of the `global.armonik` cross-chart defaults. Every chart that can be a release root lifts them with `import-values: [{child: global.armonik, parent: global.armonik}]` on its `armonik-common` dependency, a subchart's globals never reaching its parent on their own.

### Operators

`charts/armonik-operators` aggregates the five install-once operators (external-secrets, keda, cert-manager, psmdb-operator, kube-prometheus-stack) and renders nothing of its own but NOTES.txt. The control surface is `global.armonik.operators.<op>.{deploy,available,namespace}`, read through the single `armonik.operators` helper:

- `deploy` : THIS release installs the operator and its CRDs. Gates the `armonik-operators` subchart conditions and the CRD-ordering hooks on the CRs we emit.
- `available` : the CRDs exist, from here or from another release, so emit CRs.
- `namespace` : where the operator runs, for consumers deriving hostnames from it. Defaults to this release's namespace when this release deploys it, else empty, which means "not stated" and is a render error for anything that needs it.

`charts/armonik/templates/operators-guard.yaml` rejects `deploy=true` with `available=false`, and namespace drift between `global.armonik.operators.<op>.namespace` and an operator subchart's own `namespaceOverride`. `charts/armonik/templates/cert-manager-wait.yaml` gates every Certificate/Issuer emitter on the cert-manager webhook being Available, and is rendered only when this release installs cert-manager.

### Monitoring and autoscaling

`_monitoring.tpl` resolves `global.armonik.monitoring.{prometheusUrl,metricsExporterUrl}` and the Grafana dashboard sidecar's watched namespaces. The default scaling path is one KEDA ScaledObject per partition with a `metrics-api` trigger scraping the control-plane metrics-exporter `/metrics` directly for `armonik_<partition>_tasks_queued`, which keeps Prometheus out of the scaling path; it assumes one always-present sample per metric, metrics-api having neither aggregation nor absent-as-zero. A `prometheus` trigger is the documented opt-in for rate, ratio and aggregation queries, and reintroduces the dependency on `prometheusOperator.available`. Prometheus gets ArmoniK metrics through first-party ServiceMonitor and PodMonitor resources in the plane charts, gated on `prometheusOperator.available`. A pod-deletion-cost controller (port of `armonik/pdc.tf`) is in target, so KEDA scale-in evicts idle workers rather than busy ones.

## Design contract (do not regress these)

- **Both install modes work**: one umbrella release, or subcharts as separate releases. The compute-plane chart is installable several times against one cluster. Nothing may depend on the release name or namespace being `armonik`: no hardcoded service names, scrape targets, or Prometheus URLs in templates or static confs.
- **GitOps-first rendering**: every chart must render with plain `helm template` against an empty cluster; consumers include ArgoCD and XLD, not just the helm CLI. Therefore no `lookup`-dependent behavior on required paths (offer `existingSecret`-style values instead of generate-and-lookup), no render-time randomness on required paths, and Helm hooks ONLY on Jobs, always with `helm.sh/hook-delete-policy: before-hook-creation`. Never put hook annotations on long-lived resources (ScaledObjects, Certificates). The one exception is the CRD-ordering hook on CRs whose CRD this same release installs, gated on `operators.<op>.deploy`; `charts/uninstall.md` documents the cleanup that gating implies.
- **Upgrades must work**: no fixed-name plain Jobs (immutable pod templates break `helm upgrade`), and `armonik.selectorLabels` stays name+instance only so selectors remain immutable. Rollout-on-config-change is deliberately deferred: a content checksum is infeasible because plane pods cannot read umbrella-owned config at render time, so the follow-up is a reloader in the operators layer, not a checksum annotation.
- **Secrets stay in Secrets**: never materialize credentials into ConfigMaps; generated credentials must be overridable by a user-provided Secret.
- **Scope decisions already made**: unix-domain-socket agent/worker channel is the required default (tcp is a fallback); exactly one worker container per partition (multi-worker was deliberately dropped); fluent-bit must support both DaemonSet and per-pod sidecar; no new Bitnami dependencies (the rabbitmq chart is the last one and is being replaced, operator-based); operators and their CRDs are installed once per cluster; no helmfile support (`charts/armonik/helmfile.yaml` is being removed; users may bring their own).
- **Deferred, do not build now**: Windows nodes, AWS-specific paths (CloudWatch/S3 log outputs, SQS, ECR), partition-metrics-exporter, S3/minio file storage, multi-cluster load balancer, ActiveMQ-vs-Artemis strategy.

## Known gaps

Current state, not a wish list: check before assuming a path works, and prune an entry when you fix it.

- **Broken render paths** (each keeps a disabled test naming it): compute-plane `podDisruptionBudget.enabled=true` calls the undefined `armonik.compute.pdb.apiVersion` (the library defines `armonik.pdb.apiVersion`); `armonik-ingress` standalone defaults nil-pointer on `global.environment.{name,description}`, for which the chart ships no defaults (its `ci/default-values.yaml` supplies the block).
- **Compute pods run BestEffort**: the deployment reads `agent.resources` / `worker.resources` while the values ship `limits` and `requests`.
- **Unix socket mode** is forced to tcp by an undiagnosed `#TODO: things break without this` in `partitionCommon.socketType`, and the worker preStop drain waits on a socket path that tcp never creates. Terraform's default is `unixdomainsocket`, and restoring it is required parity. Likely a socket-path-versus-mount-path mismatch: Terraform mounts the comm volume at `/cache/shared`, the chart at `/cache`.
- **Fluent-bit sidecar** exists only in the compute plane, where it reads `fluentBit.configMapName` while the values ship `configMapRef`. Control-plane and init pods have no sidecar path at all. Prefer native sidecars (initContainer with `restartPolicy: Always`) so init Jobs still complete, which means raising `kubeVersion` from `>=1.25` to `>=1.29`.
- **Missing versus Terraform and in target**: pod-deletion-cost controller, control-plane cpu/memory autoscaling (and the metrics-server it needs), data retention (MongoDB DataRetention, Redis TTL, Seq retention), mongodb-exporter, auth client certificate generation and fingerprint-to-user wiring, the every-minute self-healing init CronJob, and the comm/cache/FS volume options (today a single plain emptyDir at `/cache`).
- **activemq hardcodes admin/admin**, now as a literal inside the core Secret. A real credential Secret is a separate fix.
- **Init Jobs are fixed-name plain Jobs**, so `helm upgrade` fails with "field is immutable". Workaround: delete them, then upgrade. Fix: hook plus `before-hook-creation`.
- **Kind-flip race in `conf-mounts.yaml`**: the same name renders as an empty `Secret` or as an `ExternalSecret` depending on whether the layer has sources, and toggling a layer's first or last source can let ESO garbage-collect the freshly created Secret, leaving the name absent while pods mount it non-optionally. Re-running the upgrade fixes it; the fix is to always render an ExternalSecret when ESO is available.
- **Generated credentials break the GitOps contract on a required path**: `charts/armonik/templates/secrets/redis-users.yaml` combines `lookup` with `randAlphaNum`, and the grafana dependency auto-generates its admin password at render time. Both make the render non-deterministic; both need an `existingSecret`-style opt-out.

## Conventions

- PR titles follow Conventional Commits (`<type>(<scope>): <subject>`), enforced by the semantic-pull-request workflow and tied to semantic releases (see CONTRIBUTING.md).
- Chart versions move in lockstep (currently all 0.1.0). Re-run `charts/update-charts.sh` after touching a chart: bare when only its content changed, since the local charts are re-packaged as they are, but with `-u` as soon as a `Chart.yaml` changed (a version bump, or a dependency added, removed or re-constrained). The default `build` reproduces the exact versions `Chart.lock` pins, so it fails on a bump that still satisfies the range, with `can't get a valid version for dependency <name>`.
- `charts/best-practices.md` is the in-repo chart guideline (still a draft with open TODOs).
- `charts/uninstall.md` documents teardown, which is not symmetric with install: CRDs outlive releases, and the CRs emitted with `global.armonik.operators.<op>.deploy=true` are Helm hooks, so `helm uninstall` leaves them behind and their CRDs wedge in `Terminating`. The umbrella and `armonik-operators` NOTES.txt render the matching procedure per install mode. Keep those three in sync when changing operator gating or hook annotations.
- **`.Values` nil-safety.** Multi-key `.Values` reads must tolerate an absent/nil intermediate (a nested block the user didn't set). Use `armonik.utils.index` (`charts/armonik-common/templates/_utils.tpl`): `list .Values "a" "b" | include "armonik.utils.index"` short-circuits to `""` on any nil/false/empty step and never errors; decode the result by type (bool `| empty | not`, int `| int`, list `| fromYamlArray`, object `| fromYaml`; strings come back raw). Two rules on top:
  - **Single key: plain dot access + `default`, not the helper** (`.Values.foo | default dict`). A one-level read can't hit a nil intermediate, so the helper's toYaml/fromYaml round-trip is wasted; reserve the helper for 2+ keys. A hyphenated key that can't be dot-accessed (e.g. `control-plane`) uses the builtin `index .Values "control-plane" | default dict`.
  - **Resolve a nullable block once, then index off that prefix.** Bind it (`$svc := $me.service | default dict`) and read leaves off the var rather than re-traversing `.Values` on every access. Keys already established by an enclosing gate or prefix var are safe to reuse; only the intermediates not yet established need guarding.
- **Quote interpolated string scalars.** Any `{{ ... }}` that emits a string value into YAML gets `| quote` - labels, annotations, `name`/port-name fields, string config - especially dynamic/user-derived values. It prevents YAML type-coercion (a value that looks like a number, bool, `null`, or contains a `:` gets mis-parsed) and keeps an empty result valid (`""` instead of a blank that breaks the key). Do NOT quote integers (ports, replicas, counts) or booleans consumed as real bools, and never quote blocks emitted via `toYaml`/`nindent` (they carry their own structure). Author-controlled literal scalars (e.g. a fixed `replacement: metrics-exporter`) don't need it.
- **Prefer `coalesce` over chained `default`s.** `coalesce a b c` is clearer than `a | default b | default c` and exactly equivalent - both return the first non-empty argument, and `coalesce` skips `nil` correctly. Same trap for both: `false`, `0`, `""`, and empty maps/lists all count as "empty", so never use either to fall back off a value that can legitimately be `false`/`0`/empty (decode those explicitly, e.g. `... | include "armonik.utils.index" | empty | not` for a bool). Neither makes a nil *intermediate* safe: `coalesce .Values.a.b ...` still errors when `.Values.a` is nil - that remains `armonik.utils.index`'s job.
- **Prefer pipelines over parenthesised calls** wherever the rewrite is trivial: `list .Values "a" "b" | include "armonik.utils.index"` not `include "armonik.utils.index" (list ...)`, `printf "..." $x | fail` not `fail (printf ...)`, `$x | empty | ternary "" $y` not `ternary "" $y (empty $x)`. Keep parentheses where an argument genuinely nests (`ternary "" (printf ".%s" $d)`, `and $a (not $b)`, `dict "k" (list ...)`), and where the piped position is the wrong argument: `tpl` is `tpl <string> <context>`, so `... | tpl $ctx` silently swaps them; bind a variable instead.
- **Comments target readers fluent in Helm.** Keep them short and skip the mechanics (what `tpl` does, that globals propagate downward, how hooks are ordered): document the decision and the constraint that is not visible in the code, such as why a value must not be read by its own default, or why a context must carry the full `.Values`. State a fact once and cross-reference it rather than repeating it in each chart. A comment states the current constraint, never the history behind it: no "before PR #X", no "this used to be Y". The sole exception is a disabled test's skip reason, whose whole function is to say when to re-enable it.
- **Plain ASCII everywhere, comments included.** Templates, values, scripts and docs stay in the 7-bit range: no curly quotes or apostrophes (write `certificate's`, not the typographic form), no em-dash, no ellipsis character, no accented prose. Those arrive by copy-paste from a browser or through an editor's smart-quote substitution, pass review unnoticed, then break a `grep`, a `sed`, or a terminal that is not UTF-8. Use a plain equivalent instead: commas, parentheses, semicolons, or a separate sentence where an em-dash is tempting. The single exception is the banner in `charts/armonik/templates/NOTES.txt`, whose box-drawing characters are the point.
- **Indent helpers that do not render text directly.** Inside a `define`, indent statement lines (`{{- ... -}}`) by two per nesting level; they trim their own whitespace, so the indentation is free and the control flow becomes readable. A `define` that emits YAML or text keeps that emitted content at its literal column, since indenting it would change the output. Same for templates that render nothing at all, such as the validation guards.
- **`ternary` needs a real bool.** A nil condition aborts the render with `invalid value; expected bool`, naming neither the value nor a useful location. Decode first and order the branches so `not` is unnecessary: `$x | empty | ternary "<empty case>" "<set case>"`. Same care with `and`/`or`, which return one of their arguments rather than a bool.
- **A value whose default is a helper call comes as a pair.** `<value>.default` derives the default; `<value>` resolves whatever the value currently holds, `tpl`-rendering it since that default is a template string. Consumers call the resolver, only `values.yaml` calls a `.default`, and a `.default` must never read the value it defaults or `tpl` recurses. A default written in values only applies to charts that ship it, so every chart that can be a release root has to declare it, directly or through `import-values`. Reference implementation: `charts/armonik-common/templates/_monitoring.tpl`.
- **Fail rather than emit an empty or unresolvable value.** An empty URL, host or namespace segment renders cleanly, passes `helm lint`, and only surfaces once the workload runs. Resolvers therefore `fail` on an empty result, and derivations `fail` when an input they cannot guess is absent (the monitoring namespace of an externally installed operator, for one). A render-time `fail` naming the value always beats a plausible-looking default. Same reasoning for fail-closed guards on configurations that deploy cleanly and do nothing: a compute-plane with no partition, a conf layer declaring fields the umbrella cannot render.
- **A fabricated render context carries the full `.Values`.** The per-partition render in `armonik-compute-plane` builds `omit $ "Values"` plus `omit $.Values "partitions"` plus a synthetic `partitionName`: everything except the self-referencing key, so partition values can still call helpers (a missing `.Values.global` makes them resolve empty instead of erroring) while no partition sees the catalog of all partitions. Inside `range $name, $cfg := .Values.partitions`, Go rebinds `.`, so the root must be `$.Values`.
- **Only `global.*` crosses into a third-party subchart's `tpl`.** A dependency that tpl-renders one of its own values (grafana's `sidecar.dashboards.searchNamespace`) evaluates it in its own scope, where the umbrella's root-level values do not exist, so anything such a value must reach lives under `global`.
- **Shell scripts are POSIX `sh`**, verified under dash. Never `set -o pipefail` around `... | grep -q`: on a large stream grep exits at the first match, the producer dies on SIGPIPE, and pipefail turns a MATCH into a non-zero pipeline, silently inverting the check.
- **Generated documentation is never committed; the readthedocs pipeline (`.readthedocs.yaml` -> `.docs/generate-*.sh`) regenerates it on every build.** Terraform module READMEs embed terraform-docs sections between `<!-- BEGIN_TF_DOCS -->`/`<!-- END_TF_DOCS -->` markers, and a pre-commit hook strips the injected part back out. Chart READMEs are generated in full by helm-docs, so `charts/*/README.md` is git-ignored: never write one, and never link to one from committed docs. Chart documentation is authored in `values.yaml` (`# -- ` comments), `Chart.yaml`, or a per-chart `README.md.gotmpl`. helm-docs silently skips a chart that has no `values.yaml`, which drops its page from the site; adding a chart also means adding one line to the `Helm Charts` toctree in `.docs/index.md`, since a glob cannot control the ordering.
