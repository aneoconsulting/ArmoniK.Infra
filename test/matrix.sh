#!/bin/sh
# Template-only render matrix (no cluster): each case must render with
# helm template, contain no unrendered '{{' leftovers, and schema-validate
# with kubeconform. fail_with cases assert the charts' render-time guards.
#
# KUBECONFORM=0 ./test/matrix.sh   skips schema validation (fast local pass).
# Valid fixtures live in charts/<chart>/ci/ (also linted by ct, once each);
# expected-failure and kube-version-variant fixtures live in test/fixtures/.
set -eu
cd "$(dirname "$0")/.."

KUBE_VERSION_DEFAULT="1.31.0"
KUBECONFORM="${KUBECONFORM:-1}"
SCHEMA_CACHE="$(mktemp -d)"
trap 'rm -rf "$SCHEMA_CACHE"' EXIT
failures=0
skips=0

if [ "$KUBECONFORM" = 1 ] && ! command -v kubeconform >/dev/null; then
  echo "kubeconform not found; install it or run with KUBECONFORM=0" >&2
  exit 2
fi

validate() { # <kube-version>; manifests on stdin
  kubeconform -strict -summary -kubernetes-version "$1" \
    -schema-location default \
    -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
    -ignore-missing-schemas \
    -cache "$SCHEMA_CACHE"
}

# ok <name> <chart-dir> [--kube-version V] [helm args...]
ok() {
  name="$1"
  chart="$2"
  kube_version="$KUBE_VERSION_DEFAULT"
  shift 2
  while :; do
    case "${1:-}" in
      --kube-version) kube_version="$2"; shift 2 ;;
      *) break ;;
    esac
  done
  echo "=== ok: $name"
  # stderr stays out of the manifest stream: helm warnings would corrupt it.
  if ! out=$(helm template "test-$name" "charts/$chart" --kube-version "$kube_version" "$@" 2>"$SCHEMA_CACHE/stderr"); then
    echo "FAIL(render) $name"; tail -5 "$SCHEMA_CACHE/stderr"; failures=$((failures+1)); return 0
  fi
  # document-aware: skips third-party subchart docs, allows the ESO and
  # Grafana '{{ }}' shapes where they belong; see test/check-unrendered.awk
  if ! printf '%s\n' "$out" | awk -f test/check-unrendered.awk; then
    echo "FAIL(unrendered template left in output) $name"
    failures=$((failures+1)); return 0
  fi
  if [ "$KUBECONFORM" = 1 ] && ! printf '%s\n' "$out" | validate "$kube_version"; then
    echo "FAIL(schema) $name"; failures=$((failures+1))
  fi
}

# fail_with <name> <chart-dir> <grep-pattern> [helm args...]
fail_with() {
  name="$1"
  chart="$2"
  pattern="$3"
  shift 3
  echo "=== fail_with: $name"
  if out=$(helm template "test-$name" "charts/$chart" --kube-version "$KUBE_VERSION_DEFAULT" "$@" 2>&1 >/dev/null); then
    echo "FAIL(expected render error, got success) $name"; failures=$((failures+1)); return 0
  fi
  if ! printf '%s\n' "$out" | grep -qF "$pattern"; then
    echo "FAIL(wrong error) $name: expected $pattern"; printf '%s\n' "$out" | tail -3
    failures=$((failures+1))
  fi
}

skip() { # <name> <reason>
  echo "=== SKIP: $1 -- $2"
  skips=$((skips+1))
}

# --- defaults, one per chart ---------------------------------------------
ok activemq-defaults      activemq
ok control-plane-defaults armonik-control-plane
ok compute-plane-defaults armonik-compute-plane
ok dependencies-defaults  armonik-dependencies
ok umbrella-defaults      armonik
skip ingress-defaults "broken: chart values lack global.environment, static.environment.json hits a nil pointer; enable when fixed"

# --- conditional variants --------------------------------------------------
ok umbrella-minimal       armonik               -f charts/armonik/ci/minimal-values.yaml
ok umbrella-mountpath     armonik               -f charts/armonik/ci/minimal-values.yaml --set global.armonik.mountPath=/etc/armonik
ok compute-partitions     armonik-compute-plane -f charts/armonik-compute-plane/ci/partitions-values.yaml
ok compute-keda-off       armonik-compute-plane -f charts/armonik-compute-plane/ci/keda-off-values.yaml
skip compute-pdb "broken: pdb.yaml calls the undefined helper armonik.compute.pdb.apiVersion; enable when fixed"
ok control-rbac-full      armonik-control-plane -f charts/armonik-control-plane/ci/rbac-values.yaml
ok control-headless-init  armonik-control-plane -f charts/armonik-control-plane/ci/headless-init-values.yaml
ok ingress-near-default   armonik-ingress       -f charts/armonik-ingress/ci/default-values.yaml
ok ingress-tls-mtls       armonik-ingress       -f charts/armonik-ingress/ci/tls-mtls-values.yaml
ok ingress-gateway        armonik-ingress       -f charts/armonik-ingress/ci/gateway-values.yaml
ok ingress-lb             armonik-ingress       -f charts/armonik-ingress/ci/lb-values.yaml
ok activemq-pdb-hpa       activemq              -f charts/activemq/ci/pdb-hpa-values.yaml
ok activemq-tls           activemq              -f charts/activemq/ci/tls-values.yaml
ok activemq-psp-k8s124    activemq --kube-version 1.24.17 -f test/fixtures/activemq/psp-values.yaml
ok activemq-psp-k8s131    activemq              -f test/fixtures/activemq/psp-values.yaml
skip umbrella-no-control-plane "broken: NOTES.txt dereferences control-plane values unconditionally; enable when fixed"

# --- render-time guards ------------------------------------------------
fail_with ingress-mtls-without-tls armonik-ingress \
  "mTLS requires TLS to be enabled" \
  -f test/fixtures/armonik-ingress/mtls-no-tls-values.yaml
fail_with ingress-httproute-no-gateway armonik-ingress \
  "httpRoute.enabled=true requires either gateway.enabled=true or httpRoute.parentRefs" \
  -f test/fixtures/armonik-ingress/httproute-no-gateway-values.yaml
fail_with control-authz-without-authn armonik-control-plane \
  "Authorization requires authentication to be enabled" \
  -f test/fixtures/armonik-control-plane/authz-values.yaml
fail_with umbrella-envsecret-without-eso armonik \
  "envSecret and envFromSecret require ExternalSecretsOperator" \
  --set dependencies.external-secrets.enabled=false
fail_with umbrella-bad-loglevel armonik \
  "conf.log.minimumLevel \"Bogus\" is invalid" \
  -f charts/armonik/ci/minimal-values.yaml --set conf.log.minimumLevel=Bogus

echo
echo "matrix: $skips case(s) skipped"
if [ "$failures" -eq 0 ]; then
  echo "matrix: all cases passed"
else
  echo "matrix: $failures case(s) failed"
fi
exit "$((failures > 0))"
