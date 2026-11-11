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
#   manifests/<chart>/<case>/<n>.yml  document <n> of a render, one file each so
#                                     that a finding names its document
#   documents.tsv                     <chart>/<case>/<n>.yml <name>@<version>
#                                     <location> <alias-path>, the chart whose
#                                     template rendered the document
#   renders.tsv                       <chart> <case> <ok|failed> <first error line>
#   images.tsv                        <image> <uses> <owners>, one line per
#                                     image, both comma-separated lists: uses
#                                     are <chart>/<case>, <chart>/<case>/test
#                                     when only a helm test pod runs it,
#                                     `image-map` or `operator`; owners are
#                                     <alias-path>=<name>@<version>=<location>,
#                                     the charts whose templates hold the image
#                                     by their path from the release root
#   stale.tsv                         <image> <operator> for each
#                                     operator-images.yaml entry whose operator
#                                     no render carries
#   switches.tsv                      with -s CHART: <chart> <image> <default>
#                                     <off> <on>, the values deciding whether
#                                     CHART deploys each image of its renders
#                                     (see "Switches" below)
#
# A location is a path in this repository: the template of one of our charts,
# or, for a third-party chart, the line of our Chart.yaml that declares it or
# its nearest third-party ancestor, where its version is set
# (charts/armonik-operators/Chart.yaml#L33). An image-map entry is located at
# its line of armonik-common's values.yaml.
#
# A failed render is recorded, not fatal: a chart's bare defaults may be
# invalid on purpose (armonik-compute-plane has no partition, armonik-ingress
# no URLs Secret), its fixtures then covering it. test/matrix.sh is what
# asserts which renders must succeed.
#
# Switches. Whether a release deploys an image hangs on its values, and a
# default can be off in production (Seq), so -s CHART measures it on CHART's
# renders, one value at a time:
#   - each `enabled` or `deploy` value that is true in CHART's coalesced
#     defaults is set to false on its own; the images that leave the render
#     are off with it;
#   - each setting of each fixture is dropped on its own; the images the
#     fixture adds that leave the render need it, the images the fixture
#     removes that come back are off with it, alongside the rest of that
#     fixture (another table storage for MongoDB, say).
# <default> is `on` when the defaults deploy the image, `off` otherwise. <off>
# lists the settings turning it off, comma-separated, `<key>=<value>`, with
# ` [<fixture>, ...]` when they need the rest of one of those fixtures; short
# of any setting, `[<fixture>, ...]` alone names the fixtures removing the
# image as a whole. <on> lists, ` | `-separated per fixture, the settings it
# takes, joined by ` & ` and followed by ` [<fixture>]`; a fixture whose
# settings each leave the image in its render appears bare, as `[<fixture>]`.
# A render a change breaks proves nothing and is left out. Neither list
# catches what takes two changes at once, nor a switch that is not a boolean.

set -eu

self="$0"
here=$(cd "$(dirname "$self")" && pwd)
dist="$here/../dist"
out="$here/../scan"
# test/matrix.sh's default: the compute plane refuses anything below 1.29.
kube_version=1.31.0
switch_chart=
switch_archive=
jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)
tab=$(printf '\t')

usage() {
  cat <<USAGE
Usage: $self [-d DIR] [-o DIR] [-k VERSION] [-s CHART [-j N]] [-h]

Renders the packaged charts and lists the images they can deploy.

  -d DIR      directory holding the packaged charts (default: the repo's dist/)
  -o DIR      output directory, cleared first (default: the repo's scan/)
  -k VERSION  Kubernetes version to render for (default: $kube_version)
  -s CHART    also measure the values deciding which images CHART deploys
              (switches.tsv), a few hundred renders
  -j N        renders run at once for -s (default: $jobs)
  -h          show this help
USAGE
}

while getopts ':d:o:k:s:j:h' opt; do
  case "$opt" in
    d) dist=$OPTARG ;;
    o) out=$OPTARG ;;
    k) kube_version=$OPTARG ;;
    s) switch_chart=$OPTARG ;;
    j) jobs=$OPTARG ;;
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
: > "$work/documents"
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
# A block marked `enabled: false` deploys nothing: a CR names the image of a
# component it leaves off (the PerconaServerMongoDB's pmm, backup and
# logcollector).
# shellcheck disable=SC2016 # yq expressions, not shell
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
  manifest="$work/render.yaml"
  documents="$out/manifests/$chart/$case_name"
  set -- --kube-version "$kube_version"
  [ -z "$fixture" ] || set -- "$@" -f "$fixture"
  # stderr apart: helm warnings would corrupt the manifest stream.
  if helm template scan "$archive" "$@" >"$manifest" 2>"$err"; then
    printf '%s\t%s\tok\t\n' "$chart" "$case_name" >> "$out/renders.tsv"
  else
    reason=$(grep -m1 -i 'error' "$err" || head -n1 "$err")
    printf '%s\t%s\tfailed\t%s\n' "$chart" "$case_name" "$reason" >> "$out/renders.tsv"
    printf '%s: %s/%s did not render: %s\n' "$self" "$chart" "$case_name" "$reason" >&2
    return 0
  fi

  # helm heads every document with the template it comes from, whose path
  # holds the alias path of the owning chart: armonik/charts/operators/charts/
  # kube-prometheus/templates/x.yaml is templates/x.yaml of
  # armonik/operators/kube-prometheus.
  grep '^# Source: ' "$manifest" | sed 's/^# Source: //' | awk '{
    i = index($0, "/templates/")
    path = substr($0, 1, i - 1)
    gsub(/\/charts\//, "/", path)
    print path "\t" substr($0, i + 1)
  }' > "$work/sources"
  if [ "$(wc -l < "$work/sources")" -ne "$(grep -c '^---$' "$manifest")" ]; then
    printf '%s: %s/%s: not one "# Source:" line per document, cannot attribute its images\n' \
      "$self" "$chart" "$case_name" >&2
    exit 1
  fi
  mkdir -p "$documents"
  yq -s "\"$documents/\" + \$index" "$manifest"
  awk -v prefix="$chart/$case_name/" '{ print prefix (NR - 1) ".yml\t" $0 }' "$work/sources" >> "$work/documents"

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

# Our charts, as `own <name> <dir>`, the line of each dependency they declare,
# as `dep <name> <dir> <alias> <line>`, and the line of each image-map entry,
# as `mapline <repository> <line>`: where a location points. Read from the
# text, yq's line numbers drifting after a head comment.
repo_charts() {
  for chart_yaml in "$here"/*/Chart.yaml; do
    dir="charts/$(basename "$(dirname "$chart_yaml")")"
    name=$(yq '.name' "$chart_yaml")
    printf 'own\t%s\t%s\n' "$name" "$dir"
    # An item starts at the list's own indentation; its keys sit two further.
    awk -v prefix="dep	$name	$dir	" '
      function flush() { if (start) print prefix (alias != "" ? alias : dep) "\t" start }
      function value(s) { sub(/^[^:]*:[ \t]*/, "", s); sub(/[ \t]+#.*$/, "", s); gsub(/["\047]/, "", s); return s }
      /^dependencies:/ { in_deps = 1; next }
      in_deps && /^[^ #-]/ { flush(); start = 0; in_deps = 0 }
      !in_deps { next }
      {
        line = $0
        match(line, /^ */)
        indent = RLENGTH
        if (item == "" && substr(line, indent + 1, 2) == "- ") item = indent
        if (indent == item && substr(line, indent + 1, 2) == "- ") {
          flush(); start = NR; dep = ""; alias = ""
          line = substr(line, 1, indent) "  " substr(line, indent + 3)
        }
        match(line, /^ */)
        if (RLENGTH != item + 2) next
        if (line ~ /^ *name:/) dep = value(line)
        if (line ~ /^ *alias:/) alias = value(line)
      }
      END { if (in_deps) flush() }' "$chart_yaml"
  done
  # shellcheck disable=SC2016
  yq -N '.global.armonik.imageComponents | keys | .[]' "$here/armonik-common/values.yaml" |
    while IFS= read -r key; do
      printf 'mapline\t%s\t%s\n' "$key" \
        "$(grep -n -m1 -F "  $key:" "$here/armonik-common/values.yaml" | cut -d: -f1)"
    done
}

# ---- Switches (-s), see the head comment.

# The images of a render, one per line, but for the repositories its fixture
# names.
images_of() { # images_of <manifest> <placeholders>
  yq e -N "$in_render" "$1" |
    awk -F '\t' -v placeholders="$2" "$awk_lib"'
      BEGIN { while ((getline line < placeholders) > 0) if (isref(line)) skip[repo(norm(line))] = 1 }
      isref($2) && !(repo(norm($2)) in skip) { print norm($2) }' |
    sort -u
}

# One render of the switch chart over extra values files: $probes/<name> lists
# its images, and is missing when the render fails.
probe() { # probe <name> <placeholders> [<values-file>...]
  name=$1
  placeholders=$2
  shift 2
  # Each values file becomes `-f <file>`, in order.
  i=$#
  while [ "$i" -gt 0 ]; do
    set -- "$@" -f "$1"
    shift
    i=$((i - 1))
  done
  if helm template scan "$switch_archive" --kube-version "$kube_version" "$@" \
       >"$probes/$name.yaml" 2>/dev/null; then
    images_of "$probes/$name.yaml" "$placeholders" > "$probes/$name.part"
    mv "$probes/$name.part" "$probes/$name"
  fi
  rm -f "$probes/$name.yaml"
}

# At most $jobs probes at once, a batch at a time.
spawn() { # spawn <probe arguments>
  probe "$@" &
  running=$((running + 1))
  if [ "$running" -ge "$jobs" ]; then
    wait
    running=0
  fi
}

tree() { # tree <chart-dir> <keys>: <depth> <chart-dir> <keys>, recursively, <keys> its dotted alias path
  printf '%s\t%s\t%s\n' "$(printf '%s\n' "$2" | awk -F. '{ print NF }')" "$1" "$2"
  yq -N '.dependencies[]? | [.name, (.alias // .name)] | @tsv' "$1/Chart.yaml" |
    while IFS="$tab" read -r name alias; do
      [ ! -d "$1/charts/$name" ] || (tree "$1/charts/$name" "${2:+$2.}$alias")
    done
}

# A chart's default values as helm coalesces them: every chart's values.yaml
# under its alias path, a parent's over its children's.
coalesce() { # coalesce <chart-dir>
  tree "$1" "" | sort -t "$tab" -k1,1nr > "$work/tree"
  i=0
  set --
  while IFS="$tab" read -r _ dir keys; do
    i=$((i + 1))
    [ -f "$dir/values.yaml" ] || continue
    layer="$work/layer-$i.yaml"
    if [ -z "$keys" ]; then
      cp "$dir/values.yaml" "$layer"
    else
      # shellcheck disable=SC2016
      KEYS=$keys VALUES=$dir/values.yaml \
        yq -n 'load(strenv(VALUES)) as $v | setpath(strenv(KEYS) | split("."); $v)' > "$layer"
    fi
    set -- "$@" "$layer"
  done < "$work/tree"
  # shellcheck disable=SC2016
  yq ea '. as $f ireduce ({}; . * $f)' "$@"
}

switches() { # switches <chart-dir>: switches.tsv
  probes="$work/probes"
  settings="$work/settings"
  mkdir -p "$probes" "$settings"
  : > "$work/meta"
  running=0
  printf 'base\tbase\t\t\n' >> "$work/meta"
  spawn base /dev/null

  # A global reaches every chart from the root's global, wherever a chart
  # declares it.
  coalesce "$1" > "$work/coalesced.yaml"
  yq -N '.. | select(tag == "!!bool" and . == true) | path
         | select(.[-1] == "enabled" or .[-1] == "deploy") | to_json(0)' "$work/coalesced.yaml" |
    sed 's/^\[\("[^"]*",\)*"global",/["global",/' | sort -u > "$work/flips"
  n=0
  while IFS= read -r keys; do
    n=$((n + 1))
    KEYS=$keys yq -n 'setpath(env(KEYS); false)' > "$settings/flip-$n.yaml"
    printf 'flip-%s\tflip\t\t%s=false\n' "$n" "$(KEYS=$keys yq -n 'env(KEYS) | join(".")')" >> "$work/meta"
    spawn "flip-$n" /dev/null "$settings/flip-$n.yaml"
  done < "$work/flips"

  for fixture in "$here/$switch_chart"/ci/*-values.yaml; do
    [ -f "$fixture" ] || continue
    case_name=$(basename "$fixture" -values.yaml)
    placeholders="$settings/$case_name.placeholders"
    yq ea -N "$in_fixture" "$fixture" > "$placeholders"
    printf 'fix-%s\tfixture\t%s\t\n' "$case_name" "$case_name" >> "$work/meta"
    spawn "fix-$case_name" "$placeholders" "$fixture"
    # Every setting but those inside a list, a list counting as one; a
    # multi-line value shows as one line.
    # shellcheck disable=SC2016
    TAB=$tab yq -N '.. | select(tag != "!!map" and tag != "!!null" and (parent | tag) == "!!map")
           | [(path | to_json(0)), (path | join(".")),
              ((select(tag == "!!seq") | to_json(0)) // tostring | sub("[\t\n]+"; " ") | sub(" $"; ""))]
           | join(strenv(TAB))' "$fixture" > "$work/leaves"
    n=0
    while IFS="$tab" read -r keys dotted value; do
      n=$((n + 1))
      KEYS=$keys yq 'delpaths([env(KEYS)])' "$fixture" > "$settings/$case_name-$n.yaml"
      printf 'drop-%s-%s\tdrop\t%s\t%s=%s\n' "$case_name" "$n" "$case_name" "$dotted" "$value" >> "$work/meta"
      spawn "drop-$case_name-$n" "$placeholders" "$settings/$case_name-$n.yaml"
    done < "$work/leaves"
  done
  wait

  if [ ! -f "$probes/base" ]; then
    printf '%s: %s does not render with its defaults, no switches.tsv\n' "$self" "$switch_chart" >&2
    return 0
  fi
  for result in "$probes"/*; do
    sed "s#^#$(basename "$result")	#" "$result"
  done > "$work/members"
  awk -F '\t' -v chart="$switch_chart" '
    function addto(list, item, sep) {
      if (list == "") return item
      return index(sep list sep, sep item sep) ? list : list sep item
    }
    FILENAME == ARGV[1] { order[++probes] = $1; kind[$1] = $2; fixture[$1] = $3; setting[$1] = $4; next }
    { ok[$1] = 1; has[$1, $2] = 1; images[$2] = 1 }
    END {
      for (image in images) {
        on = (("base", image) in has)
        bare = ""; tagged = ""
        delete need; delete with; delete removes
        for (i = 1; i <= probes; i++) {
          p = order[i]
          if (!(p in ok)) continue
          if (kind[p] == "flip" && on && !((p, image) in has)) bare = addto(bare, setting[p], ", ")
          if (kind[p] == "fixture" && on && !((p, image) in has)) removes[fixture[p]] = 0
          if (kind[p] != "drop" || !(("fix-" fixture[p]) in ok)) continue
          inf = (("fix-" fixture[p], image) in has)
          if (!on && inf && !((p, image) in has))
            need[fixture[p]] = addto(need[fixture[p]], setting[p], " & ")
          if (on && !inf && ((p, image) in has)) {
            removes[fixture[p]] = 1
            tagged = addto(tagged, setting[p], SUBSEP)
            with[setting[p]] = addto(with[setting[p]], fixture[p], ", ")
          }
        }
        # A setting that turns the image off alone needs no fixture; one that
        # takes the rest of several fixtures names them all. Short of any, the
        # fixtures removing the image whose settings each break the render
        # when dropped are the switch as a whole.
        off = bare
        n = split(tagged, list, SUBSEP)
        for (i = 1; i <= n; i++)
          if (!index(", " bare ", ", ", " list[i] ", "))
            off = addto(off, list[i] " [" with[list[i]] "]", ", ")
        whole = ""
        for (i = 1; i <= probes; i++) {
          p = order[i]
          if (kind[p] == "fixture" && (fixture[p] in removes) && !removes[fixture[p]])
            whole = addto(whole, fixture[p], ", ")
        }
        if (off == "" && whole != "") off = "[" whole "]"
        enable = ""
        if (!on)
          for (i = 1; i <= probes; i++) {
            p = order[i]
            if (kind[p] == "fixture" && ((p, image) in has))
              enable = addto(enable, (fixture[p] in need ? need[fixture[p]] " " : "") "[" fixture[p] "]", " | ")
          }
        print chart "\t" image "\t" (on ? "on" : "off") "\t" off "\t" enable
      }
    }' "$work/meta" "$work/members" | sort > "$out/switches.tsv"
}

for archive in "$@"; do
  chart=$(helm show chart "$archive" | yq '.name')
  [ "$chart" != "$switch_chart" ] || switch_archive=$archive
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
repo_charts > "$work/repo"

# The image map and operator-images.yaml only add images no render shows. A map
# component without a version takes the tag its rendered siblings carry, which
# is what the charts default it to (their AppVersion); an operator's image
# takes the operator's owners.
awk -F '\t' -v stale="$out/stale.tsv" -v documents="$out/documents.tsv" "$awk_lib"'
  function addlist(list, item) {
    if (item == "") return list
    if (list == "") return item
    return index("," list ",", "," item ",") ? list : list "," item
  }
  function chartname(path,   name) { name = owner[path]; sub(/@[^@]*$/, "", name); return name }
  # See "A location" above.
  function locate(path, template,   name, child, parent) {
    name = chartname(path)
    if (name in own) return own[name] "/" template
    for (child = path; match(child, /\/[^\/]*$/); child = parent) {
      parent = substr(child, 1, RSTART - 1)
      name = chartname(parent)
      if (name in own)
        return own[name] "/Chart.yaml" (((name, substr(child, RSTART + 1)) in depline) ? "#L" depline[name, substr(child, RSTART + 1)] : "")
    }
    return ""
  }
  function add(r, use, path, location) {
    r = norm(r)
    uses[r] = addlist(uses[r], use)
    owners[r] = addlist(owners[r], path "=" (path in owner ? owner[path] : "unknown") "=" location)
  }
  FILENAME == ARGV[1] { owner[$1] = $2; next }
  FILENAME == ARGV[2] {
    if ($1 == "own") own[$2] = $3
    else if ($1 == "dep") depline[$2, $4] = $5
    else if ($1 == "mapline") mapline[$2] = $3
    next
  }
  FILENAME == ARGV[3] { print $1 "\t" owner[$2] "\t" locate($2, $3) "\t" $2 > documents; next }
  FILENAME == ARGV[4] {
    add($1, $2, $3, locate($3, $4))
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
      location = own["armonik-common"] "/values.yaml" ((r in mapline) ? "#L" mapline[r] : "")
      for (i = 1; i <= n; i++) for (j = 1; j <= m; j++) add(r ":" t[i], "image-map", p[j], location)
    }
    for (image in operators) {
      op = norm(operators[image])
      if (!(op in uses)) { print image "\t" operators[image] > stale; continue }
      add(image, "operator", "", "")
      owners[norm(image)] = owners[op]
    }
    for (r in uses) print r "\t" uses[r] "\t" owners[r]
  }' "$work/graph" "$work/repo" "$work/documents" "$work/rendered" "$work/map" "$work/operators" |
  sort > "$out/images.tsv"
touch "$out/stale.tsv"

if [ -n "$switch_chart" ]; then
  if [ -z "$switch_archive" ]; then
    printf '%s: -s %s: no such packaged chart in %s\n' "$self" "$switch_chart" "$dist" >&2
    exit 2
  fi
  rm -rf "$work/chart"
  mkdir -p "$work/chart"
  tar -xzf "$switch_archive" -C "$work/chart"
  switches "$work/chart/$switch_chart"
fi

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
