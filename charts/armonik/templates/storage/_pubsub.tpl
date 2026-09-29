{{/*
Core env for the Pub/Sub queue adapter, when dependencies.pubsub.enabled.
*/}}
{{- define "armonik.pubsub.conf" -}}
{{- $pubsub := list .Values "dependencies" "pubsub" | include "armonik.utils.index" | fromYaml -}}
{{- if $pubsub.enabled }}
env:
  Components__QueueAdaptorSettings__ClassName: "ArmoniK.Core.Adapters.PubSub.QueueBuilder"
  Components__QueueAdaptorSettings__AdapterAbsolutePath: "/adapters/queue/pubsub/ArmoniK.Core.Adapters.PubSub.dll"
  PubSub__ProjectId: {{ $pubsub.projectId | quote }}
  PubSub__KmsKeyName: {{ $pubsub.kmsKeyName | quote }}
  PubSub__Prefix: {{ $pubsub.prefix | quote }}
{{- end }}
{{- end }}
