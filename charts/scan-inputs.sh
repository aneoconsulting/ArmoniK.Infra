#! /bin/sh

# Renders every packaged release-root chart, with its defaults and with each of
# its ci/*-values.yaml fixtures, then lists the container images those renders
# reference. Feeds the trivy job of .github/workflows/publish.yml: the renders
# are scanned for misconfigurations, the images for vulnerabilities. Needs helm
# and mikefarah yq v4.
#
# Outputs, under OUT:
#   manifests/<chart>/<case>.yaml   one render per case
#   renders.tsv                     <chart> <case> <ok|failed> <first error line>
#   images.tsv                      <image> <chart/case,...>, one line per image
#
# A failed render is recorded, not fatal: a chart's bare defaults may be
# invalid on purpose (armonik-compute-plane has no partition, armonik-ingress
# no URLs Secret), its fixtures then covering it. test/matrix.sh is what
# asserts which renders must succeed.

set -eu

self="$0"
here=$(cd "$(dirname "$self")" && pwd)
dist="$here/../dist"
out="$here/../scan"
# test/matrix.sh's default: the compute plane refuses anything below 1.29.
kube_version=1.31.0

usage() {
  cat <<USAGE
Usage: $self [-d DIR] [-o DIR] [-k VERSION] [-h]

Renders the packaged charts and lists the images they reference.

  -d DIR      directory holding the packaged charts (default: the repo's dist/)
  -o DIR      output directory, cleared first (default: the repo's scan/)
  -k VERSION  Kubernetes version to render for (default: $kube_version)
  -h          show this help
USAGE
}

while getopts ':d:o:k:h' opt; do
  case "$opt" in
    d) dist=$OPTARG ;;
    o) out=$OPTARG ;;
    k) kube_version=$OPTARG ;;
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
  printf "%s: unexpected argument '%s'\n" "$self" "$1" >&2
  exit 2
fi

# The Python yq wrapper shares the name and takes jq syntax.
if ! yq --version 2>/dev/null | grep -q mikefarah; then
  printf '%s: needs mikefarah yq v4 (https://github.com/mikefarah/yq)\n' "$self" >&2
  exit 2
fi

set -- "$dist"/*.tgz
if [ ! -f "$1" ]; then
  printf '%s: no packaged chart in %s; run package-charts.sh first\n' "$self" "$dist" >&2
  exit 2
fi

rm -rf "$out"
mkdir -p "$out/manifests"
out=$(cd "$out" && pwd)
: > "$out/renders.tsv"
raw="$out/images.raw"
: > "$raw"
err="$out/stderr"

# Where an image hides in a render. CRDs are skipped: their schemas carry
# `image` keys that are documentation. Beyond the `image` fields of pod specs
# and of CRs (percona's PerconaServerMongoDB, the Prometheus CR), operators
# take the images of what they spawn as flags (cert-manager's ACME solver,
# prometheus-operator's config reloader) or env (cloudnative-pg).
# shellcheck disable=SC2016 # yq expression, not shell
extract='
  select(.kind != "CustomResourceDefinition") |
  (
    (.. | select(tag == "!!map") | (.image, .imageName) | select(tag == "!!str")),
    (.. | select(tag == "!!str") | select(test("^--(([a-z0-9-]*-)?image|prometheus-config-reloader)=")) | sub("^[^=]*=", "")),
    (.. | select(tag == "!!map" and has("name") and has("value")) | select(.name | test("(?i)image")) | .value | select(tag == "!!str"))
  )
'

render() { # render <archive> <chart> <case> [helm args...]
  archive=$1
  chart=$2
  case_name=$3
  shift 3
  manifest="$out/manifests/$chart/$case_name.yaml"
  mkdir -p "$out/manifests/$chart"
  # stderr apart: helm warnings would corrupt the manifest stream.
  if helm template scan "$archive" --kube-version "$kube_version" "$@" >"$manifest" 2>"$err"; then
    printf '%s\t%s\tok\t\n' "$chart" "$case_name" >> "$out/renders.tsv"
  else
    rm -f "$manifest"
    reason=$(grep -m1 -i 'error' "$err" || head -n1 "$err")
    printf '%s\t%s\tfailed\t%s\n' "$chart" "$case_name" "$reason" >> "$out/renders.tsv"
    printf '%s: %s/%s did not render: %s\n' "$self" "$chart" "$case_name" "$reason" >&2
    return 0
  fi
  yq ea -N "$extract" "$manifest" |
    awk -v src="$chart/$case_name" '
      # One reference per line; anything else (a template leftover, prose in
      # an env value) is not an image.
      !/^[A-Za-z0-9][A-Za-z0-9._\/:@-]*$/ { next }
      {
        # One spelling per Docker Hub image: "docker.io/library/busybox",
        # "busybox" and "busybox:latest" are one image.
        sub(/^(index\.)?docker\.io\//, "")
        sub(/^library\//, "")
        n = split($0, part, "/")
        if (index($0, "@") == 0 && index(part[n], ":") == 0) $0 = $0 ":latest"
        print $0 "\t" src
      }' >> "$raw"
}

for archive in "$@"; do
  chart=$(helm show chart "$archive" | yq '.name')
  render "$archive" "$chart" defaults
  for fixture in "$here/$chart"/ci/*-values.yaml; do
    [ -f "$fixture" ] || continue
    case_name=$(basename "$fixture" -values.yaml)
    render "$archive" "$chart" "$case_name" -f "$fixture"
  done
done

sort -u "$raw" |
  awk -F '\t' '
    $1 != image { if (image != "") print image "\t" sources; image = $1; sources = $2; next }
    { sources = sources "," $2 }
    END { if (image != "") print image "\t" sources }' > "$out/images.tsv"
rm -f "$raw" "$err"

if ! grep -q '	ok	' "$out/renders.tsv"; then
  printf '%s: no chart rendered\n' "$self" >&2
  exit 1
fi
if [ ! -s "$out/images.tsv" ]; then
  printf '%s: the renders reference no image, which means the extraction broke\n' "$self" >&2
  exit 1
fi

printf '%s: %s render(s), %s failed, %s image(s), in %s\n' "$self" \
  "$(wc -l < "$out/renders.tsv" | tr -d ' ')" \
  "$(grep -c '	failed	' "$out/renders.tsv" || true)" \
  "$(wc -l < "$out/images.tsv" | tr -d ' ')" \
  "$out" >&2
