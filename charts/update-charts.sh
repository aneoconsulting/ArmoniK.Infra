#! /bin/sh

# Re-vendors the dependencies of every chart in this directory.
#
# Charts are processed in layers: a layer's charts are packaged into the
# charts/ of the next layer, so the layers run in order while the charts of a
# single layer run in parallel.

set -eu

self="$0"
cd "$(dirname "$self")"

usage() {
  cat <<EOF
Usage: $self [-u] [-r] [-h]

Re-vendors the dependencies of every chart, cheapest mode first:

  $self          helm dependency build  --skip-refresh
  $self -r       helm dependency build
  $self -u       helm dependency update --skip-refresh
  $self -u -r    helm dependency update

  -u  re-resolve the dependencies and rewrite Chart.lock, instead of
      reproducing the versions it already pins
  -r  refresh the local repository cache before resolving
  -h  show this help
EOF
}

action=build
refresh=0

while getopts ':urh' opt; do
  case "$opt" in
    u) action=update ;;
    r) refresh=1 ;;
    h) usage; exit 0 ;;
    *)
      printf '%s: invalid option -- %s\n\n' "$self" "$OPTARG" >&2
      usage >&2
      exit 2
      ;;
  esac
done
shift $((OPTIND - 1))

if [ "$#" -gt 0 ]; then
  printf "%s: unexpected argument '%s': this script re-vendors every chart\n" "$self" "$1" >&2
  exit 2
fi

helm_opts=$action
[ "$refresh" -eq 1 ] || helm_opts="$helm_opts --skip-refresh"

updatedeps() {
  running=
  for chart in "$@"; do
    # Word splitting of helm_opts is wanted; it only ever holds literal flags.
    helm dependency $helm_opts "$chart" &
    running="$running $!:$chart"
  done

  # `wait` without operand always reports success, so every job is waited on
  # individually to catch the ones that failed.
  failed=
  for job in $running; do
    if ! wait "${job%%:*}"; then
      failed="$failed ${job#*:}"
    fi
  done

  # A layer feeds the next one, so a failure here stops everything.
  if [ -n "$failed" ]; then
    printf '%s: failed to vendor:%s\n' "$self" "$failed" >&2
    [ "$action" = update ] || printf '%s: hint: a Chart.lock out of sync with its Chart.yaml needs -u\n' "$self" >&2
    [ "$refresh" -eq 1 ] || printf '%s: hint: a missing or stale repository index needs -r\n' "$self" >&2
    exit 1
  fi
}

updatedeps activemq armonik-common
updatedeps armonik-compute-plane armonik-control-plane armonik-dependencies armonik-ingress
updatedeps armonik
