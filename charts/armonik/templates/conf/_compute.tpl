{{/* "compute" layer: computeHelper hook (empty) + conf.compute. */}}
{{- define "armonik.conf.computeHelper" -}}
{{- end -}}
{{- define "armonik.conf.compute" -}}
  {{- list
        (include "armonik.conf.computeHelper" . | fromYaml)
        (list .Values "conf" "compute" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
