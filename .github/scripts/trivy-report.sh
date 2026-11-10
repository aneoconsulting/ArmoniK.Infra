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
#   image-status.tsv         <image> <status> <reason>, in images.tsv order
#                            (.github/scripts/trivy-images.sh)
#   reports/images/<n>.json  trivy image report of images.tsv line <n>
#   reports/charts.json      trivy config report of manifests/
# Writes the markdown summary to <summary-file>, annotations to stdout, and
# sarif/images.sarif and sarif/charts.sarif under <scan-dir>.
#
# SARIF_SEVERITY (default MEDIUM,HIGH,CRITICAL) filters the SARIF files only:
# the summary and the JSON reports keep every severity. A SARIF file over
# code scanning's limits loses its lowest severities until it fits.

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
: > "$work/warnings"
: > "$work/warnings-images"
: > "$work/sarif-notes"

# Annotations are capped at 10 warnings per step
# (https://github.com/actions/toolkit/blob/main/docs/problem-matchers.md), so
# they are collected and emitted at the end, the run-wide ones first.
warn() { # <title> <message>
  printf '%s\t%s\n' "$1" "$2" >> "$work/warnings"
}

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
    results=$(jq '[.runs[] | .results | length] | max // 0' "$2")
    rules=$(jq '[.runs[] | .tool.driver.rules | length] | max // 0' "$2")
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
  # fixtures (named), through ArmoniK's image map, or picked by an operator;
  # and apart, when a helm test pod runs it, unless a default install
  # deploys it anyway.
  use=$(printf '%s\n' "$uses" | tr ',' '\n' | awk -F / '
    function label(d, f) { return d ? "default install" : f != "" ? "fixture: " f : "" }
    $0 == "image-map" { m = 1; next }
    $0 == "operator" { o = 1; next }
    $3 == "test" {
      if ($2 == "defaults") td = 1
      else if (!(($2) in tseen)) { tseen[$2] = 1; tf = tf (tf == "" ? "" : ", ") $2 }
      next
    }
    $2 == "defaults" { d = 1; next }
    !($2 in seen) { seen[$2] = 1; f = f (f == "" ? "" : ", ") $2 }
    END {
      out = label(d, f)
      if (out == "" && o) out = "operator default"
      if (out == "" && m) out = "image map"
      if (!d && (td || tf != "")) out = out (out == "" ? "" : "<br>") "helm test, " label(td, tf)
      print out
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

  if [ "$status" = ok ] && [ ! -s "$report" ]; then
    status=error
    reason="no report"
  fi
  if [ "$status" != ok ]; then
    case "$status" in
      not-found) failure="not found"; title="image not found: $image" ;;
      denied) failure="pull denied"; title="image pull denied: $image" ;;
      rate-limited) failure="rate limited"; title="trivy did not scan $image (rate limited)" ;;
      *) failure="scan error"; title="trivy did not scan $image" ;;
    esac
    printf '%s\t%s\t%s\t%s\t%s\n' "$image" "$failure" "$use" "$charts" "$reason" >> "$work/failed"
    # Placeholders never get here (charts/scan-inputs.sh drops them), so an
    # unreadable image is one a user can deploy.
    printf '%s\t%s\n' "$title" "$reason" >> "$work/warnings-images"
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
    --output "$work/charts.sarif" "$charts_report"
  fit_sarif "$work/charts.sarif" "$scan/sarif/charts.sarif" chart
else
  warn "trivy did not scan the charts" "reports/charts.json is missing or empty"
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
  echo "Every image the charts can deploy: rendered with a chart's defaults (\`default install\`), rendered only with the named \`ci/\` fixtures, which enable the optional components (an image a fixture names is a placeholder and left out), a worker or other image from ArmoniK's image map (\`image map\`), or an image an operator picks itself (\`operator default\`, from \`charts/operator-images.yaml\`), and apart the images of helm test pods (\`helm test\`), which \`helm test\` alone runs. The owner is the chart whose templates name the image, with its path from the release root. Vulnerabilities count once per affected package."
  echo ""
  echo "| Image | Origin | Critical | High | Medium | Low | Unknown | Fixable | Use | Owner |"
  echo "|-|-|-:|-:|-:|-:|-:|-:|-|-|"
  sort -t "$(printf '\t')" -k1,1nr -k2,2nr -k3,3nr -k4,4nr -k7,7 "$work/scanned" |
    awk -F '\t' '{ printf "| `%s` | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n", $7, $8, $1, $2, $3, $4, $5, $6, $9, $10 }'
  if [ -s "$work/failed" ]; then
    echo ""
    echo "Not scanned. \`not found\` and \`pull denied\` are the registry's own answer and break a deployment too; Docker Hub answers a repository that does not exist as it does a private one, so a missing Docker Hub image reads as \`pull denied\`. \`rate limited\` and \`scan error\` were retried, and may pass on the next run."
    echo ""
    echo "| Image | Failure | Use | Owner | Reason |"
    echo "|-|-|-|-|-|"
    # A pipe would end the table cell.
    sort -t "$(printf '\t')" -k2,2 -k1,1 "$work/failed" | sed 's/|/\\|/g' |
      awk -F '\t' '{ printf "| `%s` | %s | %s | %s | %s |\n", $1, $2, $3, $4, $5 }'
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
  if [ -s "$work/sarif-notes" ]; then
    echo ""
    echo "### Code scanning"
    echo ""
    sed 's/^/- /' "$work/sarif-notes"
  fi
} >> "$summary"

# --- annotations ---------------------------------------------------------------

while IFS="$(printf '\t')" read -r image operator; do
  warn "charts/operator-images.yaml is stale" "$image is listed as the default of $operator, which no render carries any more: review it against the new operator"
done < "$scan/stale.tsv"

# A fixture is a valid render by contract (test/matrix.sh); defaults need not be.
awk -F '\t' '$3 == "failed" && $2 != "defaults" {
  printf "%s/%s did not render\t%s\n", $1, $2, $4 }' "$scan/renders.tsv" >> "$work/warnings"

cat "$work/warnings" "$work/warnings-images" | awk -F '\t' '
  { title[NR] = $1; message[NR] = $2 }
  END {
    shown = NR > 10 ? 9 : NR
    for (i = 1; i <= shown; i++) printf "::warning title=%s::%s\n", title[i], message[i]
    if (NR > shown) printf "::warning title=%d more warnings::see the job summary\n", NR - shown
  }'
