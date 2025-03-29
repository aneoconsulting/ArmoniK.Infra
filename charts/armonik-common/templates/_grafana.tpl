{{/*
Gets the context to execute grafana named templates

# Usage

{{ $ctx := include "armonik.grafana.context" $ | fromYaml }}
*/}}
{{- define "armonik.grafana.context" -}}
  {{- list . "grafana" | include "armonik.dependencyContext" -}}
{{- end -}}
