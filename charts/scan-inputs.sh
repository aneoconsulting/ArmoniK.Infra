#! /bin/sh

# Renders every packaged release-root chart, with its defaults and with each of
# its ci/*-values.yaml fixtures, and lists the container images the charts can
# deploy, each attributed to the chart that owns it. Feeds the trivy job of
# .github/workflows/publish.yml: the renders are scanned for
# misconfigurations, the images for vulnerabilities. Needs helm and mikefarah
# yq v4.
#
# The images come from three places:
#   - the renders. The images a user can turn on come in through fixtures
#     enabling them (armonik/ci/optional-images-values.yaml and
#     rabbitmq-values.yaml); an image a fixture names is a placeholder
#     (busybox:0.0.0-test), so a fixture's render contributes no image of a
#     repository that fixture names;
#   - ArmoniK's image map (global.armonik.imageComponents and versions), for
#     the images a user picks rather than enables, the workers chiefly;
#   - operator-images.yaml, for the images an operator picks by itself.
#
# Outputs, under OUT:
#   manifests/<chart>/<case>.yaml   one render per case
#   renders.tsv                     <chart> <case> <ok|failed> <first error line>
#   images.tsv                      <image> <uses> <owners>, one line per
#                                   image, both comma-separated lists: uses are
#                                   <chart>/<case>, <chart>/<case>/test when
#                                   only a helm test pod runs it, `image-map`
#                                   or `operator`;
#                                   owners are <alias-path>=<name>@<version>,
#                                   the charts whose templates hold the image,
#                                   by their path from the release root
#                                   (armonik/operators/kube-prometheus=
#                                   kube-prometheus-stack@92.21.2)
#   stale.tsv                       <image> <operator> for each operator-images.yaml
#                                   entry whose operator no render carries
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

Renders the packaged charts and lists the images they can deploy.

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
: > "$work/graph"
: > "$work/map"
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

# Where an image hides in a render, as <document index> <image> <is a helm
# test>. CRDs are
# skipped: their schemas carry `image` keys that are documentation. Beyond the
# `image` fields of pod specs and of CRs (percona's PerconaServerMongoDB, the
# Prometheus CR), operators take the images of what they spawn as flags
# (cert-manager's ACME solver, prometheus-operator's config reloader) or env.
# shellcheck disable=SC2016 # yq expressions, not shell
in_render='
  select(.kind != "CustomResourceDefinition") |
  (.metadata.annotations["helm.sh/hook"] // "" | tostring | test("(^|,) *test(-success)? *(,|$)")) as $test |
  (
    (.. | select(tag == "!!map") | (.image, .imageName) | select(tag == "!!str")),
    (.. | select(tag == "!!str") | select(test("^--(([a-z0-9-]*-)?image|prometheus-config-reloader)=")) | sub("^[^=]*=", "")),
    (.. | select(tag == "!!map" and has("name") and has("value")) | select(.name | test("(?i)image")) | .value | select(tag == "!!str"))
  )
  | [di, ., $test] | @tsv
'

# The repositories a fixture names.
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

  # helm heads every document with the template it comes from, whose path is
  # the alias path of the owning chart: armonik/charts/operators/charts/
  # kube-prometheus/templates/... is armonik/operators/kube-prometheus.
  grep '^# Source: ' "$manifest" |
    sed -e 's/^# Source: //' -e 's#/templates/.*##' -e 's#/charts/#/#g' > "$work/sources"
  if [ "$(wc -l < "$work/sources")" -ne "$(grep -c '^---$' "$manifest")" ]; then
    printf '%s: %s/%s: not one "# Source:" line per document, cannot attribute its images\n' \
      "$self" "$chart" "$case_name" >&2
    exit 1
  fi

  : > "$work/placeholders"
  [ -z "$fixture" ] || yq ea -N "$in_fixture" "$fixture" > "$work/placeholders"
  yq e -N "$in_render" "$manifest" |
    awk -F '\t' -v use="$chart/$case_name" -v sources="$work/sources" \
        -v placeholders="$work/placeholders" "$awk_lib"'
      BEGIN {
        while ((getline line < sources) > 0) source[n++] = line
        while ((getline line < placeholders) > 0) if (isref(line)) skip[repo(norm(line))] = 1
      }
      !isref($2) { next }
      {
        r = norm($2)
        if (!(repo(r) in skip)) print r "\t" use ($3 == "true" ? "/test" : "") "\t" source[$1]
      }' >> "$work/rendered"
}

graph() { # graph <chart-dir> <alias-path>: <alias-path> <name>@<version>, recursively
  yq -N '[.name, .version] | join("@")' "$1/Chart.yaml" | sed "s#^#$2	#"
  yq -N '.dependencies[]? | [.name, (.alias // .name)] | @tsv' "$1/Chart.yaml" |
    while IFS="$(printf '\t')" read -r name alias; do
      # Subshell: the recursion reuses this function's variables.
      [ ! -d "$1/charts/$name" ] || (graph "$1/charts/$name" "$2/$alias")
    done
}

image_map() { # image_map <chart-dir> <chart>: component <name> <repository> <version> <alias-path>
  common="$1/charts/armonik-common"
  [ -d "$common" ] || return 0
  # The root's own global.armonik over armonik-common's, as import-values does.
  # shellcheck disable=SC2016
  yq ea -N '
    . as $f ireduce ({}; . * $f) | .global.armonik as $a
    | ($a.versions // {}) as $v
    | ($a.imageComponents // {}) | to_entries | .[]
    | .value as $c
    | ["component", $c, .key, ($v[$c] // "" | tostring)] | @tsv' \
    "$common/values.yaml" "$1/values.yaml" | sed "s#\$#	$2/armonik-common#"
}

for archive in "$@"; do
  chart=$(helm show chart "$archive" | yq '.name')
  render "$archive" "$chart" defaults
  for fixture in "$here/$chart"/ci/*-values.yaml; do
    [ -f "$fixture" ] || continue
    render "$archive" "$chart" "$(basename "$fixture" -values.yaml)" "$fixture"
  done
  rm -rf "$work/chart"
  mkdir -p "$work/chart"
  tar -xzf "$archive" -C "$work/chart"
  graph "$work/chart/$chart" "$chart" >> "$work/graph"
  image_map "$work/chart/$chart" "$chart" >> "$work/map"
done

yq -N '.[] | ["operator", .image, .operator] | @tsv' "$here/operator-images.yaml" > "$work/operators"

# The image map and operator-images.yaml only add images no render shows. A map
# component without a version takes the tag its rendered siblings carry, which
# is what the charts default it to (their AppVersion); an operator's image
# takes the operator's owners.
awk -F '\t' -v stale="$out/stale.tsv" "$awk_lib"'
  function addlist(list, item) {
    if (item == "") return list
    if (list == "") return item
    return index("," list ",", "," item ",") ? list : list "," item
  }
  function add(r, use, path) {
    r = norm(r)
    uses[r] = addlist(uses[r], use)
    owners[r] = addlist(owners[r], path "=" (path in owner ? owner[path] : "unknown"))
  }
  FILENAME == ARGV[1] { owner[$1] = $2; next }
  FILENAME == ARGV[2] {
    add($1, $2, $3)
    rendered[repo($1)] = 1
    if (substr($1, length(repo($1)) + 1, 1) == ":")
      tags[repo($1)] = addlist(tags[repo($1)], substr($1, length(repo($1)) + 2))
    next
  }
  $1 == "component" { component[$3] = $2; version[$3] = $4; mapped[$3] = addlist(mapped[$3], $5); next }
  $1 == "operator" { operators[$2] = $3; next }
  END {
    for (r in mapped) {
      if (r in rendered) continue
      list = version[r]
      if (list == "")
        for (sibling in tags)
          if (component[sibling] == component[r]) list = addlist(list, tags[sibling])
      n = split(list, t, ",")
      m = split(mapped[r], p, ",")
      for (i = 1; i <= n; i++) for (j = 1; j <= m; j++) add(r ":" t[i], "image-map", p[j])
    }
    for (image in operators) {
      op = norm(operators[image])
      if (!(op in uses)) { print image "\t" operators[image] > stale; continue }
      add(image, "operator", "")
      owners[norm(image)] = owners[op]
    }
    for (r in uses) print r "\t" uses[r] "\t" owners[r]
  }' "$work/graph" "$work/rendered" "$work/map" "$work/operators" | sort > "$out/images.tsv"
touch "$out/stale.tsv"

if ! grep -q '	ok	' "$out/renders.tsv"; then
  printf '%s: no chart rendered\n' "$self" >&2
  exit 1
fi
if [ ! -s "$out/images.tsv" ]; then
  printf '%s: the charts reference no image, which means the extraction broke\n' "$self" >&2
  exit 1
fi
while IFS="$(printf '\t')" read -r image operator; do
  printf '%s: operator-images.yaml lists %s as the default of %s, which no render carries any more: review it\n' \
    "$self" "$image" "$operator" >&2
done < "$out/stale.tsv"

printf '%s: %s render(s), %s failed, %s image(s), in %s\n' "$self" \
  "$(wc -l < "$out/renders.tsv" | tr -d ' ')" \
  "$(grep -c '	failed	' "$out/renders.tsv" || true)" \
  "$(wc -l < "$out/images.tsv" | tr -d ' ')" \
  "$out" >&2
