#!/bin/sh
# Adds the helm repositories the charts depend on, then vendors every chart's
# dependencies from the committed Chart.lock files (charts/update-charts.sh
# bare mode = helm dependency build --skip-refresh). Fails when a Chart.yaml
# drifted from its Chart.lock: this is the CI dependency-freshness check.
# Flags are forwarded to update-charts.sh (-r, -u, -ur).
#
# The repository list is duplicated in ct.yaml (chart-repos); keep in sync.
set -eu
cd "$(dirname "$0")/.."

repo_add() {
  helm repo add "$1" "$2" --force-update
}

repo_add valkey               https://valkey.io/valkey-helm/
repo_add percona              https://percona.github.io/percona-helm-charts/
repo_add prometheus-community https://prometheus-community.github.io/helm-charts
repo_add kedacore             https://kedacore.github.io/charts
repo_add bitnami              https://charts.bitnami.com/bitnami
repo_add grafana              https://grafana.github.io/helm-charts
repo_add fluent               https://fluent.github.io/helm-charts
repo_add datalust             https://helm.datalust.co
repo_add jetstack             https://charts.jetstack.io
repo_add external-secrets     https://charts.external-secrets.io

charts/update-charts.sh "$@"
helm dependency build test/harness/common-harness --skip-refresh
