{{/* "jobs" layer: jobsHelper hook (empty) + conf.jobs. */}}
{{- define "armonik.conf.jobsHelper" -}}
{{- end -}}
{{- define "armonik.conf.jobs" -}}
  {{- list
        (include "armonik.conf.jobsHelper" . | fromYaml)
        (list .Values "conf" "jobs" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
