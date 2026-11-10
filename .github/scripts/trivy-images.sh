#! /bin/sh

# Scans every image of charts/scan-inputs.sh's images.tsv with trivy, for
# publish.yml's scan job, and records why an image could not be scanned.
#
# Usage: trivy-images.sh <scan-dir> [<trivy-config>]
#
# Writes, under <scan-dir>:
#   reports/images/<n>.json  trivy image report of images.tsv line <n>
#   image-status.tsv         <image> <status> <reason>, in images.tsv order,
#                            status being one of
#                              ok            scanned
#                              not-found     the registry has no such image
#                              denied        the registry refuses the pull
#                              rate-limited  the registry throttles the pulls
#                              error         anything else
#
# The vulnerability databases must already be in place: no scan updates them.
# Only rate-limited and error are retried, the others being final answers.

set -eu

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  printf 'Usage: %s <scan-dir> [<trivy-config>]\n' "$0" >&2
  exit 2
fi
scan=$1
set --
[ -z "${2:-}" ] || set -- --config "$2"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$scan/reports/images"
: > "$scan/image-status.tsv"

# <status> <reason> from trivy's stderr. A pull failure ends the FATAL line
# with "N errors occurred:", one "* remote error: ..." line following per
# registry tried: the mirrors first, the origin last. The origin's answer is
# the one that counts, a mirror missing an image it has not cached being no
# verdict. A Docker Hub repository that does not exist answers like a private
# one (UNAUTHORIZED), so it reads as denied.
classify() {
  awk '
    /^[ \t]*\* / { last = $0; bullets = 1; next }
    /(FATAL|ERROR)[ \t]/ { fatal = $0 }
    END {
      if (bullets) {
        s = last
        sub(/^[ \t]*\* /, "", s)
        sub(/^remote error: /, "", s)
      } else {
        s = fatal
        sub(/^.*(FATAL|ERROR)[ \t]+/, "", s)
      }
      gsub(/\t/, " ", s)
      if (s == "") { print "error\tno error line from trivy"; exit }
      if (s ~ /TOOMANYREQUESTS|status code 429/) status = "rate-limited"
      else if (s ~ /MANIFEST_UNKNOWN|NAME_UNKNOWN|NOT_FOUND|status code 404/) status = "not-found"
      else if (s ~ /UNAUTHORIZED|DENIED|status code 40[13]/) status = "denied"
      else status = "error"
      # The cause comes last in the wrapped errors.
      if (length(s) > 300) s = "..." substr(s, length(s) - 296)
      print status "\t" s
    }' "$1"
}

n=0
while IFS="$(printf '\t')" read -r image _; do
  n=$((n + 1))
  report="$scan/reports/images/$n.json"
  attempt=1
  while :; do
    if trivy image "$@" --image-src remote --scanners vuln \
         --skip-db-update --skip-java-db-update \
         --format json --output "$report" \
         "$image" 2>"$work/stderr" </dev/null; then
      printf '%s\tok\t\n' "$image" >> "$scan/image-status.tsv"
      break
    fi
    result=$(classify "$work/stderr")
    case "$result" in
      rate-limited*|error*)
        if [ "$attempt" -lt 3 ]; then
          sleep $((attempt * 10))
          attempt=$((attempt + 1))
          continue
        fi
        ;;
    esac
    printf '%s\t%s\n' "$image" "$result" >> "$scan/image-status.tsv"
    rm -f "$report"
    break
  done
done < "$scan/images.tsv"
