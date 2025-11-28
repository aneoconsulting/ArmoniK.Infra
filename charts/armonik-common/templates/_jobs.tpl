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

{{- define "armonik.conf.jobs" -}}
  {{- $configmap := list "jobs" . | include "armonik.conf.configmap" -}}
  {{- include "armonik.conf.jobsRaw" . | fromYaml | list $configmap | include "armonik.conf.materialized" -}}
{{- end -}}
