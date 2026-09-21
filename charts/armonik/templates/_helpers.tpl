{{/*
Which first-party subcharts and storage backends this release enables, as a bool map.
Operators are not listed: see the armonik.operators helper.
*/}}
{{- define "armonik.dependencies" }}
controlPlane: {{ include "armonik.utils.index" (list .Values "control-plane" "enabled") | empty | not }}
computePlane: {{ include "armonik.utils.index" (list .Values "compute-plane" "enabled") | empty | not }}
ingress: {{ include "armonik.utils.index" (list .Values "ingress" "enabled") | empty | not }}
activemq: {{ include "armonik.utils.index" (list .Values "dependencies" "activemq" "enabled") | empty | not }}
redis: {{ include "armonik.utils.index" (list .Values "dependencies" "redis" "enabled") | empty | not }}
mongodb: {{ include "armonik.utils.index" (list .Values "dependencies" "mongodb" "enabled") | empty | not }}
rabbitmq: {{ include "armonik.utils.index" (list .Values "dependencies" "rabbitmq" "enabled") | empty | not }}
grafana: {{ include "armonik.utils.index" (list .Values "dependencies" "grafana" "enabled") | empty | not }}
fluentBit: {{ include "armonik.utils.index" (list .Values "dependencies" "fluent-bit" "enabled") | empty | not }}
seq: {{ include "armonik.utils.index" (list .Values "dependencies" "seq" "enabled") | empty | not }}
{{- /* Operators are not listed here: see the armonik.operators helper. */}}
{{- end }}
