# shellcheck shell=sh
# Helpers of the trivy report scripts, sourced first, then report_init.

# The arguments of a report script, `<scan-dir> <summary-file> [<blob-url>]`,
# into scan, summary and blob; work, a scratch directory removed on exit.
# shellcheck disable=SC2034 # summary is the caller's
report_init() {
  if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    printf 'Usage: %s <scan-dir> <summary-file> [<blob-url>]\n' "$0" >&2
    exit 2
  fi
  scan=$1
  summary=$2
  blob=${3:-}
  tab=$(printf '\t')
  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT
  mkdir -p "$scan/reports"
}

# shellcheck disable=SC2016,SC2034 # awk program, not shell; the callers' own
md_awk='
  function emoji(s) {
    return s == "CRITICAL" ? ":red_circle:" : s == "HIGH" ? ":orange_circle:" : \
      s == "MEDIUM" ? ":yellow_circle:" : s == "LOW" ? ":large_blue_circle:" : ":white_circle:"
  }
  # A table cell: no pipe, no tag, no line break.
  function cell(s) { gsub(/\|/, "\\|", s); gsub(/</, "\\&lt;", s); gsub(/\\[tn]/, " ", s); return s }
  # The owners of charts/scan-inputs.sh (<name>@<version>=<location>=
  # <alias-path>, comma-separated) as one table cell, a line each: the template
  # of one of our charts, or the name and version of a third-party chart,
  # linked to its location when <blob> is set, the path of the chart from the
  # release root as the link title.
  function owners(list, blob,   n, entry, i, f, text, out) {
    n = split(list, entry, ",")
    for (i = 1; i <= n; i++) {
      split(entry[i], f, "=")
      text = f[1]
      sub(/@/, " ", text)
      if (f[2] ~ /\/templates\//) { text = f[2]; sub(/^charts\//, "", text); sub(/\/templates\//, ": ", text) }
      gsub(/\//, " > ", f[3])
      out = out (i > 1 ? "<br>" : "") (blob == "" ? text : "[" text "](" blob "/" f[2] " \"" f[3] "\")")
    }
    return out
  }
'

# The renders that failed, as a summary section: a chart whose bare defaults
# are invalid on purpose is covered by its fixtures.
not_rendered() {
  grep -q "${tab}failed${tab}" "$scan/renders.tsv" || return 0
  printf '\n### Not rendered\n\nLeft out; bare defaults may be invalid on purpose.\n\n| Render | Reason |\n|-|-|\n'
  awk -F '\t' "$md_awk"'$3 == "failed" { printf "| `%s/%s` | %s |\n", $1, $2, cell($4) }' "$scan/renders.tsv"
}
