{{/*
Gets the context to execute keda named templates

# Usage

{{ $ctx := include "armonik.keda.context" $ | fromYaml }}
*/}}
{{- define "armonik.keda.context" -}}
  {{- list . "keda" | include "armonik.dependencyContext" -}}
{{- end -}}
