{{/*
Gets the hostname from rabbitmq context.
*/}}
{{- define "armonik.rabbitmq.host" -}}
  {{- include "common.names.fullname" . }}.{{ include "common.names.namespace" . }}.svc.{{ .Values.clusterDomain }}
{{- end -}}

{{/*
Gets the port from rabbitmq context.
*/}}
{{- define "armonik.rabbitmq.port" -}}
  {{- or (.Values.service.portEnabled) (not .Values.auth.tls.enabled) | ternary .Values.service.ports.amqp .Values.service.ports.amqpTls -}}
{{- end -}}

{{/*
Gets the configuration from rabbitmq forwarded to ArmoniK Core.
*/}}
{{- define "armonik.rabbitmq.conf" -}}
{{/* Live subchart scope via .Subcharts (armonik-dependencies is aliased "dependencies"); skipped when the dep is disabled. */}}
{{- with .Subcharts.dependencies.Subcharts.rabbitmq -}}
env:
  Components__QueueAdaptorSettings__AdapterAbsolutePath: /adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll
  Components__QueueAdaptorSettings__ClassName: ArmoniK.Core.Adapters.Amqp.QueueBuilder
  Components__QueueStorage: ArmoniK.Adapters.Amqp.ObjectStorage

  Amqp__Host: {{ include "armonik.rabbitmq.host" . | quote }}
  Amqp__Port: {{ include "armonik.rabbitmq.port" . | quote }}
  Amqp__User: {{ .Values.auth.username | quote }}
  Amqp__MaxPriority: "10"
{{- if .Values.auth.tls.enabled }}
  Amqp__CaPath: /mounts/rabbitmq-ca.crt
  Amqp__Scheme: AMQPS
{{- else }}
  Amqp__Scheme: AMQP
{{- end }}

envFromSecret:
  Amqp__Password:
    secret: {{ include "rabbitmq.secretPasswordName" . }}
    field: {{ include "rabbitmq.secretPasswordKey" . }}
mountSecret:
{{- if .Values.auth.tls.enabled }}
  rabbitmq:
    secret: {{ include "rabbitmq.tlsSecretName" . }}
{{- end }}
{{- end }}
{{- end }}
