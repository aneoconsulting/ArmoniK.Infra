{{- define "armonik.conf.jobsHelper" -}}
{{- end -}}

{{- define "armonik.conf.jobsRaw" -}}
  {{- $ctx := include "armonik.conf.context" . | fromYaml -}}
  {{- list
        (include "armonik.conf.core" . | fromYaml)
        (include "armonik.conf.log" . | fromYaml)
        (include "armonik.conf.jobsHelper" $ctx | fromYaml)
        $ctx.Values.jobs
      | include "armonik.conf.merge"
  -}}
{{- end -}}

{{/* Since this template is supposed to be called from the armonik-control-plane or armonik-compute-plane chart, chart being non-root makes the template assume it is being called by a chart that is part of top-level armonik chart */}}
{{/* Meaning that configs need to be materialized as armonik is boostraping */}}
{{/* Otherwise, the template considers the chart calling it as an "add-on" chart to be attached to a pre-existing AK cluster */}}
{{/* In that case, configs are already materialized, and it belongs to the AK release to make the proper Helm values available  */}}
{{- define "armonik.conf.jobs" -}}
  {{- if not .Chart.IsRoot -}}
    {{- $configmap := list "jobs" . | include "armonik.conf.configmap" -}}
    {{- include "armonik.conf.jobsRaw" . | fromYaml | list $configmap | include "armonik.conf.materialized" -}}
  {{- end -}}
{{- end -}}
