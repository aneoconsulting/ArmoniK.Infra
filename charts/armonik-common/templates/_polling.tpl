{{- define "armonik.conf.pollingHelper" -}}
{{- end -}}

{{- define "armonik.conf.pollingRaw" -}}
  {{- $ctx := include "armonik.conf.context" . | fromYaml -}}
  {{- list
        (include "armonik.conf.core" . | fromYaml)
        (include "armonik.conf.compute" . | fromYaml)
        (include "armonik.conf.pollingHelper" $ctx | fromYaml)
        $ctx.Values.polling
      | include "armonik.conf.merge"
  -}}
{{- end -}}

{{- define "armonik.conf.polling" -}}
  {{- $configmap := list "polling" . | include "armonik.conf.configmap" -}}
  {{- include "armonik.conf.pollingRaw" . | fromYaml | list $configmap | include "armonik.conf.materialized" -}}
{{- end -}}
