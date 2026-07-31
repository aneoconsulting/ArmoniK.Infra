{{/*
Control map for the five install-once operators, from global.armonik.operators.<op>.{available,deploy}
(semantics in armonik-common/values.yaml, which also ships the defaults). Absent reads as false.

  {{- $ops := include "armonik.operators" $ | fromYaml }}
  {{- if $ops.keda.available }} ...emit ScaledObject... {{- end }}
  {{- if $ops.keda.deploy }}    ...emit CRD-ordering hook... {{- end }}
*/}}
{{- define "armonik.operators" -}}
externalSecrets:
  available: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "externalSecrets" "available") | empty | not }}
  deploy: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "externalSecrets" "deploy") | empty | not }}
keda:
  available: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "keda" "available") | empty | not }}
  deploy: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "keda" "deploy") | empty | not }}
certManager:
  available: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "certManager" "available") | empty | not }}
  deploy: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "certManager" "deploy") | empty | not }}
mongodbOperator:
  available: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "mongodbOperator" "available") | empty | not }}
  deploy: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "mongodbOperator" "deploy") | empty | not }}
prometheusOperator:
  available: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "prometheusOperator" "available") | empty | not }}
  deploy: {{ include "armonik.utils.index" (list .Values "global" "armonik" "operators" "prometheusOperator" "deploy") | empty | not }}
{{- end -}}
