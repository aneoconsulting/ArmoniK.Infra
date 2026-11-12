#! /bin/sh

# Renders every packaged release-root chart, with its defaults and with each of
# its ci/*-values.yaml fixtures, and lists the container images of the renders,
# each with the charts whose templates hold it. Feeds trivy: the chart-checks
# job of .github/workflows/linter-helm.yml scans the renders for
# misconfigurations, the scan job of .github/workflows/publish.yml the images
# for vulnerabilities. Needs helm and mikefarah yq v4.
#
# An image a user can turn on is listed because a fixture turns it on:
# armonik/ci/optional-images-values.yaml and rabbitmq-values.yaml exist for
# that. An image tagged 0.0.0-test is a fixture's placeholder and is left out.
# operator-images.yaml adds the images an operator picks by itself.
#
# Usage: scan-inputs.sh [-d DIR] [-o DIR] [-k VERSION] [-s CHART [-j N]]
#   -d DIR      directory holding the packaged charts (default: the repo's dist/)
#   -o DIR      output directory, cleared first (default: the repo's scan/)
#   -k VERSION  Kubernetes version to render for
#   -s CHART    also measure the values deciding which images CHART deploys
#               (switches.tsv), a few hundred partial renders of it
#   -j N        renders run at once for -s (default: one per processor)
#
# Outputs, under the output directory:
#   manifests/<chart>/<case>/<n>.yml  document <n> of a render, one file each so
#                                     that a finding names its document
#   documents.tsv                     <chart>/<case>/<n>.yml <name>@<version>
#                                     <location> <alias-path>, the chart whose
#                                     template rendered the document
#   renders.tsv                       <chart> <case> <ok|failed> <first error line>
#   images.tsv                        <image> <uses> <owners>, both
#                                     comma-separated: a use is <chart>/<case>,
#                                     <chart>/<case>/test for a helm test pod,
#                                     or `operator`; an owner is
#                                     <name>@<version>=<location>=<alias-path>,
#                                     once a chart, by its longest path from a
#                                     release root
#   switches.tsv                      with -s: <chart> <image> <on|off> <off
#                                     with> <on with>, see "Switches" below
#
# A location is a path in this repository: the template of one of our charts,
# or, for a third-party chart, the line of our Chart.yaml that declares it or
# its nearest third-party ancestor, where its version is set
# (charts/armonik-operators/Chart.yaml#L33).
#
# A failed render is recorded, not fatal: a chart's bare defaults may be
# invalid on purpose (armonik-compute-plane has no partition), its fixtures
# then covering it. test/matrix.sh is what asserts which renders must succeed.
#
# Switches. Whether a release deploys an image hangs on its values, so -s
# measures it on renders of CHART, one change at a time:
#   - each `enabled` or `deploy` value that is true in CHART's computed
#     defaults is set to false, each entry of a `partitions` map to null, and
#     each setting of each fixture is applied alone over the defaults: a
#     change that removes an image turns it off, one that adds it turns it on;
#   - each setting of each fixture is dropped from it, with the maps it alone
#     fills: when that brings an image back to what the defaults do with it,
#     the fixture needs the setting to switch the image.
# <on|off> is what the defaults do. <off with> and <on with> list the
# alternatives, ` | `-separated, each a `<key>=<value>` setting or several
# joined by ` & ` that a fixture needs together; <off with> never holds
# turning the control or compute plane off, which run in this release or in
# their own. A render a change breaks proves nothing. A fixture's file
# (ci/<case>-values.yaml) stands for an image none of its settings could be
# tied to. Neither list catches a switch that is not a boolean, nor settings
# needed together that no fixture holds.
#
# The defaults, the fixtures and every `global` setting are rendered whole.
# Any other setting lies under one subchart, the deepest whose alias path
# prefixes its keys, and is rendered on a copy of CHART keeping every chart
# and helper but only the templates of that subchart and of those below it:
# values, conditions and helpers resolve as in CHART at a fraction of the
# cost, the images of the other charts being those of the whole render the
# change starts from. A render the copy breaks is retried whole, and a copy
# whose defaults miss an image CHART renders is not used. CHART's own settings
# are rendered whole when its templates name an image, skipped otherwise.

set -eu

here=$(cd "$(dirname "$0")" && pwd)
dist="$here/../dist"
out="$here/../scan"
# test/matrix.sh's default: the compute plane refuses anything below 1.29.
kube_version=1.31.0
switch_chart=
jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)
tab=$(printf '\t')

while getopts 'd:o:k:s:j:' opt; do
  case "$opt" in
    d) dist=$OPTARG ;;
    o) out=$OPTARG ;;
    k) kube_version=$OPTARG ;;
    s) switch_chart=$OPTARG ;;
    j) jobs=$OPTARG ;;
    *) printf 'Usage: %s [-d DIR] [-o DIR] [-k VERSION] [-s CHART [-j N]]\n' "$0" >&2; exit 2 ;;
  esac
done

# The Python yq wrapper shares the name and takes jq syntax.
if ! yq --version 2>/dev/null | grep -q mikefarah; then
  printf '%s: needs mikefarah yq v4 (https://github.com/mikefarah/yq)\n' "$0" >&2
  exit 2
fi
set -- "$dist"/*.tgz
if [ ! -f "$1" ]; then
  printf '%s: no packaged chart in %s; run package-charts.sh first\n' "$0" "$dist" >&2
  exit 2
fi

rm -rf "$out"
mkdir -p "$out/manifests"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
: > "$out/renders.tsv"
: > "$work/found"

# A workflow command: GitHub Actions shows it as an annotation.
warn() {
  printf '::warning title=%s::%s\n' "$1" "$2"
}

# One spelling per image: "docker.io/library/busybox", "busybox" and
# "busybox:latest" are one image. Anything that is not one reference (a
# template leftover, prose) is not an image, nor is a fixture's placeholder.
# shellcheck disable=SC2016,SC2089 # awk program, not shell
awk_lib='
  function norm(r,   n, p) {
    sub(/^(index\.)?docker\.io\//, "", r)
    sub(/^library\//, "", r)
    n = split(r, p, "/")
    if (index(r, "@") == 0 && index(p[n], ":") == 0) r = r ":latest"
    return r
  }
  function valid(r) { return r ~ /^[A-Za-z0-9][A-Za-z0-9._\/:@-]*$/ && r !~ /:0\.0\.0-test$/ }
  function add(list, item, sep) {
    return list == "" ? item : index(sep list sep, sep item sep) ? list : list sep item
  }
'

# Where an image hides in a render, as <document index> <image> <is a helm
# test>. CRDs are skipped: their schemas carry `image` keys that are
# documentation. Beyond the `image` fields of pod specs and of CRs (percona's
# PerconaServerMongoDB, the Prometheus CR), operators take the images of what
# they spawn as flags (cert-manager's ACME solver, prometheus-operator's config
# reloader) or env. A block marked `enabled: false` deploys nothing: a CR names
# the image of a component it leaves off (the PerconaServerMongoDB's backup).
# shellcheck disable=SC2016,SC2089 # yq expressions, not shell
in_render='
  select(.kind != "CustomResourceDefinition") |
  del(.. | select(tag == "!!map" and .enabled == false)) |
  (.metadata.annotations["helm.sh/hook"] // "" | tostring | test("(^|,) *test(-success)? *(,|$)")) as $test |
  (
    (.. | select(tag == "!!map") | (.image, .imageName) | select(tag == "!!str")),
    (.. | select(tag == "!!str") | select(test("^--(([a-z0-9-]*-)?image|prometheus-config-reloader)=")) | sub("^[^=]*=", "")),
    (.. | select(tag == "!!map" and has("name") and has("value")) | select(.name | test("(?i)image")) | .value | select(tag == "!!str"))
  )
  | [di, ., $test] | @tsv
'

# Every chart of an unpacked chart as <alias path> <name>@<version> <base>
# <directory>, the alias path starting with the root's name. Our charts are the directories of
# $here: the base of one is its own, a template path completing it, the base of
# a third-party chart is where its nearest ancestor of ours declares the
# dependency leading to it: the line its list item starts at, read from the
# text, yq's line numbers drifting after a head comment.
walk() { # walk <chart-dir> <alias-path> [<base of a third-party chart>]
  id=$(yq -N '[.name, .version] | join("@")' "$1/Chart.yaml")
  base=${3:-}
  [ ! -f "$here/${id%@*}/Chart.yaml" ] || base="charts/${id%@*}"
  printf '%s\t%s\t%s\t%s\n' "$2" "$id" "$base" "$1"
  yq -N '.dependencies[]? | [.name, (.alias // .name)] | @tsv' "$1/Chart.yaml" |
    while IFS="$tab" read -r name alias; do
      [ -d "$1/charts/$name" ] || continue
      below=$base
      [ "$base" = "${3:-}" ] || below="$base/Chart.yaml#L$(awk -v dep="$alias" '
        /^ *- / { start = NR }
        $0 ~ "^ *(- )?(name|alias): *[\"\047]?" dep "[\"\047]? *(#.*)?$" { line = start }
        END { print line }' "$here/../$base/Chart.yaml")"
      # Subshell: the recursion reuses this function's variables.
      (walk "$1/charts/$name" "$2/$alias" "$below")
    done
}

# helm heads every document with the template it comes from, whose path holds
# the alias path of the owning chart: armonik/charts/operators/charts/
# kube-prometheus/templates/x.yaml is templates/x.yaml of
# armonik/operators/kube-prometheus.
render() { # render <archive> <chart>/<case> [<fixture>]
  use=$2
  manifest="$work/render.yaml"
  # stderr apart: helm warnings would corrupt the manifest stream.
  if ! helm template scan "$1" --kube-version "$kube_version" ${3:+-f "$3"} >"$manifest" 2>"$work/stderr"; then
    reason=$(grep -m1 -i 'error' "$work/stderr" || head -n1 "$work/stderr")
    printf '%s\t%s\tfailed\t%s\n' "${use%/*}" "${use#*/}" "$reason" >> "$out/renders.tsv"
    # A fixture is a valid render by contract; defaults need not be.
    [ "${use#*/}" = defaults ] || warn "$use did not render" "$reason"
    return 0
  fi
  printf '%s\t%s\tok\t\n' "${use%/*}" "${use#*/}" >> "$out/renders.tsv"
  grep '^# Source: ' "$manifest" > "$work/sources"
  if [ "$(wc -l < "$work/sources")" -ne "$(grep -c '^---$' "$manifest")" ]; then
    printf '%s: %s: not one "# Source:" line per document\n' "$0" "$use" >&2
    exit 1
  fi
  mkdir -p "$out/manifests/$use"
  yq -s "\"$out/manifests/$use/\" + \$index" "$manifest"
  yq e -N "$in_render" "$manifest" |
    awk -F '\t' -v OFS='\t' -v use="$use" -v documents="$out/documents.tsv" "$awk_lib"'
      BEGIN { n = 0 }
      FILENAME == ARGV[1] { chart[$1] = $2; base[$1] = $3; next }
      FILENAME == ARGV[2] {
        path = substr($0, 11)
        template = substr(path, index(path, "/templates/"))
        path = substr(path, 1, length(path) - length(template))
        gsub(/\/charts\//, "/", path)
        location = base[path] (base[path] ~ /\/Chart\.yaml/ ? "" : template)
        owner[n] = chart[path] "=" location "=" path
        print use "/" n ".yml", chart[path], location, path >> documents
        n++
        next
      }
      valid($2) { print norm($2), use ($3 == "true" ? "/test" : ""), owner[$1] }
    ' "$work/graph" "$work/sources" - >> "$work/found"
}

# ---- Switches (-s), see the head comment.

# The probes of one values document, as <kind> <setting> <values as JSON>:
# $kind `flip` for the computed defaults, `set` for a fixture, which gives a
# `set` and a `drop` for each of its settings. A setting is a value outside a
# list, a list counting as one; it is dropped at the shortest key prefix
# holding no other setting.
# shellcheck disable=SC2016 # jq program, not shell
probes_jq='
  def settings: paths(type != "object" and . != null) | select(all(.[]; type == "string"));
  def probe($kind; $path; $value; $values):
    [$kind, ($path | join(".")) + "=" + ($value | if type == "string" then gsub("[\t\n]+"; " ") else tojson end),
     ($path | join("/")), ($values | tojson)] | join("\t");
  . as $doc
  | if $kind == "flip" then
      ((paths(. == true) | select(.[-1] == "enabled" or .[-1] == "deploy") | [., false]),
       (paths(. != null) | select(length > 1 and .[-2] == "partitions") | [., null]))
      # helm copies the globals into every subchart: they are set at the root.
      | . as [$path, $value]
      | select($path | all(.[]; type == "string") and (.[1:] | index("global") | not))
      | probe("flip"; $path; $value; {} | setpath($path; $value))
    else
      settings as $path
      | ($doc | getpath($path)) as $value
      | (first(range(1; $path | length) as $d | select([$doc | getpath($path[:$d]) | settings] | length == 1) | $d)
         // ($path | length)) as $depth
      | probe("set"; $path; $value; {} | setpath($path; $value)),
        probe("drop"; $path; $value; $doc | delpaths([$path[:$depth]]))
    end'

# One probe, as <probe file prefix> <chart> <scope> <base pairs>: the images of
# <chart> rendered over <prefix>.json, in <prefix>.images. A scoped probe
# renders the copy of the switch chart at <scope> and takes the images of every
# other chart from the whole render <base pairs> lists; a render the copy
# breaks is retried whole. A probe that does not render leaves no image list.
# shellcheck disable=SC2016 # run by the pool's shells
probe_sh='
  images() {
    helm template scan "$1" --kube-version "$kube_version" -f "$prefix.json" > "$prefix.yaml" 2>/dev/null &&
      yq e -N "$in_render" "$prefix.yaml" | awk -F "\t" "$probe_awk" > "$prefix.own"
  }
  prefix=$1
  if [ "$3" != - ] && images "$2"; then
    awk -F "\t" -v scope="$3" "\$2 != scope && index(\$2, scope \"/\") != 1 { print \$1 }" "$4" >> "$prefix.own"
  else
    images "$switch_archive" || rm -f "$prefix.own"
  fi
  [ ! -f "$prefix.own" ] || sort -u "$prefix.own" > "$prefix.images"
  rm -f "$prefix.yaml" "$prefix.own"'

# switches.tsv, from the images render() found in the switch chart's renders
# and those of each probe.
switches() {
  probes="$work/probes"
  mkdir "$probes" "$work/scopes"
  # Each whole render: its images, each with the alias path of its chart.
  awk -F '\t' -v OFS='\t' -v dir="$probes" -v chart="$switch_chart" '
    { split($2, use, "/"); split($3, owner, "=") }
    use[1] == chart { print $1, owner[3] > (dir "/" use[2] ".pairs") }' "$work/found"
  if [ ! -f "$probes/defaults.pairs" ]; then
    printf '%s: %s does not render with its defaults, no switches.tsv\n' "$0" "$switch_chart" >&2
    return 0
  fi
  for pairs in "$probes"/*.pairs; do
    cut -f1 "$pairs" | sort -u > "${pairs%.pairs}.images"
  done

  # The computed defaults, every subchart's under its alias, as a template of
  # an unpacked copy prints them.
  rm -rf "$work/chart"
  mkdir "$work/chart"
  tar -xzf "$switch_archive" -C "$work/chart"
  root="$work/chart/$switch_chart"
  walk "$root" "$switch_chart" > "$work/graph"
  echo '{{ toJson .Values }}' > "$root/templates/scan-values.yaml"
  {
    helm template scan "$root" --kube-version "$kube_version" -s templates/scan-values.yaml |
      tail -n 1 | jq -r --arg kind flip "$probes_jq" | sed "s/^/-$tab/"
    for fixture in "$here/$switch_chart"/ci/*-values.yaml; do
      [ ! -f "$fixture" ] ||
        yq -o=json "$fixture" | jq -r --arg kind set "$probes_jq" | sed "s/^/$(basename "$fixture" -values.yaml)$tab/"
    done
  } |
    # <probe> <kind> <fixture> <setting> <scope>, the values of probe <n> in
    # <n>.json. A setting several fixtures share, or one that is a flip, is
    # applied once. A setting can only change the images of the deepest chart
    # its keys lead into, its scope: `-`, the whole chart, for a global, which
    # any chart may read, and for a value of the switch chart itself, which is
    # not probed when its own templates name no image.
    awk -F '\t' -v OFS='\t' -v dir="$probes" -v root="$switch_chart" '
      FILENAME == ARGV[1] { if ($2 == root) own = 1; next }
      FILENAME == ARGV[2] { if ($1 != root) charts[substr($1, length(root) + 2)]; next }
      $2 != "drop" && seen[$3]++ { next }
      {
        scope = ""
        for (c in charts) if (index($4 "/", c "/") == 1 && length(c) > length(scope)) scope = c
        if (scope == "" && !own && $4 !~ /^global(\/|$)/) next
        file = dir "/" ++n ".json"
        print $5 > file
        close(file)
        print n, $2, $1, $3, (scope == "" ? "-" : root "/" scope)
      }' "$probes/defaults.pairs" "$work/graph" - > "$work/probes.tsv.all"
  # ARGV[1] above: the images the switch chart's own templates render.
  rm -f "$root/templates/scan-values.yaml"

  # The copy of a scope renders the templates of its chart and of the charts
  # below, and the helpers of all, so that values, conditions and helpers
  # resolve as in the switch chart. Hard links keep it cheap. The archive is
  # already filtered: read as a directory, the root .helmignore would apply to
  # every subchart.
  echo '{}' > "$probes/empty.json"
  cut -f5 "$work/probes.tsv.all" | sort -u | grep -vx -e - > "$work/scope-list" || :
  while IFS= read -r scope; do
    name=$(printf '%s' "$scope" | tr '/' '_')
    copy="$work/scopes/$name/$switch_chart"
    mkdir "$work/scopes/$name"
    cp -R -l "$root" "$copy" 2>/dev/null || { rm -rf "$copy"; cp -R "$root" "$copy"; }
    keep=$(awk -F '\t' -v scope="$scope" '$1 == scope { print $4 }' "$work/graph")
    keep="$copy${keep#"$root"}/"
    find "$copy" -name .helmignore -exec rm -f {} +
    find "$copy" -path '*/templates/*' -type f ! -name '_*' ! -name '*.tpl' ! -path "$keep*" -exec rm -f {} +
    ln "$probes/empty.json" "$probes/scope-$name.json"
  done < "$work/scope-list"

  # shellcheck disable=SC2016,SC2090 # programs passed whole, expanded by the pool's shells
  export switch_archive kube_version in_render probe_awk="$awk_lib"'valid($2) { print norm($2) }'
  pool() { # pool: one probe per input line
    xargs -P "$jobs" -L 1 sh -c "$probe_sh" sh
  }
  # A copy whose defaults do not render the images of the switch chart cannot
  # stand in for it: its probes are rendered whole.
  while IFS= read -r scope; do
    name=$(printf '%s' "$scope" | tr '/' '_')
    printf '%s %s %s %s\n' "$probes/scope-$name" "$work/scopes/$name/$switch_chart" "$scope" "$probes/defaults.pairs"
  done < "$work/scope-list" | pool
  while IFS="$tab" read -r n kind fixture setting scope; do
    name=$(printf '%s' "$scope" | tr '/' '_')
    if [ "$scope" != - ] && ! cmp -s "$probes/scope-$name.images" "$probes/defaults.images"; then
      scope=-
    fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$n" "$kind" "$fixture" "$setting" "$scope"
  done < "$work/probes.tsv.all" > "$work/probes.tsv"
  rm -f "$probes"/scope-*
  while IFS="$tab" read -r n kind fixture _ scope; do
    base=defaults
    [ "$kind" != drop ] || base=$fixture
    chart="$work/scopes/$(printf '%s' "$scope" | tr '/' '_')/$switch_chart"
    # A drop probes a fixture that rendered.
    [ ! -f "$probes/$base.pairs" ] || printf '%s %s %s %s\n' "$probes/$n" "$chart" "$scope" "$probes/$base.pairs"
  done < "$work/probes.tsv" | pool

  awk -F '\t' -v OFS='\t' -v chart="$switch_chart" "$awk_lib"'
    BEGIN { always["control-plane.enabled=false"]; always["compute-plane.enabled=false"] }
    FILENAME == ARGV[1] {
      kind[$1] = $2; fixture[$1] = $3; setting[$1] = $4; probes = $1
      if (!($3 in file)) { file[$3] = "ci/" $3 "-values.yaml"; fixtures[++count] = $3 }
      next
    }
    FNR == 1 { p = FILENAME; sub(/.*\//, "", p); sub(/\.images$/, "", p); ok[p] }
    { has[p, $1]; images[$1] }
    END {
      for (image in images) {
        on = ("defaults", image) in has
        # A change switches the image when it moves it away from its default. A
        # fixture that does needs the settings whose drop moves it back.
        alts = ""
        delete need
        for (p = 1; p <= probes; p++) {
          f = fixture[p]
          moved = ((p, image) in has) != on
          if (!(p in ok)) continue
          if (kind[p] == "drop" && !moved) need[f] = add(need[f], setting[p], " & ")
          if (kind[p] != "drop" && moved && !(on && setting[p] in always)) alts = add(alts, setting[p], " | ")
        }
        # Unless one of them switches the image alone, or nothing tells the
        # settings of the fixture apart: it then stands for itself.
        whole = ""
        for (i = 1; i <= count; i++) {
          f = fixtures[i]
          if (!(f in ok) || ((f, image) in has) == on) continue
          whole = add(whole, file[f], " | ")
          n = split(need[f], part, " & ")
          for (j = 1; j <= n; j++) if (index(" | " alts " | ", " | " part[j] " | ")) break
          if (n && j > n && index(alts, need[f]) == 0) alts = add(alts, need[f], " | ")
        }
        if (alts == "") alts = whole
        print chart, image, (on ? "on" OFS alts OFS : "off" OFS OFS alts)
      }
    }' "$work/probes.tsv" "$probes"/*.images | sort > "$out/switches.tsv"

  # The report takes the chart's point of view: its fixtures reach every image.
  cut -f1,2 "$out/images.tsv" | while IFS="$tab" read -r image uses; do
    [ "$uses" = operator ] || grep -q "$tab$image$tab" "$out/switches.tsv" ||
      warn "$switch_chart does not deploy $image" "only $uses renders it: extend the ci fixtures of $switch_chart"
  done
}

for archive in "$@"; do
  chart=$(helm show chart "$archive" | yq '.name')
  [ "$chart" != "$switch_chart" ] || switch_archive=$archive
  rm -rf "$work/chart"
  mkdir "$work/chart"
  tar -xzf "$archive" -C "$work/chart"
  walk "$work/chart/$chart" "$chart" > "$work/graph"
  render "$archive" "$chart/defaults"
  for fixture in "$here/$chart"/ci/*-values.yaml; do
    [ ! -f "$fixture" ] || render "$archive" "$chart/$(basename "$fixture" -values.yaml)" "$fixture"
  done
done

# One line per image. An operator's image takes the operator's owners.
yq -N '.[] | [.image, "operator", .operator] | @tsv' "$here/operator-images.yaml" |
  awk -F '\t' -v OFS='\t' "$awk_lib"'
    function owners(image,   n, c, i, list) {
      n = split(charts[image], c, ",")
      for (i = 1; i <= n; i++) list = add(list, entry[image, c[i]], ",")
      return list
    }
    { $1 = norm($1); uses[$1] = add(uses[$1], $2, ",") }
    $2 == "operator" { operator[$1] = norm($3); next }
    {
      split($3, f, "=")
      depth = split(f[3], segment, "/")
      if (!(($1, f[1]) in deepest)) charts[$1] = add(charts[$1], f[1], ",")
      if (depth > deepest[$1, f[1]]) { deepest[$1, f[1]] = depth; entry[$1, f[1]] = $3 }
    }
    END {
      for (image in uses) {
        list = owners((image in operator) ? operator[image] : image)
        print image, uses[image], (list == "" ? "unknown=charts/operator-images.yaml=" : list)
      }
    }
  ' "$work/found" - | sort > "$out/images.tsv"

if [ ! -s "$out/images.tsv" ]; then
  printf '%s: the charts reference no image, which means the extraction broke\n' "$0" >&2
  exit 1
fi
# What only a review can keep true: an operator bump may change the images the
# operator picks, and an image-map repository needs a fixture deploying it.
grep "${tab}unknown=" "$out/images.tsv" | while IFS="$tab" read -r image _; do
  warn "charts/operator-images.yaml is stale" "no render carries the operator of $image any more: review the entry"
done
yq -N '.global.armonik.imageComponents | keys | .[]' "$here/armonik-common/values.yaml" |
  while IFS= read -r repository; do
    grep -q "^$repository:" "$out/images.tsv" ||
      warn "$repository is not scanned" \
        "no fixture deploys this global.armonik.imageComponents entry: extend armonik/ci/optional-images-values.yaml"
  done

if [ -n "$switch_chart" ]; then
  if [ -z "${switch_archive:-}" ]; then
    printf '%s: -s %s: no such packaged chart in %s\n' "$0" "$switch_chart" "$dist" >&2
    exit 2
  fi
  switches
fi

printf '%s: %s render(s), %s image(s), in %s\n' "$0" \
  "$(wc -l < "$out/renders.tsv" | tr -d ' ')" "$(wc -l < "$out/images.tsv" | tr -d ' ')" "$out" >&2
