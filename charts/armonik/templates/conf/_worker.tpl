{{/* "worker" layer: workerHelper hook (empty) + conf.worker. */}}
{{- define "armonik.conf.workerHelper" -}}
{{- end -}}
{{- define "armonik.conf.worker" -}}
  {{- list
        (include "armonik.conf.workerHelper" . | fromYaml)
        (list .Values "conf" "worker" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
