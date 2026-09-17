{{/* "polling" layer: pollingHelper hook (empty) + conf.polling. */}}
{{- define "armonik.conf.pollingHelper" -}}
{{- end -}}
{{/* The assembled layer: pollingHelper and the user's conf.polling, merged in that order. */}}
{{- define "armonik.conf.polling" -}}
  {{- list
        (include "armonik.conf.pollingHelper" . | fromYaml)
        (list .Values "conf" "polling" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
