{{- define "armonik.conf.computeHelper" -}}
{{- end -}}

{{- define "armonik.conf.computeRaw" -}}
  {{- $ctx := include "armonik.conf.context" . | fromYaml -}}
  {{- list
        (include "armonik.conf.log" . | fromYaml)
        (include "armonik.conf.computeHelper" $ctx | fromYaml)
        $ctx.Values.compute
      | include "armonik.conf.merge"
  -}}
{{- end -}}

{{/* Since this template is supposed to be called from the armonik-compute-plane chart, chart being non-root makes the template assume it is being called by a chart that is part of top-level armonik chart  */}}
{{/* Meaning that configs need to be materialized as armonik is boostraping */}}
{{/* Otherwise, the template considers the chart calling it as an "add-on" chart to be attached to a pre-existing AK cluster */}}
{{/* In that case, configs are already materialized, and it belongs to the armonik release to make the proper helm values available  */}}
{{- define "armonik.conf.compute" -}}
  {{- if not .Chart.IsRoot -}}
    {{- $configmap := list "compute" . | include "armonik.conf.configmap" -}}
    {{- include "armonik.conf.computeRaw" . | fromYaml | list $configmap | include "armonik.conf.materialized" -}}
  {{- end -}}
{{- end -}}
