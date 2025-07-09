{{/*
Gets the context to execute seq named templates

# Usage

{{ $ctx := include "armonik.seq.context" $ | fromYaml }}
*/}}
{{- define "armonik.seq.context" -}}
  {{- list . "seq" | include "armonik.dependencyContext" -}}
{{- end -}}
