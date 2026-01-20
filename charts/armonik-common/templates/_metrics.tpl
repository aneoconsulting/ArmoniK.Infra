{{- define "armonik.conf.metricsHelper" -}}
{{- end -}}

{{- define "armonik.conf.metricsRaw" -}}
  {{- $ctx := include "armonik.conf.context" . | fromYaml -}}
  {{- list
        (include "armonik.conf.core" . | fromYaml)
        (include "armonik.conf.log" . | fromYaml)
        (include "armonik.conf.metricsHelper" $ctx | fromYaml)
        $ctx.Values.metrics
      | include "armonik.conf.merge"
  -}}
{{- end -}}

{{- define "armonik.conf.metrics" -}}
  {{- $configmap := list "metrics" . | include "armonik.conf.configmap" -}}
  {{- include "armonik.conf.metricsRaw" . | fromYaml | list $configmap | include "armonik.conf.materialized" -}}
{{- end -}}
