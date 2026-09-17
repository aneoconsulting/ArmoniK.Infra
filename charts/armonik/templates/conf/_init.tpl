{{/* "init" layer: initHelper hook (empty) + conf.init. */}}
{{- define "armonik.conf.initHelper" -}}
{{- end -}}
{{/* The assembled layer: initHelper and the user's conf.init, merged in that order. */}}
{{- define "armonik.conf.init" -}}
  {{- list
        (include "armonik.conf.initHelper" . | fromYaml)
        (list .Values "conf" "init" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
