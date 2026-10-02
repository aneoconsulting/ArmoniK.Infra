{{/*
ActiveMQ's AMQP port. Takes the activemq subchart scope.
*/}}
{{- define "armonik.activemq.port" -}}
  {{- .Values.containerPort.amqp -}}
{{- end }}

{{/*
Core env for the in-cluster ActiveMQ.
TODO: the credentials are a hardcoded admin/admin; they need a real Secret.
*/}}
{{- define "armonik.activemq.conf" -}}
{{/* Skipped when the dependency is disabled (.Subcharts holds enabled ones only). */}}
{{- with .Subcharts.dependencies.Subcharts.activemq -}}
{{- $namespace := include "armonik.namespace" . -}}
env:
  Components__QueueAdaptorSettings__AdapterAbsolutePath: /adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll
  Components__QueueAdaptorSettings__ClassName: ArmoniK.Core.Adapters.Amqp.QueueBuilder
  Amqp__Host:        {{ printf "%s.%s.svc.%s" (include "armonik.fullname" .) $namespace .Values.tls.clusterDomain | quote }}
  Amqp__Port:        {{ include "armonik.activemq.port" . | quote }}
  Amqp__Scheme:      AMQP
  Amqp__User:        admin
  Amqp__Password:    admin
  Amqp__MaxPriority: "10"
{{- end }}
{{- end }}
