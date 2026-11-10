#! /bin/sh

# Turns the trivy reports of publish.yml's scan job into a job summary,
# annotations and two SARIF files. Report-only: findings never fail it.
#
# Usage: trivy-report.sh <scan-dir> <summary-file>
#
# Reads, under <scan-dir> (charts/scan-inputs.sh writes the first two):
#   renders.tsv              <chart> <case> <ok|failed> <reason>
#   images.tsv               <image> <uses> <owners>
#   stale.tsv                <image> <operator>, operator-images.yaml entries to review
#   image-status.tsv         <image> <ok|failed> <reason>, in images.tsv order
#   reports/images/<n>.json  trivy image report of images.tsv line <n>
#   reports/charts.json      trivy config report of manifests/
# Writes the markdown summary to <summary-file>, annotations to stdout, and
# sarif/images.sarif and sarif/charts.sarif under <scan-dir>.
#
# SARIF_SEVERITY (default MEDIUM,HIGH,CRITICAL) filters the SARIF files only:
# the summary and the JSON reports keep every severity.

set -eu

if [ "$#" -ne 2 ]; then
  printf 'Usage: %s <scan-dir> <summary-file>\n' "$0" >&2
  exit 2
fi
scan=$1
summary=$2
sarif_severity=${SARIF_SEVERITY:-MEDIUM,HIGH,CRITICAL}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$scan/sarif"

# Images ArmoniK builds; only the report tells them apart.
origin() {
  case "$1" in
    dockerhubaneo/*) echo ArmoniK ;;
    *) echo "third party" ;;
  esac
}

# --- images ------------------------------------------------------------------

paste "$scan/images.tsv" "$scan/image-status.tsv" > "$work/images"
: > "$work/scanned"
: > "$work/failed"
: > "$work/sarif-list"
n=0
while IFS="$(printf '\t')" read -r image uses owners status_image status reason; do
  n=$((n + 1))
  if [ "$image" != "$status_image" ]; then
    printf '%s: images.tsv and image-status.tsv disagree on line %s (%s, %s)\n' \
      "$0" "$n" "$image" "$status_image" >&2
    exit 1
  fi
  # How the image comes in: rendered by a chart's defaults, only by some
  # fixtures (named), through ArmoniK's image map, or picked by an operator.
  use=$(printf '%s\n' "$uses" | tr ',' '\n' | awk -F / '
    $0 == "image-map" { m = 1; next }
    $0 == "operator" { o = 1; next }
    $2 == "defaults" { d = 1; next }
    !($2 in seen) { seen[$2] = 1; f = f (f == "" ? "" : ", ") $2 }
    END {
      if (d) print "default install"
      else if (f != "") print "fixture: " f
      else if (o) print "operator default"
      else if (m) print "image map"
    }')
  # Who holds it: the charts whose templates name it, seen from the umbrella
  # when the umbrella renders it, from the other release roots otherwise.
  charts=$(printf '%s\n' "$owners" | tr ',' '\n' | awk -F = '
    { path[NR] = $1; owner[NR] = $2; if ($1 == "armonik" || $1 ~ /^armonik\//) umbrella = 1 }
    END {
      for (i = 1; i <= NR; i++) {
        if (umbrella && path[i] != "armonik" && path[i] !~ /^armonik\//) continue
        o = owner[i]; sub(/@/, " ", o)
        p = path[i]; gsub(/\//, " > ", p)
        line = o " (" p ")"
        if (!(line in seen)) { seen[line] = 1; out = out (out == "" ? "" : "<br>") line }
      }
      print out
    }')
  report="$scan/reports/images/$n.json"

  if [ "$status" != ok ] || [ ! -s "$report" ]; then
    printf '%s\t%s\t%s\t%s\n' "$image" "$use" "$charts" "${reason:-no report}" >> "$work/failed"
    # Placeholders never get here (charts/scan-inputs.sh drops them), so an
    # unreadable image is one a user can deploy.
    printf '::warning title=trivy did not scan %s::%s\n' "$image" "${reason:-no report}"
    continue
  fi

  counts=$(jq -r '
    [.Results[]?.Vulnerabilities[]?] as $v
    | ["CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN"]
    | map(. as $s | $v | map(select(.Severity == $s)) | length)
      + [$v | map(select((.FixedVersion // "") != "")) | length]
    | @tsv' "$report")
  printf '%s\t%s\t%s\t%s\t%s\n' "$counts" "$image" "$(origin "$image")" "$use" "$charts" >> "$work/scanned"

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
      ]' $(cat "$work/sarif-list") > "$scan/sarif/images.sarif"
else
  echo "::warning title=trivy scanned no image::every image scan failed, see the job summary"
  # An empty run still clears alerts no longer found.
  jq -n '{
    "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
    version: "2.1.0",
    runs: [{tool: {driver: {name: "Trivy", informationUri: "https://github.com/aquasecurity/trivy", rules: []}}, results: []}]
  }' > "$scan/sarif/images.sarif"
fi

# --- charts ------------------------------------------------------------------

charts_report="$scan/reports/charts.json"
if [ -s "$charts_report" ]; then
  jq -r '
    .Results[]?
    | [.Misconfigurations[]? | select(.Status == "FAIL")] as $m
    | [.Target]
      + (["CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN"] | map(. as $s | $m | map(select(.Severity == $s)) | length))
    | @tsv' "$charts_report" | sort > "$work/charts"
  trivy convert --quiet --format sarif --severity "$sarif_severity" \
    --output "$scan/sarif/charts.sarif" "$charts_report"
else
  echo "::warning title=trivy did not scan the charts::reports/charts.json is missing or empty"
  : > "$work/charts"
fi

# --- summary -----------------------------------------------------------------

{
  echo "## Trivy"
  echo ""
  printf 'Trivy %s, vulnerability DB of %s. Report only: findings do not block the publication.\n' \
    "$(trivy --version 2>/dev/null | sed -n 's/^Version: //p' | head -n1)" \
    "$(trivy --version 2>/dev/null | sed -n 's/^ *UpdatedAt: //p' | head -n1)"
  echo ""
  printf '### Images: %s scanned, %s not scanned\n' \
    "$(wc -l < "$work/scanned" | tr -d ' ')" "$(wc -l < "$work/failed" | tr -d ' ')"
  echo ""
  echo "Every image the charts can deploy: rendered with a chart's defaults (\`default install\`), rendered only with the named \`ci/\` fixtures, which enable the optional components (an image a fixture names is a placeholder and left out), a worker or other image from ArmoniK's image map (\`image map\`), or an image an operator picks itself (\`operator default\`, from \`charts/operator-images.yaml\`). The owner is the chart whose templates name the image, with its path from the release root. Vulnerabilities count once per affected package."
  echo ""
  echo "| Image | Origin | Critical | High | Medium | Low | Unknown | Fixable | Use | Owner |"
  echo "|-|-|-:|-:|-:|-:|-:|-:|-|-|"
  sort -t "$(printf '\t')" -k1,1nr -k2,2nr -k3,3nr -k4,4nr -k7,7 "$work/scanned" |
    awk -F '\t' '{ printf "| `%s` | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n", $7, $8, $1, $2, $3, $4, $5, $6, $9, $10 }'
  if [ -s "$work/failed" ]; then
    echo ""
    echo "Not scanned:"
    echo ""
    echo "| Image | Use | Owner | Reason |"
    echo "|-|-|-|-|"
    # A pipe would end the table cell.
    sort "$work/failed" | sed 's/|/\\|/g' |
      awk -F '\t' '{ printf "| `%s` | %s | %s | %s |\n", $1, $2, $3, $4 }'
  fi
  echo ""
  echo "### Charts"
  echo ""
  echo "Failed misconfiguration checks per render (\`<chart>/<case>\`, \`defaults\` being the chart's own values)."
  echo ""
  echo "| Render | Critical | High | Medium | Low | Unknown |"
  echo "|-|-:|-:|-:|-:|-:|"
  awk -F '\t' '{ sub(/\.yaml$/, "", $1); printf "| `%s` | %s | %s | %s | %s | %s |\n", $1, $2, $3, $4, $5, $6 }' "$work/charts"
  if grep -q '	failed	' "$scan/renders.tsv"; then
    echo ""
    echo "Not rendered, so neither scanned nor searched for images (a chart's bare defaults may be invalid on purpose):"
    echo ""
    echo "| Render | Reason |"
    echo "|-|-|"
    awk -F '\t' '$3 == "failed" { gsub(/\|/, "\\|", $4); printf "| `%s/%s` | %s |\n", $1, $2, $4 }' "$scan/renders.tsv"
  fi
} >> "$summary"

while IFS="$(printf '\t')" read -r image operator; do
  printf '::warning title=charts/operator-images.yaml is stale::%s is listed as the default of %s, which no render carries any more: review it against the new operator\n' "$image" "$operator"
done < "$scan/stale.tsv"

# A fixture is a valid render by contract (test/matrix.sh); defaults need not be.
awk -F '\t' '$3 == "failed" && $2 != "defaults" {
  printf "::warning title=%s/%s did not render::%s\n", $1, $2, $4 }' "$scan/renders.tsv"
