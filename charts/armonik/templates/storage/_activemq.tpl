{{/*
Expand the namespace of the activemq instance.
*/}}
{{- define "armonik.activemq.namespace" -}}
  {{- include "activemq.namespace" . -}}
{{- end }}

{{/*
ActiveMQ's AMQP port.
*/}}
{{- define "armonik.activemq.port" -}}
  {{- .Values.containerPort.amqp -}}
{{- end }}

{{/*
Gets the configuration from activemq forwarded to ArmoniK Core.
*/}}
{{- define "armonik.activemq.conf" -}}
{{/* Live subchart scope via .Subcharts (armonik-dependencies is aliased "dependencies"); skipped when the dep is disabled. */}}
{{- with .Subcharts.dependencies.Subcharts.activemq -}}
{{- $namespace := include "armonik.activemq.namespace" . -}}
env:
  Components__QueueAdaptorSettings__AdapterAbsolutePath: /adapters/queue/amqp/ArmoniK.Core.Adapters.Amqp.dll
  Components__QueueAdaptorSettings__ClassName: ArmoniK.Core.Adapters.Amqp.QueueBuilder
  Amqp__Host:        {{ printf "%s.%s.svc.%s" (include "activemq.fullname" .) $namespace .Values.tls.clusterDomain | quote }}
  Amqp__Port:        {{ include "armonik.activemq.port" . | quote }}
  Amqp__Scheme:      AMQP
  Amqp__User:        admin
  Amqp__Password:    admin
  Amqp__MaxPriority: "10"
{{- end }}
{{- end }}
