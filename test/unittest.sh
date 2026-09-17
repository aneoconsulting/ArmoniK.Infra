#!/bin/sh
# Runs the helm-unittest suites (charts/<chart>/tests/*_test.yaml).
# Requires the plugin: helm plugin install \
#   https://github.com/helm-unittest/helm-unittest.git --version 1.1.2
#
# --with-subchart=false: vendored subchart archives embed their own tests/
# directory; without it the parent chart would re-run them in its own values
# context and fail spuriously.
set -eu
cd "$(dirname "$0")/.."

helm_test() {
  helm unittest "$1" --strict --with-subchart=false
}

helm_test charts/activemq
helm_test charts/armonik-control-plane
helm_test charts/armonik-compute-plane
helm_test charts/armonik-ingress
helm_test charts/armonik
helm_test test/harness/common-harness
