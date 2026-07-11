{{/* "init" layer: initHelper hook (empty) + conf.init. */}}
{{- define "armonik.conf.initHelper" -}}
{{- end -}}
{{- define "armonik.conf.init" -}}
  {{- list
        (include "armonik.conf.initHelper" . | fromYaml)
        (list .Values "conf" "init" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
