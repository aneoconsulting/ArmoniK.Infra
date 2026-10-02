{{/*
Configuration for SQS forwarded to ArmoniK Core.
Core passes ServiceURL to the AWS SDK as is, so it defaults to the regional endpoint rather than empty.
*/}}
{{- define "armonik.sqs.conf" -}}
{{- $sqs := list .Values "dependencies" "sqs" | include "armonik.utils.index" | fromYaml -}}
{{- if $sqs.enabled }}
{{- $serviceUrl := $sqs.serviceUrl -}}
{{- if not $serviceUrl -}}
  {{- $serviceUrl = required "dependencies.sqs.region or dependencies.sqs.serviceUrl is required when dependencies.sqs.enabled" $sqs.region | printf "https://sqs.%s.amazonaws.com" -}}
{{- end }}
env:
  Components__QueueAdaptorSettings__ClassName: "ArmoniK.Core.Adapters.SQS.QueueBuilder"
  Components__QueueAdaptorSettings__AdapterAbsolutePath: "/adapters/queue/sqs/ArmoniK.Core.Adapters.SQS.dll"
  SQS__ServiceURL: {{ $serviceUrl | quote }}
  SQS__Prefix: {{ $sqs.prefix | quote }}
{{- with $sqs.region }}
  AWS_REGION: {{ . | quote }}
{{- end }}
{{- /* An empty attribute fails CreateQueue */}}
{{- with $sqs.kmsKeyId }}
  SQS__Attributes__KmsMasterKeyId: {{ . | quote }}
{{- end }}
{{- end }}
{{- end }}
