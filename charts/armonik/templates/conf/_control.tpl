{{/* "control" layer: controlHelper hook (empty) + conf.control. */}}
{{- define "armonik.conf.controlHelper" -}}
{{- end -}}
{{- define "armonik.conf.control" -}}
  {{- list
        (include "armonik.conf.controlHelper" . | fromYaml)
        (list .Values "conf" "control" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
