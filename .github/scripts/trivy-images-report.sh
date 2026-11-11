#! /bin/sh

# Turns the trivy image reports of publish.yml's scan job into a job summary,
# annotations, a SARIF file for code scanning and a CSV file. Report-only:
# findings never fail it.
#
# Usage: trivy-images-report.sh <scan-dir> <summary-file> [<blob-url>]
#
# <blob-url> browses the repository at the scanned commit
# (https://github.com/<owner>/<repo>/blob/<sha>); owners link there when set.
#
# Reads, under <scan-dir>:
#   renders.tsv, images.tsv,    charts/scan-inputs.sh
#   stale.tsv, switches.tsv     (scan-inputs.sh -s <umbrella chart>)
#   image-status.tsv            .github/scripts/trivy-images.sh
#   reports/images/<n>.json     trivy image report of images.tsv line <n>
# Writes the markdown summary to <summary-file>, annotations to stdout, and
# under <scan-dir>:
#   sarif/images.sarif
#   reports/vulnerabilities.csv     every vulnerability, one row per image
#                                   and affected package
#
# SARIF_SEVERITY (default MEDIUM,HIGH,CRITICAL) filters the SARIF file only:
# the summary and the CSV file keep every severity. A SARIF file over code
# scanning's limits loses its lowest severities until it fits.

set -eu

# shellcheck source=trivy-lib.sh
. "$(dirname "$0")/trivy-lib.sh"
report_init "$@"
sarif_severity=${SARIF_SEVERITY:-MEDIUM,HIGH,CRITICAL}
us=$(printf '\037')
mkdir -p "$scan/sarif" "$scan/reports" "$work/vulns"
for f in warnings-images sarif-notes scanned failed sarif-list; do
  : > "$work/$f"
done

# Code scanning rejects a SARIF file past 25,000 results or rules per run, or
# 10 MB gzipped
# (https://docs.github.com/en/code-security/reference/code-scanning/sarif-files/sarif-support).
# Severities are dropped from the lowest up until the file fits; trivy tags
# each rule with its severity.
fit_sarif() { # <in> <out> <label>
  drop=
  for severity in "" UNKNOWN LOW MEDIUM HIGH; do
    if [ -n "$severity" ]; then
      # Only what SARIF_SEVERITY let in.
      case ",$sarif_severity," in
        *",$severity,"*) drop="$drop${drop:+,}$severity" ;;
        *) continue ;;
      esac
    fi
    jq --arg drop "$drop" '
      ($drop | split(",") | map({key: ., value: true}) | from_entries) as $drop
      | .runs |= map(
          ([.tool.driver.rules[]?
            | {key: .id,
               value: ([.properties.tags[]? | select(test("^(CRITICAL|HIGH|MEDIUM|LOW|UNKNOWN)$"))][0] // "UNKNOWN")}]
           | from_entries) as $severity
          | .results = [.results[]? | select($drop[$severity[.ruleId] // "UNKNOWN"] | not)]
          | ([.results[].ruleId] | map({key: ., value: true}) | from_entries) as $used
          | .tool.driver.rules = [.tool.driver.rules[]? | select($used[.id])])' "$1" > "$2"
    sizes=$(jq -r '[[.runs[] | .results | length], [.runs[] | .tool.driver.rules | length]] | map(max // 0) | @tsv' "$2")
    results=${sizes%"$tab"*}
    rules=${sizes#*"$tab"}
    bytes=$(gzip -c "$2" | wc -c | tr -d ' ')
    if [ "$results" -le 25000 ] && [ "$rules" -le 25000 ] && [ "$bytes" -le 10000000 ]; then
      [ -z "$drop" ] || {
        printf '%s: %s left out to fit the code scanning limits.\n' "$3" "$drop" >> "$work/sarif-notes"
        warn "code scanning gets no $drop $3 finding" "the SARIF file exceeds code scanning's limits with them; the job summary and the trivy-reports artifact keep them"
      }
      return 0
    fi
  done
  printf '%s: still over the code scanning limits with CRITICAL alone (%s results, %s rules, %s bytes gzipped); the upload may be rejected.\n' \
    "$3" "$results" "$rules" "$bytes" >> "$work/sarif-notes"
  warn "the $3 SARIF file exceeds code scanning's limits" "$results results, $rules rules, $bytes bytes gzipped, with CRITICAL alone"
}

# --- images ------------------------------------------------------------------

# The most severe first, then the fixable.
ranked_jq='def ranked: sort_by([
  ({CRITICAL: 0, HIGH: 1, MEDIUM: 2, LOW: 3}[.severity] // 4),
  (if .fixed == "" then 1 else 0 end), .id, .pkg]);'
# One entry per vulnerability and affected package: trivy repeats a package
# found in several layers or targets.
vulns_jq="$ranked_jq"'
  [.Results[]? | .Vulnerabilities[]? | {
    id: .VulnerabilityID, pkg: .PkgName, path: (.PkgPath // ""),
    installed: (.InstalledVersion // ""), fixed: (.FixedVersion // ""),
    status: (.Status // ""), severity: (.Severity // "UNKNOWN"),
    title: (.Title // ""), url: (.PrimaryURL // "")}]
  | unique_by([.id, .pkg, .path, .installed]) | ranked'

# The report takes the umbrella chart's point of view: which of its values
# deploy each image (charts/scan-inputs.sh -s), as <chart> <image>
# <on|off by default> <off with> <on with>.
# Without it (the umbrella failed to render with its defaults, or -s was not
# given), the report has no tag and no deployment notes.
switches=$scan/switches.tsv
switch_chart=$(awk -F '\t' 'NR == 1 { print $1 }' "$switches" 2>/dev/null || :)
if [ -z "$switch_chart" ]; then
  warn "no image tags" "switches.tsv is missing or empty: charts/scan-inputs.sh ran without -s, or the umbrella did not render with its defaults"
  switches=/dev/null
fi

# The lists of switches.tsv, in markdown or as plain text for a tag's hover
# text: ` | `-separated alternatives, each a `key=value` setting or several
# joined by ` & `.
# shellcheck disable=SC2016 # awk program, not shell
switch_awk='
  function code(s, md) { return md ? "`" cell(s) "`" : s }
  function lists(s, md,   n, part, i, m, set, j, item, out) {
    out = ""
    n = split(s, part, / \| /)
    for (i = 1; i <= n; i++) {
      m = split(part[i], set, / & /)
      item = ""
      for (j = 1; j <= m; j++) item = item (item == "" ? "" : " & ") code(set[j], md)
      out = out (out == "" ? "" : " or ") item
    }
    return out
  }
  function list(s) { return lists(s, 1) }
  # A title attribute inside a table cell.
  function attr(s) {
    gsub(/&/, "\\&amp;", s); gsub(/"/, "\\&quot;", s); gsub(/</, "\\&lt;", s)
    gsub(/>/, "\\&gt;", s); gsub(/\|/, "\\&#124;", s); gsub(/`/, "", s)
    return s
  }
  # The tags after an image name; hovering the deployment tag shows the
  # values switching the image.
  function tags(deployed, test, off, on, note,   out, t) {
    out = test ? " <sub>helm test</sub>" : ""
    if (deployed == "always" || deployed == "") return out
    if (deployed == "opt-out") t = "Removed by " lists(off, 0)
    else if (deployed == "opt-in")
      t = "Deployed with " (note != "" ? note : on == "" ? "values the analysis did not isolate" : lists(on, 0))
    else t = ""
    return out " <sub" (t == "" ? "" : " title=\"" attr(t) "\"") ">" deployed "</sub>"
  }
  # What the chart does with the image, as a sentence.
  function deployed(chart, def, off, on, note) {
    if (chart == "") return ""
    if (def == "on" && off == "") return "Always deployed by `" chart "`."
    if (def == "on") return "Deployed by default by `" chart "`; removed by " list(off) "."
    if (note != "") return "Not deployed by default by `" chart "`; deployed with " note "."
    if (def == "off")
      return "Not deployed by default by `" chart "`; " (on == "" ? "the analysis did not isolate the values deploying it" : "deployed with " list(on)) "."
    return "Not deployable through `" chart "`."
  }
'

printf '"image","owners","deployed","off with","on with","severity","vulnerability","package","path","installed","fixed","status","title","url"\n' \
  > "$scan/reports/vulnerabilities.csv"

# Per image, joined to its switches: whether the umbrella runs it only in helm
# test pods, and whether it deploys it always, opt-out (by default, a value
# removing it) or opt-in. The image map and the operators deploy what no
# render of the umbrella shows; an image that only another chart renders is
# out of its reach, which a fixture of the umbrella should fix.
# $work/deploys keeps <image> <default> <off with> <on with> <note> <tags>
# <sentence>; $work/images joins images.tsv, image-status.tsv and <test only>
# <deployed> <off with> <on with> <note> <tags>, with \037 between the fields
# so that `read` keeps the empty ones.
paste "$scan/images.tsv" "$scan/image-status.tsv" |
  awk -F '\t' -v OFS="$us" -v chart="$switch_chart" -v switches="$switches" \
    -v deploys="$work/deploys" -v warnings="$work/warnings-images" "$md_awk$switch_awk"'
    BEGIN {
      while ((getline line < switches) > 0) {
        split(line, f, "\t"); defs[f[2]] = f[3]; offs[f[2]] = f[4]; ons[f[2]] = f[5]
      }
    }
    {
      image = $1
      n = split($2, use, ",")
      t = d = 0
      for (i = 1; i <= n; i++) {
        split(use[i], part, "/")
        if (part[1] == chart) { if (part[3] == "test") t = 1; else d = 1 }
      }
      test = t && !d
      dep = note = ""
      if (chart == "") {}
      else if (defs[image] == "on") dep = offs[image] != "" ? "opt-out" : "always"
      else if (defs[image] == "off") dep = "opt-in"
      else if (index("," $2 ",", ",image-map,")) {
        dep = "opt-in"
        note = "a value naming it as an image (a compute-plane partition'"'"'s worker, say), resolved through `global.armonik.imageComponents`"
      } else if (index("," $2 ",", ",operator,")) {
        dep = "opt-in"
        note = "a resource having its operator run it, see `charts/operator-images.yaml`"
      } else {
        dep = "not in " chart
        printf "%s does not deploy %s\tonly another chart renders it (%s): extend the ci fixtures of %s so that the report covers it\n", \
          chart, image, $2, chart > warnings
      }
      t = tags(dep, test, offs[image], ons[image], note)
      print image "\t" defs[image] "\t" offs[image] "\t" ons[image] "\t" note "\t" t "\t" \
        deployed(chart, defs[image], offs[image], ons[image], note) > deploys
      print $1, $2, $3, $4, $5, $6, test, dep, offs[image], ons[image], note, t
    }' > "$work/images"
n=0
while IFS=$us read -r image _ owners status_image status reason test_only deployed off_with on_with note tags; do
  n=$((n + 1))
  if [ "$image" != "$status_image" ]; then
    printf '%s: images.tsv and image-status.tsv disagree on line %s (%s, %s)\n' \
      "$0" "$n" "$image" "$status_image" >&2
    exit 1
  fi
  cell=$(owners_cell "$owners" 0 charts)
  report="$scan/reports/images/$n.json"

  if [ "$status" = ok ] && [ ! -s "$report" ]; then
    status=error
    reason="no report"
  fi
  if [ "$status" != ok ]; then
    case "$status" in
      not-found) failure=":x: not found"; title="image not found: $image" ;;
      denied) failure=":x: pull denied"; title="image pull denied: $image" ;;
      rate-limited) failure=":hourglass: rate limited"; title="trivy did not scan $image (rate limited)" ;;
      *) failure=":warning: scan error"; title="trivy did not scan $image" ;;
    esac
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$image" "$cell" "$failure" "$reason" "$test_only" "$tags" >> "$work/failed"
    # Placeholders never get here (charts/scan-inputs.sh drops them), so an
    # unreadable image is one a user can deploy.
    printf '%s\t%s\n' "$title" "$reason" >> "$work/warnings-images"
    continue
  fi

  jq -c "$vulns_jq" "$report" > "$work/vulns.json"
  # Found and fixable per severity, unknown folded into low.
  counts=$(jq -r '. as $v
    | [["CRITICAL"], ["HIGH"], ["MEDIUM"], ["LOW", "UNKNOWN"]]
    | map(. as $s | $v | map(select(.severity as $x | $s | index($x)))
          | [length, (map(select(.fixed != "")) | length)])
    | flatten | @tsv' "$work/vulns.json")
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$counts" "$n" "$image" "$cell" "$test_only" "$deployed" "$tags" >> "$work/scanned"
  # Critical and high for the summary, one row per package version.
  jq -r "$ranked_jq"' map(select(.severity == "CRITICAL" or .severity == "HIGH"))
    | unique_by([.id, .pkg, .installed]) | ranked
    | .[] | [.severity, .id, .url, .pkg, .installed, .fixed, .title] | @tsv' \
    "$work/vulns.json" > "$work/vulns/$n.tsv"
  jq -r --arg image "$image" --arg owners "$(owners_cell "$owners" 0 names)" --arg deployed "$deployed" \
    --arg off "$off_with" --arg on "${note:-$on_with}" \
    '.[] | [$image, $owners, $deployed, $off, $on, .severity, .id, .pkg, .path,
      .installed, .fixed, .status, .title, .url] | @csv' \
    "$work/vulns.json" >> "$scan/reports/vulnerabilities.csv"

  # One SARIF run per image, rewritten so that every location names its image:
  # trivy locates an OS package at the image repository and any other package
  # at its path inside the image, which collides between images once merged.
  # The tag is left out so an alert survives an image bump.
  trivy convert --quiet --format sarif --severity "$sarif_severity" \
    --output "$work/$n.sarif" "$report"
  jq --arg image "$image" '
    ($image | sub("@.*$"; "") | sub(":[^:/]*$"; "")) as $prefix
    # What trivy names the repository: no registry host, library/ on Docker Hub.
    | ($prefix | split("/")) as $seg
    | (if ($seg | length) > 1 and ($seg[0] | test("[.:]|^localhost$")) then $seg[1:] else $seg end) as $seg
    | ((if ($seg | length) == 1 then ["library"] else [] end) + $seg | join("/")) as $repo
    | .runs[].results[]?.locations[]?.physicalLocation.artifactLocation.uri |= (
        if . == $repo then $prefix else $prefix + "/" + . end)' \
    "$work/$n.sarif" > "$work/$n.rewritten.sarif"
  printf '%s\n' "$work/$n.rewritten.sarif" >> "$work/sarif-list"
done < "$work/images"

# Code scanning rejects two runs of one tool under one category, so the runs
# are merged into one: rules deduplicated by id, ruleIndex dropped since it
# pointed into each run's own rules array.
if [ -s "$work/sarif-list" ]; then
  # shellcheck disable=SC2046 # one path per line, no blanks in mktemp paths
  jq -s '
    [.[].runs[]] as $runs
    | .[0]
    | .runs = [
        $runs[0]
        | del(.properties)
        | .tool.driver.rules = ([$runs[].tool.driver.rules[]?] | unique_by(.id))
        | .results = [$runs[].results[]? | del(.ruleIndex)]
      ]' $(cat "$work/sarif-list") > "$work/images.sarif"
  fit_sarif "$work/images.sarif" "$scan/sarif/images.sarif" image
else
  warn "trivy scanned no image" "every image scan failed, see the job summary"
  # An empty run still clears alerts no longer found.
  jq -n '{
    "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
    version: "2.1.0",
    runs: [{tool: {driver: {name: "Trivy", informationUri: "https://github.com/aquasecurity/trivy", rules: []}}, results: []}]
  }' > "$scan/sarif/images.sarif"
fi

# --- summary -----------------------------------------------------------------

images_failed=$(wc -l < "$work/failed" | tr -d ' ')
# Deployed images first, then those only helm test pods run.
sort -t "$tab" -k12,12n -k1,1nr -k3,3nr -k5,5nr -k7,7nr -k10,10 "$work/scanned" > "$work/scanned.sorted"

{
  echo "## Trivy: images"
  echo ""
  printf 'Trivy %s, vulnerability database of %s. Report only: nothing here blocks a publication.\n' \
    "$(trivy_info Version)" "$(trivy_info UpdatedAt)"
  echo ""
  awk -F '\t' -v failed="$images_failed" -v chart="$switch_chart" '
    $1 > 0 { critical++ } $3 > 0 { high++ } $2 + $4 > 0 { fixable++ }
    $12 { tests++; next } { kind[$13]++ }
    END {
      printf "**%d images scanned** (", NR
      if (chart != "") printf "%d always deployed, %d opt-out, %d opt-in", kind["always"], kind["opt-out"], kind["opt-in"]
      else printf "no tags: see the warnings"
      if (kind["not in " chart]) printf ", %d not in `%s`", kind["not in " chart], chart
      if (tests) printf ", %d only for helm tests", tests
      printf "): :red_circle: %d with critical vulnerabilities, :orange_circle: %d with high ones, %d with a fix for at least one of those", critical, high, fixable
      if (failed) printf "; :x: %d not scanned", failed
      print "."
    }' "$work/scanned"
  echo ""
  echo "Counts: found (fixable), low including unknown. Every vulnerability is in \`vulnerabilities.csv\` of the \`trivy-reports\` artifact."
  echo ""
  if [ -n "$switch_chart" ]; then
    echo "No tag: always deployed. <sub>opt-out</sub>: deployed by default. <sub>opt-in</sub>: deployed on request. <sub>helm test</sub>: run by \`helm test\` only. Hover a tag for the values that switch it."
  else
    echo "<sub>helm test</sub>: run by \`helm test\` only."
  fi
  echo ""
  echo "| Image | Owner | Critical | High | Medium | Low |"
  echo "|-|-|-:|-:|-:|-:|"
  awk -F '\t' "$md_awk"'{
    printf "| `%s`%s | %s | %s | %s | %s | %s |\n", $10, $14, $11,
      count($1, $2, "CRITICAL"), count($3, $4, "HIGH"), count($5, $6, "MEDIUM"), count($7, $8, "LOW")
  }' "$work/scanned.sorted"
  if [ -s "$work/failed" ]; then
    echo ""
    echo "### Not scanned"
    echo ""
    echo "Docker Hub answers a repository that does not exist as it does a private one: a missing Docker Hub image reads as pull denied."
    echo ""
    echo "| Image | Owner | Failure | Reason |"
    echo "|-|-|-|-|"
    sort -t "$tab" -k5,5n -k3,3 -k1,1 "$work/failed" |
      awk -F '\t' "$md_awk"'{ printf "| `%s`%s | %s | %s | %s |\n", $1, $6, $2, $3, cell($4) }'
  fi
} > "$work/head.md"

# The critical and high vulnerabilities of each image, the fixable first, in
# the order of the table above; at most <cap> rows an image, 0 for no cap.
details() { # <cap>
  awk -F '\t' -v cap="$1" -v vulns="$work/vulns" "$md_awk"'
    FILENAME == ARGV[1] { sentence[$1] = $7; next }
    $1 + $3 == 0 { next }
    {
      printf "<details><summary>%s <code>%s</code>%s: ", emoji($1 ? "CRITICAL" : "HIGH"), $10, $14
      if ($1) printf "%d critical (%d fixable)%s", $1, $2, ($3 ? ", " : "")
      if ($3) printf "%d high (%d fixable)", $3, $4
      print "</summary>\n"
      if (sentence[$10] != "") print sentence[$10] "\n"
      print "| | Vulnerability | Package | Installed | Fixed | Title |"
      print "|-|-|-|-|-|-|"
      file = vulns "/" $9 ".tsv"
      rows = more = 0
      while ((getline line < file) > 0) {
        if (cap && ++rows > cap) { more++; continue }
        split(line, v, "\t")
        id = v[3] == "" ? v[2] : "[" v[2] "](" v[3] ")"
        printf "| %s | %s | `%s` | %s | %s | %s |\n", emoji(v[1]), id, cell(v[4]), cell(v[5]), (v[6] == "" ? "-" : cell(v[6])), cell(v[7])
      }
      close(file)
      if (more) printf "| | and %d more in `vulnerabilities.csv` | | | | |\n", more
      print "\n</details>\n"
    }' "$work/deploys" "$work/scanned.sorted"
}

{
  if [ -n "$switch_chart" ]; then
    # Every image, scanned or not, folded.
    echo ""
    echo "<details><summary>What deploys each image</summary>"
    echo ""
    # shellcheck disable=SC2016 # markdown backticks
    printf 'Measured on the renders of `%s`, one change at a time from its defaults: each `enabled` or `deploy` value turned off, each default partition set to null, each setting of a `ci/*-values.yaml` fixture applied alone or dropped from it. Settings joined by `&` are needed together. The control and compute planes count as always deployed, in this release or in their own.\n' "$switch_chart"
    echo ""
    sort -t "$tab" -k1,1 "$work/deploys" |
      awk -F '\t' "$md_awk$switch_awk"'
        BEGIN { print "| Image | Removed by | Deployed with |"; print "|-|-|-|" }
        {
          printf "| `%s`%s | %s | %s |\n", $1, $6, ($3 != "" ? list($3) : "-"),
            ($5 != "" ? $5 : $2 == "off" ? ($4 == "" ? "not isolated" : list($4)) : "-")
        }'
    echo ""
    echo "</details>"
  fi
  not_rendered "Neither scanned nor searched for images"
  if [ -s "$work/sarif-notes" ]; then
    echo ""
    echo "### Code scanning"
    echo ""
    sed 's/^/- /' "$work/sarif-notes"
  fi
} > "$work/tail.md"

# A step summary over 1 MiB is dropped whole
# (https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary):
# the vulnerability lists shrink until it fits.
used=0
[ ! -f "$summary" ] || used=$(wc -c < "$summary")
budget=$((1000000 - used - $(wc -c < "$work/head.md") - $(wc -c < "$work/tail.md") - 200))
for cap in 0 100 50 20 10 5; do
  details "$cap" > "$work/details.md"
  [ "$(wc -c < "$work/details.md")" -gt "$budget" ] || break
done
if [ "$(wc -c < "$work/details.md")" -gt "$budget" ]; then
  echo "Too many to list within the summary size limit: see \`vulnerabilities.csv\` of the \`trivy-reports\` artifact." > "$work/details.md"
fi

{
  cat "$work/head.md"
  if [ -s "$work/details.md" ]; then
    echo ""
    echo "### Critical and high vulnerabilities"
    echo ""
    cat "$work/details.md"
  fi
  cat "$work/tail.md"
} >> "$summary"

# --- annotations ---------------------------------------------------------------

while IFS="$tab" read -r image operator; do
  warn "charts/operator-images.yaml is stale" "$image is listed as the default of $operator, which no render carries any more: review it against the new operator"
done < "$scan/stale.tsv"

warn_renders
annotate "$work/warnings" "$work/warnings-images"
