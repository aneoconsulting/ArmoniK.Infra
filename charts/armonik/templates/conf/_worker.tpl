{{/* "worker" layer: workerHelper hook (empty) + conf.worker. */}}
{{- define "armonik.conf.workerHelper" -}}
{{- end -}}
{{/* The assembled layer: workerHelper and the user's conf.worker, merged in that order. */}}
{{- define "armonik.conf.worker" -}}
  {{- list
        (include "armonik.conf.workerHelper" . | fromYaml)
        (list .Values "conf" "worker" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
