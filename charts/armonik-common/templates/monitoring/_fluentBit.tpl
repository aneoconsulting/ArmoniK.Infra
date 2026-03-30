{{/*
Gets the context to execute fluent-bit named templates

# Usage

{{ $ctx := include "armonik.fluentBit.context" $ | fromYaml }}
*/}}
{{- define "armonik.fluentBit.context" -}}
  {{- list . "fluent-bit" | include "armonik.dependencyContext" -}}
{{- end -}}
