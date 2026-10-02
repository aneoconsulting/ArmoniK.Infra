{{/*
RabbitMQ Service hostname. Takes the rabbitmq subchart scope, as do the other helpers here except
armonik.rabbitmq.conf, which takes the root.
*/}}
{{- define "armonik.rabbitmq.host" -}}
  {{- include "common.names.fullname" . }}.{{ include "common.names.namespace" . }}.svc.{{ .Values.clusterDomain }}
{{- end -}}

{{/*
AMQP port, or the AMQPS one when TLS is enabled without the plain port.
*/}}
{{- define "armonik.rabbitmq.port" -}}
  {{- or (.Values.service.portEnabled) (not .Values.auth.tls.enabled) | ternary .Values.service.ports.amqp .Values.service.ports.amqpTls -}}
{{- end -}}

{{/*
Namespace of the rabbitmq instance.
*/}}
{{- define "armonik.rabbitmq.namespace" -}}
  {{- include "common.names.namespace" . -}}
{{- end }}

{{/*
Core conf for the in-cluster RabbitMQ: env, password reference and, with TLS, the TLS Secret mount.
*/}}
{{- define "armonik.rabbitmq.conf" -}}
{{- $root := . -}}
{{- $prefix := "rabbitmq-" -}}
{{/* Skipped when the dependency is disabled (.Subcharts holds enabled ones only). */}}
{{- with .Subcharts.dependencies.Subcharts.rabbitmq -}}
{{- $namespace := include "armonik.rabbitmq.namespace" . -}}
env:
  Components__QueueAdaptorSettings__AdapterAbsolutePath: /adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll
  Components__QueueAdaptorSettings__ClassName: ArmoniK.Core.Adapters.Amqp.QueueBuilder
  Components__QueueStorage: ArmoniK.Adapters.Amqp.ObjectStorage

  Amqp__Host: {{ include "armonik.rabbitmq.host" . | quote }}
  Amqp__Port: {{ include "armonik.rabbitmq.port" . | quote }}
  Amqp__User: {{ .Values.auth.username | quote }}
  Amqp__MaxPriority: "10"
{{- if .Values.auth.tls.enabled }}
  Amqp__CaPath: {{ list $prefix "ca.crt" $root | include "armonik.conf.mountFilePath" | quote }}
  Amqp__Scheme: AMQPS
{{- else }}
  Amqp__Scheme: AMQP
{{- end }}

envFromSecret:
  Amqp__Password:
    secret: {{ include "rabbitmq.secretPasswordName" . }}
    field: {{ include "rabbitmq.secretPasswordKey" . }}
    namespace: {{ $namespace | quote }}
mountSecret:
{{- if .Values.auth.tls.enabled }}
  - secret: {{ include "rabbitmq.tlsSecretName" . }}
    prefix: {{ $prefix | quote }}
    namespace: {{ $namespace | quote }}
{{- end }}
{{- end }}
{{- end }}
