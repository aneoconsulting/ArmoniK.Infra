#! /bin/sh

SKIP_REFRESH="--skip-refresh"
if [ "$1" = "-r" ]; then
  SKIP_REFRESH=""
fi

updatedeps() {
  for chart in "$@"; do
    helm dependency update "$chart" $SKIP_REFRESH &
  done
  wait
}

updatedeps activemq armonik-common
updatedeps armonik-compute-plane armonik-control-plane armonik-configuration armonik-dependencies armonik-ingress
updatedeps armonik
