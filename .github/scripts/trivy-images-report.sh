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
#   stale.tsv
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

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  printf 'Usage: %s <scan-dir> <summary-file> [<blob-url>]\n' "$0" >&2
  exit 2
fi
scan=$1
summary=$2
blob=${3:-}
sarif_severity=${SARIF_SEVERITY:-MEDIUM,HIGH,CRITICAL}
tab=$(printf '\t')

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$scan/sarif" "$scan/reports" "$work/vulns"
for f in warnings warnings-images sarif-notes scanned failed sarif-list; do
  : > "$work/$f"
done

# shellcheck source=trivy-lib.sh
. "$(dirname "$0")/trivy-lib.sh"

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

# --- images ------------------------------------------------------------------

# One entry per vulnerability and affected package: trivy repeats a package
# found in several layers or targets.
vulns_jq='
  [.Results[]? | .Vulnerabilities[]? | {
    id: .VulnerabilityID, pkg: .PkgName, path: (.PkgPath // ""),
    installed: (.InstalledVersion // ""), fixed: (.FixedVersion // ""),
    status: (.Status // ""), severity: (.Severity // "UNKNOWN"),
    title: (.Title // ""), url: (.PrimaryURL // "")}]
  | unique_by([.id, .pkg, .path, .installed])
  | sort_by([
      ({CRITICAL: 0, HIGH: 1, MEDIUM: 2, LOW: 3}[.severity] // 4),
      (if .fixed == "" then 1 else 0 end), .id, .pkg])'

printf '"image","owners","use","severity","vulnerability","package","path","installed","fixed","status","title","url"\n' \
  > "$scan/reports/vulnerabilities.csv"

paste "$scan/images.tsv" "$scan/image-status.tsv" > "$work/images"
n=0
while IFS="$tab" read -r image uses owners status_image status reason; do
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
      if (!d && (td || tf != "")) out = out (out == "" ? "" : "; ") "helm test, " label(td, tf)
      print out
    }')
  case "$use" in
    "helm test"*) test_only=1 ;;
    *) test_only=0 ;;
  esac
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
    printf '%s\t%s\t%s\t%s\t%s\n' "$image" "$cell" "$failure" "$reason" "$test_only" >> "$work/failed"
    # Placeholders never get here (charts/scan-inputs.sh drops them), so an
    # unreadable image is one a user can deploy.
    printf '%s\t%s\n' "$title" "$reason" >> "$work/warnings-images"
    continue
  fi

  # Found and fixable per severity, unknown folded into low.
  counts=$(jq -r "$vulns_jq"' as $v
    | [["CRITICAL"], ["HIGH"], ["MEDIUM"], ["LOW", "UNKNOWN"]]
    | map(. as $s | $v | map(select(.severity as $x | $s | index($x)))
          | [length, (map(select(.fixed != "")) | length)])
    | flatten | @tsv' "$report")
  printf '%s\t%s\t%s\t%s\t%s\n' "$counts" "$n" "$image" "$cell" "$test_only" >> "$work/scanned"
  # Critical and high for the summary, one row per package version.
  jq -r "$vulns_jq"' | map(select(.severity == "CRITICAL" or .severity == "HIGH"))
    | unique_by([.id, .pkg, .installed]) | sort_by([
        (if .severity == "CRITICAL" then 0 else 1 end),
        (if .fixed == "" then 1 else 0 end), .id, .pkg])
    | .[] | [.severity, .id, .url, .pkg, .installed, .fixed, .title] | @tsv' \
    "$report" > "$work/vulns/$n.tsv"
  jq -r --arg image "$image" --arg owners "$(owners_names "$owners")" --arg use "$use" \
    "$vulns_jq"' | .[] | [$image, $owners, $use, .severity, .id, .pkg, .path,
      .installed, .fixed, .status, .title, .url] | @csv' \
    "$report" >> "$scan/reports/vulnerabilities.csv"

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
tests=$(awk -F '\t' '$12' "$work/scanned.sorted" | wc -l | tr -d ' ')

{
  echo "## Trivy: images"
  echo ""
  printf 'Trivy %s, vulnerability database of %s. Report only: nothing here blocks a publication.\n' \
    "$(trivy_version)" \
    "$(trivy --version 2>/dev/null | sed -n 's/^ *UpdatedAt: //p' | head -n1)"
  echo ""
  awk -F '\t' -v failed="$images_failed" -v tests="$tests" '
    $1 > 0 { critical++ } $3 > 0 { high++ } $2 + $4 > 0 { fixable++ }
    END {
      printf "**%d images scanned**", NR
      if (tests) printf " (%d only for helm tests)", tests
      printf ": :red_circle: %d with critical vulnerabilities, :orange_circle: %d with high ones, %d with a fix for at least one of those", critical, high, fixable
      if (failed) printf "; :x: %d not scanned", failed
      print "."
    }' "$work/scanned"
  echo ""
  echo "Counts read found (fixable); low includes unknown severity. Every vulnerability, whatever its severity, is in \`vulnerabilities.csv\` of the \`trivy-reports\` artifact."
  echo ""
  echo "| Image | Owner | Critical | High | Medium | Low |"
  echo "|-|-|-:|-:|-:|-:|"
  awk -F '\t' "$md_awk"'{
    printf "| `%s`%s | %s | %s | %s | %s | %s |\n", $10, ($12 ? " <sub>helm test</sub>" : ""), $11,
      count($1, $2, ":red_circle:"), count($3, $4, ":orange_circle:"),
      count($5, $6, ":yellow_circle:"), count($7, $8, ":large_blue_circle:")
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
      awk -F '\t' "$md_awk"'{ printf "| `%s`%s | %s | %s | %s |\n", $1, ($5 ? " <sub>helm test</sub>" : ""), $2, $3, cell($4) }'
  fi
} > "$work/head.md"

# The critical and high vulnerabilities of each image, the fixable first, in
# the order of the table above; at most <cap> rows an image, 0 for no cap.
details() { # <cap>
  while IFS="$tab" read -r c cf h hf _ _ _ _ k image _ test_only; do
    [ $((c + h)) -gt 0 ] || continue
    awk -F '\t' -v cap="$1" -v test="$test_only" -v image="$image" -v c="$c" -v cf="$cf" -v h="$h" -v hf="$hf" "$md_awk"'
      BEGIN {
        printf "<details><summary>%s <code>%s</code>%s: ", (c ? ":red_circle:" : ":orange_circle:"), image, (test ? " <sub>helm test</sub>" : "")
        if (c) printf "%d critical (%d fixable)%s", c, cf, (h ? ", " : "")
        if (h) printf "%d high (%d fixable)", h, hf
        print "</summary>\n"
        print "| | Vulnerability | Package | Installed | Fixed | Title |"
        print "|-|-|-|-|-|-|"
      }
      cap && NR > cap { more++; next }
      {
        id = $3 == "" ? $2 : "[" $2 "](" $3 ")"
        printf "| %s | %s | `%s` | %s | %s | %s |\n", emoji($1), id, cell($4), cell($5), ($6 == "" ? "-" : cell($6)), cell($7)
      }
      END {
        if (more) printf "| | and %d more in `vulnerabilities.csv` | | | | |\n", more
        print "\n</details>\n"
      }' "$work/vulns/$k.tsv"
  done < "$work/scanned.sorted"
}

{
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
