{{/* "metrics" layer: metricsHelper hook (empty) + conf.metrics. */}}
{{- define "armonik.conf.metricsHelper" -}}
{{- end -}}
{{/* The assembled layer: metricsHelper and the user's conf.metrics, merged in that order. */}}
{{- define "armonik.conf.metrics" -}}
  {{- list
        (include "armonik.conf.metricsHelper" . | fromYaml)
        (list .Values "conf" "metrics" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
