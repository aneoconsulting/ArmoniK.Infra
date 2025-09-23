{{- define "armonik.conf.controlHelper" -}}
{{- end -}}


{{- define "armonik.conf.controlRaw" -}}
  {{- $ctx := include "armonik.conf.context" . | fromYaml -}}
  {{- list
        (include "armonik.conf.core" . | fromYaml)
        (include "armonik.conf.log" . | fromYaml)
        (include "armonik.conf.controlHelper" $ctx | fromYaml)
        $ctx.Values.control
      | include "armonik.conf.merge"
  -}}
{{- end -}}

{{- define "armonik.conf.control" -}}
  {{- $configmap := list "control" . | include "armonik.conf.configmap" -}}
  {{- include "armonik.conf.controlRaw" . | fromYaml | list $configmap | include "armonik.conf.materialized" -}}
{{- end -}}
