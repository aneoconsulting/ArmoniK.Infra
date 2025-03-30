{{- define "armonik.conf.workerHelper" -}}
{{- end -}}


{{- define "armonik.conf.workerRaw" -}}
  {{- $ctx := include "armonik.conf.context" . | fromYaml -}}
  {{- list
        (include "armonik.conf.compute" . | fromYaml)
        (include "armonik.conf.workerHelper" $ctx | fromYaml)
        $ctx.Values.worker
      | include "armonik.conf.merge"
  -}}
{{- end -}}

{{- define "armonik.conf.worker" -}}
  {{- $configmap := list "worker" . | include "armonik.conf.configmap" -}}
  {{- include "armonik.conf.workerRaw" . | fromYaml | list $configmap | include "armonik.conf.materialized" -}}
{{- end -}}
