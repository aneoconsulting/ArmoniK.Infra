{{- define "armonik.dependencies" }}
controlPlane: {{ include "armonik.index" (list .Values "control-plane" "enabled") | empty | not }}
computePlane: {{ include "armonik.index" (list .Values "compute-plane" "enabled") | empty | not }}
ingress: {{ include "armonik.index" (list .Values "ingress" "enabled") | empty | not }}
activemq: {{ include "armonik.index" (list .Values "dependencies" "activemq" "enabled") | empty | not }}
redis: {{ include "armonik.index" (list .Values "dependencies" "redis" "enabled") | empty | not }}
mongodb: {{ include "armonik.index" (list .Values "dependencies" "mongodb" "enabled") | empty | not }}
kubePrometheus: {{ include "armonik.index" (list .Values "dependencies" "kube-prometheus" "enabled") | empty | not }}
keda: {{ include "armonik.index" (list .Values "dependencies" "keda" "enabled") | empty | not }}
rabbitmq: {{ include "armonik.index" (list .Values "dependencies" "rabbitmq" "enabled") | empty | not }}
grafana: {{ include "armonik.index" (list .Values "dependencies" "grafana" "enabled") | empty | not }}
fluentBit: {{ include "armonik.index" (list .Values "dependencies" "fluent-bit" "enabled") | empty | not }}
seq: {{ include "armonik.index" (list .Values "dependencies" "seq" "enabled") | empty | not }}
certManager: {{ include "armonik.index" (list .Values "dependencies" "cert-manager" "enabled") | empty | not }}
{{- end }}
