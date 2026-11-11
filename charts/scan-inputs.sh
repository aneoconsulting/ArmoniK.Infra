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
# renders, one change at a time:
#   - each `enabled` or `deploy` value that is true in CHART's coalesced
#     defaults is set to false on its own, each entry of a `partitions` map to
#     null, and each setting of each fixture is applied on its own over the
#     defaults: a change that removes an image turns it off, one that adds it
#     turns it on;
#   - each setting of each fixture is dropped from it, with the maps it alone
#     fills: the images the fixture adds that leave the render need it, the
#     images it removes that come back are off with it and the rest of the
#     fixture (another table storage for MongoDB, say).
# A setting several fixtures share is applied on its own once. The defaults,
# the fixtures and every `global` setting are rendered whole. Any other
# setting lies under one subchart, the deepest whose alias path prefixes its
# keys, and is rendered on a copy of CHART keeping that subchart's templates,
# every helper, and only the charts it may read values from (its ancestors,
# the libraries and the charts importing values into them): values,
# conditions and helpers still resolve as in CHART, the images of the other
# subcharts are those of the defaults, a render the copy breaks is retried
# whole, and a copy whose defaults do not render the images CHART's do is
# rendered whole instead. CHART's own settings are rendered whole when its
# templates name an image, skipped otherwise.
# <default> is `on` when the defaults deploy the image, `off` otherwise. <off>
# and <on> list the alternatives turning it off and on, ` | `-separated, each
# a `<key>=<value>` setting or several joined by ` & ` that a fixture needs
# together. A render a change breaks proves nothing and is left out. Neither
# list catches a switch that is not a boolean, nor settings needed together
# that no fixture holds.

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
probe_job=
tab=$(printf '\t')
sep=$(printf '\001')

usage() {
  cat <<USAGE
Usage: $self [-d DIR] [-o DIR] [-k VERSION] [-s CHART [-j N]] [-h]

Renders the packaged charts and lists the images they can deploy.

  -d DIR      directory holding the packaged charts (default: the repo's dist/)
  -o DIR      output directory, cleared first (default: the repo's scan/)
  -k VERSION  Kubernetes version to render for (default: $kube_version)
  -s CHART    also measure the values deciding which images CHART deploys
              (switches.tsv), a few hundred renders, most of one subchart alone
  -j N        renders run at once for -s (default: $jobs)
  -h          show this help
USAGE
}

while getopts ':d:o:k:s:j:hP:' opt; do
  case "$opt" in
    d) dist=$OPTARG ;;
    o) out=$OPTARG ;;
    k) kube_version=$OPTARG ;;
    s) switch_chart=$OPTARG ;;
    j) jobs=$OPTARG ;;
    h) usage; exit 0 ;;
    # Internal: one probe of switches(), the script re-entering itself.
    P) probe_job=$OPTARG ;;
    *)
      printf '%s: invalid option -- %s\n\n' "$self" "$OPTARG" >&2
      usage >&2
      exit 2
      ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "$probe_job" ]; then
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
fi

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

  : > "$work/placeholders"
  [ -z "$fixture" ] || yq ea -N "$in_fixture" "$fixture" > "$work/placeholders"
  images_of "$manifest" "$work/placeholders" "$work/sources" > "$work/images"
  if [ "$(wc -l < "$work/sources")" -ne "$(grep -c '^---$' "$manifest")" ]; then
    printf '%s: %s/%s: not one "# Source:" line per document, cannot attribute its images\n' \
      "$self" "$chart" "$case_name" >&2
    exit 1
  fi
  mkdir -p "$documents"
  yq -s "\"$documents/\" + \$index" "$manifest"
  awk -v prefix="$chart/$case_name/" '{ print prefix (NR - 1) ".yml\t" $0 }' "$work/sources" >> "$work/documents"
  awk -F '\t' -v OFS='\t' -v use="$chart/$case_name" \
    '{ print $1, use ($2 ? "/test" : ""), $3, $4 }' "$work/images" >> "$work/rendered"
}

# The images of a render but those its fixture names as placeholders, as
# <image> <1 for a test pod, else 0> <alias path> <template>. helm heads every
# document with the template it comes from, whose path holds the alias path of
# the owning chart: armonik/charts/operators/charts/kube-prometheus/templates/
# x.yaml is templates/x.yaml of armonik/operators/kube-prometheus. Those
# sources, one line per document, go to <sources>.
images_of() { # images_of <manifest> <placeholders> <sources>
  grep '^# Source: ' "$1" | sed 's/^# Source: //' | awk '{
    i = index($0, "/templates/")
    path = substr($0, 1, i - 1)
    gsub(/\/charts\//, "/", path)
    print path "\t" substr($0, i + 1)
  }' > "$3"
  yq e -N "$in_render" "$1" |
    awk -F '\t' -v sources="$3" -v placeholders="$2" "$awk_lib"'
      BEGIN {
        while ((getline line < sources) > 0) source[n++] = line
        while ((getline line < placeholders) > 0) if (isref(line)) skip[repo(norm(line))] = 1
      }
      isref($2) && !(repo(norm($2)) in skip) { print norm($2) "\t" ($3 == "true") "\t" source[$1] }'
}

# Every chart of a packaged chart as <alias path> <name>@<version> <directory>,
# the alias path starting with the root's name.
walk() { # walk <chart-dir> <alias-path>
  printf '%s\t%s\t%s\n' "$2" "$(yq -N '[.name, .version] | join("@")' "$1/Chart.yaml")" "$1"
  yq -N '.dependencies[]? | [.name, (.alias // .name)] | @tsv' "$1/Chart.yaml" |
    while IFS="$tab" read -r name alias; do
      # Subshell: the recursion reuses this function's variables.
      [ ! -d "$1/charts/$name" ] || (walk "$1/charts/$name" "$2/$alias")
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

# One render of the switch chart over extra values files: $probes/<name> lists
# its images, and is missing when the render fails. A full render (empty
# <scope>) also keeps $probes/<name>.pairs, from images_of. A scoped one
# renders the copy of the chart at <scope> (see scope) and takes the images of
# every other chart from the pairs of the full render <base>.
probe() { # probe <name> <placeholders> <scope> <base> [<values-file>...]
  name=$1
  placeholders=$2
  scope=$3
  base=$4
  shift 4
  # Each values file becomes `-f <file>`, in order.
  i=$#
  while [ "$i" -gt 0 ]; do
    set -- "$@" -f "$1"
    shift
    i=$((i - 1))
  done
  chart=$switch_archive
  if [ -n "$scope" ]; then
    [ -f "$probes/$base.pairs" ] || return 0
    chart=$(scope_copy "$scope")
  fi
  # A copy lacks the charts its scope does not need, so a render it breaks
  # is retried whole.
  if helm template scan "$chart" --kube-version "$kube_version" "$@" \
       >"$probes/$name.yaml" 2>/dev/null ||
     { [ -n "$scope" ] && [ "$name" != scope-check ] && scope= &&
       helm template scan "$switch_archive" --kube-version "$kube_version" "$@" \
         >"$probes/$name.yaml" 2>/dev/null; }; then
    images_of "$probes/$name.yaml" "$placeholders" "$probes/$name.sources" | cut -f1,3 | sort -u \
      > "$probes/$name.found"
    rm -f "$probes/$name.sources"
    if [ -z "$scope" ]; then
      mv "$probes/$name.found" "$probes/$name.pairs"
      cut -f1 "$probes/$name.pairs"
    else
      awk -F '\t' -v scope="$scope" '$2 != scope && index($2, scope "/") != 1 { print $1 }' \
        "$probes/$base.pairs"
      cut -f1 "$probes/$name.found"
      rm -f "$probes/$name.found"
    fi | sort -u > "$probes/$name.part"
    mv "$probes/$name.part" "$probes/$name"
  fi
  rm -f "$probes/$name.yaml"
}

# At most $jobs probes at once, a batch at a time.
# One probe per line, each argument ended by \001, so that the empty ones
# survive the split.
queue() { # queue <probe arguments>
  for arg; do printf '%s%s' "$arg" "$sep"; done >> "$work/jobs"
  printf '\n' >> "$work/jobs"
}
# Runs the queued probes, $jobs at a time. A probe that fails proves nothing,
# as a render that fails.
run_jobs() {
  [ -s "$work/jobs" ] || return 0
  tr '\n' '\000' < "$work/jobs" |
    SCAN_WORK=$work SCAN_ARCHIVE=$switch_archive SCAN_CHART=$switch_chart \
      xargs -0 -n 1 -P "$jobs" sh "$self" -k "$kube_version" -P ||
    printf '%s: some switch probes failed\n' "$self" >&2
  : > "$work/jobs"
}

# A chart's default values as helm coalesces them: every chart's values.yaml
# under its alias path, a parent's over its children's.
coalesce() { # coalesce <chart>, its charts in $work/tree as <depth> <directory> <dotted alias path>
  awk -F '\t' -v OFS='\t' '{
    keys = $1
    sub(/^[^\/]*\/?/, "", keys)
    gsub(/\//, ".", keys)
    print (keys == "" ? 0 : split(keys, part, ".")), $3, keys
  }' "$work/walk-$1" | sort -t "$tab" -k1,1nr > "$work/tree"
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

# Where a setting can change images, from its keys joined by \001: the alias
# path of the deepest chart its keys lead into, empty for a global, which any
# chart may read, and for a value of the switch chart itself when its own
# templates name an image, `-` when they name none.
scope_of() { # scope_of <joined keys>
  case "$1" in
    global|global"$sep"*) return 0 ;;
  esac
  awk -F '\t' -v keys="$1" -v sep="$sep" -v root="$switch_chart" -v whole="$root_images" '
    {
      k = $3
      gsub(/\./, sep, k)
      if (k != "" && (keys == k || index(keys, k sep) == 1) && length(k) > length(best)) best = k
    }
    END {
      if (best == "") { if (!whole) print "-"; exit }
      gsub(sep, "/", best)
      print root "/" best
    }' "$work/charts"
}

# The copy of the switch chart rendering only the chart at <scope> and its
# subcharts: every template elsewhere goes, helpers aside, so that helm still
# evaluates values, conditions and helpers in the switch chart's context.
# Hard links keep the copies cheap.
scope_copy() { # scope_copy <scope>: its chart directory
  printf '%s/%s/%s\n' "$work/scopes" "$(printf '%s' "$1" | tr '/' '_')" "$switch_chart"
}

# Prepares <scope> and prints it, or prints nothing when its copy renders the
# defaults differently from the full render, which then stands in.
# Removes from <dir> every dependency off the path to <rel> but those that can
# still reach it: a library, or one importing values into its parent. A
# sibling's values and conditions never reach a chart otherwise, its globals
# flowing down only. Each Chart.yaml is replaced, not edited, the copy being
# hard-linked to the archive.
trim() { # trim <dir> <rel>: rel being charts/<name>/[charts/<name>/...]
  rel=${2#charts/}
  [ "$rel" != "$2" ] || return 0
  on=${rel%%/*}
  yq '.dependencies[] | select(has("import-values") | not) | .name' "$1/Chart.yaml" |
    while IFS= read -r dep; do
      [ "$dep" != "$on" ] || continue
      [ "$(yq '.type // ""' "$1/charts/$dep/Chart.yaml" 2>/dev/null)" != library ] || continue
      rm -rf "${1:?}/charts/$dep"
      printf '%s\n' "$dep"
    done > "$1/trimmed"
  # shellcheck disable=SC2016
  DROP=$(cat "$1/trimmed") yq '.dependencies |= map(select(.name as $n | strenv(DROP) | split("\n") | all_c(. != $n)))' \
    "$1/Chart.yaml" > "$1/Chart.yaml.new"
  rm -f "$1/trimmed" "$1/Chart.lock"
  mv -f "$1/Chart.yaml.new" "$1/Chart.yaml"
  trim "$1/charts/$on" "${rel#"$on"/}"
}
scope() { # scope <scope>
  if ! grep -q "^$1	" "$work/scopes.tsv"; then
    copy=$(scope_copy "$1")
    mkdir -p "$(dirname "$copy")"
    cp -R -l "$work/chart/$switch_chart" "$copy" 2>/dev/null ||
      { rm -rf "$copy"; cp -R "$work/chart/$switch_chart" "$copy"; }
    dir=$(awk -F '\t' -v scope="$1" -v root="$switch_chart" '
      { k = $3; gsub(/\./, "/", k) } root "/" k == scope { print $2 }' "$work/charts")
    keep="$copy${dir#"$work/chart/$switch_chart"}/"
    # The archive is already filtered; read as a directory, the root's
    # .helmignore (tests/) would also apply to every subchart's files.
    find "$copy" -name .helmignore -exec rm -f {} +
    trim "$copy" "${keep#"$copy"/}"
    find "$copy" -path '*/templates/*' -type f ! -name '_*' ! -name '*.tpl' |
      while IFS= read -r file; do
        case "$file" in
          "$keep"*) ;;
          *) rm -f "$file" ;;
        esac
      done
    probe "scope-check" /dev/null "$1" base
    if [ -f "$probes/scope-check" ] && cmp -s "$probes/scope-check" "$probes/base"; then
      printf '%s\tok\n' "$1" >> "$work/scopes.tsv"
    else
      printf '%s: %s does not render alone as in %s, rendering %s whole for it\n' \
        "$self" "$1" "$switch_chart" "$switch_chart" >&2
      printf '%s\tfull\n' "$1" >> "$work/scopes.tsv"
    fi
    rm -f "$probes/scope-check"
  fi
  grep -q "^$1	ok\$" "$work/scopes.tsv" && printf '%s\n' "$1"
  return 0
}

switches() { # switches <chart-dir>: switches.tsv
  probes="$work/probes"
  settings="$work/settings"
  mkdir -p "$probes" "$settings"
  : > "$work/meta"
  : > "$work/scopes.tsv"
  : > "$work/seen"
  : > "$work/jobs"

  # The full renders first: the defaults and each fixture, which the scoped
  # probes complete.
  printf 'base\tbase\t\t\n' >> "$work/meta"
  queue base /dev/null "" ""
  for fixture in "$here/$switch_chart"/ci/*-values.yaml; do
    [ -f "$fixture" ] || continue
    case_name=$(basename "$fixture" -values.yaml)
    yq ea -N "$in_fixture" "$fixture" > "$settings/$case_name.placeholders"
    printf 'fix-%s\tfixture\t%s\t\n' "$case_name" "$case_name" >> "$work/meta"
    queue "fix-$case_name" "$settings/$case_name.placeholders" "" "" "$fixture"
  done
  run_jobs
  if [ ! -f "$probes/base" ]; then
    printf '%s: %s does not render with its defaults, no switches.tsv\n' "$self" "$switch_chart" >&2
    return 0
  fi

  root_images=$(awk -F '\t' -v root="$switch_chart" '$2 == root { print 1; exit }' "$probes/base.pairs")
  # A global reaches every chart from the root's global, wherever a chart
  # declares it.
  coalesce "$switch_chart" > "$work/coalesced.yaml"
  sort -t "$tab" -k3,3 "$work/tree" > "$work/charts"
  # shellcheck disable=SC2016
  { yq -N '.. | select(tag == "!!bool" and . == true) | path
           | select(.[-1] == "enabled" or .[-1] == "deploy") | to_json(0)' "$work/coalesced.yaml" |
      sed 's/^\[\("[^"]*",\)*"global",/["global",/' | sort -u | sed 's/^/false	/'
    # A partition set to null is removed: the compute-plane's own switch for
    # its workers.
    yq -N '.. | select(tag == "!!map" and (path | length) > 0 and (path | .[-1]) == "partitions") | .[]
           | select(tag != "!!null") | path | to_json(0)' "$work/coalesced.yaml" | sed 's/^/null	/'
  } > "$work/flips"
  n=0
  while IFS="$tab" read -r value keys; do
    n=$((n + 1))
    scope=$(scope_of "$(KEYS=$keys SEP=$sep yq -n 'env(KEYS) | join(strenv(SEP))')")
    [ "$scope" != - ] || continue
    [ -z "$scope" ] || scope=$(scope "$scope")
    KEYS=$keys VALUE=$value yq -n 'setpath(env(KEYS); env(VALUE))' > "$settings/flip-$n.yaml"
    printf 'flip-%s\tflip\t\t%s=%s\n' "$n" "$(KEYS=$keys yq -n 'env(KEYS) | join(".")')" "$value" >> "$work/meta"
    queue "flip-$n" /dev/null "$scope" base "$settings/flip-$n.yaml"
  done < "$work/flips"

  for fixture in "$here/$switch_chart"/ci/*-values.yaml; do
    [ -f "$fixture" ] || continue
    case_name=$(basename "$fixture" -values.yaml)
    placeholders="$settings/$case_name.placeholders"
    # Every setting outside a list, a list counting as one, a multi-line value
    # showing as one line; with its keys joined by \001 to find its chart and
    # the maps it alone fills.
    # shellcheck disable=SC2016
    TAB=$tab SEP=$sep yq -N '
           .. | select(tag != "!!map" and tag != "!!null" and (parent | tag) == "!!map"
                       and (path | all_c(tag != "!!int")))
           | [(path | to_json(0)), (path | join(strenv(SEP))), (path | join(".")),
              ((select(tag == "!!seq") | to_json(0)) // tostring | sub("[\t\n]+"; " ") | sub(" $"; "")),
              to_json(0)]
           | join(strenv(TAB))' "$fixture" |
      # The depth to drop at: the shortest key prefix no other setting shares.
      awk -F '\t' -v OFS='\t' '
        { line[NR] = $0; depth[NR] = n = split($2, part, "\001"); for (k = 1; k <= n; k++) keys[NR, k] = part[k] }
        END {
          for (i = 1; i <= NR; i++) {
            d = 1
            for (j = 1; j <= NR; j++) {
              if (j == i) continue
              k = 0
              while (k < depth[i] && k < depth[j] && keys[i, k + 1] == keys[j, k + 1]) k++
              if (k + 1 > d) d = k + 1
            }
            split(line[i], f, "\t")
            # The value last: `read` merges the tabs around an empty one.
            print f[1], f[2], (d < depth[i] ? d : depth[i]), f[3], f[5], f[4]
          }
        }' > "$work/leaves"
    n=0
    while IFS="$tab" read -r keys joined depth dotted json value; do
      n=$((n + 1))
      scope=$(scope_of "$joined")
      [ "$scope" != - ] || continue
      [ -z "$scope" ] || scope=$(scope "$scope")
      # shellcheck disable=SC2016
      KEYS=$keys DEPTH=$depth yq 'env(KEYS) as $k | delpaths([$k | .[0:env(DEPTH)]])' "$fixture" \
        > "$settings/drop-$case_name-$n.yaml"
      printf 'drop-%s-%s\tdrop\t%s\t%s=%s\n' "$case_name" "$n" "$case_name" "$dotted" "$value" >> "$work/meta"
      queue "drop-$case_name-$n" "$placeholders" "$scope" "fix-$case_name" "$settings/drop-$case_name-$n.yaml"
      # A setting several fixtures share is applied once.
      ! grep -qxF "$keys$tab$json" "$work/seen" || continue
      printf '%s\t%s\n' "$keys" "$json" >> "$work/seen"
      KEYS=$keys VALUE=$json yq -n 'setpath(env(KEYS); env(VALUE))' > "$settings/set-$case_name-$n.yaml"
      printf 'set-%s-%s\tset\t%s\t%s=%s\n' "$case_name" "$n" "$case_name" "$dotted" "$value" >> "$work/meta"
      queue "set-$case_name-$n" "$placeholders" "$scope" base "$settings/set-$case_name-$n.yaml"
    done < "$work/leaves"
  done
  run_jobs

  for result in "$probes"/*; do
    case "$result" in
      *.pairs) continue ;;
    esac
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
        # A change switches the image when it moves it away from its default.
        alts = ""
        delete changes; delete need
        for (i = 1; i <= probes; i++) {
          p = order[i]
          if (!(p in ok)) continue
          f = fixture[p]
          if (kind[p] == "fixture" && ((p, image) in has) != on) changes[f] = 1
          if ((kind[p] == "flip" || kind[p] == "set") && ((p, image) in has) != on)
            alts = addto(alts, setting[p], " | ")
          if (kind[p] == "drop" && ((p, image) in has) == on)
            need[f] = addto(need[f], setting[p], " & ")
        }
        # A fixture adds the settings it needs together, unless one of them
        # switches the image alone.
        for (i = 1; i <= probes; i++) {
          f = fixture[order[i]]
          if (kind[order[i]] != "fixture" || !(f in changes) || !(f in need)) continue
          n = split(need[f], part, " & ")
          for (j = 1; j <= n; j++) if (index(" | " alts " | ", " | " part[j] " | ")) break
          if (j > n) alts = addto(alts, need[f], " | ")
        }
        print chart "\t" image "\t" (on ? "on\t" alts "\t" : "off\t\t" alts)
      }
    }' "$work/meta" "$work/members" | sort > "$out/switches.tsv"
}

if [ -n "$probe_job" ]; then
  work=$SCAN_WORK
  probes="$work/probes"
  switch_archive=$SCAN_ARCHIVE
  switch_chart=$SCAN_CHART
  set -f
  IFS=$sep
  # shellcheck disable=SC2086
  set -- $probe_job
  unset IFS
  set +f
  probe "$@"
  exit 0
fi

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
  walk "$work/chart/$chart" "$chart" > "$work/walk-$chart"
  cut -f1,2 "$work/walk-$chart" >> "$work/graph"
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
