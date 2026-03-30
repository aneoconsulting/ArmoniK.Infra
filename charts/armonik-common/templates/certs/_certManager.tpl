{{/*
Gets the context to execute cert-manager named templates

# Usage

{{ $ctx := include "armonik.certManager.context" $ | fromYaml }}
*/}}
{{- define "armonik.certManager.context" -}}
  {{- list . "cert-manager" | include "armonik.dependencyContext" -}}
{{- end -}}
