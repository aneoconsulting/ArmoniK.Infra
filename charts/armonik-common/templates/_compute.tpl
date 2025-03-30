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

{{- define "armonik.conf.compute" -}}
  {{- $configmap := list "compute" . | include "armonik.conf.configmap" -}}
  {{- include "armonik.conf.computeRaw" . | fromYaml | list $configmap | include "armonik.conf.materialized" -}}
{{- end -}}
