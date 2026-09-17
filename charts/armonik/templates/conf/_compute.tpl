{{/* "compute" layer: computeHelper hook (empty) + conf.compute. */}}
{{- define "armonik.conf.computeHelper" -}}
{{- end -}}
{{/* The assembled layer: computeHelper and the user's conf.compute, merged in that order. */}}
{{- define "armonik.conf.compute" -}}
  {{- list
        (include "armonik.conf.computeHelper" . | fromYaml)
        (list .Values "conf" "compute" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
