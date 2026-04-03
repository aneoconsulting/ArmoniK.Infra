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

{{/* Since this template is supposed to be called from the armonik-control-plane chart, chart being non-root makes the template assume it is being called by a chart that is part of top-level armonik chart  */}}
{{/* Meaning that configs need to be materialized as armonik is boostraping */}}
{{/* Otherwise, the template considers the chart calling it as an "add-on" chart to be attached to a pre-existing AK cluster */}}
{{/* In that case, configs are already materialized, and it belongs to the armonik release to make the proper helm values available  */}}
{{- define "armonik.conf.metrics" -}}
  {{- if not .Chart.IsRoot -}}
    {{- $configmap := list "metrics" . | include "armonik.conf.configmap" -}}
    {{- include "armonik.conf.metricsRaw" . | fromYaml | list $configmap | include "armonik.conf.materialized" -}}
  {{- end -}}
{{- end -}}
