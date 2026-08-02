# Chart tests

Template-only verification of the Helm charts: nothing here needs a Kubernetes
cluster. CI runs the same entrypoints (`.github/workflows/test-helm.yml` and
`linter-helm.yml`).

## Entrypoints

```sh
./test/vendor.sh                  # helm repo add + vendor every chart's deps from Chart.lock
./test/unittest.sh                # helm-unittest suites
./test/matrix.sh                  # render matrix + unrendered-template check + kubeconform
ct lint --config ct.yaml --all    # chart-testing lint (yamllint + schema + helm lint)
```

`test/vendor.sh` doubles as the dependency-freshness check: bare mode runs
`helm dependency build --skip-refresh`, which reproduces the committed
Chart.lock files and fails on any Chart.yaml/lock drift. Flags are forwarded
to `charts/update-charts.sh` (`-u` to re-resolve locks after a Chart.yaml
change, `-r`/`-ur` to also refresh repository indexes).

`KUBECONFORM=0 ./test/matrix.sh` skips schema validation for a faster
render-only pass.

## Prerequisites

- helm >= 3.18 (CI pins v3.18.4)
- helm-unittest plugin:
  `helm plugin install https://github.com/helm-unittest/helm-unittest.git --version 1.1.2`
- kubeconform (matrix only): v0.8.0
- ct + yamllint + yamale (lint only)

## Layout

- `charts/<chart>/tests/*_test.yaml`: helm-unittest suites. Run with
  `--with-subchart=false`; vendored subchart archives embed their own tests
  and would otherwise be re-run in the parent's values context.
- `charts/<chart>/ci/*-values.yaml`: valid render fixtures. ct lint picks
  each one up automatically (the chart is linted once per fixture), and the
  matrix renders them.
- `test/fixtures/<chart>/*.yaml`: fixtures ct must not lint: expected-failure
  inputs for the render-time guards and kube-version variants.
- `test/check-unrendered.awk`: the unrendered-template check run on every
  matrix render. Document-aware: documents sourced from third-party subcharts
  are skipped (their content legitimately embeds Grafana/Prometheus `{{ }}`
  templating), ExternalSecret documents may carry ESO target-template refs of
  the exact shape `{{ .KEY }}`, and the owned grafana dashboard ConfigMaps may
  carry Grafana legend templating `{{label}}`. Any other `{{` in an
  ArmoniK-owned document fails the case.
- `test/harness/common-harness/`: minimal chart exercising the armonik-common
  library helpers (merge engine, conf generators and guards, nil-safe index)
  through templates that surface helper output as ConfigMap data. Never
  deployed; lives outside `charts/` so ct and helm-docs ignore it.

## Skipped tests

Known-broken render paths keep their tests written but disabled, each with a
`skip.reason` (suites) or `skip` line (matrix) naming the bug. Enable them as
the bugs get fixed:

1. `armonik-compute-plane` PDB: `pdb.yaml` calls the undefined helper
   `armonik.compute.pdb.apiVersion` (armonik-common defines
   `armonik.pdb.apiVersion`).
2. umbrella with `control-plane.enabled=false`: NOTES.txt dereferences the
   control-plane values unconditionally (nil pointer).
3. `armonik-ingress` standalone defaults: the chart ships no
   `global.environment` defaults but tpl-renders
   `global.environment.{name,description}` in `static."environment.json"`.
   Until fixed, `ci/default-values.yaml` provides the block.
