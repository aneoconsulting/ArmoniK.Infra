# Flags unrendered Helm template leftovers ('{{') in a rendered manifest
# stream (helm template output on stdin). Document-aware:
# - documents sourced from third-party subcharts are ignored: upstream
#   content legitimately embeds Grafana/Prometheus '{{ }}' templating;
# - ExternalSecret documents may carry ESO target-template refs of the exact
#   shape '{{ .KEY }}' (single env-style key, evaluated by the operator);
# - the ArmoniK-owned grafana dashboard ConfigMaps may carry Grafana legend
#   templating of the exact shape '{{label}}';
# any other '{{' fails the run (exit 1) and is reported with its source.
BEGIN {
  # ArmoniK-owned subchart path segments; any other name found right after a
  # "charts" segment in a document's Source path marks it third-party.
  owned["control-plane"] = 1
  owned["compute-plane"] = 1
  owned["ingress"] = 1
  owned["dependencies"] = 1
  owned["activemq"] = 1
  owned["armonik-common"] = 1
  bad = 0
}
/^---$/ { src = ""; kind = ""; thirdparty = 0; next }
/^# Source: / {
  src = $3
  thirdparty = 0
  n = split(src, seg, "/")
  for (i = 1; i < n; i++)
    if (seg[i] == "charts" && !(seg[i + 1] in owned))
      thirdparty = 1
  next
}
kind == "" && /^kind:/ { kind = $2 }
!/\{\{/ { next }
thirdparty { next }
{
  line = $0
  if (kind == "ExternalSecret")
    gsub(/\{\{ *\.[A-Za-z0-9_]+ *\}\}/, "", line)
  if (src ~ /grafana-dashboard/)
    gsub(/\{\{ *[A-Za-z0-9_]+ *\}\}/, "", line)
  if (line ~ /\{\{/) {
    bad++
    if (bad <= 5)
      printf "%s: %s\n", src, $0
  }
}
END {
  if (bad) {
    printf "%d line(s) with unrendered templates\n", bad
    exit 1
  }
}
