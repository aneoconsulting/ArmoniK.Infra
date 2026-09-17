#! /bin/sh

# Re-vendors the dependencies of every chart in this directory.
#
# Charts are processed in layers: a layer's charts are packaged into the
# charts/ of the next layer, so the layers run in order while the charts of a
# single layer run in parallel.
#
# A dependency repository absent from `helm repo list` (helm calls it
# unmanaged) is only ever fetched by `dependency update` while it refreshes, so
# -u -r is the one mode that needs no `helm repo add` beforehand.

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
  -r  refresh the local repository cache; the charts pulling from a repository
      then run one at a time, the others stay parallel
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

# Word splitting of both is wanted; they only ever hold literal flags.
cached_opts="$action --skip-refresh"
refresh_opts=$action

# Only a chart pulling a dependency from an http(s) repository reads the shared
# repository index, and refreshes it when told to; one that resolves everything
# from file:// or an OCI registry never opens it.
usesrepos() {
  grep -qE '^[[:space:]]*repository:[[:space:]]*"?https?://' "$1/Chart.yaml"
}

updatedeps() {
  running=
  failed=
  cached=
  for chart in "$@"; do
    if [ "$refresh" -eq 1 ] && usesrepos "$chart"; then
      # A refresh rewrites the whole index and helm offers no way to refresh it
      # separately, so these run one at a time, before anything reads it.
      helm dependency $refresh_opts "$chart" || failed="$failed $chart"
    else
      cached="$cached $chart"
    fi
  done

  for chart in $cached; do
    helm dependency $cached_opts "$chart" &
    running="$running $!:$chart"
  done

  # `wait` without operand always reports success, so every job is waited on
  # individually to catch the ones that failed.
  for job in $running; do
    wait "${job%%:*}" || failed="$failed ${job#*:}"
  done

  # A layer feeds the next one, so a failure here stops everything.
  if [ -n "$failed" ]; then
    printf '%s: failed to vendor:%s\n' "$self" "$failed" >&2
    [ "$action" = update ] || printf '%s: hint: a Chart.lock out of sync with its Chart.yaml needs -u\n' "$self" >&2
    [ "$refresh" -eq 1 ] || printf '%s: hint: a stale repository index needs -r, one absent from `helm repo list` needs -u -r\n' "$self" >&2
    exit 1
  fi
}

updatedeps activemq armonik-common
updatedeps armonik-compute-plane armonik-control-plane armonik-dependencies armonik-operators armonik-ingress
updatedeps armonik
