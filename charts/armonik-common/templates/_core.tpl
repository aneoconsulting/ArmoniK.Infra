{{- define "armonik.conf.coreHelper" -}}
{{- end -}}

{{- define "armonik.conf.coreRaw" -}}
  {{- $ctx := include "armonik.conf.context" . | fromYaml -}}
  {{- list
        (include "armonik.mongodb.conf" . | fromYaml)
        (include "armonik.activemq.conf" . | fromYaml)
        (include "armonik.rabbitmq.conf" . | fromYaml)
        (include "armonik.redis.conf" . | fromYaml)
        (include "armonik.conf.coreHelper" $ctx | fromYaml)
        $ctx.Values.core
      | include "armonik.conf.merge"
  -}}
{{- end -}}

{{- define "armonik.conf.core" -}}
  {{- $configmap := list "core" . | include "armonik.conf.configmap" -}}
  {{- include "armonik.conf.coreRaw" . | fromYaml | list $configmap | include "armonik.conf.materialized" -}}
{{- end -}}
