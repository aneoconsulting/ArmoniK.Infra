{{/* "events" layer, over core for the control-plane events Deployment: the PostgreSQL server itself whatever the pooler + conf.events. */}}
{{- define "armonik.conf.events" -}}
  {{- list
        (include "armonik.postgresql.eventsConf" . | fromYaml)
        (include "armonik.externalPostgresql.eventsConf" . | fromYaml)
        (list .Values "conf" "events" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
