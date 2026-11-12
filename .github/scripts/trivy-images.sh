#! /bin/sh

# Scans every image of charts/scan-inputs.py's images.tsv with trivy, for
# publish.yml's scan job, and records why an image could not be scanned.
#
# Usage: trivy-images.sh <scan-dir> [<trivy-config>]
#
# Writes, under <scan-dir>:
#   reports/images/<n>.json  trivy image report of images.tsv line <n>
#   image-status.tsv         <image> <status> <reason>, in images.tsv order,
#                            status being ok, not-found, denied, rate-limited
#                            or error
#
# The vulnerability databases must already be in place: no scan updates them.

set -eu

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  printf 'Usage: %s <scan-dir> [<trivy-config>]\n' "$0" >&2
  exit 2
fi
scan=$1
stderr=$(mktemp)
trap 'rm -f "$stderr"' EXIT
mkdir -p "$scan/reports/images"
: > "$scan/image-status.tsv"

n=0
while IFS="$(printf '\t')" read -r image _; do
  n=$((n + 1))
  for attempt in 1 2 3; do
    status=ok
    reason=
    ! trivy image ${2:+--config "$2"} --image-src remote --scanners vuln \
      --skip-db-update --skip-java-db-update --format json \
      --output "$scan/reports/images/$n.json" "$image" 2>"$stderr" </dev/null || break
    # trivy ends on the answer of the registry it tried last, the origin: a
    # mirror missing an image it has not cached is no verdict. A Docker Hub
    # repository that does not exist answers like a private one, so it reads
    # as denied.
    reason=$(grep -v '^[[:space:]]*$' "$stderr" | tail -n 1 | tr '\t' ' ' |
      sed 's/^ *\* //; s/^remote error: //; s/^.*\(.\{300\}\)$/...\1/')
    case "$reason" in
      *TOOMANYREQUESTS* | *"status code 429"*) status=rate-limited ;;
      *MANIFEST_UNKNOWN* | *NAME_UNKNOWN* | *NOT_FOUND* | *"status code 404"*) status=not-found ;;
      *UNAUTHORIZED* | *DENIED* | *"status code 40"[13]*) status=denied ;;
      *) status=error ;;
    esac
    # The registry's final answers are not retried.
    [ "$status" = rate-limited ] || [ "$status" = error ] || break
    [ "$attempt" = 3 ] || sleep $((attempt * 10))
  done
  printf '%s\t%s\t%s\n' "$image" "$status" "$reason" >> "$scan/image-status.tsv"
done < "$scan/images.tsv"
