#! /bin/sh

# Packages the release-root charts into one directory that doubles as a helm
# repository, for air-gapped installs (see airgap.md). Dependencies must be
# vendored first (./update-charts.sh, or ../test/vendor.sh from the repo root);
# the archives carry them, so they install with no network and no repository.

set -eu

self="$0"
here=$(dirname "$self")
outdir="$here/../dist"
version=

usage() {
  cat <<USAGE
Usage: $self [-o DIR] [-v VERSION] [-h]

Packages the release-root charts and writes the repository index next to them.

  -o DIR      output directory, created if absent, its *.tgz and index.yaml
              cleared first (default: the repo's dist/)
  -v VERSION  semver to stamp over the in-tree chart versions; activemq keeps
              its own (default: keep every in-tree version)
  -h          show this help
USAGE
}

while getopts ':o:v:h' opt; do
  case "$opt" in
    o) outdir=$OPTARG ;;
    v) version=$OPTARG ;;
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
  printf "%s: unexpected argument '%s': this script packages every chart\n" "$self" "$1" >&2
  exit 2
fi

# helm's own rejection is a bare "Invalid Semantic Version", naming neither the
# chart nor the value, which usually comes from a CI expression.
if [ -n "$version" ] &&
   ! printf '%s\n' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$'; then
  printf "%s: '%s' is not a valid semantic version\n" "$self" "$version" >&2
  exit 2
fi

mkdir -p "$outdir"
# Absolute, so it survives the cd below.
outdir=$(cd "$outdir" && pwd)
cd "$here"

# The release roots, in install order. armonik-common is a library every
# consumer vendors; activemq ships alone too, being the one dependency we own.
charts="armonik-operators armonik armonik-control-plane armonik-compute-plane armonik-ingress armonik-dependencies activemq"

# Archives from a run at another version would otherwise land in the index.
rm -f "$outdir"/*.tgz "$outdir"/index.yaml

set --
if [ -n "$version" ]; then
  set -- --version "$version"
fi

for chart in $charts; do
  case "$chart" in
    # activemq is off the others' lockstep and ahead of them: a release version
    # stamped on it would read as a downgrade.
    activemq) helm package "$chart" --destination "$outdir" ;;
    *)        helm package "$chart" --destination "$outdir" "$@" ;;
  esac
done

# No --url: bare file names, resolved against whatever ends up serving the
# directory. `helm repo add` has no file:// handler, so consuming the index
# means serving it over HTTP; installing an archive by path needs no index.
helm repo index "$outdir"

printf '\npackaged into %s:\n' "$outdir"
ls -1 "$outdir"
