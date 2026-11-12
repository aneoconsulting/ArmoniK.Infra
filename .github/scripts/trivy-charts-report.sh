#! /bin/sh

# Turns the trivy config report of linter-helm.yml's chart-checks job into a job
# summary and a CSV file. Report-only: findings never fail it.
#
# Usage: trivy-charts-report.sh <scan-dir> <summary-file> [<blob-url>]
#
# <blob-url> browses the repository at the scanned commit
# (https://github.com/<owner>/<repo>/blob/<sha>); owners link there when set.
#
# Reads, under <scan-dir>:
#   renders.tsv, documents.tsv  charts/scan-inputs.sh
#   reports/charts.json         trivy config report of manifests/
# Writes the markdown summary to <summary-file> and
# <scan-dir>/reports/misconfigurations.csv, every failed check, one row per
# document.
#
# A finding is ours when the resource comes from one of our templates, which
# we can change, and third-party otherwise, which only the values we pass to
# that chart can change.

set -eu

# shellcheck source=trivy-lib.sh
. "$(dirname "$0")/trivy-lib.sh"
report_init "$@"
if [ ! -s "$scan/reports/charts.json" ]; then
  printf '%s: %s/reports/charts.json is missing or empty\n' "$0" "$scan" >&2
  exit 1
fi

# Every failed check with the document it fails on, which documents.tsv traces
# to its template: <scope> <check> <severity> <title> <resolution> <owner>
# <location> <document> <message> <url>, the CSV columns, then <alias-path>.
jq -r '.Results[]? | .Target as $t | .Misconfigurations[]? | select(.Status == "FAIL")
  | [$t, .ID, .Severity, .Title, .Resolution, .Message, .PrimaryURL] | map(. // "" | gsub("[\t\n]"; " ")) | @tsv' \
  "$scan/reports/charts.json" |
  awk -F '\t' -v OFS='\t' -v documents="$scan/documents.tsv" '
    BEGIN {
      while ((getline line < documents) > 0) {
        split(line, f, "\t")
        owner[f[1]] = f[2]; location[f[1]] = f[3]; path[f[1]] = f[4]
      }
    }
    {
      sub(/^.*manifests\//, "", $1)
      scope = location[$1] ~ /\/templates\// ? "ours" : "third-party"
      print scope, $2, $3, $4, $5, owner[$1], location[$1], $1, $6, $7, path[$1]
    }' > "$work/misconfigs"

{
  echo '"scope","check","severity","title","resolution","owner","location","document","message","url"'
  cut -f1-10 "$work/misconfigs" | sed "s/\"/\"\"/g; s/$tab/\",\"/g; s/^/\"/; s/\$/\"/"
} > "$scan/reports/misconfigurations.csv"

# One row per failing check of a scope, the most severe first, with every
# template (ours) or chart (third-party) it fails on.
checks_table() { # <scope> <heading>
  awk -F '\t' -v scope="$1" -v blob="$blob" "$md_awk"'
    $1 == scope {
      if (!($2 in row)) {
        rank[$2] = index("CHMLU", substr($3, 1, 1))
        row[$2] = sprintf("| %s | [%s](%s) | %s | %s |", emoji($3), $2, $10, cell($4), cell($5))
      }
      if (index("," where[$2], "," $6 "=" $7 "=") == 0)
        where[$2] = where[$2] (where[$2] == "" ? "" : ",") $6 "=" $7 "=" $11
    }
    END { for (check in row) print rank[check] "\t" check "\t" row[check] " " owners(where[check], blob) " |" }
  ' "$work/misconfigs" | sort -t "$tab" -k1,1n -k2,2 | cut -f3 > "$work/checks"
  printf '\n### %s: %d failing checks\n\n' "$2" "$(wc -l < "$work/checks")"
  [ ! -s "$work/checks" ] || printf '| | Check | Title | Resolution | Where |\n|-|-|-|-|-|\n'
  cat "$work/checks"
}

{
  echo "## Trivy: charts"
  echo ""
  printf "Trivy %s, Kubernetes checks on every render. Report only: no finding fails the job. %s\n" \
    "$(trivy --version 2>/dev/null | sed -n 's/^Version: //p')" \
    "Each failing resource is in \`misconfigurations.csv\` of the \`trivy-chart-reports\` artifact."
  checks_table ours "Our charts"
  checks_table third-party "Third-party charts"
  not_rendered
} >> "$summary"
