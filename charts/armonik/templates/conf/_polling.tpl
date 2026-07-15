{{/* "polling" layer: pollingHelper hook (empty) + conf.polling. */}}
{{- define "armonik.conf.pollingHelper" -}}
{{- end -}}
{{- define "armonik.conf.polling" -}}
  {{- list
        (include "armonik.conf.pollingHelper" . | fromYaml)
        (list .Values "conf" "polling" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
