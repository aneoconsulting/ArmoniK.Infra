#! /bin/sh

# Turns the trivy config report of linter-helm.yml's chart-checks job into a job
# summary, annotations and a CSV file. Report-only: findings never fail it.
#
# Usage: trivy-charts-report.sh <scan-dir> <summary-file> [<blob-url>]
#
# <blob-url> browses the repository at the scanned commit
# (https://github.com/<owner>/<repo>/blob/<sha>); owners link there when set.
#
# Reads, under <scan-dir>:
#   renders.tsv, documents.tsv  charts/scan-inputs.sh
#   reports/charts.json         trivy config report of manifests/
# Writes the markdown summary to <summary-file>, annotations to stdout, and
# under <scan-dir>:
#   reports/misconfigurations.csv   every failed check, one row per document
#
# A finding is ours when the resource comes from one of our templates, which
# we can change, and third-party otherwise, which only the values we pass to
# that chart can change.

set -eu

# shellcheck source=trivy-lib.sh
. "$(dirname "$0")/trivy-lib.sh"
report_init "$@"
mkdir -p "$scan/reports"
: > "$work/misconfigs"

# Every failed check with the document it fails on, which documents.tsv
# traces to its template: <document> <check> <severity> <title> <url>
# <message> <resolution> <owner-entry> <render> <scope>.
charts_report="$scan/reports/charts.json"
if [ -s "$charts_report" ]; then
  jq -r '.Results[]? | .Target as $t | .Misconfigurations[]? | select(.Status == "FAIL")
    | [$t, .ID, (.Severity // "UNKNOWN"), (.Title // ""), (.PrimaryURL // "")]
      + ([.Message, .Resolution] | map(. // "" | gsub("[\t\n]"; " ")))
    | @tsv' "$charts_report" |
    awk -F '\t' -v documents="$scan/documents.tsv" '
      BEGIN {
        while ((getline line < documents) > 0) {
          split(line, f, "\t")
          entry[f[1]] = f[4] "=" f[2] "=" f[3]
          location[f[1]] = f[3]
        }
      }
      {
        doc = $1
        if (!(doc in entry)) sub(/^.*manifests\//, "", doc)
        render = doc; sub(/\/[^\/]*$/, "", render)
        scope = location[doc] ~ /^charts\/[^\/]+\/templates\// ? "ours" : "third-party"
        print $0 "\t" entry[doc] "\t" render "\t" scope
      }' > "$work/misconfigs"
else
  warn "trivy did not scan the charts" "reports/charts.json is missing or empty"
fi

printf '"scope","check","severity","title","resolution","owner","location","render","document","message","url"\n' \
  > "$scan/reports/misconfigurations.csv"
awk -F '\t' '
  function csv(s) { gsub(/"/, "\"\"", s); return "\"" s "\"" }
  {
    split($8, f, "=")
    owner = f[2]; sub(/@/, " ", owner)
    print csv($10) "," csv($2) "," csv($3) "," csv($4) "," csv($7) "," csv(owner) "," csv(f[3]) "," csv($9) "," csv($1) "," csv($6) "," csv($5)
  }' "$work/misconfigs" >> "$scan/reports/misconfigurations.csv"

# One row per scope and check: <scope> <severity rank> <places> <check>
# <severity> <title> <url> <resolution> <owner entries>, a place being a
# template, or a chart for a third-party one. An empty field reads `-`: `read`
# merges the tabs around an empty one.
awk -F '\t' "$md_awk"'
  function orDash(s) { return s == "" ? "-" : s }
  {
    k = $10 SUBSEP $2
    if (!(k in severity)) { severity[k] = $3; title[k] = $4; url[k] = $5; resolution[k] = $7 }
    split($8, f, "=")
    place = $10 == "ours" ? f[3] : f[2]
    if (!((k, place) in seen)) { seen[k, place] = 1; places[k]++ }
    if (!((k, $8) in seen)) { seen[k, $8] = 1; owners[k] = owners[k] (owners[k] == "" ? "" : ",") $8 }
  }
  END {
    for (k in severity) {
      split(k, key, SUBSEP)
      print key[1] "\t" rank(severity[k]) "\t" places[k] "\t" key[2] "\t" \
        orDash(severity[k]) "\t" orDash(title[k]) "\t" orDash(url[k]) "\t" orDash(resolution[k]) "\t" owners[k]
    }
  }' "$work/misconfigs" | sort -t "$tab" -k1,1 -k2,2n -k3,3nr -k4,4 > "$work/checks"

checks_table() { # <scope> <owner-mode> <owner-heading>
  echo "| | Check | Title | Resolution | $3 |"
  echo "|-|-|-|-|-|"
  while IFS="$tab" read -r scope _ _ check severity check_title url resolution owners; do
    [ "$scope" = "$1" ] || continue
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$severity" "$check" "$url" "$check_title" "$resolution" \
      "$(owners_cell "$owners" 5 "$2")"
  done < "$work/checks" |
    awk -F '\t' "$md_awk"'{
      id = $3 == "-" ? $2 : "[" $2 "](" $3 ")"
      printf "| %s | %s | %s | %s | %s |\n", emoji($1), id, cell($4), cell($5), $6
    }'
}

ours=$(awk -F '\t' '$1 == "ours" { n++ } END { print n + 0 }' "$work/checks")
theirs=$(awk -F '\t' '$1 == "third-party" { n++ } END { print n + 0 }' "$work/checks")

{
  echo "## Trivy: charts"
  echo ""
  printf "Trivy %s, Kubernetes checks on every render. Report only: no finding fails the job. Each failing resource is in \`misconfigurations.csv\` of the \`trivy-chart-reports\` artifact.\n" \
    "$(trivy_info Version)"
  echo ""
  printf '**%d checks fail on our charts, %d on third-party charts.**\n' "$ours" "$theirs"
  echo ""
  echo "### Our charts"
  echo ""
  if [ "$ours" -gt 0 ]; then
    checks_table ours "" Templates
  else
    echo "No check fails."
  fi
  echo ""
  echo "### Third-party charts"
  echo ""
  if [ "$theirs" -gt 0 ]; then
    checks_table third-party charts Charts
  else
    echo "No check fails."
  fi
  not_rendered "Not checked"
} >> "$summary"

warn_renders
annotate "$work/warnings"
