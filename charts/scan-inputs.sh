#! /bin/sh

# Renders every packaged release-root chart, with its defaults and with each of
# its ci/*-values.yaml fixtures, and lists the container images the charts
# reference: those the renders use, plus those their values name without
# rendering them (a disabled component, a disabled subchart). Feeds the trivy
# job of .github/workflows/publish.yml: the renders are scanned for
# misconfigurations, the images for vulnerabilities. Needs helm and mikefarah
# yq v4.
#
# Outputs, under OUT:
#   manifests/<chart>/<case>.yaml   one render per case
#   renders.tsv                     <chart> <case> <ok|failed> <first error line>
#   images.tsv                      <image> <chart/case,...>, one line per image,
#                                   the case `values` meaning found in the values
#                                   of that chart's archive, not in a render
#
# A failed render is recorded, not fatal: a chart's bare defaults may be
# invalid on purpose (armonik-compute-plane has no partition, armonik-ingress
# no URLs Secret), its fixtures then covering it. test/matrix.sh is what
# asserts which renders must succeed.
#
# An image a fixture names is a placeholder (busybox:0.0.0-test), so a
# fixture's render contributes no image of a repository that fixture names.

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
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
: > "$out/renders.tsv"
: > "$work/rendered"
: > "$work/values"
err="$work/stderr"

# Shared by every awk below: one spelling per image, so that
# "docker.io/library/busybox", "busybox" and "busybox:latest" are one image.
awk_lib='
  function norm(r,   n, p) {
    sub(/^(index\.)?docker\.io\//, "", r)
    sub(/^library\//, "", r)
    n = split(r, p, "/")
    if (index(r, "@") == 0 && index(p[n], ":") == 0) r = r ":latest"
    return r
  }
  function repo(r,   n, p) {
    sub(/@.*$/, "", r)
    n = split(r, p, "/")
    if (index(p[n], ":")) sub(/:[^:\/]*$/, "", r)
    return r
  }
  # One reference: anything else (a template leftover, prose) is not an image.
  function isref(r) { return r ~ /^[A-Za-z0-9][A-Za-z0-9._\/:@-]*$/ }
'

# Where an image hides in a render. CRDs are skipped: their schemas carry
# `image` keys that are documentation. Beyond the `image` fields of pod specs
# and of CRs (percona's PerconaServerMongoDB, the Prometheus CR), operators
# take the images of what they spawn as flags (cert-manager's ACME solver,
# prometheus-operator's config reloader) or env (cloudnative-pg).
# shellcheck disable=SC2016 # yq expressions, not shell
in_render='
  select(.kind != "CustomResourceDefinition") |
  (
    (.. | select(tag == "!!map") | (.image, .imageName) | select(tag == "!!str")),
    (.. | select(tag == "!!str") | select(test("^--(([a-z0-9-]*-)?image|prometheus-config-reloader)=")) | sub("^[^=]*=", "")),
    (.. | select(tag == "!!map" and has("name") and has("value")) | select(.name | test("(?i)image")) | .value | select(tag == "!!str"))
  )
'

# Where an image hides in values, as `map <registry> <repository> <tag>
# <digest>`, `ref <reference>` or `component <component> <repository>
# <version>`: a map with a repository under a key naming an image (whatever
# else the chart composes it with, cert-manager's imageNamespace for one, is
# missed, its rendered images covering it), a reference string under a key
# ending in "image", and ArmoniK's own repository-to-component map.
# shellcheck disable=SC2016
in_values='
  (
    .. | select(tag == "!!map" and has("repository"))
       | select(.repository | tag == "!!str" and . != "")
       | select(path | map(tostring) | join(".") | test("(?i)image"))
       | ["map", (.registry // "" | tostring), .repository, (.tag // "" | tostring), ((.digest // .sha // "") | tostring)]
       | @tsv
  ),
  (
    .. | select(tag == "!!str" and . != "")
       | select(path | .[-1] | tostring | test("(?i)image$"))
       | ["ref", .] | @tsv
  ),
  (
    (.global.armonik.versions // {}) as $v
    | (.global.armonik.imageComponents // {}) | to_entries | .[]
    | .value as $c
    | ["component", $c, .key, ($v[$c] // "" | tostring)] | @tsv
  )
'

# The fixture side of the same: the repositories a fixture names.
# shellcheck disable=SC2016
in_fixture='
  (
    .. | select(tag == "!!map" and has("repository"))
       | select(.repository | tag == "!!str" and . != "")
       | select(path | map(tostring) | join(".") | test("(?i)image"))
       | [(.registry // "" | tostring), .repository] | map(select(. != "")) | join("/")
  ),
  (
    .. | select(tag == "!!str" and . != "")
       | select(path | .[-1] | tostring | test("(?i)image$"))
  )
'

render() { # render <archive> <chart> <case> [<fixture>]
  archive=$1
  chart=$2
  case_name=$3
  fixture=${4:-}
  manifest="$out/manifests/$chart/$case_name.yaml"
  mkdir -p "$out/manifests/$chart"
  set -- --kube-version "$kube_version"
  [ -z "$fixture" ] || set -- "$@" -f "$fixture"
  # stderr apart: helm warnings would corrupt the manifest stream.
  if helm template scan "$archive" "$@" >"$manifest" 2>"$err"; then
    printf '%s\t%s\tok\t\n' "$chart" "$case_name" >> "$out/renders.tsv"
  else
    rm -f "$manifest"
    reason=$(grep -m1 -i 'error' "$err" || head -n1 "$err")
    printf '%s\t%s\tfailed\t%s\n' "$chart" "$case_name" "$reason" >> "$out/renders.tsv"
    printf '%s: %s/%s did not render: %s\n' "$self" "$chart" "$case_name" "$reason" >&2
    return 0
  fi
  : > "$work/placeholders"
  [ -z "$fixture" ] || yq ea -N "$in_fixture" "$fixture" > "$work/placeholders"
  yq ea -N "$in_render" "$manifest" |
    awk -v src="$chart/$case_name" -v placeholders="$work/placeholders" "$awk_lib"'
      BEGIN { while ((getline line < placeholders) > 0) if (isref(line)) skip[repo(norm(line))] = 1 }
      !isref($0) { next }
      { r = norm($0); if (!(repo(r) in skip)) print r "\t" src }' >> "$work/rendered"
}

values() { # values <archive> <chart>
  rm -rf "$work/chart"
  mkdir -p "$work/chart"
  tar -xzf "$1" -C "$work/chart"
  # Every values.yaml of the archive, its subcharts' included, enabled or not;
  # an empty tag means its own chart's AppVersion.
  find "$work/chart" -name values.yaml | sort | while read -r file; do
    app_version=$(yq '.appVersion // ""' "$(dirname "$file")/Chart.yaml")
    yq -N "$in_values" "$file" |
      awk -v av="$app_version" -v src="$2/values" '{ print $0 "\t" av "\t" src }'
  done >> "$work/values"
}

for archive in "$@"; do
  chart=$(helm show chart "$archive" | yq '.name')
  render "$archive" "$chart" defaults
  for fixture in "$here/$chart"/ci/*-values.yaml; do
    [ -f "$fixture" ] || continue
    render "$archive" "$chart" "$(basename "$fixture" -values.yaml)" "$fixture"
  done
  values "$archive" "$chart"
done

# Values carry no rendered truth: a tag left empty becomes whatever the chart
# templates make of its AppVersion (a `v` prefix, a `-distroless` suffix). So
# a guessed tag only stands for a repository no render uses, and an ArmoniK
# component without a version takes the tag its rendered siblings carry.
awk -F '\t' "$awk_lib"'
  function add(r, src) {
    if (!isref(r)) return
    r = norm(r)
    if (!(r in sources)) { sources[r] = src; return }
    if (!index("," sources[r] ",", "," src ",")) sources[r] = sources[r] "," src
  }
  FNR == NR {
    add($1, $2)
    rendered[repo($1)] = 1
    if (substr($1, length(repo($1)) + 1, 1) == ":")
      tags[repo($1)] = tags[repo($1)] " " substr($1, length(repo($1)) + 2)
    next
  }
  $1 == "component" {
    component[$3] = $2
    if ($4 != "") add($3 ":" $4, $6)
    else pending[$3] = pending[$3] "," $6
    next
  }
  $1 == "ref" {
    if (index($2, "{{") == 0) add($2, $4)
    next
  }
  $1 == "map" {
    registry = $2; repository = $3; tag = $4; digest = $5; av = $6; src = $7
    gsub(/\{\{-? *\.Chart\.AppVersion *-?\}\}/, av, tag)
    if (index(registry repository tag digest, "{{")) next
    guessed = 0
    if (tag == "" && digest == "") { tag = av; guessed = 1 }
    if (tag == "" && digest == "") next
    r = (registry != "" ? registry "/" : "") repository (tag != "" ? ":" tag : "") (digest != "" ? "@" digest : "")
    if (guessed && repo(norm(r)) in rendered) next
    add(r, src)
  }
  END {
    for (r in pending) {
      if (r in rendered) continue
      for (sibling in tags) {
        if (component[sibling] != component[r]) continue
        n = split(tags[sibling], t, " ")
        m = split(pending[r], from, ",")
        for (i = 1; i <= n; i++) for (j = 2; j <= m; j++) add(r ":" t[i], from[j])
      }
    }
    for (r in sources) print r "\t" sources[r]
  }' "$work/rendered" "$work/values" | sort > "$out/images.tsv"

if ! grep -q '	ok	' "$out/renders.tsv"; then
  printf '%s: no chart rendered\n' "$self" >&2
  exit 1
fi
if [ ! -s "$out/images.tsv" ]; then
  printf '%s: the charts reference no image, which means the extraction broke\n' "$self" >&2
  exit 1
fi

printf '%s: %s render(s), %s failed, %s image(s), %s from values only, in %s\n' "$self" \
  "$(wc -l < "$out/renders.tsv" | tr -d ' ')" \
  "$(grep -c '	failed	' "$out/renders.tsv" || true)" \
  "$(wc -l < "$out/images.tsv" | tr -d ' ')" \
  "$(awk -F '\t' '{ n = split($2, s, ","); v = 1; for (i = 1; i <= n; i++) if (s[i] !~ /\/values$/) v = 0; c += v } END { print c + 0 }' "$out/images.tsv")" \
  "$out" >&2
