{{- define "armonik.dependencies" }}
controlPlane: {{ include "armonik.utils.index" (list .Values "control-plane" "enabled") | empty | not }}
computePlane: {{ include "armonik.utils.index" (list .Values "compute-plane" "enabled") | empty | not }}
ingress: {{ include "armonik.utils.index" (list .Values "ingress" "enabled") | empty | not }}
activemq: {{ include "armonik.utils.index" (list .Values "dependencies" "activemq" "enabled") | empty | not }}
redis: {{ include "armonik.utils.index" (list .Values "dependencies" "redis" "enabled") | empty | not }}
mongodb: {{ include "armonik.utils.index" (list .Values "dependencies" "mongodb" "enabled") | empty | not }}
kubePrometheus: {{ include "armonik.utils.index" (list .Values "dependencies" "kube-prometheus" "enabled") | empty | not }}
keda: {{ include "armonik.utils.index" (list .Values "dependencies" "keda" "enabled") | empty | not }}
rabbitmq: {{ include "armonik.utils.index" (list .Values "dependencies" "rabbitmq" "enabled") | empty | not }}
grafana: {{ include "armonik.utils.index" (list .Values "dependencies" "grafana" "enabled") | empty | not }}
fluentBit: {{ include "armonik.utils.index" (list .Values "dependencies" "fluent-bit" "enabled") | empty | not }}
seq: {{ include "armonik.utils.index" (list .Values "dependencies" "seq" "enabled") | empty | not }}
certManager: {{ include "armonik.utils.index" (list .Values "dependencies" "cert-manager" "enabled") | empty | not }}
{{- end }}

{{- define "armonik.mongodb-secret-name" -}}
  {{- if .Values.dependencies.mongodb.fullnameOverride -}}
    {{- printf "%s-secrets" .Values.dependencies.mongodb.fullnameOverride -}}
  {{- else -}}
    {{- $name := default "mongodb" .Values.dependencies.mongodb.nameOverride -}}
    {{- if contains $name .Release.Name -}}
      {{- printf "%s-secrets" (.Release.Name | trunc 21 | trimSuffix "-") -}}
    {{- else -}}
      {{- printf "%s-%s-secrets" .Release.Name $name | trunc 28 | trimSuffix "-" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}


{{- define "armonik.mongodb-exporter-uri" -}}
  {{- $mongodbSecretName := include "armonik.mongodb-secret-name" . -}}
  {{- $mongodbSecrets := (lookup "v1" "Secret" .Release.Namespace $mongodbSecretName) -}}
  
  {{- if $mongodbSecrets -}}
    {{- $user := (index $mongodbSecrets.data "MONGODB_CLUSTER_MONITOR_USER" | b64dec) -}}
    {{- $pass := (index $mongodbSecrets.data "MONGODB_CLUSTER_MONITOR_PASSWORD" | b64dec) -}}
    {{- $namespace := .Release.Namespace -}}
    {{- $mongoDBReleaseName := include "armonik.mongodb-release-name" . -}}
    {{- $replicaSetName := (first (keys (index .Values.dependencies.mongodb.replsets | default dict))) | default "rs0" -}}
    
    {{- if .Values.dependencies.mongodb.sharding.enabled -}}
      {{- printf "mongodb://%s:%s@%s-mongos.%s.svc.cluster.local:27017/admin" $user $pass $mongoDBReleaseName $namespace -}}
    {{- else -}}
      {{- printf "mongodb://%s:%s@%s-%s.%s.svc.cluster.local:27017/admin?replicaSet=%s" $user $pass $mongoDBReleaseName $replicaSetName $namespace $replicaSetName -}}
    {{- end -}}
  {{- else -}}
    {{- fail "Secret %s not found" $mongodbSecretName -}}
  {{- end -}}
    
{{- end -}}

{{- define "armonik.mongodb-release-name" -}}
  {{- if .Values.dependencies.mongodb.fullnameOverride -}}
    {{- .Values.dependencies.mongodb.fullnameOverride -}}
  {{- else -}}
    {{- printf "%s-mongodb" .Release.Name -}}
  {{- end -}}
{{- end -}}