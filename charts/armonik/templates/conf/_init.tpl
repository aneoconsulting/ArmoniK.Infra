{{/* "init" layer: identity header names + initHelper hook (empty) + conf.init. */}}
{{- define "armonik.conf.initHelper" -}}
{{- end -}}
{{- define "armonik.conf.init" -}}
  {{- list
        (include "armonik.conf.identityHeaders" . | fromYaml)
        (include "armonik.conf.initHelper" . | fromYaml)
        (list .Values "conf" "init" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
