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
  : > "$work/warnings"
}

# Annotations are capped at 10 warnings per step
# (https://github.com/actions/toolkit/blob/main/docs/problem-matchers.md), so
# they are collected and emitted at the end, the run-wide ones first.
warn() { # <title> <message>
  printf '%s\t%s\n' "$1" "$2" >> "$work/warnings"
}

# Workflow command escaping
# (https://github.com/actions/toolkit/blob/main/packages/core/src/command.ts):
# a property also escapes the separators of the properties.
annotate() { # <warnings-file>...
  awk -F '\t' '
    function data(s) { gsub(/%/, "%25", s); gsub(/\r/, "%0D", s); gsub(/\n/, "%0A", s); return s }
    function property(s) { s = data(s); gsub(/:/, "%3A", s); gsub(/,/, "%2C", s); return s }
    { title[NR] = $1; message[NR] = $2 }
    END {
      shown = NR > 10 ? 9 : NR
      for (i = 1; i <= shown; i++) printf "::warning title=%s::%s\n", property(title[i]), data(message[i])
      if (NR > shown) printf "::warning title=%d more warnings::see the job summary\n", NR - shown
    }' "$@"
}

# A fixture is a valid render by contract (test/matrix.sh); defaults need not be.
warn_renders() {
  awk -F '\t' '$3 == "failed" && $2 != "defaults" {
    printf "%s/%s did not render\t%s\n", $1, $2, $4 }' "$scan/renders.tsv" >> "$work/warnings"
}

# The owners of charts/scan-inputs.sh (<alias-path>=<name>@<version>=<location>,
# comma-separated) as one table cell: a link per location, to a template or to
# the line of our Chart.yaml that sets a chart's version, the chart's path from
# the release root as the link title, the umbrella's path when it has one.
# mode=charts names the chart alone, one link per chart, to its first
# location; mode=names gives plain names for the CSV files; past max links, the
# rest fold into a collapsed list.
# shellcheck disable=SC2016 # awk program, not shell
owners_awk='
  {
    n = split($0, entry, ",")
    k = 0
    for (i = 1; i <= n; i++) {
      split(entry[i], f, "=")
      key = f[3] != "" ? f[3] : f[2]
      if (!(key in at)) { at[key] = ++k; path[k] = f[1]; owner[k] = f[2]; loc[k] = f[3] }
      else if (f[1] == "armonik" || f[1] ~ /^armonik\//) { path[at[key]] = f[1]; owner[at[key]] = f[2] }
    }
    sep = mode == "names" ? "; " : "<br>"
    for (i = 1; i <= k; i++) {
      name = owner[i]; sub(/@.*$/, "", name)
      version = owner[i]; sub(/^[^@]*@/, "", version)
      if (loc[i] == "" || loc[i] ~ /\/Chart\.yaml(#L[0-9]+)?$/) text = name " " version
      else if (loc[i] ~ /\/values\.yaml(#L[0-9]+)?$/) text = name ": image map"
      else { text = loc[i]; sub(/^charts\/[^\/]*\/templates\//, "", text); text = name ": " text }
      if (mode == "charts") {
        if (name in named) continue
        named[name] = 1
        text = name
      }
      if (mode == "names" || blob == "" || loc[i] == "") item = text
      else {
        title = path[i]; gsub(/\//, " > ", title)
        item = "[" text "](" blob "/" loc[i] " \"" title "\")"
      }
      if (item in seen) continue
      seen[item] = 1
      if (max && shown == max) { more++; rest = rest (rest == "" ? "" : sep) item; continue }
      shown++
      out = out (out == "" ? "" : sep) item
    }
    if (more) out = out sep "<details><summary>" more " more</summary>" rest "</details>"
    print out
  }'

owners_cell() { # <owners> [<max> [<mode>]]
  printf '%s\n' "$1" | awk -v blob="$blob" -v max="${2:-0}" -v mode="${3:-}" "$owners_awk"
}

# shellcheck disable=SC2016
md_awk='
  function emoji(s) {
    return s == "CRITICAL" ? ":red_circle:" : s == "HIGH" ? ":orange_circle:" : \
      s == "MEDIUM" ? ":yellow_circle:" : s == "LOW" ? ":large_blue_circle:" : ":white_circle:"
  }
  # A table cell: no pipe, no tag, no line break.
  function cell(s) { gsub(/\|/, "\\|", s); gsub(/</, "\\&lt;", s); gsub(/\\[tn]/, " ", s); return s }
  function count(n, f, s) { return n == 0 ? "-" : emoji(s) " " n " (" f ")" }
  function rank(s) { return s == "CRITICAL" ? 0 : s == "HIGH" ? 1 : s == "MEDIUM" ? 2 : s == "LOW" ? 3 : 4 }
'

# A field of `trivy --version`: Version is trivy's own, the database's
# indented below it.
trivy_info() { # <field>
  trivy --version 2>/dev/null | sed -n "s/^ *$1: //p" | head -n1
}

# The renders that failed, as a summary section.
not_rendered() { # <what a failed render misses>
  grep -q "${tab}failed${tab}" "$scan/renders.tsv" || return 0
  echo ""
  echo "### Not rendered"
  echo ""
  printf '%s; a chart'"'"'s bare defaults may be invalid on purpose.\n' "$1"
  echo ""
  echo "| Render | Reason |"
  echo "|-|-|"
  awk -F '\t' "$md_awk"'$3 == "failed" { printf "| `%s/%s` | %s |\n", $1, $2, cell($4) }' "$scan/renders.tsv"
}
