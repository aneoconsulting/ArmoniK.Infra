{{/*
Configuration for S3 forwarded to ArmoniK Core.
Core passes EndpointUrl to the AWS SDK as is, so it defaults to the regional endpoint rather than empty.
*/}}
{{- define "armonik.s3.conf" -}}
{{- $s3 := list .Values "dependencies" "s3" | include "armonik.utils.index" | fromYaml -}}
{{- if $s3.enabled }}
{{- $endpointUrl := $s3.endpointUrl -}}
{{- if not $endpointUrl -}}
  {{- $endpointUrl = required "dependencies.s3.region or dependencies.s3.endpointUrl is required when dependencies.s3.enabled" $s3.region | printf "https://s3.%s.amazonaws.com" -}}
{{- end }}
env:
  Components__ObjectStorageAdaptorSettings__ClassName: "ArmoniK.Core.Adapters.S3.ObjectBuilder"
  Components__ObjectStorageAdaptorSettings__AdapterAbsolutePath: "/adapters/object/s3/ArmoniK.Core.Adapters.S3.dll"
  S3__EndpointUrl: {{ $endpointUrl | quote }}
  S3__BucketName: {{ required "dependencies.s3.bucketName is required when dependencies.s3.enabled" $s3.bucketName | quote }}
{{- with $s3.region }}
  AWS_REGION: {{ . | quote }}
{{- end }}
{{- end }}
{{- end }}
