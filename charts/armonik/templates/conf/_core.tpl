{{/* "core" layer: storage env + credentials (mongodb/activemq/rabbitmq/redis), coreHelper, conf.core. */}}
{{- define "armonik.conf.coreHelper" -}}
{{- end -}}
{{/* The assembled layer: the storage fragments, coreHelper, and the user's conf.core, merged in that order. */}}
{{- define "armonik.conf.core" -}}
  {{- list
        (include "armonik.mongodb.conf" . | fromYaml)
        (include "armonik.activemq.conf" . | fromYaml)
        (include "armonik.rabbitmq.conf" . | fromYaml)
        (include "armonik.redis.conf" . | fromYaml)
        (include "armonik.gcs.conf" . | fromYaml)
        (include "armonik.pubsub.conf" . | fromYaml)
        (include "armonik.conf.coreHelper" . | fromYaml)
        (list .Values "conf" "core" | include "armonik.utils.index" | fromYaml)
      | include "armonik.conf.merge" -}}
{{- end -}}
