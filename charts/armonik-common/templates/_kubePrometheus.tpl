{{/*
Gets the context to execute kube-prometheus named templates

# Usage

{{ $ctx := include "armonik.kubePrometheus.context" $ | fromYaml }}
*/}}
{{- define "armonik.kubePrometheus.context" -}}
  {{- list . "kube-prometheus" | include "armonik.dependencyContext" -}}
{{- end -}}
