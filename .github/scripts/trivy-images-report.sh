#! /bin/sh

# Turns the trivy image reports of publish.yml's scan job into a job summary,
# a SARIF file for code scanning and a CSV file. Report-only: findings never
# fail it.
#
# Usage: trivy-images-report.sh <scan-dir> <summary-file> [<blob-url>]
#
# <blob-url> browses the repository at the scanned commit
# (https://github.com/<owner>/<repo>/blob/<sha>); owners link there when set.
#
# Reads, under <scan-dir>:
#   renders.tsv, images.tsv   charts/scan-inputs.sh
#   switches.tsv              charts/scan-inputs.sh -s <umbrella chart>; without
#                             it the report has no deployment tag
#   image-status.tsv          .github/scripts/trivy-images.sh
#   reports/images/<n>.json   trivy image report of images.tsv line <n>
# Writes the markdown summary to <summary-file>, a warning annotation to
# stdout when an image was not scanned, and under <scan-dir>:
#   sarif/images.sarif
#   reports/vulnerabilities.csv   every vulnerability, one row per image and
#                                 affected package
#
# SARIF_SEVERITY (default HIGH,CRITICAL) filters the SARIF file only, which
# code scanning rejects past 25,000 results: the CSV file keeps every
# severity.

set -eu

# shellcheck source=trivy-lib.sh
. "$(dirname "$0")/trivy-lib.sh"
report_init "$@"
mkdir -p "$scan/sarif" "$work/vulns" "$work/sarif"
: > "$work/scanned"
: > "$work/failed"
# The rows of an image's critical and high vulnerabilities in the summary,
# which GitHub drops whole past 1 MiB.
cap=30

# The report takes the umbrella chart's point of view: per image, whether it
# deploys it always, by default (opt-out, a value removing it) or on request
# (opt-in: a value, or a request to an operator), from switches.tsv. As <image>
# <label> <owners> <deployed> <off with> <on with> <status> <reason>, `-` for
# an empty field; the label is the image with its tags, the deployment tag
# showing the values switching the image when hovered.
switches="$scan/switches.tsv"
[ -f "$switches" ] || switches=/dev/null
paste "$scan/images.tsv" "$scan/image-status.tsv" | awk -F '\t' -v OFS='\t' '
  # A title attribute inside a table cell.
  function attr(s) {
    gsub(/&/, "\\&amp;", s); gsub(/"/, "\\&quot;", s); gsub(/</, "\\&lt;", s); gsub(/\|/, "\\&#124;", s)
    return s
  }
  FILENAME == ARGV[1] { def[$2] = $3; off[$2] = $4 == "" ? "-" : $4; on[$2] = $5 == "" ? "-" : $5; next }
  $1 != $4 { print "images.tsv and image-status.tsv disagree on line " FNR > "/dev/stderr"; exit 1 }
  {
    label = "<code>" $1 "</code>"
    uses = "," $2
    gsub(/,[^,]*\/test/, "", uses)
    if (uses == "") label = label " <sub>helm test</sub>"
    deployed = removed = with = "-"
    if (def[$1] == "on") { removed = off[$1]; deployed = removed == "-" ? "always" : "opt-out" }
    else if (def[$1] == "off") { with = on[$1]; deployed = "opt-in" }
    else if ($2 == "operator") {
      with = "a resource having its operator run it, see charts/operator-images.yaml"
      deployed = "opt-in"
    }
    if (deployed ~ /^opt/) {
      hover = deployed == "opt-out" ? "Removed by " removed : "Deployed with " with
      gsub(/ \| /, " or ", hover)
      label = label " <sub title=\"" attr(hover) "\">" deployed "</sub>"
    }
    print $1, label, $3, deployed, removed, with, $5, $6
  }' "$switches" - > "$work/images"

# One entry per vulnerability and affected package, the most severe first,
# then the fixable: trivy repeats a package found in several layers.
vulns_jq='[.Results[]? | .Vulnerabilities[]? | {
    id: .VulnerabilityID, pkg: .PkgName, path: (.PkgPath // ""),
    installed: (.InstalledVersion // ""), fixed: (.FixedVersion // ""),
    status: (.Status // ""), severity: (.Severity // "UNKNOWN"),
    title: (.Title // ""), url: (.PrimaryURL // "")}]
  | unique_by([.id, .pkg, .path, .installed])
  | sort_by([({CRITICAL: 0, HIGH: 1, MEDIUM: 2, LOW: 3}[.severity] // 4), (.fixed == ""), .id, .pkg])'

echo '"image","owners","deployed","off with","on with","severity","vulnerability","package","path","installed","fixed","status","title","url"' \
  > "$scan/reports/vulnerabilities.csv"

n=0
while IFS="$tab" read -r image label owners deployed removed with status reason; do
  n=$((n + 1))
  report="$scan/reports/images/$n.json"
  if [ "$status" != ok ] || [ ! -s "$report" ]; then
    printf '%s\t%s\t%s\t%s\n' "$label" "$owners" "$status" "${reason:-no report}" >> "$work/failed"
    continue
  fi
  jq -c "$vulns_jq" "$report" > "$work/vulns.json"
  # Found and fixable per severity, unknown folded into low.
  counts=$(jq -r '. as $v
    | [["CRITICAL"], ["HIGH"], ["MEDIUM"], ["LOW", "UNKNOWN"]]
    | map(. as $s | $v | map(select(.severity as $x | $s | index($x)))
          | [length, (map(select(.fixed != "")) | length)])
    | flatten | @tsv' "$work/vulns.json")
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$counts" "$n" "$label" "$owners" "$deployed" "$removed" "$with" \
    >> "$work/scanned"
  jq -r 'map(select(.severity == "CRITICAL" or .severity == "HIGH"))
    | .[] | [.severity, .id, .url, .pkg, .installed, .fixed, .title] | @tsv' \
    "$work/vulns.json" | uniq > "$work/vulns/$n.tsv"
  jq -r --arg image "$image" --arg owners "$owners" --arg deployed "$deployed" --arg off "$removed" --arg on "$with" \
    '($owners | split(",") | map(sub("=.*$"; "") | sub("@"; " ")) | join("; ")) as $names
     | .[] | [$image, $names, ($deployed, $off, $on | sub("^-$"; "")), .severity, .id, .pkg, .path, .installed, .fixed, .status, .title, .url] | @csv' \
    "$work/vulns.json" >> "$scan/reports/vulnerabilities.csv"

  # Every location is rewritten to name its image: trivy locates an OS package
  # at the image repository, without its registry, and any other package at its
  # path inside the image, which collides between images once merged. The tag
  # is left out so an alert survives an image bump.
  trivy convert --quiet --format sarif --severity "${SARIF_SEVERITY:-HIGH,CRITICAL}" \
    --output "$work/$n.sarif" "$report"
  jq --arg image "$image" '
    ($image | sub("@.*$"; "") | sub(":[^:/]*$"; "")) as $prefix
    | ($prefix | sub("^[^/]*[.:][^/]*/"; "")) as $repo
    | .runs[].results[]?.locations[]?.physicalLocation.artifactLocation.uri |= (
        if . == $repo or . == "library/" + $repo then $prefix else $prefix + "/" + . end)' \
    "$work/$n.sarif" > "$work/sarif/$n.sarif"
done < "$work/images"

# Code scanning rejects two runs of one tool under one category, so the runs
# are merged into one: rules deduplicated by id, ruleIndex dropped since it
# pointed into each run's own rules array. With no image scanned, an empty run
# still clears the alerts no longer found.
find "$work/sarif" -name '*.sarif' -exec cat {} + | jq -n '
  [inputs.runs[]] as $runs
  | {"$schema": "https://json.schemastore.org/sarif-2.1.0.json", version: "2.1.0", runs: [
      ($runs[0] // {tool: {driver: {name: "Trivy", informationUri: "https://github.com/aquasecurity/trivy"}}})
      | del(.properties)
      | .tool.driver.rules = ([$runs[].tool.driver.rules[]?] | unique_by(.id))
      | .results = [$runs[].results[]? | del(.ruleIndex)]]}' > "$scan/sarif/images.sarif"

# The most vulnerable first. Columns: found and fixable for critical, high,
# medium and low, then <n> <label> <owners> <deployed> <off with> <on with>.
sort -t "$tab" -k1,1nr -k3,3nr -k5,5nr -k7,7nr -k10,10 "$work/scanned" > "$work/sorted"
failed=$(wc -l < "$work/failed" | tr -d ' ')
[ "$failed" -eq 0 ] || echo "::warning title=$failed images not scanned::see the job summary"

# The values switching an image, settings as code and prose as it is.
# shellcheck disable=SC2016 # awk program, not shell
list_awk='
  function list(s) {
    if (s !~ /=|^ci\//) return s
    s = cell(s)
    gsub(/ \\\| /, "` or `", s)
    gsub(/ & /, "` \\& `", s)
    return "`" s "`"
  }'

{
  echo "## Trivy: images"
  echo ""
  printf 'Trivy %s, vulnerability database of %s. Report only: nothing here blocks a publication.\n' \
    "$(trivy --version 2>/dev/null | sed -n 's/^Version: //p')" \
    "$(trivy --version 2>/dev/null | sed -n 's/^ *UpdatedAt: //p' | head -n 1)"
  echo ""
  awk -F '\t' -v failed="$failed" '
    $1 > 0 { critical++ } $3 > 0 { high++ } { tags[$10 ~ /helm test/ ? "test" : $12]++ }
    END {
      printf "**%d images scanned** (%d always deployed, %d opt-out, %d opt-in, %d only for helm tests): ", \
        NR, tags["always"], tags["opt-out"], tags["opt-in"], tags["test"]
      printf ":red_circle: %d with critical vulnerabilities, :orange_circle: %d with high ones", critical, high
      print (failed ? "; :x: " failed " not scanned." : ".")
    }' "$work/sorted"
  echo ""
  echo "Counts: found (fixable), low including unknown. Every vulnerability is in \`vulnerabilities.csv\` of the \`trivy-reports\` artifact."
  echo ""
  printf 'No tag: always deployed. <sub>opt-out</sub>: deployed by default. <sub>opt-in</sub>: deployed on request. '
  # shellcheck disable=SC2016 # markdown backticks
  printf '<sub>helm test</sub>: run by `helm test` only. Hover a tag for the values that switch it.\n'
  echo ""
  echo "| Image | Owner | Critical | High | Medium | Low |"
  echo "|-|-|-:|-:|-:|-:|"
  # shellcheck disable=SC2016 # awk program, not shell
  awk -F '\t' -v blob="$blob" "$md_awk"'
    function count(n, f, s) { return n == 0 ? "-" : emoji(s) " " n " (" f ")" }
    {
    printf "| %s | %s | %s | %s | %s | %s |\n", $10, owners($11, blob),
      count($1, $2, "CRITICAL"), count($3, $4, "HIGH"), count($5, $6, "MEDIUM"), count($7, $8, "LOW")
  }' "$work/sorted"
  if [ "$failed" -gt 0 ]; then
    printf '\n### Not scanned\n\n'
    echo "Docker Hub answers a repository that does not exist as it does a private one: a missing Docker Hub image reads as denied."
    echo ""
    echo "| Image | Owner | Failure | Reason |"
    echo "|-|-|-|-|"
    awk -F '\t' -v blob="$blob" "$md_awk"'{
      printf "| %s | %s | :x: %s | %s |\n", $1, owners($2, blob), $3, cell($4) }' "$work/failed"
  fi
  printf '\n### Critical and high vulnerabilities\n\n'
  echo "The most severe first, then the fixable, at most $cap an image: the rest is in \`vulnerabilities.csv\`."
  echo ""
  awk -F '\t' -v cap="$cap" -v vulns="$work/vulns" "$md_awk$list_awk"'
    $1 + $3 > 0 {
      printf "<details><summary>%s %s: %d critical (%d fixable), %d high (%d fixable)</summary>\n\n", \
        emoji($1 ? "CRITICAL" : "HIGH"), $10, $1, $2, $3, $4
      if ($12 == "always") print "Always deployed.\n"
      else if ($12 == "opt-out") print "Deployed by default, removed by " list($13) ".\n"
      else if ($12 == "opt-in") print "Deployed with " list($14) ".\n"
      print "| | Vulnerability | Package | Installed | Fixed | Title |"
      print "|-|-|-|-|-|-|"
      file = vulns "/" $9 ".tsv"
      for (rows = 0; rows < cap && (getline line < file) > 0; rows++) {
        split(line, v, "\t")
        printf "| %s | [%s](%s) | `%s` | %s | %s | %s |\n", emoji(v[1]), v[2], v[3],
          cell(v[4]), cell(v[5]), (v[6] == "" ? "-" : cell(v[6])), cell(v[7])
      }
      for (more = 0; (getline line < file) > 0;) more++
      if (more) printf "| | ... and %d more in `vulnerabilities.csv` | | | | |\n", more
      close(file)
      print "\n</details>\n"
    }' "$work/sorted"
  if [ "$switches" != /dev/null ]; then
    # Every image, scanned or not.
    printf '<details><summary>What deploys each image</summary>\n\n'
    # shellcheck disable=SC2016 # markdown backticks
    {
      printf 'Measured on the renders of `%s`, one change at a time: ' "$(cut -f1 "$switches" | head -n 1)"
      printf 'each `enabled` or `deploy` default turned off, each default partition set to null, '
      printf 'each setting of a `ci/*-values.yaml` fixture applied alone or dropped from it. '
      printf 'Settings joined by `&` are needed together; a fixture file stands for all its settings, '
      printf 'when none could be tied to the image. '
      printf 'The control and compute planes count as always deployed, in this release or in their own.\n\n'
    }
    echo "| Image | Removed by | Deployed with |"
    echo "|-|-|-|"
    awk -F '\t' "$md_awk$list_awk"'
      { printf "| %s | %s | %s |\n", $2, list($5), list($6) }' "$work/images"
    printf '\n</details>\n'
  fi
  not_rendered
} >> "$summary"
