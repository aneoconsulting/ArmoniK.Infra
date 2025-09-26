#! /bin/sh

updatedeps() {
  for chart in "$@"; do
    helm dependency update "$chart" --skip-refresh &
  done
  wait
}

updatedeps activemq armonik-common
updatedeps armonik-compute-plane armonik-control-plane armonik-configuration armonik-dependencies armonik-ingress
updatedeps armonik
